#!/usr/bin/env bash

set -euo pipefail

/tmp/bootstrap.bash --package-manager apk --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash --package-manager apk --explain --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash --package-manager apk /tmp/e2e.manifest

git --version
curl --version
jq --version
