# shellcheck shell=bash
## @file lib/backend/dnf.bash
## @brief Implements DNF-specific package backend inspection.
## @details
## This module adds the RedHat-family DNF backend behind the same resolver-facing
## inspection boundary used by APT and APK. It performs read-only package metadata
## checks only. It does not install packages, refresh repositories, or mutate the
## system.
##
## DNF is treated as the source of truth for RedHat-family package availability.
## This first DNF slice deliberately supports unconstrained package names only.
## The backend does not advertise version-constraint support because DNF version
## selection semantics should be handled explicitly rather than inferred from
## Debian-family behavior.

## @fn bootstrap_backend_dnf_is_available()
## @brief Reports whether the DNF backend can inspect and execute packages.
## @details
## The DNF backend requires the native `dnf` command for package metadata and
## installation work. It also requires `rpm` so the executor can check installed
## package state without invoking installation unnecessarily.
##
## @retval 0 Required DNF tooling is available.
## @retval 1 One or more required DNF tools are unavailable.
## @par Examples
## @code
## if bootstrap_backend_dnf_is_available; then
##   printf 'DNF backend is available\n'
## fi
## @endcode
bootstrap_backend_dnf_is_available() {
  command -v dnf >/dev/null 2>&1 &&
    command -v rpm >/dev/null 2>&1
}

## @fn bootstrap_backend_dnf_package_exists()
## @brief Reports whether DNF knows about a package in configured repositories.
## @details
## Package existence in this backend means DNF can find package metadata through
## the configured repositories or installed package database. The resolver needs
## to know whether DNF can identify a package before it creates a Resolved Action.
## The executor later decides whether the package is already installed or needs to
## be added.
##
## `dnf list` is used as a read-only native query. Output is suppressed so callers
## receive only the project-level success or diagnostic status.
##
## @param package Package name to look up through DNF metadata.
## @retval 0 DNF metadata exists for the package.
## @retval 69 DNF metadata does not exist for the package.
## @par Examples
## @code
## if bootstrap_backend_dnf_package_exists git; then
##   printf 'git can be resolved with DNF\n'
## fi
## @endcode
bootstrap_backend_dnf_package_exists() {
  local package

  package="$1"

  if [[ -z "${package}" ]]; then
    bootstrap_backend_diagnostic_missing_package_name dnf
    return "$?"
  fi

  if dnf -q list "${package}" >/dev/null 2>&1; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_backend_diagnostic_package_unavailable dnf "${package}"
}
