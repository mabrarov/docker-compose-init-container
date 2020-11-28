FROM gcr.io/distroless/java-debian10

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

ADD ["tini.tar", "/usr/bin"]
ADD ["jacoco.tar", "/"]
ADD ["dependencies.tar", "/app"]
ADD ["spring-boot-loader.tar", "/app"]
ADD ["snapshot-dependencies.tar", "/app"]
ADD ["application.tar", "/app"]

USER nonroot

# Entprypoint of base image executes java which we don't need
# because Docker Compose project overrides command to implement awaiting for init container
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