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
# Backend-specific execution lives in separate executor modules.  This dispatcher
# keeps the ADR-048 boundary visible by routing Resolved Actions to the selected
# backend without parsing manifests, planning actions, or resolving platforms.
###############################################################################

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
    case "${manager}" in
    apt)
      bootstrap_executor_apt_install_package \
        "${package}" \
        "${operator:-}" \
        "${version:-}"
      ;;
    *)
      bootstrap_execution_result_create \
        'not-executed' \
        "${BOOTSTRAP_EXIT_UNSUPPORTED}" \
        "${action}" \
        "${manager}" \
        "${package}" \
        'unsupported executor backend'
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
      ;;
    esac
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
# @fn bootstrap_executor_execute_apt_install_package(package, operator, version)
# @brief Executes one APT package installation request.
#
# @details
# This helper is the first concrete executor backend.  It receives a package
# name from an already-resolved action and delegates package installation to
# apt-get.
#
# Version constraints remain attached to records for future backend-specific
# interpretation, but they are not enforced in this first APT executor slice.
# That keeps the patch focused on establishing execution of a resolved package
# action without introducing package-version semantics prematurely.
#
# @param package Package name selected by the manifest, planner, and resolver pipeline.
# @param operator Optional version constraint operator, currently preserved but not enforced.
# @param version Optional version constraint value, currently preserved but not enforced.
# @returns An Execution Result record on standard output.
# @retval 0 The APT command completed successfully.
# @retval 70 The APT command failed.
###############################################################################
bootstrap_executor_execute_apt_install_package() {
  local package
  local operator
  local status
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"

  : "${operator}" "${version}"

  if apt-get install -y "${package}" >/dev/null; then
    bootstrap_execution_result_create \
      'success' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'apt' \
      "${package}" \
      'package installation completed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
    bootstrap_execution_result_create \
      'failed' \
      "${BOOTSTRAP_EXIT_EXECUTION}" \
      'install-package' \
      'apt' \
      "${package}" \
      "apt-get exited with status ${status}"
    return "${BOOTSTRAP_EXIT_EXECUTION}"
  fi
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
