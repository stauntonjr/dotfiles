#!/usr/bin/env bash
# Usage: 01_create_lxc.sh <CTID> <HOSTNAME> <TEMPLATE> <STORAGE>
# Example: 01_create_lxc.sh 103 sh-srv local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst rpool:32

set -e

CTID="$1"
HOSTNAME="$2"
TEMPLATE="$3"
STORAGE="$4"

pct create "$CTID" "$TEMPLATE" \
  --hostname "$HOSTNAME" \
  --cores 4 \
  --memory 4096 \
  --swap 512 \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp,type=veth \
  --rootfs "$STORAGE" \
  --ostype ubuntu \
  --password 'TempPassChangeMe123' \
  --ssh-public-keys /root/.ssh/id_ed25519.pub \
  --nameserver 10.0.0.152

pct start "$CTID"
