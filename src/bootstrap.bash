# shellcheck shell=bash

set -euo pipefail

main() {
  printf 'bootstrap.bash: not yet implemented\n'
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
