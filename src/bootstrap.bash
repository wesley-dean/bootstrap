# shellcheck shell=bash
## @file src/bootstrap.bash
## @brief Provides the bootstrap engine source entry point.
## @details
## This file contains the public command-line entry point that is assembled into
## dist/bootstrap.bash. The entry point owns user-facing option handling, dry-run
## rendering, execution-result rendering, and the final choice between planning
## and execution.
##
## The command model is intentionally a single primary operation modified by
## explicit long options. That keeps the bootstrap experience compact while still
## making user intent visible through flags such as --dry-run, --explain,
## --verbose, and --quiet.
##
## This source file is assembled into the distribution artifact together with the
## runtime, manifest, planner, resolver, backend, and executor modules. It should
## therefore avoid duplicating lower-level package-manager policy.
## @par Examples
## @code
## bootstrap.bash --help
## bootstrap.bash --dry-run --explain packages.txt
## bootstrap.bash --package-manager apt packages.txt
## @endcode

set -euo pipefail

## @fn bootstrap_print_help()
## @brief Prints the currently supported command-line usage summary.
## @details
## The help output documents behavior that is implemented and tested. Operational
## options are listed because the parser recognizes them and records their state
## before planning or execution begins.
## @par Standard Output
## Help text.
## @retval 0 Help text was printed successfully.
## @par Examples
## @code
## bootstrap_print_help
## @endcode
bootstrap_print_help() {
  cat <<'HELP_TEXT'
Usage:
  bootstrap.bash [options] [manifest ...]

Options:
  --help     Show this help text and exit.
  --version  Show version and build metadata, then exit.
  --dry-run  Parse options without making system changes.
  --package-manager NAME
             Select package manager: auto or apt.
  --explain  Request explanation output for planned behavior.
  --verbose  Request more detailed diagnostic output.
  --quiet    Suppress non-essential output.

Arguments:
  manifest   Optional package manifest path. Multiple paths are preflighted before execution.
HELP_TEXT
}

## @fn bootstrap_print_usage_error()
## @brief Prints a human-readable command-line usage error.
## @details
## Unsupported or contradictory options fail conservatively instead of being
## ignored. This keeps misspelled flags visible and avoids implying that the
## engine accepted an instruction that it cannot safely honor.
## @param message The specific usage problem to show to the user.
## @par Standard Error
## Diagnostic text.
## @retval 0 The diagnostic was printed successfully.
## @par Examples
## @code
## bootstrap_print_usage_error "unsupported option: --force"
## @endcode
bootstrap_print_usage_error() {
  local message

  message="$1"

  bootstrap_log_error "${message}"
  printf "Try 'bootstrap.bash --help' for usage.\n" >&2
}

