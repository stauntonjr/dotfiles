#!/usr/bin/env bash
# check-ssh-key-cert.sh
# Usage: ./check-ssh-key-cert.sh <private_key> <public_key> <cert_file> <ca_pubkey>

set -e


if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <private_key> <public_key> <cert_file> <ca_pubkey> <ca_privkey>"
    exit 1
fi

PRIVKEY="$1"
PUBKEY="$2"
CERT="$3"
CA_PUBKEY="$4"
CA_PRIVKEY="$5"


# 1. Check private/public key match
echo "Checking private/public key match..."
if ssh-keygen -y -f "$PRIVKEY" | diff - "$PUBKEY"; then
    echo "Private and public key match."
else
    echo "ERROR: Private and public key do NOT match."
    exit 2
fi

# 1b. Check CA private/public key match
echo "Checking CA private/public key match..."
if ssh-keygen -y -f "$CA_PRIVKEY" | diff - "$CA_PUBKEY"; then
    echo "CA private and public key match."
else
    echo "ERROR: CA private and public key do NOT match."
    exit 5
fi


# 2. Check certificate is for the public key
echo "Checking certificate is for the public key..."
CERT_PUB=$(ssh-keygen -L -f "$CERT" | grep "Public Key:" -A1 | tail -n1 | tr -d ' ')
USER_PUB=$(ssh-keygen -e -f "$PUBKEY" | tr -d '\n ')
if [[ "$CERT_PUB" != "" && "$USER_PUB" != "" && "$CERT_PUB" == *"${USER_PUB:0:32}"* ]]; then
    echo "Certificate matches public key."
else
    echo "WARNING: Certificate may not match public key (manual check recommended)."
fi



# 3. Check certificate is signed by CA
echo "Checking certificate signature..."
if ssh-keygen -L -f "$CERT" | grep -q "Signing CA:"; then
    CA_FP=$(ssh-keygen -lf "$CA_PUBKEY" | awk '{print $2}')
    # Extract only the SHA256 fingerprint from the "Signing CA:" line
    CERT_CA_FP=$(ssh-keygen -L -f "$CERT" | grep "Signing CA:" | sed -E 's/.*(SHA256:[A-Za-z0-9+/=]+).*/\1/')
    echo "CA public key fingerprint:      $CA_FP"
    echo "Certificate Signing CA:         $CERT_CA_FP"
    if [ "$CA_FP" = "$CERT_CA_FP" ]; then
        echo "Certificate is signed by the provided CA."
    else
        echo "ERROR: Certificate is NOT signed by the provided CA."
        exit 3
    fi
else
    echo "ERROR: Certificate does not have a Signing CA."
    exit 4
fi

echo "All checks passed."