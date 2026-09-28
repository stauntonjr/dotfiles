#!/usr/bin/env bash
set -euo pipefail

# Regression: accepting the defaults must expand both ~/ paths before
# validating the source and creating the destination symlink.
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/.ssh"
ln -s /root/dotfiles "$test_home/dotfiles"

printf '\n\n' | HOME="$test_home" bash /root/dotfiles/scripts/ssh/symlink-ssh-config.sh >/dev/null

test -L "$test_home/.ssh/config"
test "$(readlink -f "$test_home/.ssh/config")" = "/root/dotfiles/ssh/config"
