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
  bootstrap.bash [options] [manifest]

Options:
  --help     Show this help text and exit.
  --version  Show version and build metadata, then exit.
  --dry-run  Parse options without making system changes.
  --explain  Request explanation output for planned behavior.
  --verbose  Request more detailed diagnostic output.
  --quiet    Suppress non-essential output.

Arguments:
  manifest   Optional package manifest path. Planning currently requires --dry-run.
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
      bootstrap_context_enable_dry_run
      ;;
    --explain)
      bootstrap_context_enable_explain
      ;;
    --verbose)
      bootstrap_context_enable_verbose
      ;;
    --quiet)
      bootstrap_context_enable_quiet
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
      if bootstrap_context_has_manifest_path; then
        bootstrap_print_usage_error "unexpected argument: $1"
        return "${BOOTSTRAP_EXIT_USAGE}"
      fi
      bootstrap_context_set_manifest_path "$1"
      ;;
    esac

    shift
  done

  if bootstrap_context_is_verbose && bootstrap_context_is_quiet; then
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
  bootstrap_log_info 'bootstrap.bash: not yet implemented'
}


###############################################################################
# @fn bootstrap_print_action_record(action, package, operator, version)
# @brief Prints one human-readable dry-run line for an Action Record.
#
# @details
# The planner emits abstract Action Records.  This function renders the small
# install-package action model that exists today without resolving package
# managers or command lines.  Unknown action types are reported as usage errors
# because the CLI should not silently hide planner output it cannot explain.
#
# @param action Action Record type.
# @param package Package name associated with the action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @retval 0 The Action Record was rendered successfully.
# @retval 65 The Action Record type was unsupported by this renderer.
###############################################################################
bootstrap_print_action_record() {
  local action
  local operator
  local package
  local version

  action="$1"
  package="$2"
  operator="${3:-}"
  version="${4:-}"

  case "${action}" in
  install-package)
    if [[ -n "${operator}" || -n "${version}" ]]; then
      printf '  - install package: %s (%s %s)\n' \
        "${package}" \
        "${operator}" \
        "${version}"
    else
      printf '  - install package: %s\n' "${package}"
    fi
    ;;
  *)
    printf 'bootstrap.bash: unsupported action record: %s\n' "${action}" >&2
    return "${BOOTSTRAP_EXIT_MANIFEST}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_print_dry_run_plan(manifest_path, action_file)
# @brief Renders a planned dry-run action list for a manifest.
#
# @details
# Dry-run output is deliberately generated from Action Records rather than from
# parser records.  This keeps the user-facing output aligned with the same
# abstract plan that later resolver and executor phases will consume.
#
# Explain mode currently adds architectural context only.  It does not add
# package-manager detail because resolver and executor phases have not yet bound
# abstract actions to a platform-specific implementation.
#
# @param manifest_path Manifest path used to produce the plan.
# @param action_file File containing tab-separated Action Records.
# @returns Human-readable dry-run output on standard output.
# @retval 0 The dry-run plan was printed successfully.
# @retval 65 An Action Record could not be rendered.
###############################################################################
bootstrap_print_dry_run_plan() {
  local action
  local action_file
  local operator
  local package
  local planned_count
  local manifest_path
  local version

  manifest_path="$1"
  action_file="$2"
  planned_count=0

  printf 'Dry run plan for manifest: %s\n' "${manifest_path}"

  while IFS=$'\t' read -r action package operator version || [[ -n "${action:-}" ]]; do
    planned_count=$((planned_count + 1))
    bootstrap_print_action_record \
      "${action}" \
      "${package}" \
      "${operator:-}" \
      "${version:-}" || return "$?"
  done <"${action_file}"

  if ((planned_count == 0)); then
    printf '  - no package actions planned\n'
  fi

  printf 'Summary: %s action(s) planned.\n' "${planned_count}"

  if bootstrap_context_should_explain; then
    printf '\nExplanation:\n'
    printf '  The planner emitted abstract Action Records only.\n'
    printf '  No package manager was selected and no system changes were made.\n'
  fi
}

###############################################################################
# @fn bootstrap_run_dry_run_plan()
# @brief Parses the requested manifest and prints its abstract execution plan.
#
# @details
# This is the first end-to-end read-only path through the engine.  It composes
# the manifest parser and planner, captures the resulting Action Records, and
# renders those records for the user without resolving or executing them.
#
# @retval 0 The manifest was parsed, planned, and displayed successfully.
# @retval 65 The manifest could not be parsed or planned.
###############################################################################
bootstrap_run_dry_run_plan() {
  local action_file
  local manifest_path
  local status

  manifest_path="$(bootstrap_context_get_manifest_path)"
  action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-plan.XXXXXX")"

  if bootstrap_planner_plan_manifest_file "${manifest_path}" >"${action_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}"
    return "${status}"
  fi

  if bootstrap_print_dry_run_plan "${manifest_path}" "${action_file}"; then
    status="${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
  fi
  rm -f "${action_file}"

  return "${status}"
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
  bootstrap_context_reset

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

  if bootstrap_context_has_manifest_path; then
    if ! bootstrap_context_is_dry_run; then
      bootstrap_print_usage_error "manifest planning currently requires --dry-run"
      return "${BOOTSTRAP_EXIT_USAGE}"
    fi

    bootstrap_run_dry_run_plan
    return "$?"
  fi

  bootstrap_run_placeholder
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
