#!/bin/bash
# generate-wildcard-cert.sh
# Generate a wildcard server certificate for *.ediacarian.home

set -e

SSL_DIR=~/dotfiles/ssl
CA_KEY="$SSL_DIR/ca.key"
CA_CERT="$SSL_DIR/ca.crt"
WILDCARD_KEY="$SSL_DIR/wildcard.ediacarian.home.key"
WILDCARD_CSR="$SSL_DIR/wildcard.ediacarian.home.csr"
WILDCARD_CERT="$SSL_DIR/wildcard.ediacarian.home.crt"
WILDCARD_EXT="$SSL_DIR/wildcard.ediacarian.home.ext"
SUBJECT="/C=US/ST=Local/L=Local/O=OIDC-DEV/CN=*.ediacarian.home"

cat > "$WILDCARD_EXT" <<EOF
subjectAltName = DNS:*.ediacarian.home, DNS:ediacarian.home
EOF

openssl genrsa -out "$WILDCARD_KEY" 4096
openssl req -new -key "$WILDCARD_KEY" -out "$WILDCARD_CSR" -subj "$SUBJECT"
openssl x509 -req -in "$WILDCARD_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$WILDCARD_CERT" -days 825 -sha256 -extfile "$WILDCARD_EXT"

rm "$WILDCARD_CSR" "$WILDCARD_EXT" || true
chmod 600 "$WILDCARD_KEY"
echo "Wildcard certificate generated: $WILDCARD_CERT, $WILDCARD_KEY"
