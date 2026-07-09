#!/usr/bin/env bash

set -euo pipefail

/tmp/bootstrap.bash --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash --explain --dry-run /tmp/e2e.manifest
/tmp/bootstrap.bash /tmp/e2e.manifest

shellcheck --version
shfmt --version
bats --version
