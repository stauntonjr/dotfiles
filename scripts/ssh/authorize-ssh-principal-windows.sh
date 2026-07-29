#!/usr/bin/env bash
# This script authorizes a principal to log in as a specific user on a Windows OpenSSH server using SSH certificates.
# It creates or updates the authorized_principals file for the user in the user's .ssh directory.

# Expand ~ and resolve absolute/relative paths
expand_path() {
    case "$1" in
        ~) printf "%s\n" "$HOME" ;;
        ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
        /*) printf "%s\n" "$1" ;;
        *) printf "%s\n" "$PWD/$1" ;;
    esac
}

echo "This script authorizes a principal (identity) to log in as a specific user on this Windows OpenSSH server using SSH certificates."

read -rp "Enter the principal to authorize (e.g., jrs): " principal
read -rp "Enter the username to allow this principal to log in as (e.g., User): " username


# Default to C:/ProgramData/ssh/authorized_principals/<username>
default_apdir="/c/ProgramData/ssh/authorized_principals"
read -rp "Enter the authorized principals directory (default: $default_apdir): " apdir
apdir=$(expand_path "${apdir:-$default_apdir}")

# Ensure directory exists
mkdir -p "$apdir"

# Add principal to the correct authorized_principals file for the user
apfile="$apdir/$username"
echo "$principal" > "$apfile"
chmod 644 "$apfile"

echo "Principal '$principal' is now authorized to log in as user '$username' via SSH certificate."
echo "File: $apfile"
echo "Ensure your sshd_config contains:"
echo "  AuthorizedPrincipalsFile C:/ProgramData/ssh/authorized_principals/%u"
