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
# This first executor module establishes the interface only.  It does not install
# packages, configure repositories, modify files, or change services.  Supported
# execution backends will be added in later patches after the executor contract
# is present and tested.
###############################################################################

###############################################################################
# @fn bootstrap_executor_execute_resolved_action(action, manager, package, operator, version, source, line_number)
# @brief Attempts to execute one Resolved Action.
#
# @details
# This initial executor framework intentionally rejects every Resolved Action as
# not implemented.  That behavior may look small, but it establishes an important
# architectural boundary: execution receives already-resolved records and returns
# Execution Results.
#
# Later patches can replace the not-implemented response for specific
# action/backend combinations without allowing executors to parse manifests,
# perform planning, or select package managers.
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

  if [[ -z "${action}" ]]; then
    printf 'bootstrap.bash: malformed resolved action: missing action type\n' >&2
    bootstrap_execution_result_create \
      'not-executed' \
      "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
      '' \
      "${manager}" \
      "${package}" \
      'missing resolved action type'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  case "${action}" in
  install-package)
    bootstrap_execution_result_create \
      'not-executed' \
      "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
      "${action}" \
      "${manager}" \
      "${package}" \
      'executor backend is not implemented'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
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
    if [[ -z "${action}" ]]; then
      printf 'bootstrap.bash: malformed resolved action: missing action type\n' >&2
      bootstrap_execution_result_create \
        'not-executed' \
        "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
        '' \
        "${manager:-}" \
        "${package:-}" \
        'missing resolved action type'
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    fi

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
