#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

declare -A FILES=(
    [".env.example"]=".env"
    [".db.env.example"]=".db.env"
    [".importer.env.example"]=".importer.env"
)

for src in "${!FILES[@]}"; do
    dst="${FILES[$src]}"

    if [[ ! -f "$src" ]]; then
        echo "✖ Arquivo de exemplo não encontrado: $src" >&2
        exit 1
    fi

    if [[ -f "$dst" ]]; then
        read -r -p "⚠ $dst já existe. Deseja sobrescrever? [y/N] " answer
        case "$answer" in
            [yY][eE][sS]|[yY]) ;;
            *) echo "↷ Mantido $dst"; continue ;;
        esac
    fi

    cp "$src" "$dst"
    echo "✓ Copiado $src → $dst"
done

echo "Env files prontos. Ajuste os valores conforme necessário antes de executar docker compose up."
