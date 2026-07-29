#!/usr/bin/env bash
# This script helps a Windows OpenSSH client trust a CA for host or user certificates.
# It appends the CA public key to the user's known_hosts file with the @cert-authority marker.

# Expand ~ and resolve absolute/relative paths
expand_path() {
    case "$1" in
        ~) printf "%s\n" "$HOME" ;;
        ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
        /*) printf "%s\n" "$1" ;;
        *) printf "%s\n" "$PWD/$1" ;;
    esac
}


DEFAULT_CA_PUB="$HOME/dotfiles/ssh/ssh_ca.pub"
DEFAULT_KNOWN_HOSTS="$HOME/.ssh/known_hosts"
DEFAULT_SERVER_CA="/c/ProgramData/ssh/ca_user.pub"

read -rp "Enter the path to the CA public key (default: $DEFAULT_CA_PUB): " ca_pub
ca_pub=$(expand_path "${ca_pub:-$DEFAULT_CA_PUB}")

read -rp "Enter the known_hosts file to update (default: $DEFAULT_KNOWN_HOSTS): " kh_file
kh_file=$(expand_path "${kh_file:-$DEFAULT_KNOWN_HOSTS}")

read -rp "Enter the host pattern to trust (e.g., * or *.mydomain.com): " hostpat

if [ ! -f "$ca_pub" ]; then
    echo "Error: CA public key file '$ca_pub' not found."
    exit 1
fi

# Read the CA public key
ca_key=$(cat "$ca_pub")

# Append @cert-authority line to known_hosts
entry="@cert-authority $hostpat $ca_key"
grep -qxF "$entry" "$kh_file" 2>/dev/null || echo "$entry" >> "$kh_file"

chmod 600 "$kh_file"
echo "Trusted CA for $hostpat in $kh_file."

# Optionally copy CA public key to server location for sshd
read -rp "Copy CA public key to server for TrustedUserCAKeys? (y/N): " copy_server
if [[ "$copy_server" =~ ^[Yy]$ ]]; then
    server_ca_path=""
    read -rp "Enter server CA public key path (default: $DEFAULT_SERVER_CA): " server_ca_path
    server_ca_path=$(expand_path "${server_ca_path:-$DEFAULT_SERVER_CA}")
    mkdir -p "$(dirname "$server_ca_path")"
    cp "$ca_pub" "$server_ca_path"
    chmod 644 "$server_ca_path"
    echo "Copied CA public key to $server_ca_path for server-side TrustedUserCAKeys."
    echo "Ensure sshd_config contains:"
    echo "  TrustedUserCAKeys C:/ProgramData/ssh/ca_user.pub"
fi
