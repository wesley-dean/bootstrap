#checkov:skip=CKV2_DOCKER_1: sudo is intentionally installed in this e2e image so Bootstrap can exercise privilege escalation from a non-root user.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates curl software-properties-common sudo \
 && add-apt-repository universe \
 && apt-get update \
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
