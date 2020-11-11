FROM gcr.io/distroless/java-debian10

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

ADD ["rootfs.tar", "/"]

USER nonroot

# Entprypoint of base image executes java which we don't need
# because Docker Compose project overrides command to implement awaiting for init container
ENTRYPOINT []

CMD ["/tini", "-e", "130", "-e", "143", "--", "/usr/bin/java", "-jar", "/app.jar"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"