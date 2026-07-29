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

echo "This script authorizes a principal (identity) to log in as a specific user on this server using SSH certificates."

# Prompt for principal
read -rp "Enter the principal to authorize (e.g., jrs): " principal

# Prompt for username to authorize principal for
read -rp "Enter the username to allow this principal to log in as (e.g., ubuntu): " username

# Prompt for authorized principals directory (default: /etc/ssh/authorized_principals)
read -rp "Enter the authorized principals directory (default: /etc/ssh/authorized_principals): " apdir
apdir=$(expand_path "${apdir:-/etc/ssh/authorized_principals}")

# Ensure directory exists
sudo mkdir -p "$apdir"

# Add principal to the user's authorized principals file
apfile="$apdir/$username"
echo "$principal" | sudo tee "$apfile" > /dev/null
sudo chown root:root "$apfile"
sudo chmod 644 "$apfile"

echo "Principal '$principal' is now authorized to log in as user '$username' via SSH certificate."
echo "Ensure your /etc/ssh/sshd_config contains:"
echo "  AuthorizedPrincipalsFile $apdir/%u"
