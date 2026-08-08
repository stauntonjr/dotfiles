#!/usr/bin/env bash

# Generate and optionally apply the tracked VS Code settings fragments.
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
dotfiles_dir=${DOTFILES_DIR:-"$(CDPATH= cd -- "$script_dir/../.." && pwd)"}
settings_dir="$dotfiles_dir/vscode"
mode=
apply=false
target=
remote_host=

usage() {
	cat <<'EOF'
Usage: install-settings.sh (--client | --remote HOST) [--apply] [--target PATH]

Generate tracked VS Code settings. Without --apply, print the strict JSON to
stdout. With --apply, merge it into PATH (or the platform-default settings
path), keeping a timestamped backup of the original.
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--client) mode=client ;;
		--remote)
			shift
			[ "$#" -gt 0 ] || { usage >&2; exit 2; }
			mode=remote
			remote_host=$1
			;;
		--apply) apply=true ;;
		--target)
			shift
			[ "$#" -gt 0 ] || { usage >&2; exit 2; }
			target=$1
			;;
		-h|--help) usage; exit 0 ;;
		*) usage >&2; exit 2 ;;
	esac
	shift
done

[ -n "$mode" ] || { usage >&2; exit 2; }

case "$(uname -s)" in
	Darwin) platform=macos ;;
	MINGW*|MSYS*|CYGWIN*) platform=windows ;;
	Linux) platform=linux ;;
	*) printf 'Unsupported platform: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac

if [ "$mode" = client ]; then
	fragments=("$settings_dir/settings.base.json")
	[ "$platform" = macos ] && fragments+=("$settings_dir/settings.macos.json")
	[ "$platform" = windows ] && fragments+=("$settings_dir/settings.windows.json")
	fragments+=("$settings_dir/settings.ssh-client.json")
else
	fragments=("$settings_dir/remote/linux.json")
	if [ -f "$settings_dir/remote/$remote_host.json" ]; then
		fragments+=("$settings_dir/remote/$remote_host.json")
	fi
fi

for fragment in "${fragments[@]}"; do
	[ -f "$fragment" ] || { printf 'Missing fragment: %s\n' "$fragment" >&2; exit 1; }
done

if [ -z "$target" ]; then
	if [ "$mode" = remote ]; then
		target="$HOME/.vscode-server/data/Machine/settings.json"
	elif [ "$platform" = macos ]; then
		target="$HOME/Library/Application Support/Code/User/settings.json"
	elif [ "$platform" = windows ]; then
		target="${APPDATA:?APPDATA is required on Windows}/Code/User/settings.json"
	else
		target="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
	fi
fi

node_bin=$(command -v node || true)
[ -n "$node_bin" ] || { printf 'node is required to merge and validate JSON settings.\n' >&2; exit 1; }

if [ "$apply" = true ]; then
	if [ -e "$target" ]; then
		backup="$target.pre-dotfiles.$(date +%Y%m%d-%H%M%S)"
		cp -p "$target" "$backup"
		printf 'Backed up %s to %s\n' "$target" "$backup" >&2
	fi
	"$node_bin" - "$target" "${fragments[@]}" <<'NODE'
const fs = require('fs');
const [target, ...fragments] = process.argv.slice(2);
const stripJsonComments = text => text
  .replace(/\/\*[\s\S]*?\*\//g, '')
  .replace(/(^|[^:])\/\/.*$/gm, '$1');
const read = path => JSON.parse(stripJsonComments(fs.readFileSync(path, 'utf8')));
const merge = (left, right) => {
  for (const [key, value] of Object.entries(right)) {
    if (value && typeof value === 'object' && !Array.isArray(value) &&
        left[key] && typeof left[key] === 'object' && !Array.isArray(left[key])) {
      merge(left[key], value);
    } else {
      left[key] = value;
    }
  }
  return left;
};
let settings = fs.existsSync(target) ? read(target) : {};
for (const fragment of fragments) settings = merge(settings, read(fragment));
fs.mkdirSync(require('path').dirname(target), {recursive: true});
fs.writeFileSync(target, JSON.stringify(settings, null, 2) + '\n');
NODE
	printf 'Applied generated %s settings to %s\n' "$mode" "$target" >&2
	return_code=0
else
	"$node_bin" - "${fragments[@]}" <<'NODE'
const fs = require('fs');
const merge = (left, right) => {
  for (const [key, value] of Object.entries(right)) {
    if (value && typeof value === 'object' && !Array.isArray(value) &&
        left[key] && typeof left[key] === 'object' && !Array.isArray(left[key])) merge(left[key], value);
    else left[key] = value;
  }
  return left;
};
let settings = {};
for (const fragment of process.argv.slice(2)) settings = merge(settings, JSON.parse(fs.readFileSync(fragment, 'utf8')));
process.stdout.write(JSON.stringify(settings, null, 2) + '\n');
NODE
	return_code=0
fi

exit "$return_code"
