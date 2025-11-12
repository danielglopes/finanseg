# Firefly + FinanSeg Stack

Projeto que provisiona o Firefly III (gestão financeira pessoal) por trás de um Nginx reverse proxy com TLS local e um site institucional estático da FinanSeg. Ideal para laboratórios de segurança, demonstrações internas e provas de conceito com subdomínios segregando as áreas pública (HTTP) e segura (HTTPS).

## Arquitetura
- **Firefly III (`app`)**: container `fireflyiii/core` exposto apenas na rede interna (`firefly_iii`) na porta 8080.
- **Banco de dados (`db`)**: MariaDB LTS persistindo em `firefly_iii_db`.
- **Job Cron (`cron`)**: container Alpine que dispara o endpoint `/api/v1/cron/<token>` diariamente.
- **Nginx (`nginx`)**: imagem `nginx:trixie-perl` atuando como proxy e web server estático.
  - `finanseg.local` → porta 80, serve `nginx/public_html`.
  - `app.finanseg.local` → redireciona HTTP→HTTPS e termina TLS antes de encaminhar para `app:8080`.
- **Certificados**: CA própria (`ca.key`/`ca.pem`) assina `server.crt` com SAN para `app.finanseg.local` e `finanseg.local`.

## Estrutura de pastas
```
docker-compose.yaml        # Orquestra containers
nginx/
  nginx.conf               # Servidores HTTP/HTTPS e upstream Firefly
  public_html/             # Site institucional (index, sobre, política, contato, style.css)
  certs/                   # CA, CSR e chaves TLS (NÃO subir para repositórios públicos)
AGENTS.md                  # Guia rápido para agentes/contribuidores
```

## Pré-requisitos
- Docker + Docker Compose Plugin (v2+).
- Make sure the current user can talk to the Docker daemon (ou rode com sudo).
- Ferramentas OpenSSL já embutidas na maioria das distros.

## Passo a passo de setup
1. **Clonar e configurar variáveis**  
   - Use o helper para gerar os arquivos reais a partir dos exemplos e depois ajuste os valores:
     ```bash
     ./scripts/setup-env.sh
     ```
   - Caso queira fazer na mão: copie `.env.example`, `.db.env.example` e `.importer.env.example` para as versões reais e personalize.
2. **Popular hosts locais**  
   ```
   127.0.0.1 finanseg.local
   127.0.0.1 app.finanseg.local
   ```
3. **(Opcional) Importar CA no sistema**  
   Instale `nginx/certs/ca.pem` no trust store do seu SO/navegador para evitar avisos TLS.
4. **Gerar/rotacionar certificados**
   - Execute o script automatizado; ele cria a CA local (se não existir), gera `dhparam.pem`, garante `san.cnf`, produz `server.key/csr/crt` e valida tudo.
     ```bash
     ./scripts/generate-certs.sh                # CN padrão app.finanseg.local
     ./scripts/generate-certs.sh my.domain.test # Common Name customizado
     ```
   - Os arquivos ficam apenas em `nginx/certs/` (ignorados pelo Git). Edite `nginx/certs/san.cnf` se quiser SAN extras antes de rodar novamente. Variáveis `CA_DAYS`, `SERVER_DAYS` e `DH_BITS` podem ser exportadas para customizar validade e tamanho do dhparam.
5. **Subir os serviços**  
   ```bash
   docker compose up -d
   docker compose logs -f nginx
   ```

## Uso
- **Site institucional**: `http://finanseg.local` (HTTP deliberado). Botão “Acessar Sistema” envia para o domínio seguro.
- **Firefly III**: `https://app.finanseg.local`. Caso a CA esteja confiável, o navegador exibirá o cadeado verde “Emitido por: UFVJM-SASI-CA”.
- **Rotina cron**: confirme que `STATIC_CRON_TOKEN` está definido em `.env`. Logs aparecem via `docker compose logs -f cron`.

## Comandos úteis
```bash
docker compose ps                 # status dos containers
docker compose restart nginx      # recarregar config/certificados
docker compose down -v            # destruir ambiente e volumes
curl -I http://finanseg.local     # verificação HTTP
curl -I https://app.finanseg.local/login --cacert nginx/certs/ca.pem  # verificação HTTPS
```

## Manutenção & Boas práticas
- **Certificados**: renove antes dos 825 dias; mantenha `ca.key` e `server.key` fora de repositórios públicos.
- **Conteúdo estático**: atualize em `nginx/public_html`. O Nginx está montado em read-only, então edite os arquivos locais e reinicie.
- **Firefly upgrades**: altere a tag da imagem `fireflyiii/core` e execute `docker compose pull && docker compose up -d`.
- **Backups**: volume `firefly_iii_db` contém o banco (MariaDB). Considere dumps periódicos e snapshots dos volumes.

## Solução de problemas
- **TLS inválido**: importe `ca.pem` ou use `curl --cacert`. Verifique `openssl verify`.
- **Nginx não sobe**: rode `docker compose exec nginx nginx -t` para validar sintaxe.
- **Redirecionamentos incorretos**: confirme entradas do `/etc/hosts` e limpe DNS cache (`sudo systemd-resolve --flush-caches`).

Com isso você tem um ambiente completo que separa a vitrine pública da área autenticada, seguindo o desenho definido nas políticas da FinanSeg.
