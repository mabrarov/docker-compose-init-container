#!/bin/bash

set -e

this_path="$(cd "$(dirname "${0}")" &> /dev/null && pwd)"

# Change these variables for your environment.
# Do not put spaces between the = sign
# SSL Certificate Properties
# Country name must be exactly two letters

# Path to OpenSSL
openssl_bin="openssl"

digest="sha512"
bits="4096"
days="7300"
country_name="RU"
state="Moscow"
locality="Moscow"
organization="Private Person"
organizational_unit_name=""
common_name="Test Certificate Authority"
keystore_entry="test_ca"

#
# Don't change anything below here
#

out_path="${this_path}/out"

openssl_conf="${out_path}/ca_config.cfg"
csr_file="${out_path}/ca_request.csr"
key_file="${out_path}/ca_private.pem"
database_file="${out_path}/ca_index.txt"
serial_file="${out_path}/ca_serial.srl"
cert_file="${out_path}/ca_cert.crt"
keystore_file="${out_path}/ca_keystore.p12"

mkdir -p "${out_path}"
rm -f "${openssl_conf}"
rm -f "${database_file}"
rm -f "${key_file}"
rm -f "${csr_file}"
rm -f "${cert_file}"
rm -f "${keystore_file}"
touch "${database_file}"

(
echo "[ ca ]"
echo "default_ca = default_ca"
echo ""
echo "[ default_ca ]"
echo "database = ${database_file}"
echo "new_certs_dir = ${out_path}"
echo "certificate = ${cert_file}"
echo "private_key = ${key_file}"
echo "serial = ${serial_file}"
echo "default_md = ${digest}"
echo "policy = default_policy"
echo ""
echo "[ default_policy ]"
echo "countryName = optional"
echo "stateOrProvinceName = optional"
echo "organizationName = optional"
echo "organizationalUnitName = optional"
echo "commonName = supplied"
echo "emailAddress = optional"
echo ""
echo "[ req ]"
echo "default_bits = ${bits}"
echo "distinguished_name = req_distinguished_name"
echo "encrypt_key = no"
echo "prompt = no"
echo "string_mask = nombstr"
echo "x509_extensions = v3_ca"
echo "req_extensions = v3_req"
echo ""
echo "[ v3_req ]"
echo "basicConstraints = CA:FALSE"
echo "keyUsage = digitalSignature, keyEncipherment, dataEncipherment, nonRepudiation"
echo "extendedKeyUsage = serverAuth, clientAuth"
echo "subjectAltName = email:move"
echo ""
echo "[ v3_ca ]"
echo "subjectKeyIdentifier = hash"
echo "authorityKeyIdentifier = keyid:always,issuer:always"
echo "basicConstraints = CA:true"
echo ""
echo "[ req_distinguished_name ]"
echo "countryName = ${country_name}"
echo "stateOrProvinceName = ${state}"
echo "localityName = ${locality}"
echo "organizationName = ${organization}"
if [[ "${organizational_unit_name}" != "" ]]; then
  echo "organizationalUnitName = ${organizational_unit_name}"
fi
echo "commonName = ${common_name}"
) > "${openssl_conf}"

# Generate private key
"${openssl_bin}" genrsa "${bits}" "-${digest}" > "${key_file}"

# Generate certificate request
"${openssl_bin}" req \
  -new \
  -key "${key_file}" \
  -config "${openssl_conf}" \
  "-${digest}" \
  -out "${csr_file}"

# Self-sign certificate request and so generate self-signed CA certificate
"${openssl_bin}" ca \
  -batch \
  -create_serial \
  -out "${cert_file}" \
  -days "${days}" \
  -keyfile "${key_file}" \
  -selfsign \
  -extensions v3_ca \
  -config "${openssl_conf}" \
  -infiles "${csr_file}"

# Combine generated certificate with generated private key into keystore
"${openssl_bin}" pkcs12 \
  -export \
  -in "${cert_file}" \
  -inkey "${key_file}" \
  -name "${keystore_entry}" \
  -noiter \
  -nomaciter \
  -out "${keystore_file}"
