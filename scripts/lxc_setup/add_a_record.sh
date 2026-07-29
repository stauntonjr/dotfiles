#!/usr/bin/env bash
# Usage: add_a_record.sh <HOSTNAME> <IP>
# Example: add_a_record.sh md-srv 10.0.0.120

set -e

# Get DNS server IP and Technitium API key from environment
DNS_SERVER_IP="${DNS_SERVER_IP:?DNS_SERVER_IP not set in environment}"
TECHNITIUM_API_KEY="${TECHNITIUM_API_KEY:?TECHNITIUM_API_KEY not set in environment}"
ZONE="ediacarian.home"
TTL=3600

HOSTNAME="$1"
IP="$2"

if [[ -z "$HOSTNAME" || -z "$IP" ]]; then
  echo "Usage: $0 <HOSTNAME> <IP>"
  exit 1
fi

curl -X POST "http://${DNS_SERVER_IP}:5380/api/zones/${ZONE}/records/add?token=${TECHNITIUM_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{ \"type\": \"A\", \"name\": \"${HOSTNAME}\", \"value\": \"${IP}\", \"ttl\": ${TTL} }"
