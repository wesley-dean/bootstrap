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
  manifest   Optional package manifest path. Without --dry-run, resolved actions are executed.
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
  printf "Try 'bootstrap.bash --help' for usage.\n" >&2
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
# manifest planning and execution are handled after parsing so argument
# validation remains separate from pipeline orchestration.
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
# managers or command lines.  Unknown action types are reported as manifest
# errors because the CLI should not silently hide planner output it cannot
# explain.
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
# @fn bootstrap_print_action_explanation(action, package, operator, version, source, line_number)
# @brief Prints provenance and architectural context for one Action Record.
#
# @details
# Explain output should make the plan easier to inspect without pretending that
# executor work has already happened. This helper reports the manifest line that
# produced the action and restates that the planner output remains the immutable,
# platform-independent source of intent.
#
# @param action Action Record type.
# @param package Package name associated with the action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Manifest source path preserved by the parser and planner.
# @param line_number Manifest line number preserved by the parser and planner.
# @retval 0 The explanation was printed successfully.
# @retval 65 The Action Record type was unsupported by this renderer.
###############################################################################
bootstrap_print_action_explanation() {
  local action
  local line_number
  local operator
  local package
  local source
  local version

  action="$1"
  package="$2"
  operator="${3:-}"
  version="${4:-}"
  source="${5:-}"
  line_number="${6:-}"

  case "${action}" in
  install-package)
    if [[ -n "${operator}" || -n "${version}" ]]; then
      printf '  - %s:%s requested package %s with constraint %s %s.\n' \
        "${source:-unknown}" \
        "${line_number:-unknown}" \
        "${package}" \
        "${operator}" \
        "${version}"
    else
      printf '  - %s:%s requested package %s.\n' \
        "${source:-unknown}" \
        "${line_number:-unknown}" \
        "${package}"
    fi
    printf '    Planner action: install-package; resolver adds platform binding separately.\n'
    ;;
  *)
    printf 'bootstrap.bash: unsupported action record: %s\n' "${action}" >&2
    return "${BOOTSTRAP_EXIT_MANIFEST}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_print_resolved_action(action, manager, package, operator, version)
# @brief Prints one human-readable dry-run line for a Resolved Action.
#
# @details
# Resolved Actions bind abstract planner output to the current platform without
# executing anything. This renderer intentionally names the selected package
# manager while avoiding command-line syntax that could be mistaken for work that
# has already been performed.
#
# @param action Resolved Action type.
# @param manager Package manager selected by the resolver.
# @param package Package name associated with the action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @retval 0 The Resolved Action was rendered successfully.
# @retval 69 The Resolved Action type was unsupported by this renderer.
###############################################################################
bootstrap_print_resolved_action() {
  local action
  local manager
  local operator
  local package
  local version

  action="$1"
  manager="$2"
  package="$3"
  operator="${4:-}"
  version="${5:-}"

  case "${action}" in
  install-package)
    if [[ -n "${operator}" || -n "${version}" ]]; then
      printf '  - %s would install package: %s (%s %s)\n' \
        "${manager}" \
        "${package}" \
        "${operator}" \
        "${version}"
    else
      printf '  - %s would install package: %s\n' "${manager}" "${package}"
    fi
    ;;
  *)
    printf 'bootstrap.bash: unsupported resolved action: %s\n' "${action}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_print_resolved_action_explanation(action, manager, package, operator, version, source, line_number)
# @brief Prints explanatory context for one Resolved Action.
#
# @details
# This helper describes how the current environment resolved a planned action.
# It is deliberately phrased as future intent rather than completed work because
# dry-run mode must never mutate the system.
#
# @param action Resolved Action type.
# @param manager Package manager selected by the resolver.
# @param package Package name associated with the resolved action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Manifest source path preserved for provenance.
# @param line_number Manifest line number preserved for provenance.
# @retval 0 The explanation was printed successfully.
# @retval 69 The Resolved Action type was unsupported by this renderer.
###############################################################################
bootstrap_print_resolved_action_explanation() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  action="$1"
  manager="$2"
  package="$3"
  operator="${4:-}"
  version="${5:-}"
  source="${6:-}"
  line_number="${7:-}"

  case "${action}" in
  install-package)
    printf '  - %s:%s would be handled by package manager: %s.\n' \
      "${source:-unknown}" \
      "${line_number:-unknown}" \
      "${manager}"
    if [[ -n "${operator}" || -n "${version}" ]]; then
      printf '    The version constraint remains attached for backend-specific interpretation.\n'
    fi
    printf '    Executor has not run; no system changes were made.\n'
    ;;
  *)
    printf 'bootstrap.bash: unsupported resolved action: %s\n' "${action}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_print_dry_run_plan(manifest_path, action_file, resolved_file)
