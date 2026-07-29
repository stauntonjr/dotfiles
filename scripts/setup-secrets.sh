#!/usr/bin/env bash
set -euo pipefail

# This script materializes the repo-local SOPS-managed secrets back into their
# normal plaintext locations in the working tree.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "[setup-secrets] Dotfiles dir: $DOTFILES_DIR"
echo "[setup-secrets] Decrypting repo-managed secrets..."
bash "$DOTFILES_DIR/scripts/secrets/decrypt-all.sh"
