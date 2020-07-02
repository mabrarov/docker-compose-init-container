FROM gcr.io/distroless/base-debian10

ADD rootfs.tar /

RUN ["/bin/busybox", "sh", "-c", "set -e && for cmd in $(/bin/busybox --list); do /bin/busybox ln -s /bin/busybox \"/bin/${cmd}\"; done"]

#ENV CRT_FILE='certificate-pem-base64.crt'
#ENV KEY_FILE='private-key-pem-base64.pem'
#ENV KEYSTORE_FILE="keystore-pkcs12.p12"
#ENV KEYSTORE_PASSWORD='keystore-password'
#ENV KEY_ALIAS="key-alias"

# Work of init container
CMD ["/run.sh"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"