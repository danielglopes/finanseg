#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="$ROOT_DIR/nginx/certs"
SAN_FILE="$CERT_DIR/san.cnf"
SAN_TEMPLATE="$CERT_DIR/san.cnf.example"
CN="${1:-app.finanseg.local}"

mkdir -p "$CERT_DIR"

require_file() {
    local file="$1"
    local label="$2"
    if [[ ! -f "$file" ]]; then
        echo "✖ $label não encontrado em $file" >&2
        exit 1
    fi
}

backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local ts
        ts="$(date +%Y%m%d-%H%M%S)"
        mv "$file" "${file}.${ts}.bak"
    fi
}

# Garante arquivo SAN
if [[ ! -f "$SAN_FILE" ]]; then
    if [[ -f "$SAN_TEMPLATE" ]]; then
        cp "$SAN_TEMPLATE" "$SAN_FILE"
    else
        cat > "$SAN_FILE" <<'EOF'
subjectAltName = @alt_names
[alt_names]
DNS.1 = app.finanseg.local
DNS.2 = finanseg.local
EOF
    fi
    echo "✓ Criado $SAN_FILE (ajuste os domínios se necessário)."
fi

require_file "$CERT_DIR/ca.key" "Chave privada da CA (ca.key)"
require_file "$CERT_DIR/ca.pem" "Certificado da CA (ca.pem)"

echo "→ Gerando chave privada do servidor..."
backup_if_exists "$CERT_DIR/server.key"
openssl genrsa -out "$CERT_DIR/server.key" 2048 >/dev/null

echo "→ Criando CSR para CN=$CN ..."
backup_if_exists "$CERT_DIR/server.csr"
openssl req -new -key "$CERT_DIR/server.key" \
  -subj "/C=BR/ST=MG/L=Local/O=FinanSeg/OU=TI/CN=${CN}" \
  -out "$CERT_DIR/server.csr"

echo "→ Assinando certificado com a CA local..."
backup_if_exists "$CERT_DIR/server.crt"
openssl x509 -req -in "$CERT_DIR/server.csr" \
  -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
  -out "$CERT_DIR/server.crt" -days 825 -sha256 -extfile "$SAN_FILE"

echo "→ Validando cadeia..."
openssl verify -CAfile "$CERT_DIR/ca.pem" "$CERT_DIR/server.crt"

echo ""
echo "✓ Certificados gerados em $CERT_DIR"
echo "   - server.key"
echo "   - server.csr"
echo "   - server.crt"
echo ""
echo "Finalize reiniciando o proxy: docker compose restart nginx"
