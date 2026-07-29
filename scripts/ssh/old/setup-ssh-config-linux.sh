#!/usr/bin/env bash
set -euo pipefail
CFG_SRC="$HOME/dotfiles/ssh/config"
CFG_DST="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
if [ -f "$CFG_DST" ] && [ ! -L "$CFG_DST" ]; then
  cp "$CFG_DST" "$CFG_DST.bak.$(date +%s)"
fi
ln -sf "$CFG_SRC" "$CFG_DST"
chmod 600 "$CFG_DST"
echo "Linked $CFG_DST -> $CFG_SRC"
