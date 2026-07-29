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

# Prompt user for filename, directory, and comment
DEFAULT_DIR="$HOME/dotfiles/ssh"
read -rp "Enter the directory to save the SSH key (default: $DEFAULT_DIR): " keydir
keydir=$(expand_path "${keydir:-$DEFAULT_DIR}")

# Ensure directory exists
mkdir -p "$keydir"

read -rp "Enter the filename for the SSH key (default: id_ed25519): " keyfile
keyfile=${keyfile:-id_ed25519}

read -rp "Enter a comment for the SSH key: " keycomment

keypath="$keydir/$keyfile"

# Generate SSH key
ssh-keygen -t ed25519 -f "$keypath" -C "$keycomment"

# Set permissions
chmod 600 "$keypath"
chmod 644 "$keypath.pub"

echo "SSH key generated at $keypath and $keypath.pub"
