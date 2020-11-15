#!/bin/sh

set -e

gen_trust_store() {
  if [ -z "${TRUST_STORE_FILE}" ]; then
    return;
  fi

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

  env | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' \
    | sort | while IFS= read -r ca_store_file_var; do
    ca_store_password_var="$(echo "${ca_store_file_var}" | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*)_FILE$/\1/')_PASSWORD"
    ca_store_file="$(printenv "${ca_store_file_var}")"
    if [ -z "${ca_store_file}" ]; then
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

  ca_bundle_index=0
  env | sed -r 's/^(CA_BUNDLE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' \
    | sort | while IFS= read -r ca_bundle_var; do
    ca_bundle_file="$(printenv "${ca_bundle_var}")"
    if [ -z "${ca_bundle_file}" ]; then
      continue
    fi
    ca_bundle_cert_dir="$(mktemp -d)"
    echo "Splitting ${ca_bundle_file} CA bundle into certificate files in ${ca_bundle_cert_dir} directory"
    awk 'BEGIN {c=0;} /-----BEGIN CERTIFICATE-----/{c++} { print > "'"${ca_bundle_cert_dir}/ca-cert-"'" sprintf("%03d-%03d", '"${ca_bundle_index}"', c) ".crt"}' \
      "${ca_bundle_file}"

    echo "Importing certificates from ${ca_bundle_cert_dir} directory"
    # Some images miss find utility, so avoid it
    #find "${ca_bundle_cert_dir}" -mindepth 1 -maxdepth 1 -name "*.crt" -type f -print \
    #  | sort | while IFS= read -r cert_file; do
    for cert_file in "${ca_bundle_cert_dir}/"*.crt; do
      cert_alias="imported-$(basename "${cert_file}" | sed -r 's/^(.+)\.crt$/\1/')"
      echo "Importing ${cert_file} CA certificate into ${TRUST_STORE_FILE} with ${cert_alias} alias"
      "${keytool}" -import -noprompt \
        -keystore "${TRUST_STORE_FILE}" \
        -storetype JKS \
        -storepass "${TRUST_STORE_PASSWORD}" \
        -file "${cert_file}" \
        -alias "${cert_alias}"
    done

    rm -rf "${ca_bundle_cert_dir}"
    ca_bundle_index="$((ca_bundle_index+1))"
  done
}

gen_trust_bundle() {
  if [ -z "${TRUST_BUNDLE_FILE}" ]; then
    return
  fi

  keytool="${JAVA_HOME}/bin/keytool"

  trust_bundle_dir="$(dirname "${TRUST_BUNDLE_FILE}")"
  if ! [ -d "${trust_bundle_dir}" ]; then
    mkdir -p "${trust_bundle_dir}"
  fi

  if [ -f "${TRUST_BUNDLE_FILE}" ]; then
    echo "Removing existing ${TRUST_BUNDLE_FILE}"
    rm -f "${TRUST_BUNDLE_FILE}"
  fi

  env | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' \
    | sort | while IFS= read -r ca_store_file_var; do
    ca_store_password_var="$(echo "${ca_store_file_var}" | sed -r 's/^(CA_STORE[a-zA-Z0-9_]*)_FILE$/\1/')_PASSWORD"
    ca_store_file="$(printenv "${ca_store_file_var}")"
    if [ -z "${ca_store_file}" ]; then
      continue
    fi
    ca_store_password="$(printenv "${ca_store_password_var}")"

    echo "Importing certificates from ${ca_store_file} keystore into ${TRUST_BUNDLE_FILE}"
    "${keytool}" -list -rfc \
      -keystore "${ca_store_file}" \
      -storetype JKS \
      -storepass "${ca_store_password}" \
      >> "${TRUST_BUNDLE_FILE}"
  done

  env | sed -r 's/^(CA_BUNDLE[a-zA-Z0-9_]*_FILE)=.*$/\1/;t;d' \
    | sort | while IFS= read -r ca_bundle_var; do
    ca_bundle_file="$(printenv "${ca_bundle_var}")"
    if [ -z "${ca_bundle_file}" ]; then
      continue
    fi
    echo "Copying certificates from ${ca_bundle_file} CA bundle into ${TRUST_BUNDLE_FILE}"
    cat "${ca_bundle_file}" >> "${TRUST_BUNDLE_FILE}"
  done
}

gen_keystore() {
  if [ -z "${KEYSTORE_FILE}" ]; then
    return
  fi

  keystore_dir="$(dirname "${KEYSTORE_FILE}")"
  if ! [ -d "${keystore_dir}" ]; then
    mkdir -p "${keystore_dir}"
  fi

  # shellcheck disable=SC2153
  crt_file="${CRT_FILE}"
  tmp_crt_file=0

  if [ -z "${CA_CRT_FILE}" ]; then
    echo "Generating ${KEYSTORE_FILE} keystore using ${KEY_FILE} key, ${CRT_FILE} certificate and ${KEY_ALIAS} alias"
  else
    echo "Generating ${KEYSTORE_FILE} keystore using ${KEY_FILE} key, ${CRT_FILE} certificate, ${CA_CRT_FILE} CA certificate and ${KEY_ALIAS} alias"
    crt_file="$(mktemp)"
    tmp_crt_file=1
    cat "${CRT_FILE}" "${CA_CRT_FILE}" > "${crt_file}"
  fi

  openssl pkcs12 \
    -export \
    -inkey "${KEY_FILE}" \
    -in "${crt_file}" \
    -name "${KEY_ALIAS}" \
    -out "${KEYSTORE_FILE}" \
    -password pass:"${KEYSTORE_PASSWORD}"

  if [ "${tmp_crt_file}" -ne 0 ]; then
    rm -f "${crt_file}"
  fi
}

main() {
  gen_trust_bundle
  gen_trust_store
  gen_keystore
}

main "${@}"
