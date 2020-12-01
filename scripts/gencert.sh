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
"${openssl_bin}" genrsa "${bits}" > "${key_file}"

# Generate certificate request
"${openssl_bin}" req \
  -new \
  -key "$(native_path "${key_file}")" \
  -config "$(native_path "${openssl_conf}")" \
  "-${digest}" \
  -out "$(native_path "${csr_file}")"

# Sign certificate request
"${openssl_bin}" x509 \
  -req \
  -in "$(native_path "${csr_file}")" \
  -CAkey "$(native_path "${ca_private_key}")" \
  -CA "$(native_path "${ca_cert_file}")" \
  -CAserial "$(native_path "${serial_file}")" \
  -CAcreateserial \
  -days "${days}" \
  "-${digest}" \
  -extfile "$(native_path "${openssl_conf}")" \
  -extensions v3_req \
  -out "$(native_path "${cert_file}")"

# Create certificate chain consisting of generated certificate...
"${openssl_bin}" x509 -inform PEM -in "$(native_path "${cert_file}")" > "${cert_chain_file}"
# ... and of CA certificate.
"${openssl_bin}" x509 -inform PEM -in "$(native_path "${ca_cert_file}")" >> "${cert_chain_file}"
