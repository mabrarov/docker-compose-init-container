#!/bin/bash

set -e

export MSYS_NO_PATHCONV=1

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

mkdir -p "${out_path}"
rm -f "${openssl_conf}"
rm -f "${database_file}"
rm -f "${key_file}"
rm -f "${csr_file}"
rm -f "${cert_file}"
touch "${database_file}"

native_path() {
  path="${1}"
  uname -s | grep '^MINGW.*$' &> /dev/null && mingw=1 || mingw=0
  if [[ "${mingw}" -eq 0 ]]; then
    echo "${path}"
    return
  fi
  if ! echo "${path}" | grep -P '^\/[a-zA-Z](\/.*)?$' &> /dev/null ; then
    echo "${path}"
    return
  fi
  echo "${path}" | sed -r 's/^\/([a-zA-Z])(\/.*)?$/\U\1\E:\2/;t;d'
}

(
echo "[ ca ]"
echo "default_ca = default_ca"
echo ""
echo "[ default_ca ]"
echo "database = $(native_path "${database_file}")"
echo "new_certs_dir = $(native_path "${out_path}")"
echo "certificate = $(native_path "${cert_file}")"
echo "private_key = $(native_path "${key_file}")"
echo "serial = $(native_path "${serial_file}")"
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
"${openssl_bin}" genrsa "${bits}" > "${key_file}"

# Generate certificate request
"${openssl_bin}" req \
  -new \
  -key "$(native_path "${key_file}")" \
  -config "$(native_path "${openssl_conf}")" \
  "-${digest}" \
  -out "$(native_path "${csr_file}")"

# Self-sign certificate request and so generate self-signed CA certificate
"${openssl_bin}" ca \
  -batch \
  -create_serial \
  -out "$(native_path "${cert_file}")" \
  -days "${days}" \
  -keyfile "$(native_path "${key_file}")" \
  -selfsign \
  -extensions v3_ca \
  -config "$(native_path "${openssl_conf}")" \
  -infiles "$(native_path "${csr_file}")"
