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
# @fn bootstrap_resolved_action_validate_field(field_name, value)
# @brief Validates one serialized Resolved Action field.
#
# @details
# Resolved Actions are currently serialized as pipe-delimited records.  The
# constructor and executor both use this helper so malformed records are rejected
# consistently whether they were produced internally or supplied to executor
# tests as synthetic input.
#
# The helper intentionally validates only the record delimiter.  Semantic checks
# such as required manager and package fields are handled by the record-level
# validator where the action type is known.
#
# @param field_name Human-readable field name for diagnostics.
# @param value Field value to validate.
# @retval 0 The field can be safely serialized in a pipe-delimited record.
# @retval 69 The field contains the reserved pipe delimiter.
###############################################################################
bootstrap_resolved_action_validate_field() {
  local field_name
  local value

  field_name="$1"
  value="${2:-}"

  if [[ "${value}" == *'|'* ]]; then
    printf 'bootstrap.bash: malformed resolved action: %s contains reserved delimiter: |\n' \
      "${field_name}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

###############################################################################
# @fn bootstrap_resolved_action_validate_line_number(line_number)
# @brief Validates optional Resolved Action provenance line numbers.
#
# @details
# Provenance is useful only when it remains trustworthy.  A missing line number
# is allowed because synthetic tests and future non-file inputs may not always
# have source-line provenance.  When a value is present, however, it must be a
# decimal line number that can be displayed without surprising the reader.
#
# @param line_number Optional manifest line number preserved by the resolver.
# @retval 0 The line number is empty or numeric.
# @retval 69 The line number is present but malformed.
###############################################################################
bootstrap_resolved_action_validate_line_number() {
  local line_number

  line_number="${1:-}"

  if [[ -z "${line_number}" ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if [[ ! "${line_number}" =~ ^[0-9]+$ ]]; then
    printf 'bootstrap.bash: malformed resolved action: line number is not numeric: %s\n' \
      "${line_number}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

###############################################################################
# @fn bootstrap_resolved_action_validate_record(action, manager, package, operator, version, source, line_number)
# @brief Validates a Resolved Action record before execution.
#
# @details
# ADR-048 says executors consume Resolved Actions.  That boundary is safest when
# the executor can reject malformed Resolved Action records before backend code
# receives them.  This validator therefore checks the serialized record shape
# and the required fields for action types whose schema is currently known.
#
# Unknown action types are not rejected here.  They remain well-formed records
# that the executor can reject with its existing unsupported-action diagnostic.
# This separation keeps syntax validation distinct from capability decisions.
#
# @param action Resolved Action type.
# @param manager Backend selected by the resolver.
# @param package Package name associated with the resolved action.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Optional manifest source path preserved for provenance.
# @param line_number Optional manifest line number preserved for provenance.
# @retval 0 The record is structurally safe to pass to the executor.
# @retval 69 The record is malformed.
###############################################################################
bootstrap_resolved_action_validate_record() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  action="${1:-}"
  manager="${2:-}"
  package="${3:-}"
  operator="${4:-}"
  version="${5:-}"
  source="${6:-}"
  line_number="${7:-}"

  if [[ -z "${action}" ]]; then
    printf 'bootstrap.bash: malformed resolved action: missing action type\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  bootstrap_resolved_action_validate_field action "${action}" || return "$?"
  bootstrap_resolved_action_validate_field manager "${manager}" || return "$?"
  bootstrap_resolved_action_validate_field package "${package}" || return "$?"
  bootstrap_resolved_action_validate_field operator "${operator}" || return "$?"
  bootstrap_resolved_action_validate_field version "${version}" || return "$?"
  bootstrap_resolved_action_validate_field source "${source}" || return "$?"
  bootstrap_resolved_action_validate_field line_number "${line_number}" || return "$?"
  bootstrap_resolved_action_validate_line_number "${line_number}" || return "$?"

  case "${action}" in
  install-package)
    if [[ -z "${manager}" ]]; then
      printf 'bootstrap.bash: malformed resolved action: missing package manager\n' >&2
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    fi

    if [[ -z "${package}" ]]; then
      printf 'bootstrap.bash: malformed resolved action: missing package name\n' >&2
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    fi
    ;;
  esac

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

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
    printf 'bootstrap.bash: cannot resolve package action without package manager\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if [[ -z "${package}" ]]; then
    printf 'bootstrap.bash: cannot resolve package action without package name\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  bootstrap_resolved_action_validate_record \
    'install-package' \
    "${manager}" \
    "${package}" \
    "${operator}" \
    "${version}" \
    "${source}" \
    "${line_number}" || return "$?"

  printf 'install-package|%s|%s|%s|%s|%s|%s\n' \
    "${manager}" \
    "${package}" \
    "${operator}" \
    "${version}" \
    "${source}" \
    "${line_number}"
}
