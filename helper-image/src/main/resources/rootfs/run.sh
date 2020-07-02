#!/bin/sh

set -e

# Workaround for possible Docker Compose bug.
# Waits for some time to avoid error when Docker Compose starts stopped container
# and that container stops quickly. Even if container stops with zero exit code
# Docker Compose logs error. It looks like Docker Compose has some race condition issue.
main() {
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
