#!/usr/bin/env bash
set -euo pipefail

# idempotent installer for Grafana Alloy (Debian-style)
# Usage: install_alloy.sh [--from-repo REPO_DIR] [--force]
# - --from-repo: directory in which config.alloy.tpl lives (defaults to script dir)
# - --force: overwrite /etc/alloy/config.alloy if it exists

FORCE=0
REPO_DIR=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift;;
    --from-repo) REPO_DIR="$2"; shift 2;;
    --help) echo "Usage: $0 [--from-repo DIR] [--force]"; exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [ -z "$REPO_DIR" ]; then
  REPO_DIR=$(cd "$(dirname "$0")" && pwd)
fi

echo "[alloy-installer] repo: $REPO_DIR"

# require root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (or with sudo)" >&2
  exit 1
fi

# ensure gpg and wget exist
apt-get update -y
apt-get install -y --no-install-recommends gpg wget ca-certificates || true

# add grafana apt repo if not present
KEYRING=/etc/apt/keyrings/grafana.gpg
REPO_FILE=/etc/apt/sources.list.d/grafana.list
if [ ! -f "$KEYRING" ]; then
  echo "[alloy-installer] adding grafana apt key"
  mkdir -p /etc/apt/keyrings
  wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee $KEYRING >/dev/null
fi
if [ ! -f "$REPO_FILE" ]; then
  echo "deb [signed-by=$KEYRING] https://apt.grafana.com stable main" | tee $REPO_FILE
fi

apt-get update -y

# install alloy
if ! command -v alloy >/dev/null 2>&1; then
  echo "[alloy-installer] installing alloy package"
  apt-get install -y alloy
else
  echo "[alloy-installer] alloy already installed"
fi

# ensure dirs and alloy user exist
if ! id -u alloy >/dev/null 2>&1; then
  echo "[alloy-installer] creating alloy user"
  useradd --system --no-create-home --shell /usr/sbin/nologin alloy || true
fi

mkdir -p /etc/alloy /var/lib/alloy /var/log/alloy
chown -R alloy:alloy /var/lib/alloy /var/log/alloy
chmod 0750 /var/lib/alloy || true

# deploy config template if present in repo
TEMPLATE="$REPO_DIR/config.alloy.tpl"
TARGET_CONF=/etc/alloy/config.alloy
if [ -f "$TEMPLATE" ]; then
  if [ -f "$TARGET_CONF" ] && [ "$FORCE" -eq 0 ]; then
    echo "[alloy-installer] /etc/alloy/config.alloy already exists — use --force to overwrite"
  else
    echo "[alloy-installer] deploying config template -> $TARGET_CONF"
    cp "$TEMPLATE" "$TARGET_CONF"
    chown root:root "$TARGET_CONF"
    chmod 0644 "$TARGET_CONF"
  fi
else
  echo "[alloy-installer] template $TEMPLATE not found; leaving /etc/alloy untouched"
fi

# ensure systemd unit exists; package may install one
if [ ! -f /etc/systemd/system/alloy.service ]; then
  echo "[alloy-installer] installing example systemd unit"
  cat > /etc/systemd/system/alloy.service <<'UNIT'
[Unit]
Description=Grafana Alloy Service
After=network.target

[Service]
Type=simple
User=alloy
ExecStart=/usr/bin/alloy run /etc/alloy/config.alloy
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
  systemctl daemon-reload || true
fi

# enable and start service (don't fail if it errors)
echo "[alloy-installer] enabling and starting alloy.service"
systemctl enable --now alloy.service || true

echo "[alloy-installer] finished"
