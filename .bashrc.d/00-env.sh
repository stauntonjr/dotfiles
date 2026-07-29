# Shared shell environment for bash.

DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/dotfiles"}
export DOTFILES_DIR

if [[ $- == *i* ]]; then
	# Unlimited history: negative values disable truncation (bash >=4).
	export HISTFILESIZE=-1
	export HISTSIZE=-1
	export HISTTIMEFORMAT="%F %T"
	export HISTCONTROL=erasedups:ignoredups:ignorespace
	shopt -s checkwinsize histappend
fi

# Source user dotfiles env if present
if [ -f "$DOTFILES_DIR/.env" ]; then
	set -a
	# shellcheck disable=SC1090
	. "$DOTFILES_DIR/.env"
	set +a
fi

# set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Some environments (notably `pct enter` into an LXC) export XDG_RUNTIME_DIR
# even when the path does not exist. ble.sh treats that as a hard error, so
# clear the variable unless it points at a real directory.
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ ! -d "${XDG_RUNTIME_DIR}" ]; then
	unset XDG_RUNTIME_DIR
fi

# Prefer a UTF-8 locale that exists locally; fall back cleanly if the system
# does not provide en_US.UTF-8.
if command -v locale >/dev/null 2>&1; then
	if locale -a 2>/dev/null | grep -qx 'en_US\.utf8\|en_US\.UTF-8'; then
		export LANG=${LANG:-en_US.UTF-8}
		export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
	elif locale -a 2>/dev/null | grep -qx 'C\.UTF-8\|C\.utf8'; then
		export LANG=${LANG:-C.UTF-8}
		export LC_CTYPE=${LC_CTYPE:-C.UTF-8}
	else
		export LANG=${LANG:-C}
		export LC_CTYPE=${LC_CTYPE:-C}
	fi
fi

# Seeing as other scripts will use it might as well export it
export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# Keep common command locations available without multiplying entries whenever
# login shells source .bashrc. These paths work in Linux, WSL, and Git Bash.
path_prepend() {
	case ":${PATH:-}:" in
		*:"$1":*) ;;
		*) PATH="$1${PATH:+:$PATH}" ;;
	esac
}

path_append() {
	case ":${PATH:-}:" in
		*:"$1":*) ;;
		*) PATH="${PATH:+$PATH:}$1" ;;
	esac
}

path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.atuin/bin"
if [ -d "$HOME/anaconda3/condabin" ]; then
	path_prepend "$HOME/anaconda3/condabin"
fi
path_append /usr/local/bin
path_append /var/lib/flatpak/exports/bin
path_append "$HOME/.local/share/flatpak/exports/bin"
export PATH
unset -f path_prepend path_append

# Load additional user environment exports when available.
if [ -f "$HOME/.local/bin/env" ] && [ -z "${DOTFILES_LOCAL_ENV_LOADED:-}" ]; then
	# shellcheck disable=SC1091
	. "$HOME/.local/bin/env"
	export DOTFILES_LOCAL_ENV_LOADED=1
fi

# trust the CA of mcp-srv for vscode connections to 1mcp
if [ -f "$DOTFILES_DIR/mcp-srv/ca.crt" ]; then
	export NODE_EXTRA_CA_CERTS="$DOTFILES_DIR/mcp-srv/ca.crt"
fi

# On macOS, Node-based clients such as MCP connectors often need to read the
# system keychain trust store rather than a separate PEM file.
if [[ "$(uname -s)" == "Darwin" ]]; then
	case " ${NODE_OPTIONS:-} " in
		*" --use-system-ca "*) ;;
		*) export NODE_OPTIONS="${NODE_OPTIONS:-}${NODE_OPTIONS:+ }--use-system-ca" ;;
	esac
fi

# Set the default editor
export EDITOR=nano
export VISUAL=nano

# To have colors for ls and all grep commands such as grep, egrep and zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Prefer ripgrep when available.
if [[ $- == *i* ]] && command -v rg >/dev/null 2>&1; then
	alias grep='rg'
fi