# @brief Renders a planned and resolved dry-run action list for a manifest.
#
# @details
# Dry-run output is deliberately generated from Action Records and Resolved
# Actions rather than from parser records. This keeps the user-facing output
# aligned with the same pipeline that later executor phases will consume while
# still guaranteeing that dry-run mode performs no system changes.
#
# Explain mode reports both the manifest source line behind each planned action
# and the resolver binding selected for the current environment.
#
# @param manifest_path Manifest path used to produce the plan.
# @param action_file File containing pipe-delimited Action Records.
# @param resolved_file File containing pipe-delimited Resolved Actions.
# @returns Human-readable dry-run output on standard output.
# @retval 0 The dry-run plan was printed successfully.
# @retval 65 An Action Record could not be rendered.
# @retval 69 A Resolved Action could not be rendered.
###############################################################################
bootstrap_print_dry_run_plan() {
  local action
  local action_file
  local line_number
  local manager
  local operator
  local package
  local planned_count
  local manifest_path
  local resolved_file
  local resolved_count
  local source
  local version

  manifest_path="$1"
  action_file="$2"
  resolved_file="$3"
  planned_count=0
  resolved_count=0

  printf 'Dry run plan for manifest: %s\n' "${manifest_path}"

  printf '\nPlanned actions:\n'
  while IFS='|' read -r action package operator version source line_number || [[ -n "${action:-}" ]]; do
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

  printf '\nResolved actions:\n'
  while IFS='|' read -r action manager package operator version source line_number || [[ -n "${action:-}" ]]; do
    resolved_count=$((resolved_count + 1))
    bootstrap_print_resolved_action \
      "${action}" \
      "${manager}" \
      "${package}" \
      "${operator:-}" \
      "${version:-}" || return "$?"
  done <"${resolved_file}"

  if ((resolved_count == 0)); then
    printf '  - no package actions resolved\n'
  fi

  printf 'Summary: %s action(s) planned; %s action(s) resolved.\n' \
    "${planned_count}" \
    "${resolved_count}"

  if bootstrap_context_should_explain; then
    printf '\nExplanation:\n'
    printf '  The planner emitted immutable abstract Action Records.\n'
    printf '  The resolver selected platform-specific Resolved Actions for this system.\n'
    printf '  Executor has not run and no system changes were made.\n'

    if ((planned_count > 0)); then
      printf '\nAction provenance:\n'
      while IFS='|' read -r action package operator version source line_number || [[ -n "${action:-}" ]]; do
        bootstrap_print_action_explanation \
          "${action}" \
          "${package}" \
          "${operator:-}" \
          "${version:-}" \
          "${source:-}" \
          "${line_number:-}" || return "$?"
      done <"${action_file}"
    fi

    if ((resolved_count > 0)); then
      printf '\nResolver decisions:\n'
      while IFS='|' read -r action manager package operator version source line_number || [[ -n "${action:-}" ]]; do
        bootstrap_print_resolved_action_explanation \
          "${action}" \
          "${manager}" \
          "${package}" \
          "${operator:-}" \
          "${version:-}" \
          "${source:-}" \
          "${line_number:-}" || return "$?"
      done <"${resolved_file}"
    fi
  fi
}

###############################################################################
# @fn bootstrap_run_dry_run_plan()
# @brief Parses, plans, resolves, and prints a read-only dry-run plan.
#
# @details
# This path composes the manifest parser, planner, and resolver, captures their
# intermediate records, and renders the results for the user without executing
# the resolved actions. It is the first end-to-end path through the engine that
# can report both what the project intends to do and how the current system
# would satisfy that intent.
#
# @retval 0 The manifest was parsed, planned, resolved, and displayed successfully.
# @retval 65 The manifest could not be parsed or planned.
# @retval 69 The planned actions could not be resolved on this system.
###############################################################################
bootstrap_run_dry_run_plan() {
  local action_file
  local manifest_path
  local resolved_file
  local status

  manifest_path="$(bootstrap_context_get_manifest_path)"
  action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-plan.XXXXXX")"
  resolved_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-resolved.XXXXXX")"

  if bootstrap_planner_plan_manifest_file "${manifest_path}" >"${action_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}" "${resolved_file}"
    return "${status}"
  fi

  if bootstrap_resolver_resolve_action_records auto <"${action_file}" >"${resolved_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}" "${resolved_file}"
    return "${status}"
  fi

  if bootstrap_print_dry_run_plan "${manifest_path}" "${action_file}" "${resolved_file}"; then
    status="${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
  fi
  rm -f "${action_file}" "${resolved_file}"

  return "${status}"
}

