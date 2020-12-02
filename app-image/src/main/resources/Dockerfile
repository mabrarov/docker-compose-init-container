FROM gcr.io/distroless/java-debian10

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

ADD ["dependencies.tar", "/"]
ADD ["spring-boot-loader.tar", "/"]
ADD ["snapshot-dependencies.tar", "/"]
ADD ["application.tar", "/"]

USER nonroot

# Entry point of the base image executes java which we don't need
# because Docker Compose project overrides command to implement awaiting for init container.
# Docker Compose project can not override entry point.
ENTRYPOINT []

WORKDIR "/app"

CMD ["tini", "-e", "130", "-e", "143", "--", "java", "org.springframework.boot.loader.JarLauncher"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"