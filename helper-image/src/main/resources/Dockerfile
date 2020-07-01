FROM gcr.io/distroless/static-debian10

ADD rootfs.tar /

RUN ["/bin/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /bin/busybox ln -s /bin/busybox \"/bin/${cmd}\"; done"]

RUN ["/helper/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /helper/busybox ln -s /helper/busybox \"/helper/${cmd}\"; done"]

CMD ["/run.sh"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"