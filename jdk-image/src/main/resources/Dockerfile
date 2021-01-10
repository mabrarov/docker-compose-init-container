FROM gcr.io/distroless/java-debian10:base

ENV JAVA_HOME="/opt/@jdk.dir@" \
    PATH="/opt/@jdk.dir@/bin:${PATH}"

ADD ["jdk.tar.gz", "/opt"]

LABEL name="@docker.repository@"