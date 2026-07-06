# shellcheck shell=bash
###############################################################################
# @file lib/backend/apt.bash
# @brief Implements APT-specific package backend inspection.
#
# @details
# This module is the first concrete implementation of the package backend
# interface used by the resolver.  It deliberately performs read-only package
# manager queries only.  It does not install packages, remove packages, update
# package indexes, or otherwise mutate the system.
#
# APT is treated as the source of truth for Debian-family package availability.
# The resolver uses this module to decide whether a requested package can be
# planned for the selected backend before any later execution phase attempts to
# perform work.
#
# Future package managers, such as Alpine APK, should provide equivalent
# backend modules rather than teaching the resolver package-manager-specific
# command syntax.
###############################################################################

###############################################################################
# @fn bootstrap_backend_apt_is_available()
# @brief Reports whether the APT backend can inspect packages on this system.
#
# @details
# The APT backend requires the native tools it delegates to.  `apt-cache` is
# needed for repository availability checks, `apt-get` is needed by later
# execution phases, and `dpkg` remains part of the Debian-family package-manager
# surface already expected elsewhere in the project.
#
# This function performs command discovery only.  It does not infer user intent,
# inspect manifests, or query package repositories.
#
# @retval 0 The required APT tooling is available.
# @retval 1 One or more required APT tools are unavailable.
###############################################################################
bootstrap_backend_apt_is_available() {
  command -v apt-cache >/dev/null 2>&1 \
    && command -v apt-get >/dev/null 2>&1 \
    && command -v dpkg >/dev/null 2>&1
}

###############################################################################
# @fn bootstrap_backend_apt_package_exists(package)
# @brief Reports whether APT knows about a package in configured repositories.
#
# @details
# Package existence in Phase 5 means repository availability, not installation
# state.  That distinction matters because planning should answer whether the
# requested package can be handed to the backend, while execution will later
# decide whether any mutation is still necessary.
#
# `apt-cache show` is used because it asks APT about package metadata available
# through the configured package sources.  Output is suppressed so callers get a
# simple status result that can be translated into project-level diagnostics.
#
# Version constraints are intentionally not interpreted here.  The manifest and
# action records preserve those fields, but Phase 5 only establishes the backend
# inspection boundary and package-name availability check.
#
# @param package Package name to look up through APT metadata.
# @retval 0 APT metadata exists for the package.
# @retval 69 APT metadata does not exist for the package.
###############################################################################
bootstrap_backend_apt_package_exists() {
  local package

  package="$1"

  if [[ -z "${package}" ]]; then
    printf 'bootstrap.bash: cannot inspect apt package without package name\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if apt-cache show "${package}" >/dev/null 2>&1; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: apt package not available: %s\n' "${package}" >&2
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}
