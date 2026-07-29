#!/usr/bin/env bash
# fix-ssh-key-line-endings.sh
# Ensures SSH private/public key files have correct Unix (LF) line endings for OpenSSH compatibility on Windows.

# Expand ~ and resolve absolute/relative paths
expand_path() {
    case "$1" in
        ~) printf "%s\n" "$HOME" ;;
        ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
        /*) printf "%s\n" "$1" ;;
        *) printf "%s\n" "$PWD/$1" ;;
    esac
}

echo "This script will convert SSH key files to Unix (LF) line endings using dos2unix."
read -rp "Enter the path to the SSH key file to fix (e.g., ~/.ssh/id_ed25519): " keyfile
keyfile=$(expand_path "$keyfile")

if [ ! -f "$keyfile" ]; then
    echo "Error: File '$keyfile' not found."
    exit 1
fi

dos2unix "$keyfile"
echo "Line endings fixed for $keyfile."
