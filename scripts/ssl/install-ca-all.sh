#!/bin/bash
# install-ca-all.sh
# Install ca.crt on all hosts in SSH config
# Usage: bash install-ca-all.sh

SSH_CONFIG=~/dotfiles/ssh/config
CA_CERT=~/dotfiles/ssl/ca.crt
REMOTE_CA_PATH=~/oidc-srv-ca.crt

if [ ! -f "$CA_CERT" ]; then
  echo "CA certificate not found at $CA_CERT"
  echo "If this repo is using SOPS-managed secrets, run: bash ~/dotfiles/scripts/setup-secrets.sh"
  exit 1
fi

if [ ! -f "$SSH_CONFIG" ]; then
  echo "SSH config not found at $SSH_CONFIG"
  exit 1
fi

# Extract all unique Host entries (skip wildcards and comments)
HOSTS=$(awk '/^Host / {for(i=2;i<=NF;i++) if ($i!="*" && $i!~/#/) print $i}' "$SSH_CONFIG" | sort -u)


for HOST in $HOSTS; do
  if [[ $HOST == "wsl-desktop-local" ]]; then
    echo "Skipping $HOST"
    continue
  fi
  echo -e "\n--- Installing CA on $HOST ---"
  if [[ $HOST == win-* ]]; then
    # Windows host: use PowerShell installer
    scp -q "$CA_CERT" "$HOST:oidc-srv-ca.crt"
    scp -q "$(dirname $0)/install-ca-windows.ps1" "$HOST:install-ca-windows.ps1"
    ssh "$HOST" "powershell -ExecutionPolicy Bypass -File install-ca-windows.ps1"
    ssh "$HOST" "del install-ca-windows.ps1; del oidc-srv-ca.crt"
    echo "CA certificate installed on $HOST (Windows)"
  else
    # Linux host: use Bash installer
    # Always copy to ~ (home dir of remote user)
    scp -q "$CA_CERT" "$HOST:~/oidc-srv-ca.crt"
    # Detect if remote user is root
    REMOTE_USER=$(awk -v host="$HOST" '$1=="Host"{f=0} $2==host{f=1} f && $1=="User"{print $2}' "$SSH_CONFIG")
    if [ -z "$REMOTE_USER" ]; then
      REMOTE_USER="root" # default to root if not specified
    fi
    ssh "$HOST" "bash -s" -- "$REMOTE_USER" <<'ENDSSH'
REMOTE_USER="$1"
set -e
CA=~/oidc-srv-ca.crt
if [ -d /etc/pki/ca-trust/source/anchors ]; then
  if [ "${REMOTE_USER}" = "root" ]; then
    cp "$CA" /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract
  else
    sudo cp "$CA" /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust extract
  fi
elif [ -d /usr/local/share/ca-certificates ]; then
  if [ "${REMOTE_USER}" = "root" ]; then
    cp "$CA" /usr/local/share/ca-certificates/oidc-srv-ca.crt
    update-ca-certificates
  else
    sudo cp "$CA" /usr/local/share/ca-certificates/oidc-srv-ca.crt
    sudo update-ca-certificates
  fi
else
  echo "Unsupported Linux distribution. Please install $CA manually."
  exit 2
fi
rm -f "$CA"
echo "CA certificate installed on \\$(hostname)"
ENDSSH
    if [ $? -eq 0 ]; then
      echo "CA certificate installed on $HOST (Linux)"
    else
      echo "[ERROR] Failed to install CA on $HOST"
    fi
  fi
  echo "--- Done with $HOST ---"
done
