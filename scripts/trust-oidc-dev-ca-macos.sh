#!/usr/bin/env bash
set -euo pipefail

# trust-oidc-dev-ca-macos.sh
# Install the local OIDC-DEV CA into the macOS trust store.
# Usage:
#   ./trust-oidc-dev-ca-macos.sh [path-to-ca.crt]
#
# Default CA:
#   ~/dotfiles/ssl/ca.crt
#
# This makes browsers and many system tools trust the local HTTPS services
# signed by OIDC-DEV-CA.

CA_PATH="${1:-$HOME/dotfiles/ssl/ca.crt}"

if [ ! -f "$CA_PATH" ]; then
  echo "CA certificate not found at $CA_PATH"
  echo "If this repo is using SOPS-managed secrets, run: bash ~/dotfiles/scripts/setup-secrets.sh"
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is intended for macOS (Darwin)."
  exit 2
fi

CERT_NAME="$(basename "$CA_PATH")"
TMP_CERT="/tmp/$CERT_NAME"
cp "$CA_PATH" "$TMP_CERT"

echo "Importing $CA_PATH into the login keychain..."
security add-trusted-cert \
  -d \
  -r trustRoot \
  -k "$HOME/Library/Keychains/login.keychain-db" \
  "$TMP_CERT"

echo "CA installed. Restart browsers and VS Code to pick up trust changes."
echo "If VS Code/Node still rejects the cert, launch it with:"
echo "  export NODE_EXTRA_CA_CERTS=\"$CA_PATH\""
echo "  code"
