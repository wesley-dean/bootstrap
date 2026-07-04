#!/usr/bin/env bash
#
# bootstrap.bash
#
# Bootstrap entry point for the workstation bootstrap tool.
#

set -euo pipefail

##
# Main program entry point.
#
# Arguments:
#   All command-line arguments are passed through unchanged.
#
# Returns:
#   Exit status code.
#
main() {
  printf 'bootstrap.bash: not yet implemented\n'

  return 0
}

#
# Execute main() only when this file is executed directly.
#
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
