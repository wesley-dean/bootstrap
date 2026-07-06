# shellcheck shell=bash
###############################################################################
# @file src/bootstrap.bash
# @brief Provides the bootstrap engine source entry point.
#
# @details
# This file contains the public command-line entry point that is assembled into
# dist/bootstrap.bash. Phase 2 establishes the supported option surface without
# introducing manifest parsing, planning, or package execution ahead of the
# roadmap.
#
# The command model is intentionally a single primary operation modified by
# explicit long options. The project does not currently use subcommands. That
# keeps the initial bootstrap experience compact while still making user intent
# visible through flags such as --dry-run, --explain, --verbose, and --quiet.
#
# The no-argument placeholder output is preserved so the Phase 1 observable
# behavior remains stable while the project incrementally adds supported command
# behavior.
###############################################################################

set -euo pipefail

BOOTSTRAP_EXIT_SUCCESS=0
BOOTSTRAP_EXIT_USAGE=64

BOOTSTRAP_FLAG_DRY_RUN=false
BOOTSTRAP_FLAG_EXPLAIN=false
BOOTSTRAP_FLAG_VERBOSE=false
BOOTSTRAP_FLAG_QUIET=false


###############################################################################
# @fn bootstrap_reset_options()
# @brief Restores command-line option state to documented defaults.
#
# @details
# The generated artifact normally runs once per process, but tests and future
# callers may invoke main more than once after sourcing the file. Resetting
# parser state at the start of each invocation prevents state from leaking across
# calls and keeps behavior deterministic.
#
# @retval 0 Option state was reset successfully.
###############################################################################
bootstrap_reset_options() {
  BOOTSTRAP_FLAG_DRY_RUN=false
  BOOTSTRAP_FLAG_EXPLAIN=false
  BOOTSTRAP_FLAG_VERBOSE=false
  BOOTSTRAP_FLAG_QUIET=false
}


###############################################################################
# @fn bootstrap_print_help()
# @brief Prints the currently supported command-line usage summary.
#
# @details
# The help output documents behavior that is implemented and tested. Operational
# options are listed because Phase 2 now recognizes them and records their state,
# even though later roadmap phases will give those options deeper planning and
# execution meaning.
#
# @returns Help text on standard output.
# @retval 0 Help text was printed successfully.
###############################################################################
bootstrap_print_help() {
  cat <<'HELP_TEXT'
Usage:
  bootstrap.bash [options]

Options:
  --help     Show this help text and exit.
  --version  Show version and build metadata, then exit.
  --dry-run  Parse options without making system changes.
  --explain  Request explanation output for planned behavior.
  --verbose  Request more detailed diagnostic output.
  --quiet    Suppress non-essential output.
HELP_TEXT
}


###############################################################################
# @fn bootstrap_print_usage_error(message)
# @brief Prints a human-readable command-line usage error.
#
# @details
# Unsupported or contradictory options fail conservatively instead of being
# ignored. This keeps misspelled flags visible and avoids implying that the
# engine accepted an instruction that it cannot safely honor.
#
# @param message The specific usage problem to show to the user.
# @returns Diagnostic text on standard error.
# @retval 0 The diagnostic was printed successfully.
###############################################################################
bootstrap_print_usage_error() {
  local message

  message="$1"

  printf 'bootstrap.bash: %s\n' "${message}" >&2
  printf 'Try `bootstrap.bash --help` for usage.\n' >&2
}


###############################################################################
# @fn bootstrap_parse_arguments(...)
# @brief Parses supported long-form command-line options.
#
# @details
# The parser intentionally accepts only explicit long options. Short aliases are
# not added yet because the ADRs prefer clarity and compatibility over a broad
# convenience surface.
#
# The parser records option state in global variables for later roadmap phases.
# At this stage, the flags are accepted and made available to the runtime, but
# package manifests, execution plans, and package-manager operations are still
# intentionally out of scope.
#
# @param ... Command-line arguments supplied by the user.
# @retval 0 All arguments were parsed successfully.
# @retval 64 The user supplied unsupported, unexpected, or contradictory input.
###############################################################################
bootstrap_parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --dry-run)
        BOOTSTRAP_FLAG_DRY_RUN=true
        ;;
      --explain)
        BOOTSTRAP_FLAG_EXPLAIN=true
        ;;
      --verbose)
        BOOTSTRAP_FLAG_VERBOSE=true
        ;;
      --quiet)
        BOOTSTRAP_FLAG_QUIET=true
        ;;
      --help | --version)
        bootstrap_print_usage_error "$1 must be used by itself"
        return "${BOOTSTRAP_EXIT_USAGE}"
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

    shift
  done

  if [[ "${BOOTSTRAP_FLAG_VERBOSE}" == true && "${BOOTSTRAP_FLAG_QUIET}" == true ]]; then
    bootstrap_print_usage_error "--verbose and --quiet cannot be used together"
    return "${BOOTSTRAP_EXIT_USAGE}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}


###############################################################################
# @fn bootstrap_run_placeholder()
# @brief Runs the current placeholder operation after option parsing.
#
# @details
# The project has not yet implemented manifest parsing, planning, or execution.
# This function preserves the established placeholder behavior while respecting
# --quiet as the only flag whose behavior is meaningful before planning exists.
#
# @returns A placeholder status message on standard output unless quiet mode is enabled.
# @retval 0 The placeholder operation completed successfully.
###############################################################################
bootstrap_run_placeholder() {
  if [[ "${BOOTSTRAP_FLAG_QUIET}" == true ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: not yet implemented\n'
  return "${BOOTSTRAP_EXIT_SUCCESS}"
}


###############################################################################
# @fn main(...)
# @brief Runs the bootstrap command-line entry point.
#
# @details
# Phase 2 provides a small, explicit CLI. Discovery commands such as --help and
# --version return immediately and must be used by themselves. Operational flags
# are parsed and stored for later phases, but the current operation remains the
# placeholder until the roadmap introduces manifest parsing, planning, and
# execution.
#
# Unsupported options return a usage-oriented failure rather than being silently
# ignored. This follows the project's conservative CLI posture and keeps public
# behavior predictable for both people and automation.
#
# @param ... Command-line arguments supplied by the user.
# @returns Command output on standard output, or diagnostics on standard error.
# @retval 0 The command completed successfully.
# @retval 64 The user supplied unsupported or invalid command-line arguments.
###############################################################################
main() {
  bootstrap_reset_options

  case "${1:-}" in
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
  esac

  bootstrap_parse_arguments "$@" || return "$?"
  bootstrap_run_placeholder
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
