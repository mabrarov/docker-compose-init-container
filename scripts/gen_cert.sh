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
days="3650"
country_name="RU"
state="Moscow"
locality="Moscow"
organization="Private Person"
organizational_unit_name=""

ca_cert_file="${this_path}/out/ca_cert.crt"
ca_private_key="${this_path}/out/ca_private.pem"

#
# Don't change anything below here
#

out_path="${this_path}/out"

openssl_conf="${out_path}/config.cfg"
csr_file="${out_path}/request.csr"
key_file="${out_path}/private.pem"
serial_file="${out_path}/serial.srl"
cert_file="${out_path}/cert.crt"
cert_chain_file="${out_path}/chain.crt"
keystore_file="${out_path}/keystore.p12"

friendly_name="${1}"

if [[ -z "${friendly_name}" ]]; then
  echo "Please specify server FQDN (e.g. server.domain.net)"
  exit 1
fi

host_short_name="${friendly_name%%\.*}"
subject_alt_name=""
if ! [[ "${host_short_name}" = "*" ]] && ! [[ "${host_short_name}" = "${friendly_name}" ]]; then
  subject_alt_name="DNS:${friendly_name}, DNS:${host_short_name}"
else
  subject_alt_name="DNS:${friendly_name}"
fi

name_idx=2
while [[ "${name_idx}" -le "${#}" ]]; do
  name_type="DNS"
  name="${!name_idx}"
  if echo "${name}" | grep -E "^([0-9]{1,3}[\.]){3}[0-9]{1,3}$" > /dev/null; then
    name_type="IP"
  elif echo "${name}" | grep -E "^([0-9a-fA-F]{0,4}:){1,7}([0-9a-fA-F]){0,4}$" > /dev/null; then
    name_type="IP"
  fi
  subject_alt_name="${subject_alt_name:-DNS:${friendly_name}}"
  subject_alt_name="${subject_alt_name}, ${name_type}:${name}"
  name_idx=$((name_idx+1))
done

mkdir -p "${out_path}"
rm -f "${openssl_conf}"
rm -f "${key_file}"
rm -f "${serial_file}"
rm -f "${csr_file}"
rm -f "${cert_file}"
rm -f "${cert_chain_file}"
rm -f "${keystore_file}"

(
echo "[ req ]"
echo "default_bits = ${bits}"
echo "distinguished_name = req_distinguished_name"
echo "encrypt_key = no"
echo "prompt = no"
echo "string_mask = nombstr"
echo "req_extensions = v3_req"
echo ""
echo "[ v3_req ]"
echo "basicConstraints = CA:FALSE"
echo "keyUsage = digitalSignature, keyEncipherment, dataEncipherment, nonRepudiation"
echo "extendedKeyUsage = serverAuth, clientAuth"
if ! [[ "${subject_alt_name}" = "" ]]; then
  echo "subjectAltName = ${subject_alt_name}"
fi
echo ""
echo "[ req_distinguished_name ]"
echo "countryName = ${country_name}"
echo "stateOrProvinceName = ${state}"
echo "localityName = ${locality}"
echo "organizationName = ${organization}"
if [[ "${organizational_unit_name}" != "" ]]; then
  echo "organizationalUnitName = ${organizational_unit_name}"
fi
echo "commonName = ${friendly_name}"
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

# Sign certificate request
"${openssl_bin}" x509 \
  -req \
  -in "${csr_file}" \
  -CAkey "${ca_private_key}" \
  -CA "${ca_cert_file}" \
  -CAserial "${serial_file}" \
  -CAcreateserial \
  -days "${days}" \
  "-${digest}" \
  -extfile "${openssl_conf}" \
  -extensions v3_req \
  -out "${cert_file}"

# Create certificate chan consisting of generated certificate...
"${openssl_bin}" x509 -inform PEM -in "${cert_file}" > "${cert_chain_file}"

# ... and of  CA certificate.
"${openssl_bin}" x509 -inform PEM -in "${ca_cert_file}" >> "${cert_chain_file}"

# Combine chain of generated certificate and CA certificate
# with generated private key into keystore
"${openssl_bin}" pkcs12 \
  -export \
  -in "${cert_chain_file}" \
  -inkey "${key_file}" \
  -CAfile "${ca_cert_file}" \
  -name "${friendly_name}" \
  -noiter \
  -nomaciter \
  -out "${keystore_file}"
