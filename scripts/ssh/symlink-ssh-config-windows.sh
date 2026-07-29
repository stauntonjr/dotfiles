#!/usr/bin/env bash
# symlink-ssh-config-windows.sh
# Symlink or copy SSH config file on Windows (Git Bash/MSYS2/WSL or native)

# Expand ~ and resolve absolute/relative paths
expand_path() {
    case "$1" in
        ~) printf "%s\n" "$HOME" ;;
        ~/*) printf "%s\n" "$HOME/${1#~/}" ;;
        /*) printf "%s\n" "$1" ;;
        *) printf "%s\n" "$PWD/$1" ;;
    esac
}

echo "This script will symlink (or copy) your SSH config file on Windows."

default_src="$HOME/dotfiles/ssh/config"
default_dst="$HOME/.ssh/config"
read -rp "Enter source config file (default: $default_src): " src
src=$(expand_path "${src:-$default_src}")
read -rp "Enter destination config file (default: $default_dst): " dst
dst=$(expand_path "${dst:-$default_dst}")

# Ensure destination directory exists
mkdir -p "$(dirname "$dst")"

# Remove existing destination if present
if [ -e "$dst" ]; then
    echo "Removing existing $dst"
    rm -f "$dst"
fi

# Try to create a symlink (works in Git Bash/MSYS2/WSL)
if ln -s "$src" "$dst" 2>/dev/null; then
    echo "Symlinked $src -> $dst"
else
    # If ln -s fails, try mklink in cmd.exe (native Windows)
    echo "ln -s failed, trying mklink (requires admin on some systems)"
    src_win=$(cygpath -w "$src" 2>/dev/null || echo "$src")
    dst_win=$(cygpath -w "$dst" 2>/dev/null || echo "$dst")
    cmd.exe /C "mklink \"$dst_win\" \"$src_win\"" && echo "mklink created $dst_win -> $src_win" || {
        echo "mklink failed, falling back to copying file."
        cp "$src" "$dst" && echo "Copied $src to $dst."
    }
fi
