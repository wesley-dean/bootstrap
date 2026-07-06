# shellcheck shell=bash
###############################################################################
# @file lib/executor/executor.bash
# @brief Defines the executor boundary for Resolved Actions.
#
# @details
# The executor is the final stage of the bootstrap pipeline.  It consumes
# Resolved Actions and produces Execution Results.  ADR-048 deliberately keeps
# execution separate from manifest parsing, planning, and platform resolution.
#
# Backend-specific execution is reached through the package backend interface.
# This dispatcher keeps the ADR-048 boundary visible by routing Resolved Actions
# to the selected backend without parsing manifests, planning actions, or
# resolving platforms.
###############################################################################


###############################################################################
# @fn bootstrap_executor_malformed_resolved_action_message(action, manager, package)
# @brief Chooses a stable Execution Result message for malformed input records.
#
# @details
# The structural validator prints the precise diagnostic for a malformed
# Resolved Action.  The executor also needs to emit an Execution Result record
# so stream consumers receive structured failure data.  This helper keeps those
# result messages stable without duplicating every validation rule in the
# executor itself.
#
# @param action Resolved Action type, when present.
# @param manager Backend selected by the resolver, when present.
# @param package Package name associated with the action, when present.
# @returns A short Execution Result message on standard output.
# @retval 0 The message was printed successfully.
###############################################################################
bootstrap_executor_malformed_resolved_action_message() {
  local action
  local manager
  local package

  action="${1:-}"
  manager="${2:-}"
  package="${3:-}"

  if [[ -z "${action}" ]]; then
    printf 'missing resolved action type\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if [[ "${action}" == 'install-package' && -z "${manager}" ]]; then
    printf 'missing resolved package manager\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if [[ "${action}" == 'install-package' && -z "${package}" ]]; then
    printf 'missing resolved package name\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'malformed resolved action\n'
}

###############################################################################
# @fn bootstrap_executor_execute_resolved_action(action, manager, package, operator, version, source, line_number)
# @brief Attempts to execute one Resolved Action.
#
# @details
# The executor dispatches by Resolved Action type and resolved backend.  It does
# not inspect manifests, make planning decisions, or select package managers.
# Unsupported action/backend combinations fail conservatively with structured
# Execution Results.
#
# @param action Resolved Action type.
# @param manager Package manager or backend selected by the resolver.
# @param package Package name associated with the resolved action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Optional manifest source path preserved for provenance.
# @param line_number Optional manifest line number preserved for provenance.
# @returns An Execution Result record on standard output when possible.
# @retval 69 Execution is not implemented for the Resolved Action.
###############################################################################
bootstrap_executor_execute_resolved_action() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  action="$1"
  manager="${2:-}"
  package="${3:-}"
  operator="${4:-}"
  version="${5:-}"
  source="${6:-}"
  line_number="${7:-}"

  : "${operator}" "${version}" "${source}" "${line_number}"

  if ! bootstrap_resolved_action_validate_record \
    "${action}" \
    "${manager}" \
    "${package}" \
    "${operator}" \
    "${version}" \
    "${source}" \
    "${line_number}"; then
    bootstrap_execution_result_create \
      'not-executed' \
      "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
      "${action}" \
      "${manager}" \
      "${package}" \
      "$(bootstrap_executor_malformed_resolved_action_message \
        "${action}" \
        "${manager}" \
        "${package}")"
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  case "${action}" in
  install-package)
    if ! bootstrap_backend_supports_capability \
      "${manager}" \
      package-execution >/dev/null; then
      bootstrap_execution_result_create \
        'not-executed' \
        "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
        "${action}" \
        "${manager}" \
        "${package}" \
        'unsupported executor backend'
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    fi

    bootstrap_backend_install_package \
      "${manager}" \
      "${package}" \
      "${operator:-}" \
      "${version:-}"
    ;;
  *)
    printf 'bootstrap.bash: unsupported resolved action: %s\n' "${action}" >&2
    bootstrap_execution_result_create \
      'not-executed' \
      "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
      "${action}" \
      "${manager}" \
      "${package}" \
      'unsupported resolved action'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_executor_execute_resolved_actions()
# @brief Executes Resolved Actions from standard input.
#
# @details
# This stream-oriented helper mirrors the parser, planner, and resolver helpers
# already used elsewhere in the engine.  It allows tests and future CLI
# integration to exercise executor behavior with record streams instead of
# private arrays or global state.
#
# The initial implementation stops at the first unsupported or unimplemented
# action.  That conservative behavior prevents later execution paths from
# skipping failures and continuing with a partially applied bootstrap.
#
# @returns Execution Result records on standard output.
# @retval 0 All Resolved Actions executed successfully.
# @retval 69 At least one Resolved Action could not be executed.
###############################################################################
bootstrap_executor_execute_resolved_actions() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  while IFS='|' read -r action manager package operator version source line_number || [[ -n "${action:-}" ]]; do
    bootstrap_executor_execute_resolved_action \
      "${action}" \
      "${manager:-}" \
      "${package:-}" \
      "${operator:-}" \
      "${version:-}" \
      "${source:-}" \
      "${line_number:-}" || return "$?"
  done

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}
