FROM gcr.io/distroless/static-debian10

ADD rootfs.tar /

RUN ["/bin/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /bin/busybox ln -s /bin/busybox \"/bin/${cmd}\"; done"]

# Work of init container
CMD ["/bin/sh", "-c", "set -e && if ! [ -d /config ]; then mkdir -p /config; fi && echo 'Hello, User!' > /config/greeting.txt"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"