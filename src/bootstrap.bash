# shellcheck shell=bash
###############################################################################
# @file src/bootstrap.bash
# @brief Provides the bootstrap engine source entry point.
#
# @details
# This file contains the public command-line entry point that is assembled into
# dist/bootstrap.bash.  Phase 2 begins the public CLI by implementing discovery
# commands that are safe, deterministic, and useful before package operations
# exist.
#
# The no-argument placeholder output is preserved so the Phase 1 observable
# behavior remains stable while the project incrementally adds supported command
# behavior.
###############################################################################

set -euo pipefail

BOOTSTRAP_EXIT_SUCCESS=0
BOOTSTRAP_EXIT_USAGE=64


###############################################################################
# @fn bootstrap_print_help()
# @brief Prints the currently supported command-line usage summary.
#
# @details
# The help output documents only behavior that is implemented and tested.  The
# roadmap includes future options such as --dry-run, --explain, --verbose, and
# --quiet, but those options are intentionally omitted until their behavior is
# actually present.
#
# @returns Help text on standard output.
# @retval 0 Help text was printed successfully.
#
# @par Examples
# @code
# bootstrap_print_help
# @endcode
###############################################################################
bootstrap_print_help() {
  cat <<'HELP_TEXT'
Usage:
  bootstrap.bash
  bootstrap.bash --help
  bootstrap.bash --version

Options:
  --help     Show this help text and exit.
  --version  Show version and build metadata, then exit.
HELP_TEXT
}


###############################################################################
# @fn bootstrap_print_usage_error(message)
# @brief Prints a human-readable command-line usage error.
#
# @details
# Unsupported options fail conservatively instead of being ignored.  This keeps
# misspelled flags visible and avoids implying that future roadmap options work
# before they are implemented.
#
# @param message The specific usage problem to show to the user.
# @returns Diagnostic text on standard error.
# @retval 0 The diagnostic was printed successfully.
#
# @par Examples
# @code
# bootstrap_print_usage_error "unsupported option: --unknown"
# @endcode
###############################################################################
bootstrap_print_usage_error() {
  local message

  message="$1"

  printf 'bootstrap.bash: %s\n' "${message}" >&2
  printf 'Try `bootstrap.bash --help` for usage.\n' >&2
}


###############################################################################
# @fn main(...)
# @brief Runs the bootstrap command-line entry point.
#
# @details
# Phase 2 starts with a small, explicit CLI.  The supported discovery commands
# are --help and --version.  Running without arguments keeps the existing
# placeholder behavior until later roadmap phases introduce manifest parsing,
# planning, and execution.
#
# Unsupported options return a usage-oriented failure rather than being silently
# ignored.  This follows the project's conservative CLI posture and keeps public
# behavior predictable for both people and automation.
#
# @param ... Command-line arguments supplied by the user.
# @returns Command output on standard output, or diagnostics on standard error.
# @retval 0 The command completed successfully.
# @retval 64 The user supplied unsupported or invalid command-line arguments.
#
# @par Examples
# @code
# dist/bootstrap.bash --help
# dist/bootstrap.bash --version
# @endcode
###############################################################################
main() {
  case "${1:-}" in
    "")
      printf 'bootstrap.bash: not yet implemented\n'
      return "${BOOTSTRAP_EXIT_SUCCESS}"
      ;;
    --help)
      if (($# > 1)); then
        bootstrap_print_usage_error "--help does not accept additional arguments"
        return "${BOOTSTRAP_EXIT_USAGE}"
      fi
      bootstrap_print_help
      return "${BOOTSTRAP_EXIT_SUCCESS}"
      ;;
    --version)
      if (($# > 1)); then
        bootstrap_print_usage_error "--version does not accept additional arguments"
        return "${BOOTSTRAP_EXIT_USAGE}"
      fi
      bootstrap_print_version
      return "${BOOTSTRAP_EXIT_SUCCESS}"
      ;;
    --*)
      bootstrap_print_usage_error "unsupported option: $1"
      return "${BOOTSTRAP_EXIT_USAGE}"
      ;;
    *)
      bootstrap_print_usage_error "unexpected argument: $1"
      return "${BOOTSTRAP_EXIT_USAGE}"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
