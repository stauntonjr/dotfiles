#!/bin/bash
set -e

## Variables
SSL_DIR=~/dotfiles/ssl
CA_KEY="$SSL_DIR/ca.key"
CA_CERT="$SSL_DIR/ca.crt"
WILDCARD_KEY="$SSL_DIR/wildcard.ediacarian.home.key"
WILDCARD_CSR="$SSL_DIR/wildcard.ediacarian.home.csr"
WILDCARD_CERT="$SSL_DIR/wildcard.ediacarian.home.crt"
WILDCARD_EXT="$SSL_DIR/wildcard.ediacarian.home.ext"
WILDCARD_SUBJECT="/C=US/ST=Local/L=Local/O=OIDC-DEV/CN=*.ediacarian.home"

# 1. Generate CA key and cert
if [ ! -f "$CA_KEY" ]; then
  openssl genrsa -out "$CA_KEY" 4096
fi
if [ ! -f "$CA_CERT" ]; then
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 -out "$CA_CERT" -subj "/C=US/ST=Local/L=Local/O=OIDC-DEV/CN=OIDC-DEV-CA"
fi

# 2. Generate server key and CSR
echo "Certificates generated: $CA_CERT, $SERVER_CERT, $SERVER_KEY"
openssl genrsa -out "$WILDCARD_KEY" 4096
openssl req -new -key "$WILDCARD_KEY" -out "$WILDCARD_CSR" -subj "$WILDCARD_SUBJECT"

# 3. Create SAN config for wildcard
cat > "$WILDCARD_EXT" <<EOF
subjectAltName = DNS:*.ediacarian.home, DNS:ediacarian.home
EOF

# 4. Sign wildcard server cert with CA
openssl x509 -req -in "$WILDCARD_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$WILDCARD_CERT" -days 825 -sha256 -extfile "$WILDCARD_EXT"

# 5. Cleanup
rm "$WILDCARD_CSR" "$WILDCARD_EXT" || true

chmod 600 "$CA_KEY" "$WILDCARD_KEY"
echo "Certificates generated: $CA_CERT, $WILDCARD_CERT, $WILDCARD_KEY"
