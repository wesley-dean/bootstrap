# shellcheck shell=bash
## @file lib/executor/dnf.bash
## @brief Implements DNF-specific executor behavior.
## @details
## This module consumes package installation requests that have already been
## resolved to DNF. It delegates installation to the native package manager while
## preserving the executor boundary: it does not parse manifests, plan actions,
## select backends, or perform package availability resolution.
##
## Version fields remain attached to Resolved Actions for future compatibility,
## but the DNF backend does not advertise version-constraint support in this
## slice. Therefore, normally this executor receives unconstrained package
## requests only.
## @par Examples
## @code
## bootstrap_executor_dnf_install_package "curl"
## @endcode

## @fn bootstrap_executor_dnf_package_is_installed()
## @brief Reports whether a DNF/RPM package is already installed.
## @details
## The executor should avoid invoking DNF when the requested desired state is
## already satisfied. `rpm -q` checks installed package state and suppresses output
## so callers can make a simple idempotency decision.
## @param package Package name to inspect.
## @retval 0 The package is already installed.
## @retval 1 The package is not installed or could not be confirmed as installed.
## @par Examples
## @code
## if bootstrap_executor_dnf_package_is_installed "curl"; then
##   printf 'curl is already installed\n'
## fi
## @endcode
bootstrap_executor_dnf_package_is_installed() {
  local package

  package="$1"

  rpm -q "${package}" >/dev/null 2>&1
}

## @fn bootstrap_executor_dnf_install_package()
## @brief Executes one DNF package installation request.
## @details
## This backend receives a package name from an already-resolved action. It first
## checks whether the package is already installed. If the package is present, it
## returns an Execution Result without invoking `dnf install`.
##
## The optional version fields are accepted to preserve the executor interface,
## but they are not interpreted here. Version-constraint capability is controlled
## by the backend layer before a Resolved Action reaches execution.
## @param package Package name selected by the manifest, planner, and resolver pipeline.
## @param operator Optional version constraint operator, currently preserved but not enforced.
## @param version Optional version constraint value, currently preserved but not enforced.
## @par Standard Output
## An Execution Result record.
## @retval 0 The package was already installed or DNF completed successfully.
## @retval 70 The DNF command failed.
## @par Examples
## @code
## bootstrap_executor_dnf_install_package "curl"
## bootstrap_executor_dnf_install_package "curl" "" ""
## @endcode
bootstrap_executor_dnf_install_package() {
  local operator
  local package
  local status
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"

  : "${operator}" "${version}"

  if bootstrap_executor_dnf_package_is_installed "${package}"; then
    bootstrap_execution_result_create \
      'already-satisfied' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'dnf' \
      "${package}" \
      'package already installed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_log_install_start "${package}"

  if bootstrap_privilege_run_install dnf install -y "${package}" >/dev/null; then
    bootstrap_log_install_done
    bootstrap_execution_result_create \
      'success' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'dnf' \
      "${package}" \
      'package installation completed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
    bootstrap_log_install_failed
    if [[ "${status}" == "124" ]]; then
      bootstrap_execution_result_create \
        'failed' \
        "${BOOTSTRAP_EXIT_EXECUTION}" \
        'install-package' \
        'dnf' \
        "${package}" \
        "package installation timed out after $(bootstrap_context_get_install_timeout) seconds"
      bootstrap_recovery_execution_failed 'dnf' "${package}"
      return "${BOOTSTRAP_EXIT_EXECUTION}"
    fi

    if [[ "${status}" == "${BOOTSTRAP_EXIT_PRIVILEGE}" ]]; then
      bootstrap_execution_result_create \
        'failed' \
        "${BOOTSTRAP_EXIT_PRIVILEGE}" \
        'install-package' \
        'dnf' \
        "${package}" \
        'privilege escalation unavailable'
      return "${BOOTSTRAP_EXIT_PRIVILEGE}"
    fi

    bootstrap_execution_result_create \
      'failed' \
      "${BOOTSTRAP_EXIT_EXECUTION}" \
      'install-package' \
      'dnf' \
      "${package}" \
      "dnf exited with status ${status}"
    bootstrap_recovery_execution_failed 'dnf' "${package}"
    return "${BOOTSTRAP_EXIT_EXECUTION}"
  fi
}
