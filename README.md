# Docker Compose Init Container

Simulation of K8s / OpenShift init container within Docker Compose.

**Note** that some support from docker images is required - they should not use "complex" entrypoints,
preventing overridden docker container command to intercept start of container with helpers.

Idea is to use the same images for init container and pod container b/w K8s / OpenShift and
Docker Compose. Docker Compose project uses additional image sharing helpers which are used 
to intercept end of init container work and start of pod container to implement awaiting 
of pod container for completion of work of init container.

## Building

If remote Docker engine is used then `DOCKER_HOST` environment variable should point to that engine
and include the schema, like `tcp://docker-host:2375` instead of `docker-host:2375`.

Building with [Maven Wrapper](https://github.com/takari/maven-wrapper):

```bash
./mvnw clean package
```

or on Windows:

```bash
mvnw.cmd clean package
```

## Testing with Docker Compose

Refer to [docker-compose](docker-compose) directory for example of Docker Compose project

Check [http://localhost:8080](http://localhost:8080) URL, e.g. with curl:

```bash
curl -s http://localhost:8080
```

Expected output is

```text
Hello, User!
```

## Testing with OpenShift Origin

TODO
