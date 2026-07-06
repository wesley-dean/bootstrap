# shellcheck shell=bash
###############################################################################
# @file lib/backend/backend.bash
# @brief Defines the stable package backend inspection interface.
#
# @details
# The backend interface is the resolver-facing boundary between bootstrap intent
# and operating-system-specific package manager behavior.  The resolver should
# ask this module capability questions instead of calling APT, APK, or another
# native package manager directly.
#
# Phase 5 intentionally keeps the interface small.  It supports backend
# discovery and package availability checks, which are enough for install
# planning to avoid creating resolved actions for package names the selected
# backend cannot find.  Package installation remains executor work and is not
# performed here.
#
# The first supported backend is APT.  Additional backends should be added by
# implementing the same narrow inspection concepts and extending the dispatcher
# in this file, rather than by adding package-manager branches throughout the
# planner or resolver.
###############################################################################

###############################################################################
# @fn bootstrap_backend_detect_package_manager()
# @brief Detects the supported package backend for the current environment.
#
# @details
# Detection is deliberately conservative.  A backend is selected only when its
# required native tooling is present.  This avoids producing plans that appear
# executable but cannot actually be inspected or executed by later phases.
#
# The return value is a backend identifier such as `apt`.  It is an internal
# stable concept used by resolved actions and dispatcher functions.
#
# @returns The detected backend identifier on standard output.
# @retval 0 A supported backend was detected.
# @retval 69 No supported backend was detected.
###############################################################################
bootstrap_backend_detect_package_manager() {
  if bootstrap_backend_apt_is_available; then
    printf 'apt\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_backend_diagnostic_no_supported_manager
}

###############################################################################
# @fn bootstrap_backend_supports_capability(manager, capability)
# @brief Reports whether a backend advertises a named package capability.
#
# @details
# Capabilities describe backend behavior that higher layers may rely on without
# knowing which native package manager implements that behavior.  The resolver
# uses this function as the stable decision point before asking a backend to
# inspect package availability or evaluate version constraints.
#
# The capability names are intentionally plain strings because this project uses
# pipe-delimited shell records rather than richer data structures.  The current
# stable capability names are:
#
# - `package-availability`: the backend can determine whether a package can be
#   found in configured package sources.
# - `version-constraints`: the backend can evaluate manifest version
#   constraints against the native package candidate.
# - `package-execution`: the backend has an execution implementation elsewhere
#   in the bootstrap engine.
#
# Unsupported capabilities fail conservatively.  That gives future backends,
# such as Alpine APK, a way to join the interface incrementally without forcing
# every backend to pretend it supports every package-manager concept.
#
# @param manager Backend identifier, such as `apt`.
# @param capability Capability name to query.
# @retval 0 The backend advertises the requested capability.
# @retval 69 The backend or capability is unsupported.
###############################################################################
bootstrap_backend_supports_capability() {
  local capability
  local manager

  manager="$1"
  capability="$2"

  case "${manager}" in
  apt)
    case "${capability}" in
    package-availability | version-constraints | package-execution)
      return "${BOOTSTRAP_EXIT_SUCCESS}"
      ;;
    *)
      bootstrap_backend_diagnostic_unsupported_capability \
        "${manager}" \
        "${capability}"
      ;;
    esac
    ;;
  *)
    bootstrap_backend_diagnostic_unsupported_manager "${manager}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_backend_package_exists(manager, package, operator, version)
# @brief Checks whether the selected backend can find a requested package.
#
# @details
# This function translates a backend-specific package lookup into the stable
# success/failure behavior the resolver needs.  It accepts version-constraint
# fields so callers can pass complete package intent records without knowing
# whether the selected backend uses those fields in the current phase.
#
# The current APT implementation validates package-name availability and, when
# a version constraint is present, checks the APT candidate version using native
# Debian package comparison semantics.  The interface remains backend-neutral so
# future package managers can provide equivalent capability behind the same
# resolver-facing contract.
#
# @param manager Backend identifier, such as `apt`.
# @param package Package name to inspect.
# @param operator Optional version constraint operator preserved from the manifest.
# @param version Optional version constraint value preserved from the manifest.
# @retval 0 The backend can find the requested package.
# @retval 69 The backend is unsupported or cannot find the requested package.
###############################################################################
bootstrap_backend_package_exists() {
  local manager
  local operator
  local package
  local version

  manager="$1"
  package="$2"
  operator="${3:-}"
  version="${4:-}"

  : "${operator}" "${version}"

  case "${manager}" in
  apt)
    bootstrap_backend_apt_package_satisfies_version \
      "${package}" \
      "${operator}" \
      "${version}"
    ;;
  *)
    bootstrap_backend_diagnostic_unsupported_manager "${manager}"
    ;;
  esac
}
