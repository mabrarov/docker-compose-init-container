FROM gcr.io/distroless/java-debian10

ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

ADD ["rootfs.tar", "/"]

RUN ["busybox", "sh", "-c", "set -e && for cmd in $(busybox --list); do busybox ln -s /usr/bin/busybox \"/usr/bin/${cmd}\"; done && busybox ln -s /usr/bin/busybox /bin/sh"]

ENV CA_STORE_JDK_FILE="/usr/lib/jvm/java-11-openjdk-amd64/lib/security/cacerts" \
    CA_STORE_JDK_PASSWORD="changeit"

#ENV CA_STORE*_FILE="ca-certificate-trust-store-sun-jks.jks"
#ENV CA_STORE*_PASSWORD="ca-certificate-trust-store-password"
#ENV CA_BUNDLE*_FILE="ca-certificate-bundle-pem-base64.crt"
#ENV TRUST_STORE_FILE="trust-store-sun-jks.jks"
#ENV TRUST_STORE_PASSWORD="trust-store-password"
#ENV TRUST_BUNDLE_FILE="trust-ca-bundle-pem-base64.crt"
#ENV CA_CRT_FILE="ca-certificate-pem-base64.crt"
#ENV CRT_FILE="certificate-pem-base64.crt"
#ENV KEY_FILE="private-key-pem-base64.pem"
#ENV KEYSTORE_FILE="keystore-pkcs12.p12"
#ENV KEYSTORE_PASSWORD="keystore-password"
#ENV KEY_ALIAS="key-alias"

USER nonroot

# Entprypoint of base image executes java which we don't need
ENTRYPOINT []

# Work of init container
CMD ["/run.sh"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"