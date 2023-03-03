#!/bin/sh

set -e

# Implements work done by init container
init() {
  if [ "${INIT_COMMAND}" = "" ]; then
    return
  fi
  "${INIT_COMMAND}"
}

# Runs simple echo server used by containers to wait until init container finishes its work
run_server() {
  script_dir="$(cd "$(dirname "${0}")" >/dev/null 2>&1 && pwd)"

  "${script_dir}/http-echo" -listen=:8080 -text="ready" &
  server_pid="${!}"

  # shellcheck disable=SC2064
  trap "kill -HUP \"${server_pid}\"" HUP
  # shellcheck disable=SC2064
  trap "kill -INT \"${server_pid}\"" INT
  # shellcheck disable=SC2064
  trap "kill -INT \"${server_pid}\"" QUIT
  # shellcheck disable=SC2064
  trap "kill -PIPE \"${server_pid}\"" PIPE
  # shellcheck disable=SC2064
  trap "kill -INT \"${server_pid}\"" TERM

  wait "${server_pid}" || true

  trap - HUP INT QUIT PIPE TERM
  exit_code=0
  wait "${server_pid}" && exit_code=0 || exit_code="${?}"

  if [ "${exit_code}" -eq 2 ]; then
    # Stopped by SIGTERM
    exit_code=0
  fi

  return "${exit_code}"
}

main() {
  init "${@}"
  run_server "${@}"
}

main "${@}"
