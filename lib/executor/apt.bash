# shellcheck shell=bash
## @file lib/executor/apt.bash
## @brief Implements APT-specific executor behavior.
## @details
## This module contains the first concrete executor backend. It consumes package
## installation requests that have already been resolved to APT and delegates the
## actual package operation to the native package manager.
##
## The module deliberately does not parse manifests, plan actions, resolve package
## managers, or decide which backend should handle a Resolved Action. Those
## responsibilities belong to earlier stages in the bootstrap pipeline.
## @par Examples
## @code
## bootstrap_executor_apt_install_package "curl"
## bootstrap_executor_apt_install_package "make" ">=" "4.3"
## @endcode

## @fn bootstrap_executor_apt_package_is_installed()
## @brief Reports whether an APT package is already installed.
## @details
## The executor should avoid performing work that is already satisfied. This
## helper asks dpkg-query whether the requested package is installed and leaves
## all output suppressed so callers receive only a success or failure signal.
## @param package Package name to inspect.
## @retval 0 The package is already installed.
## @retval 1 The package is not installed or could not be confirmed as installed.
## @par Examples
## @code
## if bootstrap_executor_apt_package_is_installed "curl"; then
##   printf '%s\n' "curl is already installed"
## fi
## @endcode
bootstrap_executor_apt_package_is_installed() {
  local package

  package="$1"

  dpkg-query -W -f='${Status}' "${package}" 2>/dev/null |
    grep -qx 'install ok installed'
}

## @fn bootstrap_executor_apt_install_package()
## @brief Executes one APT package installation request.
## @details
## This backend receives a package name from an already-resolved action. It first
## checks whether the package is already installed. If the desired state is
## already satisfied, it returns an Execution Result without invoking apt-get.
##
## Version constraints remain attached to records for future backend-specific
## interpretation, but they are not enforced in this first APT executor slice.
## That keeps the patch focused on idempotent execution of a resolved package
## action without introducing package-version semantics prematurely.
## @param package Package name selected by the manifest, planner, and resolver pipeline.
## @param operator Optional version constraint operator, currently preserved but not enforced.
## @param version Optional version constraint value, currently preserved but not enforced.
## @par Standard Output
## An Execution Result record.
## @retval 0 The package was already installed or APT completed successfully.
## @retval 70 The APT command failed.
## @par Examples
## @code
## bootstrap_executor_apt_install_package "curl"
## bootstrap_executor_apt_install_package "make" ">=" "4.3"
## @endcode
bootstrap_executor_apt_install_package() {
  local package
  local operator
  local status
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"

  : "${operator}" "${version}"

  if bootstrap_executor_apt_package_is_installed "${package}"; then
    bootstrap_execution_result_create \
      'already-satisfied' \
      "${BOOTSTRAP_EXIT_SUCCESS}" \
      'install-package' \
      'apt' \
      "${package}" \
      'package already installed'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_log_install_start "${package}"

  if bootstrap_privilege_run_install apt-get install -y --no-install-recommends "${package}" >/dev/null; then
    bootstrap_log_install_done
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
    bootstrap_log_install_failed
    if [[ "${status}" == "124" ]]; then
      bootstrap_execution_result_create \
        'failed' \
        "${BOOTSTRAP_EXIT_EXECUTION}" \
        'install-package' \
        'apt' \
        "${package}" \
        "package installation timed out after $(bootstrap_context_get_install_timeout) seconds"
      bootstrap_recovery_execution_failed 'apt' "${package}"
      return "${BOOTSTRAP_EXIT_EXECUTION}"
    fi

    if [[ "${status}" == "${BOOTSTRAP_EXIT_PRIVILEGE}" ]]; then
      bootstrap_execution_result_create \
        'failed' \
        "${BOOTSTRAP_EXIT_PRIVILEGE}" \
        'install-package' \
        'apt' \
        "${package}" \
        'privilege escalation unavailable'
      return "${BOOTSTRAP_EXIT_PRIVILEGE}"
    fi

    bootstrap_execution_result_create \
      'failed' \
      "${BOOTSTRAP_EXIT_EXECUTION}" \
      'install-package' \
      'apt' \
      "${package}" \
      "apt-get exited with status ${status}"
    bootstrap_recovery_execution_failed 'apt' "${package}"
    return "${BOOTSTRAP_EXIT_EXECUTION}"
  fi
}
