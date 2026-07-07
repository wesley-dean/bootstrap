# shellcheck shell=bash
###############################################################################
# @file lib/resolver/resolved-action.bash
# @brief Defines constructors for resolver output records.
#
# @details
# Resolved Actions are the resolver output that follows the immutable Action
# Records described by ADR-047.  A Resolved Action preserves the original
# planning intent while adding the implementation binding selected for the
# current environment.
#
# The current implementation serializes records as pipe-delimited text.  That
# format is an implementation detail; callers should use constructor functions
# instead of assembling records directly.
###############################################################################

###############################################################################
# @fn bootstrap_resolved_action_create_install_package(manager, package, operator, version, source, line_number)
# @brief Creates a resolved package-installation action.
#
# @details
# This constructor records that an abstract install-package Action Record has
# been bound to a package manager.  It still does not contain a command line and
# it does not execute anything.  Execution remains a later pipeline stage.
#
# @param manager Package manager selected by the resolver.
# @param package Package name from the original Action Record.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Optional manifest source path preserved for explanation output.
# @param line_number Optional manifest line number preserved for explanation output.
# @returns A pipe-delimited Resolved Action on standard output.
# @retval 0 The Resolved Action was created successfully.
# @retval 69 Required resolver fields were missing.
###############################################################################
bootstrap_resolved_action_create_install_package() {
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  manager="$1"
  package="$2"
  operator="${3:-}"
  version="${4:-}"
  source="${5:-}"
  line_number="${6:-}"

  if [[ -z "${manager}" ]]; then
    bootstrap_log_error 'cannot resolve package action without package manager'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if [[ -z "${package}" ]]; then
    bootstrap_log_error 'cannot resolve package action without package name'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  printf 'install-package|%s|%s|%s|%s|%s|%s\n' \
    "${manager}" \
    "${package}" \
    "${operator}" \
    "${version}" \
    "${source}" \
    "${line_number}"
}
