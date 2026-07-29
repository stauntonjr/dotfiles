#!/usr/bin/env bash
# Usage: 02_prepare_container.sh <CTID>
# Installs git, copies SSH key, sets up git config, and clones dotfiles

set -e

CTID="$1"


# Update and install required packages
pct exec "$CTID" -- apt-get update
pct exec "$CTID" -- apt-get install -y git curl zoxide

# Install starship prompt
pct exec "$CTID" -- sh -c "curl -sS https://starship.rs/install.sh | sh -s -- -y"

# Ensure /usr/local/bin is in PATH for root
pct exec "$CTID" -- bash -c 'grep -q "/usr/local/bin" /root/.bashrc || echo "export PATH=\"/usr/local/bin:\$PATH\"" >> /root/.bashrc'

# Ensure /root/.ssh exists
pct exec "$CTID" -- mkdir -p /root/.ssh

# Copy SSH private key (edit path as needed)
pct push "$CTID" ~/.ssh/github_ed25519 /root/.ssh/github_ed25519
pct exec "$CTID" -- chmod 600 /root/.ssh/github_ed25519

# Write .gitconfig
pct exec "$CTID" -- bash -c 'cat > /root/.gitconfig <<EOF
[user]
	name = stauntonjr
	email = jack.rory.staunton@gmail.com
[core]
	sshCommand = "ssh -i /root/.ssh/github_ed25519"
EOF'

# Clone dotfiles
pct exec "$CTID" -- git clone git@github.com:stauntonjr/dotfiles.git /root/dotfiles || pct exec "$CTID" -- bash -c 'cd /root/dotfiles && git pull'

# Symlink SSH config
pct exec "$CTID" -- ln -sf /root/dotfiles/ssh/config /root/.ssh/config
