#!/bin/sh

set -e

keystore_dir="$(dirname "${KEYSTORE_FILE}")"
if ! [ -d "${keystore_dir}" ]; then
  mkdir -p "${keystore_dir}"
fi

openssl pkcs12 \
  -export \
  -inkey "${KEY_FILE}" \
  -in "${CRT_FILE}" \
  -name "${KEY_ALIAS}" \
  -out "${KEYSTORE_FILE}" \
  -password pass:"${KEYSTORE_PASSWORD}"
