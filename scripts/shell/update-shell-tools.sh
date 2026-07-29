#!/usr/bin/env bash

set -euo pipefail

platform=$(uname -s)
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:$PATH"

tag=""
version=""
allow_prerelease=false

usage() {
	cat <<'EOF'
Usage: update-shell-tools.sh [--tag TAG | --version VERSION] [--prerelease]

Updates shell tools managed by these dotfiles. Currently this script updates
Atuin and prefers Atuin's official `atuin-update` helper when available.

Options:
  --tag TAG          Install a specific Atuin release tag
  --version VERSION  Install a specific Atuin version
  --prerelease       Allow prereleases when updating to the latest Atuin
  -h, --help         Show this help text
EOF
}

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

print_atuin_version() {
	if command -v atuin >/dev/null 2>&1; then
		atuin --version
	else
		printf 'atuin is not currently on PATH.\n'
	fi
}

update_atuin_with_helper() {
	local cmd=(atuin-update)

	if [ -n "$tag" ]; then
		cmd+=(--tag "$tag")
	fi

	if [ -n "$version" ]; then
		cmd+=(--version "$version")
	fi

	if [ "$allow_prerelease" = true ]; then
		cmd+=(--prerelease)
	fi

	printf 'Updating Atuin with %s\n' "$(command -v atuin-update)"
	"${cmd[@]}"
}

ensure_latest_only_for_package_manager() {
	if [ -n "$tag" ] || [ -n "$version" ] || [ "$allow_prerelease" = true ]; then
		printf 'Versioned/prerelease Atuin updates require the official atuin-update helper.\n' >&2
		printf 'Current PATH does not provide atuin-update, so only latest package-manager upgrades are available.\n' >&2
		exit 1
	fi
}

update_atuin_with_package_manager() {
	ensure_latest_only_for_package_manager

	case "$platform" in
		Linux)
			if command -v apt-get >/dev/null 2>&1; then
				printf 'Updating Atuin with apt-get.\n'
				run_as_root apt-get update
				run_as_root apt-get install -y --only-upgrade atuin
			elif command -v dnf >/dev/null 2>&1; then
				printf 'Updating Atuin with dnf.\n'
				run_as_root dnf upgrade -y atuin
			elif command -v pacman >/dev/null 2>&1; then
				printf 'Updating Atuin with pacman.\n'
				run_as_root pacman -Sy --noconfirm atuin
			else
				printf 'Unsupported Linux package manager for updating Atuin.\n' >&2
				exit 1
			fi
			;;
		Darwin)
			if command -v brew >/dev/null 2>&1; then
				printf 'Updating Atuin with Homebrew.\n'
				brew upgrade atuin
			else
				printf 'Homebrew is required to update Atuin on macOS.\n' >&2
				exit 1
			fi
			;;
		MINGW*|MSYS*|CYGWIN*)
			if command -v winget.exe >/dev/null 2>&1; then
				printf 'Updating Atuin with winget.\n'
				winget.exe upgrade --id atuinsh.atuin --exact --accept-package-agreements --accept-source-agreements
			elif command -v scoop >/dev/null 2>&1; then
				printf 'Updating Atuin with Scoop.\n'
				scoop update atuin
			else
				printf 'Install winget or Scoop, then rerun this script from Git Bash.\n' >&2
				exit 1
			fi
			;;
		*)
			printf 'Unsupported platform: %s\n' "$platform" >&2
			exit 1
			;;
	esac
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--tag)
			if [ "$#" -lt 2 ]; then
				printf 'Missing value for --tag.\n' >&2
				usage >&2
				exit 2
			fi
			tag=$2
			shift 2
			;;
		--version)
			if [ "$#" -lt 2 ]; then
				printf 'Missing value for --version.\n' >&2
				usage >&2
				exit 2
			fi
			version=$2
			shift 2
			;;
		--prerelease)
			allow_prerelease=true
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown argument: %s\n' "$1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [ -n "$tag" ] && [ -n "$version" ]; then
	printf 'Use either --tag or --version, not both.\n' >&2
	exit 2
fi

printf 'Current Atuin version: '
print_atuin_version

if command -v atuin-update >/dev/null 2>&1; then
	update_atuin_with_helper
else
	update_atuin_with_package_manager
fi

printf 'Updated Atuin version: '
print_atuin_version
