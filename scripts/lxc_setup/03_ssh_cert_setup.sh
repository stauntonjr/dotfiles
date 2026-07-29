#!/usr/bin/env bash
# Usage: 03_ssh_cert_setup.sh <CTID> <PRINCIPAL>
# Sets up SSH CA trust and principal authorization in the container

set -e

CTID="$1"
PRINCIPAL="$2"

# Copy trust and principal scripts
pct push "$CTID" ~/dotfiles/scripts/ssh/trust-ssh-ca.sh /root/trust-ssh-ca.sh
pct push "$CTID" ~/dotfiles/scripts/ssh/authorize-ssh-principal.sh /root/authorize-ssh-principal.sh

# Trust SSH CA (assumes default answers for user CA and /etc/ssh)
pct exec "$CTID" -- bash -c 'echo -e "\n\nuser" | bash /root/trust-ssh-ca.sh'

# Authorize principal for root
pct exec "$CTID" -- bash -c "echo -e '$PRINCIPAL\nroot\n\n' | bash /root/authorize-ssh-principal.sh"

# Enable AuthorizedPrincipalsFile in sshd_config
pct exec "$CTID" -- sed -i '/^#AuthorizedPrincipalsFile/c\AuthorizedPrincipalsFile /etc/ssh/authorized_principals/%u' /etc/ssh/sshd_config

# Disable password auth and allow root login
pct exec "$CTID" -- sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
pct exec "$CTID" -- sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Restart SSH
pct exec "$CTID" -- systemctl restart sshd
