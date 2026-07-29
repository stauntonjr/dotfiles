#!/usr/bin/env bash
# Refresh and publish an OpenSSH user certificate, then store encrypted in repo via SOPS.
# Defaults assume:
# - User CA:      ~/.ssh/ca/jrs-ssh-user-ca
# - User pubkey:  ~/.ssh/id_ed25519.pub
# - Cert out:     ~/.ssh/id_ed25519-cert.pub
# - Principal(s): jrs
# - Validity:     +52w (1 year)
# - Repo dest:    <repo_root>/ssh/id_ed25519-cert.pub
# Override via environment vars: CA_KEY, PUB_KEY, CERT_OUT, PRINCIPALS, VALIDITY, DEST, REPO_ROOT, PUSH

set -euo pipefail

CA_KEY=${CA_KEY:-"$HOME/.ssh/ca/jrs-ssh-user-ca"}
PUB_KEY=${PUB_KEY:-"$HOME/.ssh/id_ed25519.pub"}
CERT_OUT=${CERT_OUT:-"$HOME/.ssh/id_ed25519-cert.pub"}
PRINCIPALS=${PRINCIPALS:-"jrs"}
VALIDITY=${VALIDITY:-"+52w"}
# Derive repo root relative to this script (../../)
REPO_ROOT=${REPO_ROOT:-"$(cd "$(dirname "$0")"/../.. && pwd)"}
DEST=${DEST:-"$REPO_ROOT/ssh/id_ed25519-cert.pub"}
PUSH=${PUSH:-1}

err() { echo "[ssh-cert-update] $*" >&2; }

# Preconditions
command -v ssh-keygen >/dev/null 2>&1 || { err "ssh-keygen not found"; exit 1; }
command -v sops >/dev/null 2>&1 || { err "sops not found"; exit 1; }
[ -f "$CA_KEY" ] || { err "CA key not found: $CA_KEY"; exit 1; }
[ -f "$PUB_KEY" ] || { err "User public key not found: $PUB_KEY"; exit 1; }

# Sign the user key
IDENT="jrs-$(date +%Y%m%d)"
echo "[ssh-cert-update] Signing $PUB_KEY with CA $CA_KEY as principals=[$PRINCIPALS], validity=$VALIDITY"
ssh-keygen -q -s "$CA_KEY" -I "$IDENT" -n "$PRINCIPALS" -V "$VALIDITY" "$PUB_KEY"
[ -f "$CERT_OUT" ] || { err "Expected cert not found after signing: $CERT_OUT"; exit 1; }

# Copy to repo destination
mkdir -p "$(dirname "$DEST")"
cp -f "$CERT_OUT" "$DEST"

echo "[ssh-cert-update] Re-encrypting $DEST into repo store"
bash "$REPO_ROOT/scripts/secrets/encrypt-all.sh" "ssh/id_ed25519-cert.pub"

# Commit and optionally push
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_ROOT" add "$REPO_ROOT/secrets/store/ssh/id_ed25519-cert.pub.sops"
  git -C "$REPO_ROOT" commit -m "ssh: refresh cert ($IDENT, principals=$PRINCIPALS, $VALIDITY)" || true
  if [ "$PUSH" = "1" ]; then
    git -C "$REPO_ROOT" push || true
  fi
fi

echo "[ssh-cert-update] Done: $DEST and corresponding encrypted store updated"
