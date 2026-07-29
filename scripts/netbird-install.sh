#!/usr/bin/env bash
# NetBird client installer that ensures the installed version matches what you specify
# or, optionally, what your Management server reports.
#
# Features:
# - Installs or downgrades NetBird to an exact version (and pins it via apt-mark hold)
# - Optionally attempts to detect Management version from a URL
# - Handles amd64/arm64 .deb packages (Debian/Ubuntu-family)
# - Verifies the installed version and exits non-zero if it doesn't match
#
# Usage examples:
#   sudo ./netbird-install.sh --version 0.59.5
#   sudo ./netbird-install.sh --match-management http://netbird-management.ediacarian.home:80
#   sudo ./netbird-install.sh --match-management https://netbird.my.domain --insecure
#
# Optional flags:
#   --no-hold           Do not apt-mark hold netbird after install (default: hold)
#   --start             Start/enable service after install (default: do not change service state)
#   --insecure          Allow insecure TLS when querying --match-management URL
#
# Exit codes:
#   0  success
#   1  usage / validation error
#   2  failed to determine desired version
#   3  install failed
#   4  version verification failed

set -euo pipefail

# --------------- Helpers ---------------
err() { echo "[ERROR] $*" >&2; }
info() { echo "[INFO]  $*"; }
die() { err "$*"; exit 1; }
require_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || die "Run as root (sudo)."; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
json_grep_version() {
  # Extract first X.Y.Z from input
  grep -Eo '([0-9]+\.[0-9]+\.[0-9]+)' | head -n1 || true
}
get_arch() {
  local uname_arch
  uname_arch=$(uname -m)
  case "$uname_arch" in
    x86_64|amd64) echo "amd64";;
    aarch64|arm64) echo "arm64";;
    *) die "Unsupported architecture: $uname_arch (expected x86_64/amd64 or aarch64/arm64)";;
  esac
}

# --------------- Defaults / Args ---------------
DESIRED_VERSION=""
MATCH_MGMT_URL=""
APT_HOLD=1
START_SERVICE=0
CURL_INSECURE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --version) shift; DESIRED_VERSION=${1:-};;
    --match-management) shift; MATCH_MGMT_URL=${1:-};;
    --no-hold) APT_HOLD=0;;
    --start) START_SERVICE=1;;
    --insecure) CURL_INSECURE=1;;
    -h|--help)
      sed -n '1,120p' "$0"; exit 0;;
    *) die "Unknown argument: $1";;
  esac
  shift
done

require_root

# --------------- Determine desired version ---------------
if [ -z "$DESIRED_VERSION" ] && [ -n "$MATCH_MGMT_URL" ]; then
  have_cmd curl || die "curl is required to detect management version"
  info "Attempting to detect NetBird Management version from: $MATCH_MGMT_URL"
  CURL_OPTS=(-fsSL -m 6)
  if [ "$CURL_INSECURE" -eq 1 ]; then CURL_OPTS+=(--insecure); fi

  # Try a few likely endpoints to extract X.Y.Z
  DETECTED=""
  for ep in \
    "/api/version" \
    "/api/server-info" \
    "/api" \
    "/version" \
    "/"; do
    set +e
    BODY=$(curl "${CURL_OPTS[@]}" "${MATCH_MGMT_URL%/}$ep" 2>/dev/null || true)
    set -e
    if [ -n "$BODY" ]; then
      VER=$(printf '%s' "$BODY" | json_grep_version)
      if [ -n "$VER" ]; then DETECTED="$VER"; break; fi
    fi
  done
  if [ -n "$DETECTED" ]; then
    info "Detected management version: $DETECTED"
    DESIRED_VERSION="$DETECTED"
  else
    err "Could not detect management version from $MATCH_MGMT_URL"
    err "Please re-run with --version X.Y.Z"
    exit 2
  fi
fi

[ -n "$DESIRED_VERSION" ] || die "Provide --version X.Y.Z or --match-management <url>"

# --------------- Install / Downgrade ---------------
ARCH=$(get_arch)
DEB_NAME="netbird_${DESIRED_VERSION}_linux_${ARCH}.deb"
URL="https://github.com/netbirdio/netbird/releases/download/v${DESIRED_VERSION}/${DEB_NAME}"
TMP_DEB="/tmp/${DEB_NAME}"

if ! have_cmd dpkg || ! have_cmd apt-get; then
  die "This installer supports Debian/Ubuntu-family systems (needs dpkg and apt-get)."
fi

# Stop service if running to avoid hangs during replace/downgrade
if systemctl list-units --type=service | grep -q '^netbird.service'; then
  info "Stopping netbird service (if running)"
  systemctl stop netbird || true
fi

info "Downloading ${URL}"
curl -fL -o "$TMP_DEB" "$URL"

info "Installing $DEB_NAME"
set +e
dpkg -i "$TMP_DEB"
DPKG_CODE=$?
set -e
if [ $DPKG_CODE -ne 0 ]; then
  info "Fixing dependencies via apt-get -f install"
  apt-get update
  apt-get -y -f install || { err "apt-get -f install failed"; exit 3; }
  # Re-try dpkg to ensure correct version applied
  dpkg -i "$TMP_DEB" || { err "dpkg failed after dependency fix"; exit 3; }
fi

if [ $APT_HOLD -eq 1 ] && have_cmd apt-mark; then
  info "Holding netbird at $DESIRED_VERSION (apt-mark hold)"
  apt-mark hold netbird || true
fi

# --------------- Verify Version ---------------
if ! have_cmd netbird; then
  err "netbird binary not found after install"
  exit 3
fi
INSTALLED_VER=$(netbird version 2>/dev/null | head -n1 | tr -d '\r\n ')
info "Installed netbird version: $INSTALLED_VER"
if [ "$INSTALLED_VER" != "$DESIRED_VERSION" ]; then
  err "Installed version ($INSTALLED_VER) does not match desired ($DESIRED_VERSION)"
  exit 4
fi

# --------------- Optional: start service ---------------
if [ $START_SERVICE -eq 1 ]; then
  if systemctl list-unit-files | grep -q '^netbird.service'; then
    info "Starting/enabling netbird service"
    systemctl enable --now netbird || true
  else
    info "netbird.service unit not found; skipping start"
  fi
fi

info "NetBird $DESIRED_VERSION installed successfully on $(uname -m)"
