#!/usr/bin/env bash
# trust-mcp-srv-ca.sh
# Adds a local CA certificate to the system trust store on Linux
# (Debian/Ubuntu and RedHat/CentOS).
# Usage: ./trust-mcp-srv-ca.sh [path-to-ca.crt]
#
# Backward-compatible default:
#   $HOME/dotfiles/ssl/ca.crt
#
# This is the CA used for local HTTPS services such as mcp.ediacarian.home
# and should also be trusted by tools like VS Code / Node.

set -euo pipefail

CA_PATH="${1:-$HOME/dotfiles/ssl/ca.crt}"
CA_NAME="$(basename "$CA_PATH")"

if [ ! -f "$CA_PATH" ]; then
  echo "CA certificate not found at $CA_PATH"
  echo "If this repo is using SOPS-managed secrets, run: bash ~/dotfiles/scripts/setup-secrets.sh"
  exit 1
fi

# Determine if running as root
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "This script must be run as root or with sudo installed."
    exit 1
  fi
fi

# Detect distribution
if [ -f /etc/debian_version ]; then
  # Debian/Ubuntu
  echo "Detected Debian/Ubuntu. Installing CA..."
  $SUDO cp "$CA_PATH" "/usr/local/share/ca-certificates/$CA_NAME"
  $SUDO update-ca-certificates
  echo "CA installed. You may need to restart applications."
elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
  # RedHat/CentOS
  echo "Detected RedHat/CentOS. Installing CA..."
  $SUDO cp "$CA_PATH" "/etc/pki/ca-trust/source/anchors/$CA_NAME"
  $SUDO update-ca-trust
  echo "CA installed. You may need to restart applications."
else
  echo "Unsupported Linux distribution. Please install the CA manually."
  exit 2
fi
