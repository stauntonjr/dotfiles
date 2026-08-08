#!/usr/bin/env bash
set -euo pipefail

# Materialize the mcp-srv runtime configuration managed by this dotfiles repo,
# validate the Compose project, and optionally restart it. This script never
# prints secret values.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MCP_SRV_ROOT="${MCP_SRV_ROOT:-$HOME/src/mcp-srv}"
RESTART=false

if [ "${1:-}" = "--restart" ]; then
  RESTART=true
elif [ -n "${1:-}" ]; then
  printf 'usage: %s [--restart]\n' "$(basename "$0")" >&2
  exit 2
fi

install_runtime_file() {
  local source_path=$1 destination_path=$2 mode=$3
  if [ -w "$(dirname "$destination_path")" ]; then
    install -D -m "$mode" "$source_path" "$destination_path"
  else
    sudo install -D -m "$mode" "$source_path" "$destination_path"
  fi
}

materialize_target() {
  local target=$1
  bash "$DOTFILES_DIR/scripts/secrets/decrypt-all.sh" "$target"
}

materialize_target 'mcp-srv/runtime/.env'
materialize_target 'mcp-srv/runtime/config/mcp.json'
materialize_target 'mcp-srv/runtime/config/filesystem-connectors.json'
materialize_target 'mcp-srv/runtime/traefik/traefik.yml'

install_runtime_file "$DOTFILES_DIR/mcp-srv/runtime/.env" "$MCP_SRV_ROOT/.env" 600
install_runtime_file "$DOTFILES_DIR/mcp-srv/runtime/config/mcp.json" "$MCP_SRV_ROOT/config/mcp.json" 600
install_runtime_file "$DOTFILES_DIR/mcp-srv/runtime/config/filesystem-connectors.json" "$MCP_SRV_ROOT/config/filesystem-connectors.json" 600
install_runtime_file "$DOTFILES_DIR/mcp-srv/runtime/traefik/traefik.yml" "$MCP_SRV_ROOT/traefik/traefik.yml" 600

docker compose --project-directory "$MCP_SRV_ROOT" config -q
if [ "$RESTART" = true ]; then
  docker compose --project-directory "$MCP_SRV_ROOT" up -d
fi

printf '[mcp-srv] runtime configuration deployed to %s\n' "$MCP_SRV_ROOT"
