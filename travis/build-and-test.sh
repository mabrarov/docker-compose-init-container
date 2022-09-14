#!/bin/bash

set -e

# shellcheck source=maven.sh
source "${TRAVIS_BUILD_DIR}/travis/maven.sh"

build_maven_project() {
  build_cmd="$(maven_runner)$(maven_settings)$(maven_project_file)$(docker_maven_plugin_version)"
  build_cmd="${build_cmd:+${build_cmd} }--batch-mode"

  if [[ -n "${MAVEN_BUILD_PROFILES}" ]]; then
    build_cmd="${build_cmd:+${build_cmd} }--activate-profiles $(printf "%q" "${MAVEN_BUILD_PROFILES}")"
  fi

  build_cmd="${build_cmd:+${build_cmd} }package"

  echo "Building with: ${build_cmd}"
  eval "${build_cmd}"

  docker images
}

wait_for_healthy_container() {
  container_name="${1}"
  wait_seconds=${2}
  exit_code=0
  while true; do
    echo "Waiting for ${container_name} container to become healthy during next ${wait_seconds} seconds"
    container_status="$(docker inspect \
      -f "{{.State.Health.Status}}" "${container_name}")" \
      || exit_code="${?}"
    if [[ "${exit_code}" -ne 0 ]]; then
      echo "Failed to inspect ${container_name} container"
      return 1
    fi
    if [[ "${container_status}" == "healthy" ]]; then
      echo "${container_name} container is healthy"
      return 0
    fi
    if [[ "${wait_seconds}" -le 0 ]]; then
      echo "Timeout waiting for ${container_name} container to become healthy"
      return 1
    fi
    sleep 1
    wait_seconds=$((wait_seconds-1))
  done
}

get_container_status() {
  container_name="${1}"
  docker inspect \
    --type container \
    --format='{{ .State.Status }}' \
    "${container_name}"
}

get_container_exit_code() {
  container_name="${1}"
  docker inspect \
    --type container \
    --format='{{ .State.ExitCode }}' \
    "${container_name}"
}

request_application() {
  docker_compose_project_network="${1}"
  app_host="${2}"
  app_port="${3}"
  echo "Requesting application"
  docker run --rm \
    --network "${docker_compose_project_network}" \
    --volume "${TRAVIS_BUILD_DIR}/certificates/ca.crt:/ca.crt:ro" \
    curlimages/curl \
    curl -s --cacert "/ca.crt" "https://${app_host}:${app_port}"
  echo
}

asserted_exited_containers_zero_exit_code() {
  docker_compose_project_name="${1}"
  docker_compose_project_file="${2}"
  local exited_status="exited"
  for container_name in $(docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    ps -a \
    | sed -r "s/^(${docker_compose_project_name}_[^[:space:]]*)[[:space:]]+.*\$/\\1/;t;d"); do
      echo "Retrieving status of container ${container_name}"
      container_status="$(get_container_status "${container_name}")"
      echo "Status of ${container_name} container: ${container_status}"
      if [[ "${container_status}" == "running" ]]; then
        continue
      fi
      if [[ "${container_status}" != "${exited_status}" ]]; then
        echo "Unexpected status of container ${container_name}, expected: ${exited_status}"
        return 1
      fi
      echo "Retrieving exit code of container ${container_name}"
      container_exit_code="$(get_container_exit_code "${container_name}")"
      echo "Exit code of ${container_name} container: ${container_exit_code}"
      if [[ "${container_exit_code}" -ne 0 ]]; then
        echo "Unexpected exit code of ${container_name} container, expected: 0"
        return 1
      fi
  done
}

assert_all_containers_zero_exit_code() {
  docker_compose_project_name="${1}"
  docker_compose_project_file="${2}"
  for container_name in $(docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    ps -a \
    | sed -r "s/^(${docker_compose_project_name}_[^[:space:]]*)[[:space:]]+.*\$/\\1/;t;d"); do
      echo "Retrieving exit code of container ${container_name}"
      container_exit_code="$(get_container_exit_code "${container_name}")"
      echo "Exit code of ${container_name} container: ${container_exit_code}"
      if [[ "${container_exit_code}" -ne 0 ]]; then
        echo "Unexpected exit code of ${container_name} container, expected: 0"
        return 1
      fi
  done
}

test_images() {
  mvn_expression_evaluate_cmd="$(maven_runner)$(maven_settings)$(maven_project_file) --batch-mode --non-recursive"
  mvn_expression_evaluate_cmd="${mvn_expression_evaluate_cmd:+${mvn_expression_evaluate_cmd} }org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate"

  docker_image_repository_base_cmd="${mvn_expression_evaluate_cmd:+${mvn_expression_evaluate_cmd} }--define expression=docker.image.repository.base"
  docker_image_repository_base="$(eval "${docker_image_repository_base_cmd}" | sed -e '/^\[.*\].*$/d')"

  maven_project_version_cmd="${mvn_expression_evaluate_cmd:+${mvn_expression_evaluate_cmd} }--define expression=project.version"
  maven_project_version="$(eval "${maven_project_version_cmd}" | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }')"

  app_image_name="${docker_image_repository_base}docker-compose-init-container-app:${maven_project_version}"
  echo "Running container created from ${app_image_name} image"
  docker run --rm "${app_image_name}" java --version

  docker_compose_project_name="dcic"
  docker_compose_project_file="${TRAVIS_BUILD_DIR}/docker-compose/docker-compose.yml"
  docker_compose_project_network="${docker_compose_project_name}_default"
  app_host="app.docker-compose-init-container.local"
  app_port="8443"

  echo "Creating and starting application using Docker Compose"
  docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    up -d

  app_container_name="$(docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    ps -a \
    | sed -r "s/^(${docker_compose_project_name}_app[^[:space:]]*)[[:space:]]+.*\$/\\1/;t;d")"

  wait_for_healthy_container "${app_container_name}" "${APP_START_TIMEOUT}"

  asserted_exited_containers_zero_exit_code \
    "${docker_compose_project_name}" \
    "${docker_compose_project_file}"

  request_application \
    "${docker_compose_project_network}" \
    "${app_host}" "${app_port}"

  echo "Stopping application"
  docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    stop -t "${APP_STOP_TIMEOUT}"

  assert_all_containers_zero_exit_code \
    "${docker_compose_project_name}" \
    "${docker_compose_project_file}"

  echo "Starting application"
  docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    start

  wait_for_healthy_container "${app_container_name}" "${APP_START_TIMEOUT}"

  request_application \
    "${docker_compose_project_network}" \
    "${app_host}" "${app_port}"

  echo "Stopping application"
  docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    stop -t "${APP_STOP_TIMEOUT}"

  assert_all_containers_zero_exit_code \
    "${docker_compose_project_name}" \
    "${docker_compose_project_file}"

  echo "Removing application"
  docker-compose \
    -p "${docker_compose_project_name}" \
    -f "${docker_compose_project_file}" \
    down -v -t 0
}

main() {
  build_maven_project "${@}"
  test_images "${@}"
}

main "${@}"
