FROM alpine:3.20

RUN apk add --no-cache bash ca-certificates doas \
  && adduser -D -s /bin/bash bootstrap \
  && printf 'permit nopass bootstrap as root\n' > /etc/doas.d/bootstrap.conf \
  && chmod 0400 /etc/doas.d/bootstrap.conf \
  && mkdir -p /workspace \
  && chown bootstrap:bootstrap /workspace

ENTRYPOINT ["/usr/bin/env", "bash", "/tmp/test.bash"]
WORKDIR /workspace

HEALTHCHECK NONE

COPY bootstrap.bash /tmp/
COPY e2e.manifest /tmp/
COPY test.bash /tmp/

USER bootstrap
