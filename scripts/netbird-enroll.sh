#!/usr/bin/env bash
# Robust, non-interactive NetBird enrollment script
# - Installs/pins NetBird version if requested
# - Ensures management URL/hosts mapping
# - Runs enrollment fully detached (won't hang your shell)
# - Produces logs at /var/log/netbird-enroll.log
#
# Usage:
#   sudo ./netbird-enroll.sh \
#     --setup-key "<SETUP_KEY>" \
#     [--management-url http://netbird-management.ediacarian.home:80] \
#     [--version 0.59.5] \
#     [--hosts-ip 10.0.0.7] \
#     [--hostname netbird-management.ediacarian.home] \
#     [--insecure]
#
# Example (matches your environment):
#   sudo ./netbird-enroll.sh \
#     --setup-key "8653C125-FA40-4040-8009-A47BD702A1A9" \
#     --management-url http://netbird-management.ediacarian.home:80 \
#     --version 0.59.5 \
#     --hosts-ip 10.0.0.7 \
#     --hostname netbird-management.ediacarian.home
set -euo pipefail

LOG_FILE="/var/log/netbird-enroll.log"
PID_FILE="/var/run/netbird-enroll.pid"
HOSTS_FILE="/etc/hosts"

# Defaults
SETUP_KEY="8653C125-FA40-4040-8009-A47BD702A1A9"
MGMT_URL="https://netbird-management.ediacarian.home:443"
NB_VERSION=""
HOSTS_IP=""
HOSTNAME_ENTRY="netbird-management.ediacarian.home"
INSECURE="0"

# Helpers
err() { echo "[ERROR] $*" >&2; }
info() { echo "[INFO]  $*"; }
die() { err "$*"; exit 1; }
require_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || die "Run as root (sudo)."; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --setup-key) shift; SETUP_KEY=${1:-};;
    --management-url) shift; MGMT_URL=${1:-};;
    --version) shift; NB_VERSION=${1:-};;
    --hosts-ip) shift; HOSTS_IP=${1:-};;
    --hostname) shift; HOSTNAME_ENTRY=${1:-};;
    --insecure) INSECURE="1";;
    -h|--help)
      sed -n '1,60p' "$0"; exit 0;
      ;;
    *) die "Unknown argument: $1";;
  esac
  shift
done

require_root

[ -n "$SETUP_KEY" ] || die "--setup-key is required"

# Optionally add /etc/hosts mapping
if [ -n "$HOSTS_IP" ] && [ -n "$HOSTNAME_ENTRY" ]; then
  if ! grep -qE "(^|\s)$HOSTNAME_ENTRY(\s|$)" "$HOSTS_FILE"; then
    info "Adding $HOSTS_IP $HOSTNAME_ENTRY to $HOSTS_FILE"
    printf '%s %s\n' "$HOSTS_IP" "$HOSTNAME_ENTRY" >> "$HOSTS_FILE"
  else
    info "$HOSTNAME_ENTRY already present in $HOSTS_FILE"
  fi
fi

# Validate management URL reachability (non-fatal if only 404)
if have_cmd curl; then
  info "Checking management URL: $MGMT_URL"
  set +e
  HTTP_CODE=$(curl -sS -o /dev/null -m 5 -w '%{http_code}' "$MGMT_URL" || true)
  set -e
  if [ -z "$HTTP_CODE" ]; then
    err "Management URL is not reachable right now. Continuing anyway."
  else
    info "Management URL HTTP code: $HTTP_CODE (404 is OK for root path)"
  fi
else
  info "curl not found; skipping URL reachability check"
fi

# Install/pin NetBird version if requested
if [ -n "$NB_VERSION" ]; then
  info "Ensuring NetBird $NB_VERSION is installed"
  if have_cmd apt-get; then
    TMP_DEB="/tmp/netbird_${NB_VERSION}_linux_amd64.deb"
    curl -fL -o "$TMP_DEB" "https://github.com/netbirdio/netbird/releases/download/v${NB_VERSION}/netbird_${NB_VERSION}_linux_amd64.deb"
    dpkg -i "$TMP_DEB" || (apt-get update && apt-get -y -f install)
    # Pin the package to avoid accidental upgrades
    if have_cmd apt-mark; then apt-mark hold netbird || true; fi
  else
    die "This script currently supports apt-based systems for version pinning. Install NetBird $NB_VERSION manually or extend the script."
  fi
fi


# No need to stop/disable service or remove socket; enrollment works with service running

# Build enrollment command (fully detached, logs to file)
ENROLL_CMD=(netbird up --management-url "$MGMT_URL" --setup-key "$SETUP_KEY" --log-level info --log-file console)
# Ensure no local socket is used; always use remote management URL
export NETBIRD_MANAGEMENT_URL="$MGMT_URL"
if [ "$INSECURE" = "1" ]; then
  ENROLL_CMD+=(--insecure)
fi

info "Starting enrollment (detached). Logs -> $LOG_FILE"
# shellcheck disable=SC2143
setsid "${ENROLL_CMD[@]}" > "$LOG_FILE" 2>&1 < /dev/null &
ENROLL_PID=$!
echo "$ENROLL_PID" > "$PID_FILE"

# Poll logs for up to 45s for obvious success/error signals
info "Waiting for enrollment to complete (up to 45s)"
for i in $(seq 1 45); do
  sleep 1
  if grep -qiE "(connected|success|enrolled|peer registered)" "$LOG_FILE" 2>/dev/null; then
    info "Enrollment appears successful (matched success keyword)."
    break
  fi
  if grep -qiE "(invalid setup key|unauthorized|forbidden|failed|error)" "$LOG_FILE" 2>/dev/null; then
    err "Detected error in enrollment logs; showing last 60 lines:";
    tail -n 60 "$LOG_FILE" || true
    exit 2
  fi
  # If process died early, break to show logs
  if ! ps -p "$(cat "$PID_FILE" 2>/dev/null)" >/dev/null 2>&1; then
    break
  fi
  # Print a dot to show progress when run interactively
  if [ -t 1 ]; then printf '.'; fi
done
if [ -t 1 ]; then echo; fi

# Show status without hanging shell; use a short timeout
if have_cmd timeout; then
  info "NetBird status (2s timeout):"
  timeout 2s netbird status || true
else
  info "NetBird status (no timeout executable available):"
  netbird status || true
fi

info "Last 80 lines of $LOG_FILE:"
tail -n 80 "$LOG_FILE" || true

info "Done."