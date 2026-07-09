#!/usr/bin/env bash

set -euo pipefail

/tmp/bootstrap.bash --package-manager dnf --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash --package-manager dnf --explain --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash --package-manager dnf /tmp/e2e.manifest

git --version
curl --version
jq --version
