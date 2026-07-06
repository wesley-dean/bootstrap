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
# APT is treated as the source of truth for Debian-family package availability
# and version comparison.  The resolver uses this module to decide whether a
# requested package can be planned for the selected backend before any later
# execution phase attempts to perform work.
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
# execution phases, and `dpkg` provides native Debian version comparison
# semantics for constrained package requirements.
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
# This helper only checks whether package metadata exists.  Version constraints
# are checked by `bootstrap_backend_apt_package_satisfies_version` so callers
# can distinguish package-name availability from candidate-version suitability
# while still using native APT and dpkg semantics.
#
# @param package Package name to look up through APT metadata.
# @retval 0 APT metadata exists for the package.
# @retval 69 APT metadata does not exist for the package.
###############################################################################
bootstrap_backend_apt_package_exists() {
  local package

  package="$1"

  if [[ -z "${package}" ]]; then
    bootstrap_backend_diagnostic_missing_package_name apt
    return "$?"
  fi

  if apt-cache show "${package}" >/dev/null 2>&1; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_backend_diagnostic_package_unavailable apt "${package}"
}

###############################################################################
# @fn bootstrap_backend_apt_candidate_version(package)
# @brief Prints the APT candidate version for a package.
#
# @details
# A version constraint should be evaluated against the package candidate that
# APT would normally install from configured repositories.  This helper keeps
# candidate extraction in one place so the higher-level constraint function can
# focus on translating manifest operators into native dpkg comparison operators.
#
# A missing or `(none)` candidate is treated as unsupported for planning.  The
# package may still have historical metadata in some APT states, but bootstrap
# cannot conservatively plan an install when APT has no installable candidate.
#
# @param package Package name to inspect through APT policy metadata.
# @returns The candidate version on standard output.
# @retval 0 APT reported an installable candidate version.
# @retval 69 APT did not report an installable candidate version.
###############################################################################
bootstrap_backend_apt_candidate_version() {
  local candidate
  local package

  package="$1"

  candidate="$(apt-cache policy "${package}" \
    | awk '/^[[:space:]]*Candidate:/ { print $2; exit }')"

  if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
    bootstrap_backend_diagnostic_no_candidate apt "${package}"
    return "$?"
  fi

  printf '%s\n' "${candidate}"
}

###############################################################################
# @fn bootstrap_backend_apt_dpkg_operator(operator)
# @brief Translates a manifest version operator into a dpkg comparison operator.
#
# @details
# The manifest grammar intentionally exposes a small human-readable set of
# operators.  `dpkg --compare-versions` uses a related but different operator
# vocabulary, so this function performs the translation at the APT backend
# boundary instead of spreading that native detail through resolver code.
#
# @param operator Manifest operator such as `=`, `==`, `>`, or `>=`.
# @returns The corresponding dpkg comparison operator on standard output.
# @retval 0 The operator is supported by the APT backend.
# @retval 69 The operator is not supported by the APT backend.
###############################################################################
bootstrap_backend_apt_dpkg_operator() {
  local operator

  operator="$1"

  case "${operator}" in
  '=' | '==')
    printf 'eq\n'
    ;;
  '>')
    printf 'gt\n'
    ;;
  '>=')
    printf 'ge\n'
    ;;
  *)
    bootstrap_backend_diagnostic_unsupported_version_operator apt "${operator}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_backend_apt_package_satisfies_version(package, operator, version)
# @brief Checks whether the APT candidate satisfies a version constraint.
#
# @details
# Version comparison is delegated to `dpkg --compare-versions` rather than
# implemented with shell string comparison.  This preserves Debian-family
# version semantics, including epochs, revisions, and ordering rules that are
# easy to mishandle in handwritten Bash.
#
# An empty operator means the manifest requested only a package name.  In that
# case, package metadata availability is sufficient and no candidate comparison
# is required.
#
# @param package Package name to inspect.
# @param operator Optional manifest version operator.
# @param version Optional manifest version value.
# @retval 0 The package request is available and any constraint is satisfied.
# @retval 69 The package is unavailable or the candidate violates the constraint.
###############################################################################
bootstrap_backend_apt_package_satisfies_version() {
  local candidate
  local dpkg_operator
  local operator
  local package
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"

  bootstrap_backend_apt_package_exists "${package}" || return "$?"

  if [[ -z "${operator}" ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if [[ -z "${version}" ]]; then
    bootstrap_backend_diagnostic_missing_version apt "${package}" "${operator}"
    return "$?"
  fi

  candidate="$(bootstrap_backend_apt_candidate_version "${package}")" \
    || return "$?"
  dpkg_operator="$(bootstrap_backend_apt_dpkg_operator "${operator}")" \
    || return "$?"

  if dpkg --compare-versions "${candidate}" "${dpkg_operator}" "${version}"; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_backend_diagnostic_unsatisfied_version_constraint \
    apt \
    "${package}" \
    "${candidate}" \
    "${operator}" \
    "${version}"
}
