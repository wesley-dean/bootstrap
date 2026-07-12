# shellcheck shell=bash
## @file lib/runtime/recovery.bash
## @brief Provides human-centered recovery guidance for common failures.
## @details
## Diagnostics explain what failed.  Recovery guidance explains what a person can
## do next.  Keeping those concerns adjacent but separate lets backend, resolver,
## and executor code report stable failure concepts without scattering long-form
## user guidance throughout implementation logic.
##
## Recovery output is intentionally printed on standard error and is not
## suppressed by --quiet.  When bootstrap stops conservatively, the next step is
## part of the essential diagnostic surface.

## @fn bootstrap_recovery_emit()
## @brief Prints one normalized recovery guidance line.
## @details
## Recovery guidance uses its own stable log level so users can visually separate
## the failure itself from suggested next steps.  The message body is supplied by
## higher-level recovery helpers, which keeps specific guidance centralized while
## preserving one output shape.
##
## @param message Recovery guidance text to print after the recovery label.
## @par Standard Error
## A normalized recovery line.
## @retval 0 The recovery line was emitted successfully.
## @par Examples
## @code
## bootstrap_recovery_emit 'Review the package name in the manifest.'
## @endcode
bootstrap_recovery_emit() {
  local message

  message="$1"

  bootstrap_log_emit 'recovery' "${message}" 'stderr'
}

## @fn bootstrap_recovery_no_supported_package_manager()
## @brief Explains next steps when no supported package manager was detected.
## @details
## This guidance is used when automatic backend detection cannot find a package
## manager that bootstrap currently knows how to use.  The message names the
## current support boundary rather than guessing about the host operating system.
##
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_log_error 'no supported package manager detected'
## bootstrap_recovery_no_supported_package_manager
## @endcode
bootstrap_recovery_no_supported_package_manager() {
  bootstrap_recovery_emit 'Supported package managers in this release: apt, apk, dnf.'
  bootstrap_recovery_emit 'Install a supported package manager, or run on a system where one is available.'
  bootstrap_recovery_emit 'If you expected APT, check that apt-cache, apt-get, and dpkg are on PATH.'
  bootstrap_recovery_emit 'If you expected APK, check that apk is on PATH.'
  bootstrap_recovery_emit 'If you expected DNF, check that dnf and rpm are on PATH.'
}

## @fn bootstrap_recovery_unsupported_package_manager()
## @brief Explains next steps when the selected package manager is unsupported.
## @details
## Explicit package-manager selection may come from the CLI, the environment, or
## .env configuration.  This guidance helps the user recover without needing to
## know which layer provided the effective value.
##
## @param manager Unsupported package manager name supplied by the user or config.
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_print_usage_error 'unsupported package manager: pkgsrc'
## bootstrap_recovery_unsupported_package_manager pkgsrc
## @endcode
bootstrap_recovery_unsupported_package_manager() {
  local manager

  manager="$1"

  : "${manager}"

  bootstrap_recovery_emit 'Supported package managers in this release: auto, apt, apk, dnf.'
  bootstrap_recovery_emit 'Use --package-manager apt for APT, --package-manager apk for APK, --package-manager dnf for DNF, or --package-manager auto to let bootstrap detect one.'
  bootstrap_recovery_emit 'If this came from configuration, check BOOTSTRAP_PACKAGE_MANAGER in the environment or .env.'
}

## @fn bootstrap_recovery_package_unavailable()
## @brief Explains next steps when a package cannot be found or installed.
## @details
## Package availability failures usually mean either the manifest name does not
## match the selected package manager's package database, the package indexes are
## stale, or the required repository is not configured.  The guidance stays
## concrete for APT while remaining safe for future backends.
##
## @param manager Package manager that could not provide the package.
## @param package Package name that could not be resolved.
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_backend_diagnostic_package_unavailable apt 'example-package'
## bootstrap_recovery_package_unavailable apt 'example-package'
## @endcode
bootstrap_recovery_package_unavailable() {
  local manager
  local package

  manager="$1"
  package="$2"

  bootstrap_recovery_emit 'Verify that the package name in the manifest is spelled correctly.'

  case "${manager}" in
  apt)
    bootstrap_recovery_emit "For APT, try: sudo apt update"
    bootstrap_recovery_emit "For APT, search for the package with: apt search ${package}"
    ;;
  apk)
    bootstrap_recovery_emit "For APK, try: sudo apk update"
    bootstrap_recovery_emit "For APK, search for the package with: apk search ${package}"
    ;;
  dnf)
    bootstrap_recovery_emit "For DNF, try: sudo dnf makecache"
    bootstrap_recovery_emit "For DNF, search for the package with: dnf search ${package}"
    ;;
  *)
    bootstrap_recovery_emit "Check that ${manager} has package metadata for: ${package}"
    ;;
  esac
}

