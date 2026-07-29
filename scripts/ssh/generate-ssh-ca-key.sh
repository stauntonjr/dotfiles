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

# Prompt user for directory, filename, and comment for the SSH CA key
DEFAULT_DIR="$HOME/dotfiles/ssh"
read -rp "Enter the directory to save the SSH CA key (default: $DEFAULT_DIR): " cadir
cadir=$(expand_path "${cadir:-$DEFAULT_DIR}")

# Ensure directory exists
mkdir -p "$cadir"

read -rp "Enter the filename for the SSH CA key (default: ssh_ca): " cafile
cafile=${cafile:-ssh_ca}

read -rp "Enter a comment for the SSH CA key: " cacmt

capath="$cadir/$cafile"

# Generate SSH CA key
ssh-keygen -t ed25519 -f "$capath" -C "$cacmt"

# Set permissions
chmod 600 "$capath"
chmod 644 "$capath.pub"

echo "SSH CA key generated at $capath and $capath.pub"
