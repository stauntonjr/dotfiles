#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export DOTFILES_DIR=${DOTFILES_DIR:-"$(CDPATH= cd -- "$script_dir/../.." && pwd)"}
install_tools=true
install_links=true

usage() {
	cat <<'EOF'
Usage: setup-shell.sh [--links-only | --tools-only]

Sets up the repository-managed Bash configuration on a new machine.
  --links-only  Back up and install shell configuration files; install no packages.
  --tools-only  Install/update shell tools; change no shell configuration files.
EOF
}

case "${1:-}" in
	"") ;;
	--links-only) install_tools=false ;;
	--tools-only) install_links=false ;;
	-h|--help) usage; exit 0 ;;
	*) usage >&2; exit 2 ;;
esac

if [ "$install_tools" = true ]; then
	bash "$script_dir/install-shell-tools.sh"
fi

if [ "$install_links" = true ]; then
	bash "$script_dir/install-bashrc.sh"
fi

printf '\nShell setup complete. Start a new terminal to apply all changes.\n'
