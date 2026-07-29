# Session-specific shell behavior.

dotfiles_dir=${DOTFILES_DIR:-"$HOME/dotfiles"}

# Only query a terminal when this shell actually has one.
if [ "$is_interactive" = true ] && [ -t 0 ]; then
	GPG_TTY=$(tty)
	export GPG_TTY
fi

if [ "$is_interactive" = true ] && [ -f "$HOME/.local/share/nvwb/nvwb-wrapper.sh" ]; then
	# shellcheck disable=SC1091
	. "$HOME/.local/share/nvwb/nvwb-wrapper.sh"
fi

# Load SOPS-managed secrets from this repo (encrypted .env files)
# Requires: sops and age installed, and local age private key available
if command -v sops >/dev/null 2>&1; then
    REPO_SECRETS_DIR="$dotfiles_dir/secrets"
    if [ -d "$REPO_SECRETS_DIR" ] && [ -f "$REPO_SECRETS_DIR/load_env.sh" ]; then
        # shellcheck disable=SC1090
        . "$REPO_SECRETS_DIR/load_env.sh"
    fi
fi

# Load local secrets if present (never commit secrets; keep this file 0600)
if [ -f "$HOME/.config/secrets.sh" ]; then
    . "$HOME/.config/secrets.sh"
fi

if [ "$is_interactive" = true ] && [ "$(uname -s 2>/dev/null)" = Linux ]; then
	if [[ -z ${DISPLAY:-} ]] && [[ $(tty 2>/dev/null) = /dev/tty1 ]] && command -v startx >/dev/null 2>&1; then
		exec startx
	fi
fi
