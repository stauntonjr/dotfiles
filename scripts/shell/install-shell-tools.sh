#!/usr/bin/env bash

set -euo pipefail

platform=$(uname -s)
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$PATH"

linux_packages=(
	curl
	git
	make
	gawk
	trash-cli
	ripgrep
	starship
	zoxide
	atuin
	fastfetch
	fzf
	tree
	multitail
	bash-completion
)

macos_packages=(
	curl
	git
	make
	gawk
	ripgrep
	starship
	zoxide
	atuin
	fastfetch
	fzf
	tree
	multitail
	bash-completion@2
	trash
)

windows_winget_packages=(
	Git.Git
	Starship.Starship
	ajeetdsouza.zoxide
	atuinsh.atuin
	Fastfetch-cli.Fastfetch
	BurntSushi.ripgrep.GNU
	junegunn.fzf
)

windows_scoop_packages=(
	git
	make
	starship
	zoxide
	atuin
	fastfetch
	ripgrep
	fzf
)

run_as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	else
		printf 'A root package install is required, but sudo is unavailable.\n' >&2
		return 1
	fi
}

install_apt_packages() {
	local package available=()
	run_as_root apt-get update
	for package in "${linux_packages[@]}"; do
		if apt-cache show "$package" >/dev/null 2>&1; then
			available+=("$package")
		else
			printf 'Not available from apt on this release: %s\n' "$package"
		fi
	done
	run_as_root apt-get install -y "${available[@]}"
}

install_linux_tools() {
	local package
	if command -v apt-get >/dev/null 2>&1; then
		install_apt_packages
	elif command -v dnf >/dev/null 2>&1; then
		for package in "${linux_packages[@]}"; do
			run_as_root dnf install -y "$package" || printf 'Could not install with dnf: %s\n' "$package" >&2
		done
	elif command -v pacman >/dev/null 2>&1; then
		run_as_root pacman -Syu --noconfirm
		for package in "${linux_packages[@]}"; do
			run_as_root pacman -S --needed --noconfirm "$package" || printf 'Could not install with pacman: %s\n' "$package" >&2
		done
	else
		printf 'Unsupported Linux package manager. Install curl, git, make, gawk, trash-cli, ripgrep, starship, zoxide, atuin, fastfetch, fzf, tree, multitail, and bash-completion manually.\n' >&2
		return 1
	fi
}

install_atuin_fallback() {
	if command -v atuin >/dev/null 2>&1; then
		return 0
	fi
	if ! command -v curl >/dev/null 2>&1; then
		printf 'Atuin is unavailable from the package manager and curl is missing.\n' >&2
		return 1
	fi
	printf 'Installing Atuin with the official installer.\n'
	curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
}

install_fastfetch_fallback() {
	local arch asset_url api_json tmp_dir
	if command -v fastfetch >/dev/null 2>&1; then
		return 0
	fi
	if ! command -v curl >/dev/null 2>&1; then
		printf 'Fastfetch is unavailable from the package manager and curl is missing.\n' >&2
		return 1
	fi
	if ! command -v python3 >/dev/null 2>&1; then
		printf 'Fastfetch fallback needs python3 to select the release asset.\n' >&2
		return 1
	fi

	case "$(uname -m)" in
		x86_64|amd64) arch=amd64 ;;
		aarch64|arm64) arch=aarch64 ;;
		*)
			printf 'Fastfetch fallback does not yet support architecture: %s\n' "$(uname -m)" >&2
			return 1
			;;
	esac

	api_json=$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest)
	asset_url=$(printf '%s' "$api_json" | python3 -c 'import json, sys
arch = sys.argv[1]
data = json.load(sys.stdin)
for asset in data.get("assets", []):
    name = asset.get("name", "")
    if name.endswith(f"fastfetch-linux-{arch}.tar.gz") or name.endswith(f"fastfetch-linux-{arch}/fastfetch-linux-{arch}.tar.gz"):
        print(asset.get("browser_download_url", ""))
        raise SystemExit(0)
print("")' "$arch")
	if [ -z "$asset_url" ]; then
		printf 'Could not find a Fastfetch release asset for linux-%s.\n' "$arch" >&2
		return 1
	fi

	tmp_dir=$(mktemp -d)
	trap 'rm -rf "$tmp_dir"' RETURN
	printf 'Installing Fastfetch from the latest GitHub release.\n'
	curl -fsSL "$asset_url" -o "$tmp_dir/fastfetch.tar.gz"
	tar -xzf "$tmp_dir/fastfetch.tar.gz" -C "$tmp_dir"
	mkdir -p "$HOME/.local/bin"
	if [ -f "$tmp_dir/fastfetch-linux-$arch/usr/bin/fastfetch" ]; then
		install -m 0755 "$tmp_dir/fastfetch-linux-$arch/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
	elif [ -f "$tmp_dir/fastfetch-linux-$arch/fastfetch" ]; then
		install -m 0755 "$tmp_dir/fastfetch-linux-$arch/fastfetch" "$HOME/.local/bin/fastfetch"
	elif [ -f "$tmp_dir/fastfetch" ]; then
		install -m 0755 "$tmp_dir/fastfetch" "$HOME/.local/bin/fastfetch"
	else
		printf 'Fastfetch archive did not contain a fastfetch binary.\n' >&2
		return 1
	fi
}