## @fn bootstrap_recovery_version_constraint()
## @brief Explains next steps for unsatisfied version constraints.
## @details
## Version constraint failures are usually resolved by changing the manifest,
## enabling the correct package source, or accepting the package manager's
## available candidate.  The helper does not recommend forcing versions because
## bootstrap should remain conservative.
##
## @param manager Package manager that evaluated the version constraint.
## @param package Package name whose candidate did not satisfy the constraint.
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_backend_diagnostic_unsatisfied_version_constraint \
##   apt curl 7.68.0 '>=' 8.0.0
## bootstrap_recovery_version_constraint apt curl
## @endcode
bootstrap_recovery_version_constraint() {
  local manager
  local package

  manager="$1"
  package="$2"

  bootstrap_recovery_emit 'Review the version constraint in the manifest.'

  case "${manager}" in
  apt)
    bootstrap_recovery_emit "For APT, inspect available versions with: apt-cache policy ${package}"
    ;;
  *)
    bootstrap_recovery_emit "Check which versions ${manager} can install for: ${package}"
    ;;
  esac

  bootstrap_recovery_emit 'If the available candidate is acceptable, update the manifest constraint.'
}

## @fn bootstrap_recovery_privilege_unavailable()
## @brief Explains next steps when elevated privileges are required but unavailable.
## @details
## Package installation commonly requires root privileges.  This guidance keeps
## the explanation concrete without hiding the conservative stop that already
## happened in the privilege helper.
##
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_log_error 'privilege escalation requires sudo or doas'
## bootstrap_recovery_privilege_unavailable
## @endcode
bootstrap_recovery_privilege_unavailable() {
  bootstrap_recovery_emit 'Run bootstrap as root, or install/configure sudo or doas for privilege escalation.'
  bootstrap_recovery_emit 'Use --dry-run first if you want to inspect the plan before retrying execution.'
}

## @fn bootstrap_recovery_execution_failed()
## @brief Explains next steps when native package installation fails.
## @details
## Native package-manager failures are intentionally summarized by bootstrap.  The
## next step is to inspect the native tool directly because it has the most
## complete system-specific details about locks, network failures, dependency
## conflicts, or repository problems.
##
## @param manager Package manager that attempted the installation.
## @param package Package name that failed to install.
## @par Standard Error
## Recovery guidance.
## @retval 0 The guidance was emitted successfully.
## @par Examples
## @code
## bootstrap_execution_result_failure apt 'example-package' 70 \
##   'native package installation failed'
## bootstrap_recovery_execution_failed apt 'example-package'
## @endcode
bootstrap_recovery_execution_failed() {
  local manager
  local package

  manager="$1"
  package="$2"

  case "${manager}" in
  apt)
    bootstrap_recovery_emit "Run the native command directly for full details: sudo apt-get install -y --no-install-recommends ${package}"
    bootstrap_recovery_emit 'Check for package-manager locks, network failures, or repository errors.'
    ;;
  apk)
    bootstrap_recovery_emit "Run the native command directly for full details: sudo apk add ${package}"
    bootstrap_recovery_emit 'Check for package-manager locks, network failures, or repository errors.'
    ;;
  dnf)
    bootstrap_recovery_emit "Run the native command directly for full details: sudo dnf install -y ${package}"
    bootstrap_recovery_emit 'Check for package-manager locks, network failures, or repository errors.'
    ;;
  *)
    bootstrap_recovery_emit "Run ${manager} directly to inspect why installation failed for: ${package}"
    ;;
  esac
}