## @fn bootstrap_parse_arguments()
## @brief Parses supported long-form command-line options.
## @details
## The parser intentionally accepts only explicit long options. Short aliases are
## not added yet because the ADRs prefer clarity and compatibility over a broad
## convenience surface.
##
## The parser records option state in runtime context for later phases. Manifest
## planning and execution happen after parsing so argument validation remains
## separate from pipeline orchestration.
## @param arguments[] Command-line arguments supplied by the user.
## @retval 0 All arguments were parsed successfully.
## @retval 64 The user supplied unsupported, unexpected, or contradictory input.
## @par Examples
## @code
## bootstrap_parse_arguments --dry-run --package-manager apt packages.txt
## bootstrap_parse_arguments --verbose packages.txt
## @endcode
bootstrap_parse_arguments() {
  while (($# > 0)); do
    case "$1" in
    --dry-run)
      bootstrap_context_enable_dry_run
      ;;
    --explain)
      bootstrap_context_enable_explain
      ;;
    --package-manager)
      if (($# < 2)); then
        bootstrap_print_usage_error "--package-manager requires a value"
        return "${BOOTSTRAP_EXIT_USAGE}"
      fi
      bootstrap_context_set_package_manager "$2"
      shift
      ;;
    --package-manager=*)
      bootstrap_context_set_package_manager "${1#--package-manager=}"
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
      bootstrap_context_add_manifest_path "$1"
      ;;
    esac

    shift
  done

  local manifest_index
  local manifest_path
  local stdin_count

  stdin_count=0
  for ((manifest_index = 0; manifest_index < $(bootstrap_context_get_manifest_count); manifest_index++)); do
    manifest_path="$(bootstrap_context_get_manifest_path_at "${manifest_index}")"
    if [[ "${manifest_path}" == "-" ]]; then
      stdin_count=$((stdin_count + 1))
    fi
  done

  if ((stdin_count > 1)); then
    bootstrap_print_usage_error "standard input manifest '-' may be specified at most once"
    return "${BOOTSTRAP_EXIT_USAGE}"
  fi

  if bootstrap_context_is_verbose && bootstrap_context_is_quiet; then
    bootstrap_print_usage_error "--verbose and --quiet cannot be used together"
    return "${BOOTSTRAP_EXIT_USAGE}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

## @fn bootstrap_run_placeholder()
## @brief Runs the placeholder operation when no manifest was supplied.
## @details
## This function preserves the established no-manifest behavior while respecting
## --quiet as the only flag whose behavior is meaningful without manifest input.
## @par Standard Output
## A placeholder status message unless quiet mode is enabled.
## @retval 0 The placeholder operation completed successfully.
## @par Examples
## @code
## bootstrap_run_placeholder
## @endcode
bootstrap_run_placeholder() {
  bootstrap_log_info 'not yet implemented'
}

## @fn bootstrap_print_action_record()
## @brief Prints one human-readable dry-run line for an Action Record.
## @details
## The planner emits abstract Action Records. This function renders the current
## install-package action model without resolving package managers or command
## lines. Unknown action types are reported as manifest errors.
## @param action Action Record type.
## @param package Package name associated with the action.
## @param operator Optional version constraint operator.
## @param version Optional version constraint value.
## @retval 0 The Action Record was rendered successfully.
## @retval 65 The Action Record type was unsupported by this renderer.
## @par Examples
## @code
## bootstrap_print_action_record install-package shellcheck
## bootstrap_print_action_record install-package bash ">=" 5.0
## @endcode
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
    bootstrap_log_error "unsupported action record: ${action}"
    return "${BOOTSTRAP_EXIT_MANIFEST}"
    ;;
  esac
}

## @fn bootstrap_print_action_explanation()
## @brief Prints provenance and architectural context for one Action Record.
## @details
## Explain output should make the plan easier to inspect without pretending that
## executor work has already happened. This helper reports the manifest line that
## produced the action and restates the planner boundary.
## @param action Action Record type.
## @param package Package name associated with the action.
## @param operator Optional version constraint operator.
## @param version Optional version constraint value.
## @param source Manifest source path preserved by the parser and planner.
## @param line_number Manifest line number preserved by the parser and planner.
## @retval 0 The explanation was printed successfully.
## @retval 65 The Action Record type was unsupported by this renderer.
## @par Examples
## @code
## bootstrap_print_action_explanation install-package shellcheck "" "" packages.txt 3
## bootstrap_print_action_explanation install-package bash ">=" 5.0 packages.txt 4
## @endcode
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
    bootstrap_log_error "unsupported action record: ${action}"
    return "${BOOTSTRAP_EXIT_MANIFEST}"
    ;;
  esac
}

## @fn bootstrap_print_resolved_action()
## @brief Prints one human-readable dry-run line for a Resolved Action.
## @details
## Resolved Actions bind abstract planner output to the current platform without
## executing anything. This renderer names the selected package manager while
## avoiding command-line syntax that could be mistaken for completed work.
## @param action Resolved Action type.
## @param manager Package manager selected by the resolver.
## @param package Package name associated with the action.
## @param operator Optional version constraint operator.
## @param version Optional version constraint value.
## @retval 0 The Resolved Action was rendered successfully.
## @retval 69 The Resolved Action type was unsupported by this renderer.
## @par Examples
## @code
## bootstrap_print_resolved_action install-package apt shellcheck
## bootstrap_print_resolved_action install-package apt bash ">=" 5.0
## @endcode
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
    bootstrap_log_error "unsupported resolved action: ${action}"
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

