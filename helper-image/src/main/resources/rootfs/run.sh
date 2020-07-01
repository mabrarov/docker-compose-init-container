#!/bin/sh

set -e

main() {
  # Wait for some time to avoid error when Docker Compose starts stopped container
  time_to_wait_sec="${1}"
  if [ "${time_to_wait_sec}" = "" ]; then
    time_to_wait_sec=5
  fi

  ping -q -i 1 -c "${time_to_wait_sec}" 127.0.0.1 >/dev/null 2>&1 &
  pid="${!}"

  trap "kill -HUP \"${pid}\"" HUP
  trap "kill -INT \"${pid}\"" INT
  trap "kill -INT \"${pid}\"" QUIT
  trap "kill -PIPE \"${pid}\"" PIPE
  trap "kill -INT \"${pid}\"" TERM

  wait "${pid}" || true

  trap - HUP INT QUIT PIPE TERM
  exit_code=0
  wait "${pid}" && exit_code=0 || exit_code="${?}"

  return "${exit_code}"
}

main "${@}"
