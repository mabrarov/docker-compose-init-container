FROM @jdk.image.repository@:@project.version@

ADD ["dependencies.tar", "/"]
ADD ["spring-boot-loader.tar", "/"]
ADD ["snapshot-dependencies.tar", "/"]
ADD ["application.tar", "/"]

USER nonroot

WORKDIR "/app"

CMD ["tini", "-e", "130", "-e", "143", "--", "java", "org.springframework.boot.loader.JarLauncher"]

LABEL name="@docker.repository@" \
    version="@project.version@" \
    release="@project.version@" \
    build-date="@git.commit.time@" \
    vcs-url="@git.remote.origin.url@" \
    vcs-type="git" \
    vcs-ref="@git.commit.id@"