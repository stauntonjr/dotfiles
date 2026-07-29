#!/usr/bin/env bash
# Symlink central atuin config to ~/.config/atuin/config.toml
# Usage: atuin-config-symlink.sh [TARGET_CONFIG_DIR]

set -e

TARGET_CONFIG_DIR="${1:-$HOME/.config/atuin}"
CENTRAL_CONFIG="$HOME/dotfiles/atuin/config.toml"

mkdir -p "$TARGET_CONFIG_DIR"
ln -sf "$CENTRAL_CONFIG" "$TARGET_CONFIG_DIR/config.toml"

echo "Symlinked $CENTRAL_CONFIG to $TARGET_CONFIG_DIR/config.toml"
