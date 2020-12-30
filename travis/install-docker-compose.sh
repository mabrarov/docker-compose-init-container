#!/bin/bash

set -e

docker_compose_url="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
docker_compose_tmp="$(mktemp)"
echo "Downloading Docker Compose from ${docker_compose_url} into ${docker_compose_tmp}"
curl -Ls "${docker_compose_url}" > "${docker_compose_tmp}"
chmod +x "${docker_compose_tmp}"
sudo mv -f "${docker_compose_tmp}" /usr/local/bin/docker-compose

docker-compose --version
