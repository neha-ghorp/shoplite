#!/usr/bin/env bash
# Creates a private CA and a server certificate for shoplite.localhost signed by it.
# Output goes to swarm/certs/ (git-ignored: it contains private keys).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p certs && cd certs

# 1. Root CA: a key and a self-signed certificate. This is the trust anchor.
openssl genrsa -out ca.key 4096
openssl req -x509 -new -key ca.key -sha256 -days 365 \
  -subj "/O=ShopLite Lab/CN=ShopLite Root CA" -out ca.crt

# 2. Server key + certificate signing request (CSR): "please sign this public key for this name"
openssl genrsa -out shoplite.key 2048
openssl req -new -key shoplite.key -subj "/O=ShopLite Lab/CN=shoplite.localhost" -out shoplite.csr

# 3. The CA signs the CSR. Browsers only check the SAN list, not the CN, so the SAN is required.
cat > shoplite.ext <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:shoplite.localhost,DNS:*.shoplite.localhost
EOF
openssl x509 -req -in shoplite.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days 90 -sha256 -extfile shoplite.ext -out shoplite.crt

rm shoplite.csr shoplite.ext ca.srl
openssl verify -CAfile ca.crt shoplite.crt