## @fn bootstrap_print_resolved_action_explanation()
## @brief Prints explanatory context for one Resolved Action.
## @details
## This helper describes how the current environment resolved a planned action.
## It is deliberately phrased as future intent rather than completed work because
## dry-run mode must never mutate the system.
## @param action Resolved Action type.
## @param manager Package manager selected by the resolver.
## @param package Package name associated with the resolved action.
## @param operator Optional version constraint operator.
## @param version Optional version constraint value.
## @param source Manifest source path preserved for provenance.
## @param line_number Manifest line number preserved for provenance.
## @retval 0 The explanation was printed successfully.
## @retval 69 The Resolved Action type was unsupported by this renderer.
## @par Examples
## @code
## bootstrap_print_resolved_action_explanation install-package apt shellcheck "" "" packages.txt 3
## bootstrap_print_resolved_action_explanation install-package apt bash ">=" 5.0 packages.txt 4
## @endcode
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
    bootstrap_log_error "unsupported resolved action: ${action}"
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

## @fn bootstrap_print_manifest_scope()
## @brief Prints the ordered manifests included in the current invocation.
## @details
## Single-manifest output retains the established wording for compatibility.
## Multi-manifest output lists every path explicitly so users can verify the
## preflight scope and correlate later provenance-bearing diagnostics.
## @param heading Singular heading prefix used before the manifest description.
## @retval 0 The manifest scope was printed successfully.
bootstrap_print_manifest_scope() {
  local count
  local heading
  local index
  local manifest_path

  heading="$1"
  count="$(bootstrap_context_get_manifest_count)"

  if ((count == 1)); then
    manifest_path="$(bootstrap_context_get_manifest_path_at 0)"
    printf '%s manifest: %s\n' "${heading}" "${manifest_path}"
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf '%s manifests:\n' "${heading}"
  for ((index = 0; index < count; index++)); do
    manifest_path="$(bootstrap_context_get_manifest_path_at "${index}")"
    printf '  - %s\n' "${manifest_path}"
  done
}

