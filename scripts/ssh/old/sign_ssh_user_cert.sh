#!/bin/bash
# sign_ssh_user_cert.sh
# Signs an SSH public key for user authentication using your CA.

set -euo pipefail

# Path to the CA private key (must be accessible on this machine)
CA_KEY="/root/.ssh/jrs-id_ed25519"
# Path to the user's public key to sign (this machine's user key)
USER_PUBKEY="${1:-/root/.ssh/jrs-id_ed25519.pub}"
# Output certificate path
CERT_OUT="${2:-/root/.ssh/id_ed25519-cert.pub}"
# Username/principal for the cert
PRINCIPAL="${3:-jrs}"
# Validity period
VALIDITY="${4:-52w}"

if [[ ! -f "$CA_KEY" ]]; then
  echo "CA private key not found: $CA_KEY" >&2
  exit 1
fi

if [[ ! -f "$USER_PUBKEY" ]]; then
  echo "User public key not found: $USER_PUBKEY" >&2
  exit 1
fi

ssh-keygen -s "$CA_KEY" -I "$PRINCIPAL" -n "$PRINCIPAL" -V "+${VALIDITY}" -z 1 -f "$USER_PUBKEY" -h -O no-agent-forwarding -O no-port-forwarding -O no-pty -O no-user-rc -O no-x11-forwarding

# Move the generated cert to the desired output location
if [[ -f "${USER_PUBKEY}-cert.pub" ]]; then
  mv "${USER_PUBKEY}-cert.pub" "$CERT_OUT"
fi

echo "Certificate written to $CERT_OUT"