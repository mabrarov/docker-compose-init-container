FROM gcr.io/distroless/static-debian10

ADD rootfs.tar /

# For run.sh
RUN ["/bin/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /bin/busybox ln -s /bin/busybox \"/bin/${cmd}\"; done"]

# For helper/init.sh
RUN ["/helper/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /helper/busybox ln -s /helper/busybox \"/helper/${cmd}\"; done"]

# We have to provide at least one of ENTRYPOINT or CMD and it's better to do that here
# to reduce Docker Compose project
CMD ["/run.sh"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"