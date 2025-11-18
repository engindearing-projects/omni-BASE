#!/bin/bash
#
# Generate test certificates for TLS testing
#
# Creates:
# - CA certificate and key
# - Server certificate and key
# - Client certificate and key
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$SCRIPT_DIR/../certs"

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

echo "Generating test certificates in $CERTS_DIR..."

# Generate CA
echo "1. Generating CA certificate..."
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -days 365 -key ca-key.pem -out ca-cert.pem \
    -subj "/C=US/ST=Test/L=Test/O=OmniTAK/CN=OmniTAK Test CA"

# Generate Server certificate
echo "2. Generating server certificate..."
openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server-req.pem \
    -subj "/C=US/ST=Test/L=Test/O=OmniTAK/CN=localhost"

# Sign server certificate with CA
openssl x509 -req -in server-req.pem -days 365 \
    -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
    -out server-cert.pem

# Generate Client certificate
echo "3. Generating client certificate..."
openssl genrsa -out client-key.pem 2048
openssl req -new -key client-key.pem -out client-req.pem \
    -subj "/C=US/ST=Test/L=Test/O=OmniTAK/CN=Test Client"

# Sign client certificate with CA
openssl x509 -req -in client-req.pem -days 365 \
    -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
    -out client-cert.pem

# Clean up CSRs
rm -f server-req.pem client-req.pem ca-cert.srl

echo "
✅ Certificates generated successfully!

Files created:
  ca-cert.pem       - CA certificate
  ca-key.pem        - CA private key
  server-cert.pem   - Server certificate
  server-key.pem    - Server private key
  client-cert.pem   - Client certificate
  client-key.pem    - Client private key

To start TLS server:
  cargo run --example tls_server

To test with TLS client:
  cargo run --example tls_client
"
