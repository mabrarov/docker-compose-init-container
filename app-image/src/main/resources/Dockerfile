FROM gcr.io/distroless/java-debian10

ADD rootfs.tar /

# Entprypoint of base image executes java which we don't need
# because Docker Compose project overrides command to implement awaiting for init container
ENTRYPOINT []

CMD ["/tini", "-e", "130", "-e", "143", "--", "/usr/bin/java", "-jar", "/app.jar"]

ENV GREETING_FILE="/config/greeting.txt"

EXPOSE 8080

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"