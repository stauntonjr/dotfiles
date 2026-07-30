# Interactive-only shell behavior.

if [ "$is_interactive" = true ]; then
	dotfiles_dir=${DOTFILES_DIR:-"$HOME/dotfiles"}

	# ble.sh must be loaded near the start of interactive setup. Its own config
	# is linked at ~/.blerc by the shell bootstrap.
	if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
		# shellcheck disable=SC1091
		. "$HOME/.local/share/blesh/ble.sh" --noattach
	fi

	for bash_completion in \
		/opt/homebrew/etc/profile.d/bash_completion.sh \
		/usr/local/etc/profile.d/bash_completion.sh \
		/usr/share/bash-completion/bash_completion \
		/etc/bash_completion \
		/usr/local/etc/bash_completion
	do
		if [ -f "$bash_completion" ]; then
			# shellcheck disable=SC1090
			. "$bash_completion"
			break
		fi
	done
	unset bash_completion

	if command -v atuin >/dev/null 2>&1; then
		# Initialize pty-proxy before the regular Atuin shell hooks so the daemon
		# can capture command output for MCP/AI tooling.
		eval "$(atuin pty-proxy init bash)"
	fi

	if [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
		fastfetch
	fi
	bind "set bell-style visible"
	if [ -t 0 ]; then
		stty -ixon
	fi
	bind "set completion-ignore-case on"
	bind "set show-all-if-ambiguous On"

	if command -v atuin >/dev/null 2>&1; then
		eval "$(atuin init bash)"
	else
		PROMPT_COMMAND='history -a'
	fi

	__conda_setup=
	if command -v conda >/dev/null 2>&1; then
		__conda_setup="$(conda shell.bash hook 2>/dev/null)" || true
	fi
	if [ -n "$__conda_setup" ]; then
		eval "$__conda_setup"
	else
		for conda_profile in \
			"$HOME/anaconda3/etc/profile.d/conda.sh" \
			"$HOME/miniconda3/etc/profile.d/conda.sh"
		do
			if [ -f "$conda_profile" ]; then
				# shellcheck disable=SC1090
				. "$conda_profile"
				break
			fi
		done
		unset conda_profile
	fi
	unset __conda_setup

	if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
		if command -v starship >/dev/null 2>&1 && [ -f "$dotfiles_dir/starship.toml" ]; then
			export STARSHIP_CONFIG="$dotfiles_dir/starship.toml"
			eval "$(starship init bash)"
		else
			# Portable fallback for Linux, WSL, and Git Bash terminals.
			PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ '
		fi
	else
		PS1='\u@\h:\w\$ '
	fi
	if command -v zoxide >/dev/null 2>&1; then
		eval "$(zoxide init bash)"
	fi

	if command -v sparkrun >/dev/null 2>&1; then
		eval "$(_SPARKRUN_COMPLETE=bash_source sparkrun)"
	fi

	if declare -F ble-attach >/dev/null 2>&1; then
		if [ -n "${VSCODE_INJECTION:-}" ]; then
			VSCODE_INJECTION= ble-attach
		else
			ble-attach
		fi
	fi

	# Bind Ctrl+f to insert 'zi' followed by a newline
	bind '"\C-f":"zi\n"'
fi
