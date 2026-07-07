# shellcheck shell=bash
###############################################################################
# @file lib/backend/diagnostics.bash
# @brief Provides backend-facing diagnostic translation helpers.
#
# @details
# Backend modules talk to native package managers, but user-facing diagnostics
# should remain project-level concepts.  This module gives package backends a
# shared vocabulary for reporting unsupported managers, unavailable packages,
# missing candidates, and unsatisfied version constraints without leaking raw
# tool behavior into resolver or CLI output.
#
# Keeping these messages in one place matters for future package managers such
# as APK.  A new backend can report the same bootstrap concepts while using its
# own native commands internally, and callers can continue to reason about one
# stable diagnostic surface.
###############################################################################

###############################################################################
# @fn bootstrap_backend_diagnostic_no_supported_manager()
# @brief Reports that no supported package manager could be detected.
#
# @details
# Backend detection intentionally fails closed.  When the project cannot find a
# supported package manager, planning cannot honestly claim that requested
# packages can be resolved for the current system.
#
# @returns Diagnostic text on standard error.
# @retval 69 No supported package manager was detected.
###############################################################################
bootstrap_backend_diagnostic_no_supported_manager() {
  bootstrap_log_error 'no supported package manager detected'
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_unsupported_manager(manager)
# @brief Reports that a package manager identifier is unsupported.
#
# @details
# This diagnostic is used when a caller names a backend that the current engine
# does not implement.  It is separate from detection failure so explicit invalid
# configuration can be distinguished from an environment where no supported
# tools were found.
#
# @param manager Backend identifier that could not be handled.
# @returns Diagnostic text on standard error.
# @retval 69 The package manager is unsupported.
###############################################################################
bootstrap_backend_diagnostic_unsupported_manager() {
  local manager

  manager="$1"

  bootstrap_log_error "unsupported package manager: ${manager}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_missing_package_name(manager)
# @brief Reports that a backend lookup was requested without a package name.
#
# @details
# Package names are required for every backend lookup.  Reporting the selected
# manager keeps the diagnostic useful once additional package backends exist.
#
# @param manager Backend identifier that received the incomplete request.
# @returns Diagnostic text on standard error.
# @retval 69 The package lookup request was incomplete.
###############################################################################
bootstrap_backend_diagnostic_missing_package_name() {
  local manager

  manager="$1"

  bootstrap_log_error \
    "cannot inspect ${manager} package without package name"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_unsupported_capability(manager, capability)
# @brief Reports that a backend does not support a requested capability.
#
# @details
# Capability diagnostics keep backend feature gaps explicit.  This matters when
# new package managers are added incrementally because the resolver can fail
# with a project-level explanation instead of falling through to native command
# errors or silently ignoring unsupported behavior.
#
# @param manager Backend identifier that was asked to provide the capability.
# @param capability Capability name that is not supported.
# @returns Diagnostic text on standard error.
# @retval 69 The backend capability is unsupported.
###############################################################################
bootstrap_backend_diagnostic_unsupported_capability() {
  local capability
  local manager

  manager="$1"
  capability="$2"

  bootstrap_log_error \
    "backend capability not supported: ${manager} ${capability}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_package_unavailable(manager, package)
# @brief Reports that a backend cannot find package metadata.
#
# @details
# Package unavailability is a planning failure, not an execution failure.  The
# resolver should not produce a Resolved Action for a package the selected
# backend cannot find in its configured sources.
#
# @param manager Backend identifier that performed the lookup.
# @param package Package name that could not be found.
# @returns Diagnostic text on standard error.
# @retval 69 The package is unavailable through the selected backend.
###############################################################################
bootstrap_backend_diagnostic_package_unavailable() {
  local manager
  local package

  manager="$1"
  package="$2"

  bootstrap_log_error \
    "${manager} package not available: ${package}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_no_candidate(manager, package)
# @brief Reports that a backend has no installable candidate for a package.
#
# @details
# Some package managers can expose historical or partial metadata without an
# installable candidate.  Bootstrap treats that state as unsupported for
# planning because execution would not have a conservative package version to
# install.
#
# @param manager Backend identifier that inspected the package.
# @param package Package name that lacks an install candidate.
# @returns Diagnostic text on standard error.
# @retval 69 The package has no installable candidate.
###############################################################################
bootstrap_backend_diagnostic_no_candidate() {
  local manager
  local package

  manager="$1"
  package="$2"

  bootstrap_log_error \
    "${manager} package has no install candidate: ${package}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_unsupported_version_operator(manager, operator)
# @brief Reports that a backend cannot evaluate a version operator.
#
# @details
# The manifest parser owns grammar acceptance, but each backend owns the mapping
# from manifest operators into native version semantics.  This diagnostic makes
# an unsupported backend-level operator failure explicit and conservative.
#
# @param manager Backend identifier that rejected the operator.
# @param operator Manifest operator that could not be translated.
# @returns Diagnostic text on standard error.
# @retval 69 The backend cannot evaluate the operator.
###############################################################################
bootstrap_backend_diagnostic_unsupported_version_operator() {
  local manager
  local operator

  manager="$1"
  operator="$2"

  bootstrap_log_error \
    "unsupported ${manager} version operator: ${operator}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_missing_version(manager, package, operator)
# @brief Reports that a version comparison lacks the version value.
#
# @details
# A backend cannot safely evaluate a version operator without the version string
# it should compare against.  This should normally be prevented by parser and
# planner contracts, but the backend still fails closed when called directly.
#
# @param manager Backend identifier that received the incomplete constraint.
# @param package Package name being inspected.
# @param operator Version operator that lacked a right-hand value.
# @returns Diagnostic text on standard error.
# @retval 69 The version constraint is incomplete.
###############################################################################
bootstrap_backend_diagnostic_missing_version() {
  local manager
  local operator
  local package

  manager="$1"
  package="$2"
  operator="$3"

  bootstrap_log_error \
    "cannot check ${manager} version without version: ${package} ${operator}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_backend_diagnostic_unsatisfied_version_constraint(manager, package, candidate, operator, version)
# @brief Reports that a candidate version does not satisfy a constraint.
#
# @details
# The backend has already used native package-manager semantics by the time this
# diagnostic is emitted.  The message reports the bootstrap-level result and the
# candidate involved, giving the user enough context to adjust the manifest or
# package sources without exposing raw command output.
#
# @param manager Backend identifier that evaluated the constraint.
# @param package Package name being inspected.
# @param candidate Candidate version reported by the backend.
# @param operator Manifest version operator.
# @param version Manifest version value.
# @returns Diagnostic text on standard error.
# @retval 69 The candidate does not satisfy the requested constraint.
###############################################################################
bootstrap_backend_diagnostic_unsatisfied_version_constraint() {
  local candidate
  local manager
  local operator
  local package
  local version

  manager="$1"
  package="$2"
  candidate="$3"
  operator="$4"
  version="$5"

  bootstrap_log_error \
    "${manager} package candidate does not satisfy version constraint: ${package} candidate ${candidate} does not match ${operator} ${version}"
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}
