#!/usr/bin/env bash
# Legacy helper: materialize repo-local SSH secret files into a target directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT_DIR="${1:-$REPO_ROOT/ssh}"
DECRYPT_SCRIPT="$REPO_ROOT/scripts/secrets/decrypt-all.sh"

FILES=(
  "ssh/old/jrs-ssh-user-ca"
  "ssh/old/jrs-id_ed25519"
  "ssh/old/dns-srv.key"
  "ssh/old/mcp-srv-ca.key"
  "ssh/old/mcp-srv-local.key"
)

mkdir -p "$OUT_DIR"

for target in "${FILES[@]}"; do
  bash "$DECRYPT_SCRIPT" "$target" >/dev/null
  src="$REPO_ROOT/$target"
  dest="$OUT_DIR/$(basename "$target")"
  cp "$src" "$dest"
  chmod 600 "$dest"
  echo "[OK] Materialized $target -> $dest"
done

echo "---"
echo "Emitted files to $OUT_DIR"
