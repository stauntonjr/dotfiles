#!/bin/bash
set -euo pipefail

# Install Docker (for Ubuntu/Debian)
if ! command -v docker &>/dev/null; then
    echo "[INFO] Installing Docker..."
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release


    # Add Docker's official GPG key if not present
    install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    else
        echo "[INFO] Docker GPG key already exists, skipping download."
    fi

    # Add Docker repository

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
            > /etc/apt/sources.list.d/docker.list

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "[INFO] Docker installed successfully."
else
    echo "[INFO] Docker is already installed."
fi
