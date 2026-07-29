#!/bin/bash
# configure_ssh_ca_trust.sh
# Sets up SSH CA trust for a host to allow certificate authentication for principal 'jrs'.
# Usage: sudo ./configure_ssh_ca_trust.sh [CA_PUBKEY_PATH]

set -euo pipefail

CA_PUBKEY_SRC="${1:-/root/dotfiles/ssh/jrs-ssh-user-ca.pub}"
CA_PUBKEY_DST="${CA_PUBKEY_DST:-/etc/ssh/jrs-ssh-user-ca.pub}"
PRINCIPALS_DIR="/etc/ssh/principals"
PRINCIPALS_FILE="$PRINCIPALS_DIR/root"
SSHD_CONFIG_DIR="/etc/ssh/sshd_config.d"
USERCA_CONF="$SSHD_CONFIG_DIR/50-userca.conf"
AUTH_CONF="$SSHD_CONFIG_DIR/60-auth.conf"

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Copy CA public key
install -m 0644 -o root -g root "$CA_PUBKEY_SRC" "$CA_PUBKEY_DST"

# Create principals directory and file
mkdir -p "$PRINCIPALS_DIR"
echo 'jrs' > "$PRINCIPALS_FILE"
chmod 0644 "$PRINCIPALS_FILE"

# Write sshd drop-in configs
mkdir -p "$SSHD_CONFIG_DIR"
echo "TrustedUserCAKeys $CA_PUBKEY_DST" > "$USERCA_CONF"
echo "AuthorizedPrincipalsFile $PRINCIPALS_DIR/%u" > "$AUTH_CONF"
chmod 0644 "$USERCA_CONF" "$AUTH_CONF"

# Test sshd config
if ! sshd -t; then
  echo "sshd config test failed. Aborting." >&2
  exit 2
fi

# Reload sshd
systemctl reload sshd

echo "SSH CA trust configured. Principal 'jrs' is now trusted for root."
