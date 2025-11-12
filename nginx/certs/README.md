# Certificados locais (não versionados)

Este diretório armazena apenas artefatos *locais* de TLS. Para evitar vazamento de segredos, os arquivos reais são ignorados no Git (.gitignore). Gere-os manualmente antes de subir o stack.

## Passo a passo rápido
### 1. Script automatizado (recomendado)
```bash
# a partir da raiz do projeto
./scripts/generate-certs.sh            # usa SAN padrão
./scripts/generate-certs.sh my.domain  # Common Name customizado
```
O script:
- cria/atualiza `san.cnf` (a partir de `san.cnf.example`);
- gera uma CA local (`ca.key` + `ca.pem`) e exporta `fireflyCA.crt` se ela não existir;
- produz `dhparam.pem` (configurável via `DH_BITS`, default 2048);
- gera `server.key`, `server.csr`, assina `server.crt` com a CA e roda `openssl verify`;
- faz backup de artefatos antigos (`*.bak` com carimbo de tempo).

### 2. Procedimento manual (quando quiser personalizar tudo)
```bash
cd nginx/certs
cp san.cnf.example san.cnf   # ajuste os domínios
openssl genrsa -out server.key 2048
openssl req -new -key server.key \
  -subj "/C=BR/ST=MG/L=Local/O=FinanSeg/OU=TI/CN=app.finanseg.local" \
  -out server.csr
openssl x509 -req -in server.csr \
  -CA ca.pem -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 -extfile san.cnf
openssl verify -CAfile ca.pem server.crt
```

> **Importante:** mantenha `ca.key`, `server.key`, `server.crt`, `server.csr`, `ca.pem`, `ca.srl`, `dhparam.pem` e demais arquivos sensíveis fora de repositórios públicos. Faça backup seguro em outra mídia (cofre de segredos, gerenciador de senhas, etc.).
