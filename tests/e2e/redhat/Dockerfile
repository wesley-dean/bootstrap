FROM fedora:44

RUN dnf install -y bash ca-certificates sudo \
  && dnf clean all \
  && dnf makecache \
  && useradd --create-home --shell /usr/bin/bash bootstrap \
  && printf 'bootstrap ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/bootstrap \
  && chmod 0440 /etc/sudoers.d/bootstrap \
  && mkdir -p /workspace \
  && chown bootstrap:bootstrap /workspace

ENTRYPOINT ["/usr/bin/env", "bash", "/tmp/test.bash"]
WORKDIR /workspace

HEALTHCHECK NONE

COPY bootstrap.bash /tmp/
COPY e2e.manifest /tmp/
COPY test.bash /tmp/

USER bootstrap
