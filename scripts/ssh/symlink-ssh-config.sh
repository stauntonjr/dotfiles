#!/usr/bin/env bash
set -euo pipefail

# Expand ~ and resolve absolute/relative paths
expand_path() {
  case "$1" in
    ~) printf "%s\n" "$HOME" ;;
    ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
    /*) printf "%s\n" "$1" ;;
    *) printf "%s\n" "$PWD/$1" ;;
  esac
}

# Set defaults
DEFAULT_SRC="~/dotfiles/ssh/config"
DEFAULT_DST="~/.ssh/config"

# This script symlinks a source file to a destination path (e.g., dotfiles/ssh/config to ~/.ssh/config)
# - Prompts for src and dst, using defaults if empty
# - Creates parent dir for dst if missing
# - Backs up an existing non-symlink dst to dst.bak.<timestamp>
# - Forces the symlink to point to the src
# - Ensures parent dir has secure permissions

read -rp "Enter the source file to symlink [${DEFAULT_SRC}]: " src
src=${src:-$DEFAULT_SRC}
src=$(expand_path "$src")

read -rp "Enter the destination path for the symlink [${DEFAULT_DST}]: " dst
dst=${dst:-$DEFAULT_DST}
dst=$(expand_path "$dst")

echo "Source: $src"
echo "Destination: $dst"

if [ ! -f "$src" ]; then
  echo "Error: source file not found at $src" >&2
  exit 1
fi

dst_dir="$(dirname "$dst")"
mkdir -p "$dst_dir"
chmod 700 "$dst_dir"

# Backup existing file if it's not a symlink
if [ -e "$dst" ] && [ ! -L "$dst" ]; then
  ts="$(date +%Y%m%d-%H%M%S)"
  mv "$dst" "$dst.bak.$ts"
  echo "Backed up existing $dst to $dst.bak.$ts"
fi

# Create/refresh symlink
ln -sfn "$src" "$dst"

# Try to ensure the target file has safe perms (if regular file)
if resolved=$(readlink -f "$dst" 2>/dev/null); then
  if [ -f "$resolved" ]; then
    chmod 600 "$resolved" || true
  fi
fi

echo "Symlinked: $dst -> $src"