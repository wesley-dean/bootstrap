# shellcheck shell=bash
## @file lib/executor/apk.bash
## @brief Implements APK-specific executor behavior.
## @details
## This module consumes package installation requests that have already been
## resolved to APK.  It delegates installation to Alpine's native package manager
## while preserving the executor boundary: it does not parse manifests, plan
## actions, select backends, or perform package availability resolution.
##
## Version fields remain attached to Resolved Actions for future compatibility,
## but the APK backend does not advertise version-constraint support in this
## slice.  Therefore, normally this executor receives unconstrained package
## requests only.
## @par Examples
## @code
## bootstrap_executor_apk_install_package "curl"
## @endcode

## @fn bootstrap_executor_apk_package_is_installed()
## @brief Reports whether an APK package is already installed.
## @details
## The executor should avoid invoking APK when the requested desired state is
## already satisfied.  `apk info -e` checks installed package state and suppresses
## output so callers can make a simple idempotency decision.
## @param package Package name to inspect.
## @retval 0 The package is already installed.
## @retval 1 The package is not installed or could not be confirmed as installed.
## @par Examples
## @code
## if bootstrap_executor_apk_package_is_installed "curl"; then
##   printf 'curl is already installed\n'
## fi
## @endcode
bootstrap_executor_apk_package_is_installed() {
  local package

  package="$1"

  apk info -e "${package}" >/dev/null 2>&1
}

## @fn bootstrap_executor_apk_install_package()
## @brief Executes one APK package installation request.
## @details
## This backend receives a package name from an already-resolved action.  It first
## checks whether the package is already installed.  If the package is present, it
## returns an Execution Result without invoking `apk add`.
##
## The optional version fields are accepted to preserve the executor interface,
## but they are not interpreted here.  Version-constraint capability is controlled
## by the backend layer before a Resolved Action reaches execution.
## @param package Package name selected by the manifest, planner, and resolver pipeline.
## @param operator Optional version constraint operator, currently preserved but not enforced.
## @param version Optional version constraint value, currently preserved but not enforced.
## @returns An Execution Result record on standard output.
## @retval 0 The package was already installed or APK completed successfully.
## @retval 70 The APK command failed.
## @par Examples
## @code
## bootstrap_executor_apk_install_package "curl"
## bootstrap_executor_apk_install_package "curl" "" ""
## @endcode
bootstrap_executor_apk_install_package() {
  local operator
  local package
  local status
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"

  : "${operator}" "${version}"

  if bootstrap_executor_apk_package_is_installed "${package}"; then
    bootstrap_execution_result_create \
      'already-satisfied' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'apk' \
      "${package}" \
      'package already installed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if bootstrap_privilege_run apk add "${package}" >/dev/null; then
    bootstrap_execution_result_create \
      'success' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'apk' \
      "${package}" \
      'package installation completed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  else
    status="$?"
    if [[ "${status}" == "${BOOTSTRAP_EXIT_PRIVILEGE}" ]]; then
      bootstrap_execution_result_create \
        'failed' \
        "${BOOTSTRAP_EXIT_PRIVILEGE}" \
        'install-package' \
        'apk' \
        "${package}" \
        'privilege escalation unavailable'
      return "${BOOTSTRAP_EXIT_PRIVILEGE}"
    fi

    bootstrap_execution_result_create \
      'failed' \
      "${BOOTSTRAP_EXIT_EXECUTION}" \
      'install-package' \
      'apk' \
      "${package}" \
      "apk exited with status ${status}"
    bootstrap_recovery_execution_failed 'apk' "${package}"
    return "${BOOTSTRAP_EXIT_EXECUTION}"
  fi
}
