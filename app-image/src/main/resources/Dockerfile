FROM gcr.io/distroless/java-debian10

ADD rootfs.tar /

ENTRYPOINT []

CMD ["/tini", "-e", "130", "-e", "143", "--", "/usr/bin/java", "-jar", "/app.jar"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"