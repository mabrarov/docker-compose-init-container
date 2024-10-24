# Docker Compose Init Container

[![License](https://img.shields.io/github/license/mabrarov/docker-compose-init-container)](https://github.com/mabrarov/docker-compose-init-container/tree/master/LICENSE)
[![Travis CI build status](https://travis-ci.com/mabrarov/docker-compose-init-container.svg?branch=master)](https://travis-ci.com/github/mabrarov/docker-compose-init-container)

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
1. Subdomain name of application FQDN is defined by `app_subdomain` environment variable
1. Current directory is directory where this repository is cloned
1. Name of Docker Compose project is defined by `compose_project` environment variable

e.g.

```bash
app_subdomain='app' && \
compose_project='dcic'
```

### Docker Compose Testing Steps

Refer to [docker-compose](docker-compose) directory for Docker Compose project.

1. Create and start containers

    ```bash
    docker-compose -p "${compose_project}" -f docker-compose/docker-compose.yml up -d
    ```

    If there is a need to deploy with [JaCoCo](https://www.jacoco.org) agent turned on, 
    then use this command instead (adds `JAVA_OPTIONS` environment variable which is picked and used
    by Docker Compose project)

    ```bash
    jacoco_port='6300' && \
    JAVA_OPTIONS="-javaagent:/jacoco.jar=output=tcpserver,address=0.0.0.0,port=${jacoco_port},includes=org.mabrarov.dockercomposeinitcontainer.*" \
    docker-compose -p "${compose_project}" -f docker-compose/docker-compose.yml up -d
    ```

1. Wait till application starts

    For Docker Compose 1.x

    ```bash
    while [[ "$(docker inspect --format '{{ .State.Health.Status }}' \
      "${compose_project}_app_1")" != 'healthy' ]]; do \
      sleep 5s; \
    done
    ```

    For Docker Compose 2.x

    ```bash
    while [[ "$(docker inspect --format '{{ .State.Health.Status }}' \
      "${compose_project}-app-1")" != 'healthy' ]]; do \
      sleep 5s; \
    done
    ```

1. Check `https://${app_subdomain}.docker-compose-init-container.local` URL, e.g. with curl:

    ```bash
    docker run --rm \
      --network "${compose_project}_default" \
      --volume "$(pwd)/certificates/ca.crt:/ca.crt:ro" \
      curlimages/curl \
      curl -s --cacert "/ca.crt" \
      "https://${app_subdomain}.docker-compose-init-container.local:8443"
    ```

    Expected output is

    ```text
    Hello, World!
    ```

1. If deployed with JaCoCo agent turned on then check coverage using this command
   (note that project has to be _built_ and _not cleaned_ at the time of execution of this command)

    ```bash
    jacoco_version='0.8.8' && \
    jacoco_report_dir="$(pwd)/jacoco-report" && \
    jacoco_tmp_dir="$(mktemp -d)" && \
    jacoco_dist_file="${jacoco_tmp_dir}/jacoco-${jacoco_version}.zip" && \
    jacoco_exec_file="${jacoco_tmp_dir}/jacoco.exec" && \
    curl -Ls -o "${jacoco_dist_file}" \
      "https://repo1.maven.org/maven2/org/jacoco/jacoco/${jacoco_version}/jacoco-${jacoco_version}.zip" && \
    unzip -q -o -j "${jacoco_dist_file}" -d "${jacoco_tmp_dir}" lib/jacococli.jar && \
    jacococli_file="${jacoco_tmp_dir}/jacococli.jar" && \
    chmod o+r "${jacococli_file}" && \
    docker run --rm \
      -v "${jacococli_file}:/$(basename "${jacococli_file}")" \
      -v "$(dirname "${jacoco_exec_file}"):/jacoco" \
      --network "${compose_project}_default" \
      gcr.io/distroless/java-debian11 \
      "/$(basename "${jacococli_file}")" dump \
      --address app \
      --port "${jacoco_port}" \
      --destfile "/jacoco/$(basename "${jacoco_exec_file}")" \
      --quiet --retry 3 && \
    mkdir -p "${jacoco_report_dir}" && \
    java -jar "${jacococli_file}" report "${jacoco_exec_file}" \
      --classfiles app/target/classes \
      --sourcefiles app/src/main/java \
      --html "${jacoco_report_dir}" && \
    rm -f "${jacoco_exec_file}" && \
    rm -rf "${jacoco_tmp_dir}"
    ```

    After successful execution of command JaCoCo HTML report can be found in `${jacoco_report_dir}`
    directory (`${jacoco_report_dir}/index.html` file is report entry point).

1. Stop and remove containers

    ```bash
    docker-compose -p "${compose_project}" -f docker-compose/docker-compose.yml down -v -t 0
    ```

## Testing with OpenShift

All commands were tested using Bash on CentOS 7.7.
Curl is required for testing outside OpenShift.
Commands for other OS and shells - like determining public IP address of host - may differ.

[oc Client Tools](https://www.okd.io/download.html) can be used to

* Setup local instance of [OKD](https://www.okd.io)
* Communicate with OpenShift cluster (existing OpenShift cluster or local OKD instance)

Setup of oc commandline tool from oc Client Tools can be done using following command

```bash
openshift_version='3.11.0' && openshift_build='0cbc58b' && \
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
    openshift_version='3.11.0' && \
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
    docker pull "docker.io/openshift/origin-web-console:v${openshift_short_version}" && \
    docker pull "docker.io/openshift/origin-service-serving-cert-signer:v${openshift_short_version}" && \
    oc cluster up \
      --base-dir="${HOME}/openshift.local.clusterup" \
      --public-hostname="${openshift_address}" \
      --enable="router,web-console"
    ```

### OpenShift Testing Assumptions

1. OpenShift API server **IP address** is defined by `openshift_address` environment variable
1. OpenShift API server user name is defined by `openshift_user` environment variable
1. OpenShift API server user password is defined by `openshift_password` environment variable
1. Name of OpenShift project for deployment is defined by `openshift_project` environment 
   variable
1. Name of OpenShift application is defined by `openshift_app` environment variable
1. Name of Helm release is defined by `helm_release` environment variable
1. Project is built (refer to "[Building](#building)" section)
1. Current directory is directory where this repository is cloned

e.g.

```bash
openshift_address="$(ip address show \
  | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
  | head -n 1)" && \
openshift_user='developer' && \
openshift_password='developer' && \
openshift_project='myproject' && \
openshift_app='app' && \
helm_release='dcic'
```

### OpenShift Testing Steps

1. Deploy application using [openshift/app](openshift/app) Helm chart and wait for
   completion of rollout

    ```bash
    oc login -u "${openshift_user}" -p "${openshift_password}" \
      --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
    helm upgrade "${helm_release}" openshift/app \
      --kube-apiserver "https://${openshift_address}:8443" \
      -n "${openshift_project}" \
      --set nameOverride="${openshift_app}" \
      --set route.host="${openshift_app}.docker-compose-init-container.local" \
      --set-file route.tls.caCertificate="$(pwd)/certificates/ca.crt" \
      --set-file route.tls.certificate="$(pwd)/certificates/tls.crt" \
      --set-file route.tls.key="$(pwd)/certificates/tls.key" \
      --install --wait
    ```

    If there is a need to deploy with [JaCoCo](https://www.jacoco.org) agent turned on, 
    then use this command instead (overrides `app.extraJvmOptions` Helm chart value comparing to
    previous command)

    ```bash
    jacoco_port='6300' && \
    oc login -u "${openshift_user}" -p "${openshift_password}" \
      --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
    helm upgrade "${helm_release}" openshift/app \
      --kube-apiserver "https://${openshift_address}:8443" \
      -n "${openshift_project}" \
      --set nameOverride="${openshift_app}" \
      --set route.host="${openshift_app}.docker-compose-init-container.local" \
      --set-file route.tls.caCertificate="$(pwd)/certificates/ca.crt" \
      --set-file route.tls.certificate="$(pwd)/certificates/tls.crt" \
      --set-file route.tls.key="$(pwd)/certificates/tls.key" \
      --set "app.extraJvmOptions={-javaagent:/jacoco.jar=output=tcpserver\\,address=0.0.0.0\\,port=${jacoco_port}\\,includes=org.mabrarov.dockercomposeinitcontainer.*}" \
      --install --wait
    ```

    Expected output looks like:

    ```text
    Login successful.

    You have one project on this server: "myproject"

    Using project "myproject".
    Release "dcic" does not exist. Installing it now.
    NAME: dcic
    LAST DEPLOYED: Tue Nov  9 03:59:42 2021
    NAMESPACE: myproject
    STATUS: deployed
    REVISION: 1
    NOTES:
    1. Application URL: https://app.docker-compose-init-container.local/
    ```

1. Test OpenShift service and pod

    ```bash
    oc login -u "${openshift_user}" -p "${openshift_password}" \
      --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
    helm test "${helm_release}" \
      --kube-apiserver "https://${openshift_address}:8443" \
      -n "${openshift_project}" \
      --logs
    ```

    Expected output ends with

    ```text
    Hello, World!
    ```

1. Check `https://${openshift_app}.docker-compose-init-container.local`, e.g. with curl:

    ```bash
    curl -s --cacert "$(pwd)/certificates/ca.crt" \
      --resolve "${openshift_app}.docker-compose-init-container.local:443:${openshift_address}" \
      "https://${openshift_app}.docker-compose-init-container.local"
    ```

    Expected output is

    ```text
    Hello, World!
    ```

1. If deployed with JaCoCo agent turned on then check coverage using this command
   (note that project has to be _built_ and _not cleaned_ at the time of execution of this command)

    ```bash
    jacoco_version='0.8.8' && \
    jacoco_report_dir="$(pwd)/jacoco-report" && \
    jacoco_tmp_dir="$(mktemp -d)" && \
    jacoco_dist_file="${jacoco_tmp_dir}/jacoco-${jacoco_version}.zip" && \
    jacoco_exec_file="${jacoco_tmp_dir}/jacoco.exec" && \
    curl -Ls -o "${jacoco_dist_file}" \
      "https://repo1.maven.org/maven2/org/jacoco/jacoco/${jacoco_version}/jacoco-${jacoco_version}.zip" && \
    unzip -q -o -j "${jacoco_dist_file}" -d "${jacoco_tmp_dir}" lib/jacococli.jar && \
    jacococli_file="${jacoco_tmp_dir}/jacococli.jar" && \
    oc login -u "${openshift_user}" -p "${openshift_password}" \
      --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
    pod_counter=0 && \
    for pod_name in $(oc get pods -n "${openshift_project}" \
      --no-headers \
      --output="custom-columns=NAME:.metadata.name" \
      --selector="app.kubernetes.io/name=${openshift_app},app.kubernetes.io/instance=${helm_release}"); do \
      oc get pod "${pod_name}" -o jsonpath="{.spec['containers'][*].name}" \
        | grep -F -m 1 app > /dev/null || continue && \
      pod_jacoco_exec_file="$([[ "${pod_counter}" -eq 0 ]] && \
        echo "${jacoco_exec_file}" || \
        echo "${jacoco_exec_file}.${pod_counter}")" && \
      { oc port-forward "${pod_name}" "${jacoco_port}:${jacoco_port}" > /dev/null & \
        oc_port_forward_pid="${!}"; } 2>/dev/null && \
      sleep 2 && \
      java -jar "${jacococli_file}" dump \
        --address localhost --port "${jacoco_port}" \
        --destfile "${pod_jacoco_exec_file}" \
        --quiet --retry 3 && \
      { kill -s INT "${oc_port_forward_pid}" && \
        wait; } 2>/dev/null && \
      if [[ "${pod_counter}" -ne 0 ]]; then \
        jacoco_exec_merge_file="${jacoco_exec_file}.tmp" && \
        java -jar "${jacococli_file}" merge "${pod_jacoco_exec_file}" "${jacoco_exec_file}" \
          --destfile "${jacoco_exec_merge_file}" --quiet && \
        mv -f "${jacoco_exec_merge_file}" "${jacoco_exec_file}"; \
      fi && \
      pod_counter=$((pod_counter+1)); \
    done && \
    mkdir -p "${jacoco_report_dir}" && \
    java -jar "${jacococli_file}" report "${jacoco_exec_file}" \
      --classfiles app/target/classes \
      --sourcefiles app/src/main/java \
      --html "${jacoco_report_dir}" && \
    rm -rf "${jacoco_tmp_dir}"
    ```

    After successful execution of command JaCoCo HTML report can be found in `${jacoco_report_dir}`
    directory (`${jacoco_report_dir}/index.html` file is report entry point).

1. Stop and remove OpenShift application

    ```bash
    oc login -u "${openshift_user}" -p "${openshift_password}" \
      --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
    helm uninstall "${helm_release}" \
      --kube-apiserver "https://${openshift_address}:8443" \
      -n "${openshift_project}" --wait --cascade foreground
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

## Testing with Kubernetes

All commands were tested using Bash on Ubuntu Server 18.04.
Curl is required for testing outside Kubernetes.

### kubectl Setup

```bash
k8s_version='1.31.2' && \
curl -Ls "https://dl.k8s.io/release/v${k8s_version}/bin/linux/amd64/kubectl" \
  | sudo tee /usr/local/bin/kubectl > /dev/null && \
sudo chmod +x /usr/local/bin/kubectl
```

### Helm Setup

```bash
helm_version='3.16.2' && \
curl -Ls "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz" \
  | sudo tar -xz --strip-components=1 -C /usr/local/bin "linux-amd64/helm"
```

### Minikube Setup

In case of need in Kubernetes (K8s) instance one can use [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) to setup local K8s instance easily

1. Download Minikube executable (minikube)

    ```bash
    minikube_version='1.34.0' && \
    curl -Ls "https://github.com/kubernetes/minikube/releases/download/v${minikube_version}/minikube-linux-amd64.tar.gz" \
      | tar -xzO --strip-components=1 "out/minikube-linux-amd64" \
      | sudo tee /usr/local/bin/minikube > /dev/null && \
    sudo chmod +x /usr/local/bin/minikube
    ```

1. Create & start K8s instance

    ```bash
    minikube start --driver=docker --addons=ingress,registry,dashboard
    ```

1. Configure Docker insecure registry for Minikube registry - add subnet of Minikube registry into
   insecure-registries list of Docker daemon configuration, e.g. into /etc/docker/daemon.json file.

    Minikube registry IP address can be retrieved using this command

    ```bash
    minikube ip
    ```

    If command returns `192.168.49.2`, then the daemon.json file should look like this

    ```json
    {
      "insecure-registries": ["192.168.49.0/24"]
    }
    ```

1. Stop Minikube

    ```bash
    minikube stop
    ```

1. Restart Docker daemon to apply changes
1. Start Minikube back

    ```bash
    minikube start
    ```

1. Start proxy if need to access outside host where Minikube runs

    ```bash
    kubectl proxy --address='0.0.0.0' --disable-filter=true --port=8080
    ```

1. Check K8s dashboard using [http://localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/](http://localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/)

    If accessing outside of host where Minikube runs then replace localhost with external address of host where Minikube runs, e.g.

    ```bash
    k8s_address="$(ip address show \
      | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
      | head -n 1)"
    ```

    and use [http://${k8s_address}:8080/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/](http://${k8s_address}:8080/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/)

### Minikube Testing Assumptions

1. Name of K8s namespace for deployment is defined by `k8s_namespace` environment variable
1. Name of K8s application is defined by `k8s_app` environment variable
1. Name of Helm release is defined by `helm_release` environment variable

e.g.

```bash
k8s_namespace='default' && \
k8s_app='app' && \
helm_release='dcic'
```

### Minikube Testing Steps

1. Push built docker images into Minikube registry

    ```bash
    minikube_registry="$(minikube ip):5000" && \
    docker tag abrarov/docker-compose-init-container-app "${minikube_registry}/app" && \
    docker tag abrarov/docker-compose-init-container-initializer "${minikube_registry}/app-initializer" && \
    docker push "${minikube_registry}/app" && \
    docker push "${minikube_registry}/app-initializer"
    ```

1. Deploy application using [kubernetes/app](kubernetes/app) Helm chart and wait
   for completion of rollout

    ```bash
    helm upgrade "${helm_release}" kubernetes/app \
      -n "${k8s_namespace}" \
      --set nameOverride="${k8s_app}" \
      --set image.registry='localhost:5000' \
      --set image.repository='app' \
      --set init.image.registry='localhost:5000' \
      --set init.image.repository='app-initializer' \
      --set ingress.host="${k8s_app}.docker-compose-init-container.local" \
      --set-file ingress.tls.caCertificate="$(pwd)/certificates/ca.crt" \
      --set-file ingress.tls.certificate="$(pwd)/certificates/tls.crt" \
      --set-file ingress.tls.key="$(pwd)/certificates/tls.key" \
      --install --wait
    ```

    If there is a need to deploy with JaCoCo agent turned on, then use this command instead

    ```bash
    jacoco_port='6300' && \
    helm upgrade "${helm_release}" kubernetes/app \
      -n "${k8s_namespace}" \
      --set nameOverride="${k8s_app}" \
      --set image.registry='localhost:5000' \
      --set image.repository='app' \
      --set init.image.registry='localhost:5000' \
      --set init.image.repository='app-initializer' \
      --set ingress.host="${k8s_app}.docker-compose-init-container.local" \
      --set-file ingress.tls.caCertificate="$(pwd)/certificates/ca.crt" \
      --set-file ingress.tls.certificate="$(pwd)/certificates/tls.crt" \
      --set-file ingress.tls.key="$(pwd)/certificates/tls.key" \
      --set "app.extraJvmOptions={-javaagent:/jacoco.jar=output=tcpserver\\,address=0.0.0.0\\,port=${jacoco_port}\\,includes=org.mabrarov.dockercomposeinitcontainer.*}" \
      --install --wait
    ```

    Expected output looks like:

    ```text
    Release "dcic" does not exist. Installing it now.
    NAME: dcic
    LAST DEPLOYED: Tue Nov  9 00:22:17 2021
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    NOTES:
    1. Application URL: https://app.docker-compose-init-container.local/
    ```

1. Test K8s service and pod

    ```bash
    helm test "${helm_release}" -n "${k8s_namespace}" --logs
    ```

    Expected output ends with

    ```text
    Hello, World!
    ```

1. Check `https://${k8s_app}.docker-compose-init-container.local`, e.g. with curl:

    ```bash
    ingress_ip="$(minikube ip)" && \
    curl -s --cacert "$(pwd)/certificates/ca.crt" \
      --resolve "${k8s_app}.docker-compose-init-container.local:443:${ingress_ip}" \
      "https://${k8s_app}.docker-compose-init-container.local"
    ```

    Expected output is

    ```text
    Hello, World!
    ```

1. If deployed with JaCoCo agent turned on then check coverage using this command
   (note that project has to be _built_ and _not cleaned_ at the time of execution of this command)

    ```bash
    jacoco_version='0.8.8' && \
    jacoco_report_dir="$(pwd)/jacoco-report" && \
    jacoco_tmp_dir="$(mktemp -d)" && \
    jacoco_dist_file="${jacoco_tmp_dir}/jacoco-${jacoco_version}.zip" && \
    jacoco_exec_file="${jacoco_tmp_dir}/jacoco.exec" && \
    curl -Ls -o "${jacoco_dist_file}" \
      "https://repo1.maven.org/maven2/org/jacoco/jacoco/${jacoco_version}/jacoco-${jacoco_version}.zip" && \
    unzip -q -o -j "${jacoco_dist_file}" -d "${jacoco_tmp_dir}" lib/jacococli.jar && \
    jacococli_file="${jacoco_tmp_dir}/jacococli.jar" && \
    pod_counter=0 && \
    for pod_name in $(kubectl get pods -n "${k8s_namespace}" \
      --no-headers \
      --output="custom-columns=NAME:.metadata.name" \
      --selector="app.kubernetes.io/name=${k8s_app},app.kubernetes.io/instance=${helm_release}"); do \
      kubectl get pod "${pod_name}" -o jsonpath="{.spec['containers'][*].name}" \
        | grep -F -m 1 app > /dev/null || continue && \
      pod_jacoco_exec_file="$([[ "${pod_counter}" -eq 0 ]] && \
        echo "${jacoco_exec_file}" || \
        echo "${jacoco_exec_file}.${pod_counter}")" && \
      { kubectl port-forward "${pod_name}" "${jacoco_port}:${jacoco_port}" > /dev/null & \
        kubectl_port_forward_pid="${!}"; } 2>/dev/null && \
      sleep 2 && \
      java -jar "${jacococli_file}" dump \
        --address localhost --port "${jacoco_port}" \
        --destfile "${pod_jacoco_exec_file}" \
        --quiet --retry 3 && \
      { kill -s INT "${kubectl_port_forward_pid}" && \
        wait; } 2>/dev/null && \
      if [[ "${pod_counter}" -ne 0 ]]; then \
        jacoco_exec_merge_file="${jacoco_exec_file}.tmp" && \
        java -jar "${jacococli_file}" merge "${pod_jacoco_exec_file}" "${jacoco_exec_file}" \
          --destfile "${jacoco_exec_merge_file}" --quiet && \
        mv -f "${jacoco_exec_merge_file}" "${jacoco_exec_file}"; \
      fi && \
      pod_counter=$((pod_counter+1)); \
    done && \
    mkdir -p "${jacoco_report_dir}" && \
    java -jar "${jacococli_file}" report "${jacoco_exec_file}" \
      --classfiles app/target/classes \
      --sourcefiles app/src/main/java \
      --html "${jacoco_report_dir}" && \
    rm -rf "${jacoco_tmp_dir}"
    ```

    After successful execution of command JaCoCo HTML report can be found in `${jacoco_report_dir}`
    directory (`${jacoco_report_dir}/index.html` file is report entry point).

1. Stop and remove K8s application, remove temporary images from local Docker registry

    ```bash
    helm uninstall "${helm_release}" -n "${k8s_namespace}" --wait --cascade foreground && \
    minikube_registry="$(minikube ip):5000" && \
    docker rmi "${minikube_registry}/app" && \
    docker rmi "${minikube_registry}/app-initializer"
    ```

### Minikube Removal

1. Delete minikube instance

    ```bash
    minikube delete --purge=true
    ```

1. Optionally remove K8s configuration files

    ```bash
    rm -rf ~/.kube
    ```