## @fn bootstrap_print_dry_run_plan()
## @brief Renders a planned and resolved dry-run action list for all manifests.
## @details
## Dry-run output is deliberately generated from Action Records and Resolved
## Actions rather than parser records. This keeps user-facing output aligned with
## the same pipeline that later executor phases consume while guaranteeing that
## dry-run mode performs no system changes.
## @param action_file File containing pipe-delimited Action Records.
## @param resolved_file File containing pipe-delimited Resolved Actions.
## @par Standard Output
## Human-readable dry-run output.
## @retval 0 The dry-run plan was printed successfully.
## @retval 65 An Action Record could not be rendered.
## @retval 69 A Resolved Action could not be rendered.
## @par Examples
## @code
## bootstrap_print_dry_run_plan /tmp/bootstrap-plan.txt /tmp/bootstrap-resolved.txt
## @endcode
bootstrap_print_dry_run_plan() {
  local action
  local action_file
  local line_number
  local manager
  local operator
  local package
  local planned_count
  local package_manager_selector
  local resolved_file
  local resolved_count
  local source
  local version

  action_file="$1"
  resolved_file="$2"
  package_manager_selector="$(bootstrap_context_get_package_manager)"
  planned_count=0
  resolved_count=0

  bootstrap_print_manifest_scope "Dry run plan for"

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
    printf '  What happened: bootstrap inspected all manifests, planned package work,\n'
    printf '  and resolved that plan for the selected package manager.\n'
    printf '  Safety boundary: --dry-run is active, so execution stops here and no\n'
    printf '  system changes were made.\n'
    bootstrap_print_manifest_scope "  Preflight scope includes"
    printf '  Package manager selector: %s\n' "${package_manager_selector}"
    printf '  Planned actions: %s\n' "${planned_count}"
    printf '  Resolved actions: %s\n' "${resolved_count}"
    printf '\nHow to read this output:\n'
    printf '  Planned actions describe user intent from the manifest.\n'
    printf '  Resolved actions describe how this system would satisfy that intent.\n'
    printf '  A later execution run consumes the same resolved action stream.\n'

    if ((planned_count > 0)); then
      printf '\nWhy these actions are planned:\n'
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
      printf '\nWhy these package-manager decisions were made:\n'
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

## @fn bootstrap_preflight_manifests()
## @brief Parses, plans, and resolves every supplied manifest before execution.
## @details
## Each manifest is planned into a private temporary file first. Its Action
## Records are appended to the invocation plan only after that manifest succeeds,
## preventing partial records from a failed manifest from entering the executable
## plan. Resolution runs only after every manifest has parsed and planned
## successfully. This establishes the ADR-049 global preflight barrier.
##
## @param action_file Destination for the complete ordered Action Record stream.
## @param resolved_file Destination for the complete ordered Resolved Action stream.
## @retval 0 Every manifest parsed, planned, and resolved successfully.
## @retval 65 A manifest could not be read, parsed, or planned.
## @retval 69 At least one planned action could not be resolved.
bootstrap_preflight_manifests() {
  local count
  local index
  local manifest_action_file
  local manifest_path
  local status

  count="$(bootstrap_context_get_manifest_count)"
  : >"$1"
  : >"$2"

  for ((index = 0; index < count; index++)); do
    manifest_path="$(bootstrap_context_get_manifest_path_at "${index}")"
    manifest_action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-manifest-plan.XXXXXX")"

    if bootstrap_planner_plan_manifest_file "${manifest_path}" >"${manifest_action_file}"; then
      cat "${manifest_action_file}" >>"$1"
      rm -f "${manifest_action_file}"
    else
      status="$?"
      rm -f "${manifest_action_file}"
      return "${status}"
    fi
  done

  if bootstrap_resolver_resolve_action_records \
    "$(bootstrap_context_get_package_manager)" <"$1" >"$2"; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
    return "${status}"
  fi
}

## @fn bootstrap_run_dry_run_plan()
## @brief Preflights all manifests and prints one read-only invocation plan.
## @details
## Dry-run uses the same complete Action Record and Resolved Action streams that
## execution would consume. No output plan is rendered until every manifest has
## crossed the global preflight barrier successfully.
## @retval 0 All manifests were preflighted and displayed successfully.
## @retval 65 A manifest could not be parsed or planned.
## @retval 69 The complete action set could not be resolved on this system.
bootstrap_run_dry_run_plan() {
  local action_file
  local resolved_file
  local status

  action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-plan.XXXXXX")"
  resolved_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-resolved.XXXXXX")"

  if bootstrap_preflight_manifests "${action_file}" "${resolved_file}"; then
    :
  else
    status="$?"
    rm -f "${action_file}" "${resolved_file}"
    return "${status}"
  fi

  if bootstrap_print_dry_run_plan "${action_file}" "${resolved_file}"; then
    status="${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
  fi

  rm -f "${action_file}" "${resolved_file}"
  return "${status}"
}

## @fn bootstrap_print_execution_result()
## @brief Prints one human-readable execution result line.
## @details
## Execution Results are the final records in the pipeline. This renderer keeps
## user-facing reporting separate from executor behavior so executor tests can
## focus on record contracts.
## @param status Execution Result status such as success, already-satisfied, or failed.
## @param exit_code Process-style exit code attached to the result.
## @param action Resolved Action type that was executed.
## @param manager Backend or package manager that handled the action.
## @param package Package name associated with the result.
## @param message Human-readable execution result message.
## @par Standard Output
## Human-readable execution output.
## @retval 0 The Execution Result was printed successfully.
## @par Examples
## @code
## bootstrap_print_execution_result success 0 install-package apt shellcheck installed
## bootstrap_print_execution_result already-satisfied 0 install-package apt bash "already installed"
## @endcode
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

## @fn bootstrap_print_execution_results()
## @brief Prints a human-readable execution summary from Execution Result records.
## @details
## This helper renders the structured records emitted by the executor. It keeps
## output formatting outside the executor so executor tests can focus on record
## contracts while CLI tests focus on user-visible behavior.
## @param result_file File containing pipe-delimited Execution Result records.
## @par Standard Output
## Human-readable execution output.
## @retval 0 Execution Results were printed successfully.
## @par Examples
## @code
## bootstrap_print_execution_results /tmp/bootstrap-results.txt
## @endcode
bootstrap_print_execution_results() {
  local action
  local already_satisfied_count
  local exit_code
  local failed_count
  local manager
  local message
  local not_executed_count
  local package
  local result_file
  local status
  local success_count
  local total_count
  local unknown_count

  result_file="$1"
  already_satisfied_count=0
  failed_count=0
  not_executed_count=0
  success_count=0
  total_count=0
  unknown_count=0

  printf 'Execution results:\n'

  while IFS='|' read -r status exit_code action manager package message || [[ -n "${status:-}" ]]; do
    total_count=$((total_count + 1))

    case "${status}" in
    already-satisfied)
      already_satisfied_count=$((already_satisfied_count + 1))
      ;;
    failed)
      failed_count=$((failed_count + 1))
      ;;
    not-executed)
      not_executed_count=$((not_executed_count + 1))
      ;;
    success)
      success_count=$((success_count + 1))
      ;;
    *)
      unknown_count=$((unknown_count + 1))
      ;;
    esac

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

  printf 'Summary:\n'
  printf '  total:             %s\n' "${total_count}"
  printf '  already satisfied: %s\n' "${already_satisfied_count}"
  printf '  installed:         %s\n' "${success_count}"
  printf '  failed:            %s\n' "${failed_count}"
  printf '  not executed:      %s\n' "${not_executed_count}"
  printf '  unknown:           %s\n' "${unknown_count}"
}

