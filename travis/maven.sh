#!/bin/bash

maven_runner() {
  if [[ "${MAVEN_WRAPPER}" -ne 0 ]]; then
    printf "%q" "${TRAVIS_BUILD_DIR}/mvnw"
  else
    echo "mvn"
  fi
}

maven_settings() {
  maven_settings_file="${TRAVIS_BUILD_DIR}/travis/settings.xml"
  if [[ -f "${maven_settings_file}" ]]; then
    printf " %s %q" "--settings" "${maven_settings_file}"
  fi
}

maven_project_file() {
  printf " %s %q" "--file" "${TRAVIS_BUILD_DIR}/pom.xml"
}

docker_maven_plugin_version() {
  if [[ -n "${DOCKER_MAVEN_PLUGIN_VERSION}" ]]; then
    printf " %s%q" "--define docker-maven-plugin.version=" "${DOCKER_MAVEN_PLUGIN_VERSION}"
  fi
}
