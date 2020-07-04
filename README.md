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
1. Address of Docker which Docker Compose connects is defined by
   `docker_address` environment variable, e.g.

   ```bash
   docker_address="localhost"
   ```

   or

   ```bash
   docker_address="$(echo "${DOCKER_HOST}" | sed -r 's/^[a-zA-Z0-9_]+:\/\/(([0-9]+\.){3}[0-9]+)(:[0-9]+)?$/\1/;t;d')"
   ```

1. Current directory is directory where this repository is cloned

### Docker Compose Testing Steps

Refer to [docker-compose](docker-compose) directory for Docker Compose project.

1. Create and start containers

   ```bash
   docker-compose -f docker-compose/docker-compose.yml up -d
   ```

1. Wait till application starts

   ```bash
   while ! docker-compose -f docker-compose/docker-compose.yml logs app \
   | grep -E '^.*\s+INFO\s+.*\[\s*main\]\s+.*dockercomposeinitcontainer\.Main\s*:\s*Started Main\s*.*$' \
   > /dev/null ;
   do
   sleep 5s;
   done
   ```

1. Check [https://${docker_address}](https://localhost) URL, e.g. with curl:

   ```bash
   curl -ks "https://${docker_address}"
   ```

   Expected output is

   ```text
   Hello, World!
   ```

1. Stop and remove containers

   ```bash
   docker-compose -f docker-compose/docker-compose.yml down -v
   ```

## Testing with OpenShift

All commands were tested using Bash on Cent OS 7.7. Commands for other OS and shells - 
like determining public IP address of host - may differ.

[OpenShift Origin Client Tools](https://www.okd.io/download.html) can be used to

* Setup instance of [OKD](https://www.okd.io/) (OpenShift Origin)
* Communicate with OpenShift cluster (existing OpenShift cluster or OpenShift Origin instance)

Setup of oc commandline tool from OpenShift Origin Client Tools can be done using following command

```bash
openshift_version="3.11.0" && openshift_build="0cbc58b" && \
curl -Ls "https://github.com/openshift/origin/releases/download/v${openshift_version}/openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit.tar.gz" \
| sudo tar -xz --strip-components=1 -C /usr/bin "openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit/oc"
```

### OpenShift Origin Setup

In case of need in OpenShift instance one could use [OKD](https://www.okd.io/) (OpenShift Origin) to
setup OpenShift instance easily

1. Configure Docker insecure registry - add 172.30.0.0/16 subnet into insecure-registries list of
   Docker daemon configuration, e.g. into /etc/docker/daemon.json file.

   Like this

   ```json
   {
     "insecure-registries": ["172.30.0.0/16"]
   }
   ```

1. Restart Docker daemon to apply changes
1. Determine & decide what address will be used to access OpenShift, 
   e.g. localhost or IP address of VM.
   
   Let's assume that OpenShift address is defined in `openshift_address` environment variable, e.g.

   ```bash
   openshift_address="$(ip address show \
   | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
   | head -n 1)"
   ``` 

1. Setup & start OpenShift Origin instance

   ```bash
   openshift_version="3.11.0" && \
   openshift_short_version="$(echo ${openshift_version} | sed -r 's/^([0-9]+\.[0-9]+)\.[0-9]+$/\1/')" && \
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
   pushd ~ && \
   oc cluster up --public-hostname="${openshift_address}" --enable="registry,router,web-console" ; \
   popd
   ```

### OpenShift Testing Assumptions

1. OpenShift API server address is defined by `openshift_address` environment variable
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
   docker tag abrarov/docker-compose-init-container-app "${openshift_registry}/${openshift_project}/${openshift_app}" && \
   docker tag abrarov/docker-compose-init-container-initializer "${openshift_registry}/${openshift_project}/${openshift_app}-initializer" && \
   oc login -u "${openshift_user}" -p "${openshift_password}" "${openshift_address}:8443" && \
   docker login -p "$(oc whoami -t)" -u unused "${openshift_registry}" && \
   docker push "${openshift_registry}/${openshift_project}/${openshift_app}" && \
   docker push "${openshift_registry}/${openshift_project}/${openshift_app}-initializer"
   ```

1. Apply OpenShift deployment which automatically triggers rollout and wait for completion of rollout

   ```bash
   oc login -u "${openshift_user}" -p "${openshift_password}" "${openshift_address}:8443" && \
   oc process -n "${openshift_project}" -o yaml -f openshift/template.yml \
   "NAMESPACE=${openshift_project}" \
   "APP=${openshift_app}" \
   "REGISTRY=${openshift_registry}" \
   | oc apply -n "${openshift_project}" -f - && \
   oc rollout status -n "${openshift_project}" "dc/${openshift_app}"
   ```

1. Add hosts entry to access OpenShift application

   ```bash
   echo "${openshift_address} ${openshift_app}.router.default.svc.cluster.local" | sudo tee -a /etc/hosts
   ```

1. Check [https://${openshift_app}.router.default.svc.cluster.local](https://app.router.default.svc.cluster.local) URL,
   e.g. with curl:

   ```bash
   curl -ks https://${openshift_app}.router.default.svc.cluster.local
   ```

   Expected output is

   ```text
   Hello, World!
   ```

1. Stop and remove OpenShift application

   ```bash
   oc login -u "${openshift_user}" -p "${openshift_password}" "${openshift_address}:8443" && \
   oc delete route "${openshift_app}" && \
   oc delete service "${openshift_app}" && \
   oc delete dc "${openshift_app}" && \
   oc delete secret "${openshift_app}"
   ```

1. Remove hosts entry used to access OpenShift application

   ```bash
   sudo sed -ir "/${openshift_app}\\.router\\.default\\.svc\\.cluster\\.local/d" /etc/hosts
   ```

### OpenShift Origin Removal

1. Stop and remove OpenShift Origin containers

   ```bash
   oc cluster down
   ```

1. Remove OpenShift mounts

   ```bash
   for openshift_mount in $(mount | grep openshift | awk '{ print $3 }'); do
   echo "Unmounting ${openshift_mount}" && sudo umount "${openshift_mount}"; 
   done
   ```

1. Remove OpenShift Origin configuration

   ```bash
   sudo rm -rf "$(cd ~ &> /dev/null && pwd)/openshift.local.clusterup"
   ```
