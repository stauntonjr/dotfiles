#!/usr/bin/env bash

# Expand ~ and resolve absolute/relative paths robustly
gen_path() {
  local input="$1"
  eval echo $input
}

# This script helps you create an SSH certificate by having the SSH Certificate Authority (CA) sign a public key.
# Imagine: "The private key of the SSH Certificate Authority (CA) (let's call it {{filename1}}) signs the SSH public key ({{filename2}}), creating the SSH certificate ({{filename3}})."

echo "SSH certificates can be for users or hosts:"
echo "- User certificates let people (users) log in to servers."
echo "- Host certificates let servers prove their identity to clients."
echo "If you want to allow a person to log in, choose 'user'. If you want to identify a server, choose 'host'."
read -rp "Should this certificate be for a user or a host? (user/host, default: user): " certtype
certtype=${certtype:-user}

# Set default directory
DEFAULT_DIR="$HOME/dotfiles/ssh"

# Prompt for CA private key
read -rp "Enter the path to the SSH CA private key (default: $DEFAULT_DIR/ssh_ca): " ca_key
ca_key=$(gen_path "${ca_key:-$DEFAULT_DIR/ssh_ca}")

# Prompt for public key to sign
read -rp "Enter the path to the SSH public key to sign (default: $DEFAULT_DIR/id_ed25519.pub): " pubkey
pubkey=$(gen_path "${pubkey:-$DEFAULT_DIR/id_ed25519.pub}")

# Prompt for output certificate filename
read -rp "Enter the filename for the SSH certificate to create (default: $DEFAULT_DIR/id_ed25519-cert.pub): " certfile
certfile=$(gen_path "${certfile:-$DEFAULT_DIR/id_ed25519-cert.pub}")

# Prompt for certificate identity (principal)
read -rp "Enter the identity (principal) for the certificate (e.g., username): " principal

# Prompt for certificate validity period (default: 5 years). Accepts integer (years) or full format.
echo "Enter the validity period. You can enter just a number of years (e.g., 5), or use the full format (e.g., +0s:+1825d for 5 years, +0s:+1w for 1 week). Default: 5"
read -rp "Validity period: " validity
validity=${validity:-5}

# If the user entered just an integer, convert to +0s:+<N>d (days)
if [[ "$validity" =~ ^[0-9]+$ ]]; then
    days=$((validity * 365))
    validity="+0s:+${days}d"
fi

# Ensure CA private key has correct permissions
chmod 600 "$ca_key"

# Set -h flag for host certificates
host_flag=""
if [ "$certtype" = "host" ]; then
    host_flag="-h"
fi

# Sign the public key with the CA private key to create the certificate
ssh-keygen -s "$ca_key" $host_flag -I "$principal" -n "$principal" -V "$validity" -z 1 "$pubkey"

# Move the generated certificate to the desired filename
cert_generated="${pubkey%.pub}-cert.pub"
if [ -f "$cert_generated" ] && [ "$cert_generated" != "$certfile" ]; then
    mv "$cert_generated" "$certfile"
    echo "The private key of the SSH Certificate Authority ($ca_key) signed the SSH public key $pubkey, creating the SSH certificate $certfile."
elif [ -f "$cert_generated" ]; then
    echo "The private key of the SSH Certificate Authority ($ca_key) signed the SSH public key $pubkey, creating the SSH certificate $certfile."
else
    echo "Certificate generation failed."
fi