install_macos_tools() {
	if ! command -v brew >/dev/null 2>&1; then
		printf 'Homebrew is required on macOS: https://brew.sh\n' >&2
		return 1
	fi
	brew install "${macos_packages[@]}"
}

install_windows_tools() {
	local package
	if command -v winget.exe >/dev/null 2>&1; then
		for package in "${windows_winget_packages[@]}"; do
			winget.exe install --id "$package" --exact --accept-package-agreements --accept-source-agreements || \
				printf 'Could not install with winget: %s\n' "$package" >&2
		done
	elif command -v scoop >/dev/null 2>&1; then
		scoop install "${windows_scoop_packages[@]}"
	else
		printf 'Install winget or Scoop, then rerun this script from Git Bash.\n' >&2
		return 1
	fi
}

install_blesh() {
	local cache_root source_dir legacy_dir backup_dir
	cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
	source_dir="$cache_root/blesh-src"
	legacy_dir="$HOME/.local/share/blesh"

	if ! command -v git >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
		printf 'Skipping ble.sh: git and make are required.\n' >&2
		return 0
	fi

	mkdir -p "$cache_root"

	# Older versions cloned the ble.sh source into the install destination
	# under ~/.local/share/blesh. Leave that tree in place and switch future
	# updates to a dedicated cache checkout that make install will not dirty.
	if [ ! -e "$source_dir" ] && [ -d "$legacy_dir/.git" ]; then
		printf 'Detected legacy ble.sh checkout in %s; switching to cached source at %s.\n' "$legacy_dir" "$source_dir"
	fi

	if [ -d "$source_dir/.git" ]; then
		if [ -n "$(git -C "$source_dir" status --porcelain 2>/dev/null)" ]; then
			backup_dir="${source_dir}.bak.$(date +%Y%m%d-%H%M%S)"
			mv "$source_dir" "$backup_dir"
			printf 'Backed up dirty ble.sh cache to %s\n' "$backup_dir"
			git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git "$source_dir"
		else
			git -C "$source_dir" pull --ff-only
		fi
		git -C "$source_dir" submodule update --init --recursive
	elif [ -e "$source_dir" ]; then
		printf 'Skipping ble.sh: %s exists but is not a Git checkout.\n' "$source_dir" >&2
		return 0
	else
		git clone --recursive --depth 1 https://github.com/akinomyoga/ble.sh.git "$source_dir"
	fi

	make -C "$source_dir" install PREFIX="$HOME/.local"
}

install_starship_fallback() {
	if command -v starship >/dev/null 2>&1; then
		return 0
	fi
	if ! command -v curl >/dev/null 2>&1; then
		printf 'Starship is unavailable from the package manager and curl is missing.\n' >&2
		return 1
	fi
	mkdir -p "$HOME/.local/bin"
	printf 'Installing Starship in %s using its official installer.\n' "$HOME/.local/bin"
	curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
}

case "$platform" in
	Linux) install_linux_tools ;;
	Darwin) install_macos_tools ;;
	MINGW*|MSYS*|CYGWIN*) install_windows_tools ;;
	*) printf 'Unsupported platform: %s\n' "$platform" >&2; exit 1 ;;
esac

install_atuin_fallback
install_fastfetch_fallback
install_starship_fallback
install_blesh

printf '\nInstalled shell tools for %s.\n' "$platform"
printf 'Tool versions found on PATH:\n'
for tool in git make starship zoxide atuin fastfetch rg fzf tree multitail trash; do
	if command -v "$tool" >/dev/null 2>&1; then
		printf '  %-10s %s\n' "$tool" "$(command -v "$tool")"
	else
		printf '  %-10s missing (install manually if unavailable from your package manager)\n' "$tool"
	fi
done
