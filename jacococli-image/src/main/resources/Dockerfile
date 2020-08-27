FROM gcr.io/distroless/java-debian10

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

ADD rootfs.tar /

CMD ["/jacococli.jar", "--help"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"