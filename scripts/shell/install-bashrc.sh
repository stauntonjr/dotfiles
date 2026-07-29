#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir=${DOTFILES_DIR:-"$HOME/dotfiles"}
backup_suffix="pre-dotfiles.$(date +%Y%m%d-%H%M%S)"

link_config() {
	local source=$1 target=$2 backup=

	if [ ! -e "$source" ]; then
		printf 'Missing dotfile: %s\n' "$source" >&2
		return 1
	fi

	if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
		printf 'Already linked: %s\n' "$target"
		return 0
	fi

	if [ -e "$target" ] || [ -L "$target" ]; then
		backup="${target}.${backup_suffix}"
		mv "$target" "$backup"
		printf 'Backed up %s to %s\n' "$target" "$backup"
	fi

	if ln -s "$source" "$target"; then
		printf 'Linked %s -> %s\n' "$target" "$source"
	else
		[ -n "$backup" ] && mv "$backup" "$target"
		printf 'Could not create %s. On Windows, enable Developer Mode or run an elevated shell.\n' "$target" >&2
		return 1
	fi
}

install_managed_bashrc() {
	local target="$HOME/.bashrc" temp backup=

	temp=$(mktemp)
	cat >"$temp" <<EOF
#!/usr/bin/env bash

# Managed by $dotfiles_dir/scripts/shell/install-bashrc.sh
export DOTFILES_DIR=\${DOTFILES_DIR:-"$dotfiles_dir"}

is_interactive=false
case \$- in
	*i*) is_interactive=true ;;
esac

# shellcheck disable=SC1090
. "\$DOTFILES_DIR/.bashrc.d/00-env.sh"

if [ "\$is_interactive" != true ]; then
	return 0 2>/dev/null || exit 0
fi

if [ -f /etc/bashrc ] && [ -z "\${BASHRCSOURCED:-}" ]; then
	. /etc/bashrc
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
elif [ -f /usr/local/etc/bash_completion ]; then
	. /usr/local/etc/bash_completion
fi

for fragment in \
	"\$DOTFILES_DIR/.bashrc.d/10-aliases.sh" \
	"\$DOTFILES_DIR/.bashrc.d/20-functions.sh" \
	"\$DOTFILES_DIR/.bashrc.d/90-interactive.sh" \
	"\$DOTFILES_DIR/.bashrc.d/95-session.sh"
do
	if [ -f "\$fragment" ]; then
		# shellcheck disable=SC1090
		. "\$fragment"
	fi
done
EOF

	if [ ! -L "$target" ] && [ -f "$target" ] && cmp -s "$temp" "$target"; then
		rm -f "$temp"
		printf 'Already up to date: %s\n' "$target"
		return 0
	fi

	if [ -e "$target" ] || [ -L "$target" ]; then
		backup="${target}.${backup_suffix}"
		mv "$target" "$backup"
		printf 'Backed up %s to %s\n' "$target" "$backup"
	fi

	mv "$temp" "$target"
	chmod 0644 "$target"
	printf 'Installed managed %s\n' "$target"
}

mkdir -p "$HOME/.config" "$HOME/.config/fastfetch"

install_managed_bashrc
link_config "$dotfiles_dir/.profile" "$HOME/.profile"
link_config "$dotfiles_dir/starship.toml" "$HOME/.config/starship.toml"
link_config "$dotfiles_dir/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
link_config "$dotfiles_dir/.blerc" "$HOME/.blerc"

if [ -f "$dotfiles_dir/atuin/config.toml" ]; then
	mkdir -p "$HOME/.config/atuin"
	link_config "$dotfiles_dir/atuin/config.toml" "$HOME/.config/atuin/config.toml"
fi

printf '\nShell configuration installed. Start a new shell or run: source ~/.bashrc\n'
printf 'To install shell tools too, run: %s/scripts/shell/setup-shell.sh\n' "$dotfiles_dir"