###############################################################################
# @fn bootstrap_print_execution_result(status, exit_code, action, manager, package, message)
# @brief Prints one human-readable execution result line.
#
# @details
# Execution Results are the final records in the Phase 4 pipeline.  This renderer
# keeps user-facing reporting separate from executor behavior so executors can
# remain focused on performing resolved work and returning structured outcomes.
#
# @param status Execution Result status such as `success`, `already-satisfied`, or `failed`.
# @param exit_code Process-style exit code attached to the result.
# @param action Resolved Action type that was executed.
# @param manager Backend or package manager that handled the action.
# @param package Package name associated with the result.
# @param message Human-readable execution result message.
# @returns Human-readable execution output on standard output.
# @retval 0 The Execution Result was printed successfully.
###############################################################################
bootstrap_print_execution_result() {
  local action
  local exit_code
  local manager
  local message
  local package
  local status

  status="$1"
  exit_code="$2"
  action="${3:-}"
  manager="${4:-}"
  package="${5:-}"
  message="${6:-}"

  : "${exit_code}"

  case "${status}" in
  already-satisfied)
    printf '  - %s %s package %s: %s\n' \
      "${manager}" \
      "${action}" \
      "${package}" \
      "${message}"
    ;;
  success)
    printf '  - %s %s package %s: %s\n' \
      "${manager}" \
      "${action}" \
      "${package}" \
      "${message}"
    ;;
  failed)
    printf '  - %s %s package %s failed: %s\n' \
      "${manager}" \
      "${action}" \
      "${package}" \
      "${message}"
    ;;
  *)
    printf '  - %s %s package %s: %s\n' \
      "${manager:-unknown}" \
      "${action:-unknown}" \
      "${package:-unknown}" \
      "${message:-unknown result}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_print_execution_results(result_file)
# @brief Prints a human-readable execution summary from Execution Result records.
#
# @details
# This helper renders the structured records emitted by the executor.  It keeps
# output formatting outside the executor so executor tests can focus on record
# contracts while CLI tests focus on user-visible behavior.
#
# @param result_file File containing pipe-delimited Execution Result records.
# @returns Human-readable execution output on standard output.
# @retval 0 Execution Results were printed successfully.
###############################################################################
bootstrap_print_execution_results() {
  local action
  local exit_code
  local failed_count
  local manager
  local message
  local package
  local result_file
  local status
  local total_count

  result_file="$1"
  failed_count=0
  total_count=0

  printf 'Execution results:\n'

  while IFS='|' read -r status exit_code action manager package message || [[ -n "${status:-}" ]]; do
    total_count=$((total_count + 1))
    if [[ "${status}" == "failed" ]]; then
      failed_count=$((failed_count + 1))
    fi

    bootstrap_print_execution_result \
      "${status}" \
      "${exit_code}" \
      "${action:-}" \
      "${manager:-}" \
      "${package:-}" \
      "${message:-}"
  done <"${result_file}"

  if ((total_count == 0)); then
    printf '  - no actions executed\n'
  fi

  printf 'Summary: %s action(s) executed; %s failure(s).\n' \
    "${total_count}" \
    "${failed_count}"
}

###############################################################################
# @fn bootstrap_run_execution_plan()
# @brief Parses, plans, resolves, executes, and prints execution results.
#
# @details
# This path is the first CLI integration that performs resolved work.  It uses
# the same parser, planner, and resolver pipeline as dry-run mode, then streams
# Resolved Actions into the executor.
#
# Dry-run mode continues to stop before this function.  That keeps read-only
# inspection and execution separated by a clear CLI boundary.
#
# @retval 0 The manifest was executed successfully or no actions were needed.
# @retval 65 The manifest could not be parsed or planned.
# @retval 69 The planned actions could not be resolved on this system.
# @retval 70 At least one resolved action failed during execution.
###############################################################################
bootstrap_run_execution_plan() {
  local action_file
  local manifest_path
  local resolved_file
  local result_file
  local status

  manifest_path="$(bootstrap_context_get_manifest_path)"
  action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-plan.XXXXXX")"
  resolved_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-resolved.XXXXXX")"
  result_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-results.XXXXXX")"

  if bootstrap_planner_plan_manifest_file "${manifest_path}" >"${action_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}" "${resolved_file}" "${result_file}"
    return "${status}"
  fi

  if bootstrap_resolver_resolve_action_records auto <"${action_file}" >"${resolved_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}" "${resolved_file}" "${result_file}"
    return "${status}"
  fi

  if bootstrap_executor_execute_resolved_actions <"${resolved_file}" >"${result_file}"; then
    status="${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
  fi

  bootstrap_print_execution_results "${result_file}"

  rm -f "${action_file}" "${resolved_file}" "${result_file}"
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
    if bootstrap_context_is_dry_run; then
      bootstrap_run_dry_run_plan
      return "$?"
    fi

    bootstrap_run_execution_plan
    return "$?"
  fi

  bootstrap_run_placeholder
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
