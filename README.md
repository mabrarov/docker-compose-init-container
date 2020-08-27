# Docker Compose Init Container

Simulation of K8s / OpenShift init container within Docker Compose.

**Note** that some support from docker images is required - they should not use "complex" entrypoints,
preventing overridden docker container command to intercept start of container with helpers.

Idea is to use the same images for init container and pod container b/w K8s / OpenShift and
Docker Compose. Docker Compose project uses additional image sharing helpers which are used 
to intercept end of init container work and start of pod container to implement awaiting 
of pod container for completion of work of init container.

## Building

### Building Requirements

1. JDK 1.8+
1. Docker 1.12+
1. If remote Docker instance is used then `DOCKER_HOST` environment variable should point to that
   engine and include schema, like `tcp://docker-host:2375` instead of `docker-host:2375`.
1. Current directory is directory where this repository is cloned

### Building Steps

Building with [Maven Wrapper](https://github.com/takari/maven-wrapper):

```bash
./mvnw clean package -P docker
```

or on Windows:

```bash
mvnw.cmd clean package -P docker
```

## Testing with Docker Compose

### Docker Compose Testing Assumptions

1. All commands are given for Bash
1. Docker Compose is installed and has access to Docker
1. Project is built (refer to "[Building](#building)" section) using the same Docker instance
   which Docker Compose connects
1. IP address of Docker which Docker Compose connects is defined by `docker_address` environment variable
1. Subdomain name of application FQDN is defined by `app_subdomain` environment variable
1. Current directory is directory where this repository is cloned

e.g.

```bash
docker_address="$([[ "${DOCKER_HOST}" = "" ]] && echo "127.0.0.1" \
  || echo "${DOCKER_HOST}" \
  | sed -r 's/^([a-zA-Z0-9_]+:\/\/)?(([0-9]+\.){3}[0-9]+)(:[0-9]+)?$/\2/;t;d')" && \
app_subdomain="app"
```

### Docker Compose Testing Steps

Refer to [docker-compose](docker-compose) directory for Docker Compose project.

1. Create and start containers

   ```bash
   docker-compose -f docker-compose/docker-compose.yml up -d
   ```

1. Wait till application starts

   ```bash
   while ! docker-compose -f docker-compose/docker-compose.yml logs app \
     | grep -E '^.*\s+INFO\s+.*\[\s*main\]\s+(.*\.)?Application\s*:\s*Started Application\s*.*$' \
     > /dev/null ;
   do
     sleep 5s;
   done
   ```

1. Add hosts entry to access application

   ```bash
   echo "${docker_address} ${app_subdomain}.docker-compose-init-container.local" \
     | sudo tee -a /etc/hosts
   ```

1. Check [https://${app_subdomain}.docker-compose-init-container.local](https://app.docker-compose-init-container.local) URL,
   e.g. with curl:

   ```bash
   curl -s --cacert "$(pwd)/certificates/ca-cert.crt" \
     "https://${app_subdomain}.docker-compose-init-container.local"
   ```

   Expected output is

   ```text
   Hello, World!
   ```

1. Remove hosts entry used to access application

   ```bash
   sudo sed -ir "/${app_subdomain}\\.docker-compose-init-container\\.local/d" /etc/hosts
   ```

1. Stop and remove containers

   ```bash
   docker-compose -f docker-compose/docker-compose.yml down -v
   ```

## Testing with OpenShift

All commands were tested using Bash on Cent OS 7.7.
Commands for other OS and shells - like determining public IP address of host - may differ.

[oc Client Tools](https://www.okd.io/download.html) can be used to

* Setup local instance of [OKD](https://www.okd.io)
* Communicate with OpenShift cluster (existing OpenShift cluster or local OKD instance)

Setup of oc commandline tool from oc Client Tools can be done using following command

```bash
openshift_version="3.11.0" && openshift_build="0cbc58b" && \
curl -Ls "https://github.com/openshift/origin/releases/download/v${openshift_version}/openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit.tar.gz" \
  | sudo tar -xz --strip-components=1 -C /usr/bin "openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit/oc"
```

### OKD Setup

In case of need in OpenShift instance one can use [OKD](https://www.okd.io/) to setup local OpenShift instance easily

1. Configure Docker insecure registry - add 172.30.0.0/16 subnet into insecure-registries list of
   Docker daemon configuration, e.g. into /etc/docker/daemon.json file.

   Like this

   ```json
   {
     "insecure-registries": ["172.30.0.0/16"]
   }
   ```

1. Restart Docker daemon to apply changes
1. Determine & decide what address (existing domain name or IP address) will be used to access OpenShift,
   e.g. localhost or IP address of VM.

   Let's assume that OpenShift address is defined in `openshift_address` environment variable, e.g.

   ```bash
   openshift_address="$(ip address show \
     | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
     | head -n 1)"
   ``` 

1. Create & start OKD instance

   ```bash
   openshift_version="3.11.0" && \
   openshift_short_version="$(echo ${openshift_version} \
     | sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+$/\1/')" && \
   docker pull "docker.io/openshift/origin-control-plane:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-hyperkube:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-hypershift:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-node:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-haproxy-router:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-pod:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-deployer:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-cli:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-docker-registry:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-web-console:v${openshift_short_version}" && \
   docker pull "docker.io/openshift/origin-service-serving-cert-signer:v${openshift_short_version}" && \
   oc cluster up \
     --base-dir="${HOME}/openshift.local.clusterup" \
     --public-hostname="${openshift_address}" \
     --enable="registry,router,web-console"
   ```

### OpenShift Testing Assumptions

1. OpenShift API server **IP address** is defined by `openshift_address` environment variable
1. OpenShift API server user name is defined by `openshift_user` environment variable
1. OpenShift API server user password is defined by `openshift_password` environment variable
1. Name of OpenShift project for deployment is defined by `openshift_project` environment 
   variable
1. Name of OpenShift application is defined by `openshift_app` environment variable
1. OpenShift registry is defined by `openshift_registry` environment variable
1. Project is built (refer to "[Building](#building)" section)
1. Current directory is directory where this repository is cloned

e.g.

```bash
openshift_address="$(ip address show \
  | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
  | head -n 1)" && \
openshift_user="developer" && \
openshift_password="developer" && \
openshift_project="myproject" && \
openshift_app="app" && \
openshift_registry="172.30.1.1:5000"
```

### OpenShift Testing Steps

1. Push built docker images into OpenShift registry

   ```bash
   docker tag abrarov/docker-compose-init-container-app \
     "${openshift_registry}/${openshift_project}/${openshift_app}" && \
   docker tag abrarov/docker-compose-init-container-initializer \
     "${openshift_registry}/${openshift_project}/${openshift_app}-initializer" && \
   oc login -u "${openshift_user}" -p "${openshift_password}" \
     --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
   docker login -p "$(oc whoami -t)" -u unused "${openshift_registry}" && \
   docker push "${openshift_registry}/${openshift_project}/${openshift_app}" && \
   docker push "${openshift_registry}/${openshift_project}/${openshift_app}-initializer"
   ```

1. Apply OpenShift deployment which automatically triggers rollout and wait for completion of rollout

   ```bash
   oc login -u "${openshift_user}" -p "${openshift_password}" \
     --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
   oc process -n "${openshift_project}" -o yaml -f openshift/template.yml \
     "NAMESPACE=${openshift_project}" \
     "APP=${openshift_app}" \
     "REGISTRY=${openshift_registry}" \
     "ROUTE_CA_CERT_FILE=$(cat certificates/ca-cert.crt)" \
     "ROUTE_CERT_FILE=$(cat certificates/tls-cert.crt)" \
     "ROUTE_KEY_FILE=$(cat certificates/tls-key.pem)" \
     | oc apply -n "${openshift_project}" -f - && \
   oc rollout status -n "${openshift_project}" "dc/${openshift_app}"
   ```

1. Add hosts entry to access application

   ```bash
   echo "${openshift_address} ${openshift_app}.docker-compose-init-container.local" \
     | sudo tee -a /etc/hosts
   ```

1. Check [https://${openshift_app}.docker-compose-init-container.local](https://app.docker-compose-init-container.local) URL,
   e.g. with curl:

   ```bash
   curl -s --cacert "$(pwd)/certificates/ca-cert.crt" \
     "https://${openshift_app}.docker-compose-init-container.local"
   ```

   Expected output is

   ```text
   Hello, World!
   ```

1. Remove hosts entry used to access application

   ```bash
   sudo sed -ir "/${openshift_app}\\.docker-compose-init-container\\.local/d" /etc/hosts
   ```

1. Stop and remove OpenShift application, remove images from OpenShift registry and local Docker registry

   ```bash
   oc login -u "${openshift_user}" -p "${openshift_password}" \
     --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
   oc delete route "${openshift_app}" && \
   oc delete service "${openshift_app}" && \
   oc delete dc "${openshift_app}" && \
   oc delete secret "${openshift_app}" && \
   oc delete imagestream "${openshift_app}" && \
   oc delete imagestream "${openshift_app}-initializer" && \
   docker rmi "${openshift_registry}/${openshift_project}/${openshift_app}" && \
   docker rmi "${openshift_registry}/${openshift_project}/${openshift_app}-initializer"
   ```

### OKD Removal

1. Stop and remove OKD containers

   ```bash
   oc cluster down
   ```

1. Remove OKD mounts

   ```bash
   for openshift_mount in $(mount | grep openshift | awk '{ print $3 }'); do \
     echo "Unmounting ${openshift_mount}" && sudo umount "${openshift_mount}"; \
   done
   ```

1. Remove OKD configuration

   ```bash
   sudo rm -rf "${HOME}/openshift.local.clusterup"
   ```
