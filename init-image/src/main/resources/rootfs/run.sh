#!/bin/sh

set -e

cat_ca_bundles() {
  for ca_bundle_var in $(env | sed -r 's/^(CA_BUNDLE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' | sort); do
    ca_bundle_file="$(printenv "${ca_bundle_var}")"
    if [ "${ca_bundle_file}" = "" ]; then
      continue
    fi
    cat "${ca_bundle_file}"
  done
}

gen_trust_store() {
  keytool="${JAVA_HOME}/bin/keytool"

  trust_store_dir="$(dirname "${TRUST_STORE_FILE}")"
  if ! [ -d "${trust_store_dir}" ]; then
    mkdir -p "${trust_store_dir}"
  fi

  if [ -f "${TRUST_STORE_FILE}" ]; then
    echo "Removing existing ${TRUST_STORE_FILE}"
    rm -f "${TRUST_STORE_FILE}"
  fi
  echo "Creating empty ${TRUST_STORE_FILE}"
  "${keytool}" -genkeypair -alias temp \
    -dname "CN=Temp, OU=Temp, O=Temp, L=Temp, ST=Temp, C=RU" \
    -keystore "${TRUST_STORE_FILE}" \
    -storetype JKS \
    -keypass "${TRUST_STORE_PASSWORD}" \
    -storepass "${TRUST_STORE_PASSWORD}"
  "${keytool}" -delete -alias temp \
    -keystore "${TRUST_STORE_FILE}" \
    -storetype JKS \
    -storepass "${TRUST_STORE_PASSWORD}"

  for ca_store_file_var in $(env | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' | sort); do
    ca_store_password_var="$(echo "${ca_store_file_var}" | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*)_FILE$/\1/')_PASSWORD"
    ca_store_file="$(printenv "${ca_store_file_var}")"
    if [ "${ca_store_file}" = "" ]; then
      continue
    fi
    ca_store_password="$(printenv "${ca_store_password_var}")"
    "${keytool}" -importkeystore -noprompt \
      -srckeystore "${ca_store_file}" \
      -srcstoretype JKS \
      -srcstorepass "${ca_store_password}" \
      -destkeystore "${TRUST_STORE_FILE}" \
      -deststoretype JKS \
      -deststorepass "${TRUST_STORE_PASSWORD}"
  done

  echo "Splitting CA bundles"
  cat_ca_bundles \
    | awk 'BEGIN {c=0;} /-----BEGIN CERTIFICATE-----/{c++} { print > "/tmp/ca-cert-" sprintf("%03d", c) ".crt"}'

  echo "Importing certificates from CA bundles"
  for cert_file in $(find "/tmp" -mindepth 1 -maxdepth 1 -name "ca-cert-*.crt" -type f -print | sort); do
    cert_alias="imported-$(basename "${cert_file}" | sed -r 's/^(.+)\.crt$/\1/')"
    echo "Importing ${cert_file} CA certificate into ${TRUST_STORE_FILE} with ${cert_alias} alias"
    "${keytool}" -import -noprompt \
      -keystore "${TRUST_STORE_FILE}" \
      -storetype JKS \
      -storepass "${TRUST_STORE_PASSWORD}" \
      -file "${cert_file}" \
      -alias "${cert_alias}"
  done
}

gen_keystore() {
  keystore_dir="$(dirname "${KEYSTORE_FILE}")"
  if ! [ -d "${keystore_dir}" ]; then
    mkdir -p "${keystore_dir}"
  fi

  crt_file="${CRT_FILE}"

  if [ "${CA_CRT_FILE}" = "" ]; then
    echo "Generating ${KEYSTORE_FILE} keystore using ${KEY_FILE} key, ${CRT_FILE} certificate and ${KEY_ALIAS} alias"
  else
    echo "Generating ${KEYSTORE_FILE} keystore using ${KEY_FILE} key, ${CRT_FILE} certificate, ${CA_CRT_FILE} CA certificate and ${KEY_ALIAS} alias"
    crt_file="/tmp/cert.crt"
    cat "${CRT_FILE}" "${CA_CRT_FILE}" > "${crt_file}"
  fi

  openssl pkcs12 \
    -export \
    -inkey "${KEY_FILE}" \
    -in "${crt_file}" \
    -name "${KEY_ALIAS}" \
    -out "${KEYSTORE_FILE}" \
    -password pass:"${KEYSTORE_PASSWORD}"
}

main() {
  gen_trust_store
  gen_keystore
}

main "${@}"
