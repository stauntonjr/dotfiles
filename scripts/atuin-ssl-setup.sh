#!/usr/bin/env bash
# Script to symlink SSL cert/key for Atuin server from dotfiles/ssl
# Usage: atuin-ssl-setup.sh <ATUIN_CONFIG_DIR>

set -e

ATUIN_CONFIG_DIR="${1:-$HOME/.config/atuin}"
DOTFILES_SSL="$HOME/dotfiles/ssl"

mkdir -p "$ATUIN_CONFIG_DIR"

if [ ! -f "$DOTFILES_SSL/wildcard.ediacarian.home.crt" ] || [ ! -f "$DOTFILES_SSL/wildcard.ediacarian.home.key" ]; then
    echo "Missing decrypted TLS material in $DOTFILES_SSL."
    echo "Run: bash ~/dotfiles/scripts/setup-secrets.sh"
    exit 1
fi

ln -sf "$DOTFILES_SSL/wildcard.ediacarian.home.crt" "$ATUIN_CONFIG_DIR/fullchain.pem"
ln -sf "$DOTFILES_SSL/wildcard.ediacarian.home.key" "$ATUIN_CONFIG_DIR/privkey.pem"

# Update server.toml for TLS
if [ -f "$ATUIN_CONFIG_DIR/server.toml" ]; then
    if ! grep -q '\[tls\]' "$ATUIN_CONFIG_DIR/server.toml"; then
        echo -e "\n[tls]\nenable = true\ncert_path = \"$ATUIN_CONFIG_DIR/fullchain.pem\"\npkey_path = \"$ATUIN_CONFIG_DIR/privkey.pem\"" >> "$ATUIN_CONFIG_DIR/server.toml"
    fi
fi

echo "SSL cert and key symlinked. Atuin server.toml updated for TLS."
