#!/usr/bin/env bash

# Expand ~ and resolve absolute/relative paths
expand_path() {
    case "$1" in
        ~) printf "%s\n" "$HOME" ;;
        ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
        /*) printf "%s\n" "$1" ;;
        *) printf "%s\n" "$PWD/$1" ;;
    esac
}

# This script helps a host trust an SSH Certificate Authority (CA) by adding the CA's public key to the trusted list.
# Imagine: "If you trust the CA's public key, you trust all certificates it signs!"

echo "SSH Certificate Authorities (CAs) can be for users or hosts:"
echo "- User CA: lets the server trust user certificates for login."
echo "- Host CA: lets clients trust host certificates for server identity."
echo "Most setups use a user CA for login."

# Set default CA public key path
DEFAULT_CA_PUB="$HOME/dotfiles/ssh/ssh_ca.pub"
# Prompt for the CA public key file
read -rp "Enter the path to the SSH CA public key (default: $DEFAULT_CA_PUB): " ca_pubkey
ca_pubkey_abs=$(expand_path "${ca_pubkey:-$DEFAULT_CA_PUB}")
if [ ! -f "$ca_pubkey_abs" ]; then
    echo "Error: CA public key file '$ca_pubkey_abs' not found. Please provide a valid path."
    exit 1
fi

# Prompt for the directory to update (default: /etc/ssh)
read -rp "Enter the SSH config directory (default: /etc/ssh): " sshdir
sshdir=$(expand_path "${sshdir:-/etc/ssh}")

# Prompt for the type of CA (host or user)
read -rp "Is this a user CA or a host CA? (user/host, default: user): " catype
catype=${catype:-user}

# Set the target file based on CA type
if [ "$catype" = "user" ]; then
    target="$sshdir/ssh_user_ca_keys"
else
    target="$sshdir/ssh_ca_keys"
fi

# Copy the CA public key to the target file
sudo cp "$ca_pubkey_abs" "$target"
sudo chown root:root "$target"
sudo chmod 644 "$target"

# Configure OpenSSH to trust the CA
sshd_config="$sshdir/sshd_config"
if [ "$catype" = "user" ]; then
    config_line="TrustedUserCAKeys $target"
else
    config_line="HostCertificate $target"
fi

# Add the config line if not already present
if ! grep -qF "$config_line" "$sshd_config"; then
    echo "$config_line" | sudo tee -a "$sshd_config"
    echo "Added '$config_line' to $sshd_config."
else
    echo "$config_line" already present in $sshd_config.
fi

# Restart sshd to apply changes
echo "Restarting sshd to apply changes..."
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart sshd
else
    sudo service ssh restart
fi

echo "The host now trusts the SSH CA public key ($ca_pubkey_abs). All certificates signed by this CA will be trusted!"
