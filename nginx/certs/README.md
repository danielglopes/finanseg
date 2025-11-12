# Certificados locais (não versionados)

Este diretório armazena apenas artefatos *locais* de TLS. Para evitar vazamento de segredos, os arquivos reais são ignorados no Git (.gitignore). Gere-os manualmente antes de subir o stack.

## Passo a passo rápido
```bash
cd nginx/certs

# 1. Ajuste os domínios conforme necessário
cp san.cnf.example san.cnf

# 2. Gere/rotacione a chave do servidor
openssl genrsa -out server.key 2048

# 3. Crie o CSR
openssl req -new -key server.key \
  -subj "/C=BR/ST=MG/L=Local/O=FinanSeg/OU=TI/CN=app.finanseg.local" \
  -out server.csr

# 4. Assine usando a CA local existente (copie/importe ca.key + ca.pem manualmente)
openssl x509 -req -in server.csr \
  -CA ca.pem -CAkey ca.key -CAcreateserial \
  -out server.crt -days 825 -sha256 -extfile san.cnf

# 5. Conferir
openssl verify -CAfile ca.pem server.crt
```

> **Importante:** mantenha `ca.key`, `server.key`, `server.crt`, `server.csr`, `ca.pem`, `ca.srl`, `dhparam.pem` e demais arquivos sensíveis fora de repositórios públicos. Faça backup seguro em outra mídia (cofre de segredos, gerenciador de senhas, etc.).