## @fn bootstrap_run_execution_plan()
## @brief Preflights all manifests before executing the complete resolved plan.
## @details
## No executor is invoked until every supplied manifest has parsed, planned, and
## resolved successfully. The resulting Resolved Action stream preserves manifest
## argument order and source provenance, satisfying ADR-049 without concatenating
## source files or losing filename and line-number diagnostics.
## @retval 0 The complete manifest set executed successfully or required no work.
## @retval 65 At least one manifest could not be parsed or planned.
## @retval 69 At least one planned action could not be resolved.
## @retval 70 At least one resolved action failed during execution.
bootstrap_run_execution_plan() {
  local action_file
  local resolved_file
  local result_file
  local status

  action_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-plan.XXXXXX")"
  resolved_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-resolved.XXXXXX")"
  result_file="$(mktemp "${TMPDIR:-/tmp}/bootstrap-results.XXXXXX")"

  if bootstrap_preflight_manifests "${action_file}" "${resolved_file}"; then
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

## @fn main()
## @brief Runs the bootstrap command-line entry point.
## @details
## Discovery commands such as --help and --version return immediately and must be
## used by themselves. Operational flags are parsed, configuration is validated,
## and a supplied manifest is then either dry-run planned or executed.
## @param arguments[] Command-line arguments supplied by the user.
## @par Output Streams
## Command output on standard output, or diagnostics on standard error.
## @retval 0 The command completed successfully.
## @retval 64 The user supplied unsupported or invalid command-line arguments.
## @retval 65 Manifest parsing or planning failed.
## @retval 69 Resolution failed for the current system.
## @retval 70 Execution failed for at least one resolved action.
## @par Examples
## @code
## main --help
## main --dry-run --explain packages.txt
## main --package-manager apt packages.txt
## @endcode
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

  bootstrap_config_load_default_file || return "$?"
  bootstrap_config_apply_environment

  bootstrap_parse_arguments "$@" || return "$?"
  bootstrap_config_validate_effective_runtime || return "$?"

  if bootstrap_context_has_manifest_paths; then
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
