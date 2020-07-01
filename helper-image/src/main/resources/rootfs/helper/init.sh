#!/bin/sh

set -e

export PATH="/helper:${PATH}"

init() {
  touch /config/data
}

pid_alive() {
  pid="${1}"
  if ps -p "${pid}" > /dev/null 2>&1; then
    echo 1
  else
    echo 0
  fi
}

run_server() {
  script_dir="$(cd "$(dirname "${0}")" >/dev/null 2>&1 && pwd)"

  ${script_dir}/http-echo -listen=:8080 -text="ready" &
  server_pid="${!}"

  trap "kill -HUP \"${server_pid}\"" HUP
  trap "kill -INT \"${server_pid}\"" INT
  trap "kill -INT \"${server_pid}\"" QUIT
  trap "kill -PIPE \"${server_pid}\"" PIPE
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
