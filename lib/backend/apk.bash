# shellcheck shell=bash
###############################################################################
# @file lib/backend/apk.bash
# @brief Implements APK-specific package backend inspection.
#
# @details
# This module adds the Alpine APK backend behind the same resolver-facing
# inspection boundary used by APT.  It performs read-only package metadata
# checks only.  It does not install packages, update indexes, or mutate the
# system.
#
# APK is treated as the source of truth for Alpine package availability.  This
# first APK slice deliberately supports unconstrained package names only.  The
# backend does not advertise version-constraint support because APK version
# semantics and package selection syntax should be handled explicitly rather
# than inferred from Debian-family behavior.
###############################################################################

###############################################################################
# @fn bootstrap_backend_apk_is_available()
# @brief Reports whether the APK backend can inspect packages on this system.
#
# @details
# The APK backend requires the native `apk` command.  Detection is intentionally
# limited to command discovery.  Repository availability, package existence, and
# execution checks are handled by later backend and executor functions.
#
# @retval 0 The APK command is available.
# @retval 1 The APK command is unavailable.
###############################################################################
bootstrap_backend_apk_is_available() {
  command -v apk >/dev/null 2>&1
}

###############################################################################
# @fn bootstrap_backend_apk_package_exists(package)
# @brief Reports whether APK knows about a package in configured repositories.
#
# @details
# Package existence in this backend means repository availability, not installed
# state.  The resolver needs to know whether APK can find a package before it
# creates a Resolved Action.  The executor later decides whether the package is
# already installed or needs to be added.
#
# `apk search` is used as a read-only query against configured APK repositories.
# The exact-match flag avoids treating similarly named packages as satisfying the
# manifest request. APK prints package records with native version suffixes, so
# Bootstrap treats any non-empty exact-match result as repository availability.
#
# @param package Package name to look up through APK metadata.
# @retval 0 APK metadata exists for the package.
# @retval 69 APK metadata does not exist for the package.
###############################################################################
bootstrap_backend_apk_package_exists() {
  local package

  package="$1"

  if [[ -z "${package}" ]]; then
    bootstrap_backend_diagnostic_missing_package_name apk
    return "$?"
  fi

  if [[ -n "$(apk search -q -x "${package}" 2>/dev/null)" ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_backend_diagnostic_package_unavailable apk "${package}"
}
