# shellcheck shell=bash
###############################################################################
# @file lib/executor/execution-result.bash
# @brief Defines constructors for executor output records.
#
# @details
# Execution Results are the executor output that follows Resolved Actions.  They
# describe what happened when an executor attempted to perform a resolved piece
# of work.
#
# ADR-048 establishes that executors consume only Resolved Actions.  This module
# complements that boundary by giving executor output a small, explicit record
# shape.  Later reporting code can consume Execution Results without needing to
# understand manifest syntax, planning internals, resolver decisions, or package
# manager command lines.
#
# The current implementation serializes results as pipe-delimited text.  That
# representation is an implementation detail; callers should use constructor
# functions instead of assembling records directly.
###############################################################################


###############################################################################
# @fn bootstrap_execution_result_validate_field(field_name, value)
# @brief Validates one field before serializing an Execution Result.
#
# @details
# Execution Results currently use a pipe-delimited text representation.  The
# delimiter is an implementation detail, but it is still part of the trusted
# internal data path between the executor, renderer, and exit-code evaluator.
#
# This helper rejects field values that would corrupt that record stream.  The
# validation is intentionally placed in the constructor module so executor
# backends do not each need to remember the serialization hazard.
#
# @param field_name Human-readable field name used in diagnostics.
# @param value Field value to validate.
# @retval 0 The field can be safely serialized.
# @retval 69 The field contains the reserved record delimiter.
###############################################################################
bootstrap_execution_result_validate_field() {
  local field_name
  local value

  field_name="$1"
  value="${2:-}"

  if [[ "${value}" == *"|"* ]]; then
    printf 'bootstrap.bash: execution result %s contains reserved delimiter: |\n' \
      "${field_name}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

###############################################################################
# @fn bootstrap_execution_result_validate_exit_code(exit_code)
# @brief Validates an Execution Result exit code before it can be returned.
#
# @details
# Bash function return values are limited to unsigned 8-bit process statuses.
# Returning a larger or non-numeric value can produce surprising shell behavior
# or diagnostics that bypass the bootstrap engine's human-centered error model.
#
# This helper keeps the constructor strict and lets the exit-code evaluator fail
# conservatively when it encounters malformed externally supplied records.
#
# @param exit_code Process-style status value to validate.
# @retval 0 The exit code is numeric and can be returned safely by Bash.
# @retval 69 The exit code is missing, non-numeric, or outside Bash's range.
###############################################################################
bootstrap_execution_result_validate_exit_code() {
  local exit_code

  exit_code="${1:-}"

  if [[ ! "${exit_code}" =~ ^[0-9]+$ ]]; then
    printf 'bootstrap.bash: execution result exit code is not numeric: %s\n' \
      "${exit_code:-<empty>}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if ((exit_code > 255)); then
    printf 'bootstrap.bash: execution result exit code is outside 0-255: %s\n' \
      "${exit_code}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

###############################################################################
# @fn bootstrap_execution_result_create(status, exit_code, action, manager, package, message)
# @brief Creates an Execution Result record.
#
# @details
# This constructor captures the observable outcome of an executor attempt.  The
# record is intentionally small during the initial executor-framework phase.
# Future executor work may add richer result records, but this shape is enough to
# establish that execution produces data rather than only process exit status.
#
# @param status Human-readable result status, such as `success` or `not-executed`.
# @param exit_code Process-style exit code associated with the result.
# @param action Resolved Action type the executor attempted to handle.
# @param manager Package manager or backend selected by the resolver.
# @param package Package name associated with the resolved action.
# @param message Short human-readable result message.
# @returns A pipe-delimited Execution Result on standard output.
# @retval 0 The Execution Result was created successfully.
# @retval 69 Required execution result fields were missing.
###############################################################################
bootstrap_execution_result_create() {
  local action
  local exit_code
  local manager
  local message
  local package
  local status

  status="$1"
  exit_code="$2"
  action="${3:-}"
  manager="${4:-}"
  package="${5:-}"
  message="${6:-}"

  if [[ -z "${status}" ]]; then
    printf 'bootstrap.bash: cannot create execution result without status\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if [[ -z "${exit_code}" ]]; then
    printf 'bootstrap.bash: cannot create execution result without exit code\n' >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  bootstrap_execution_result_validate_exit_code "${exit_code}" || return "$?"
  bootstrap_execution_result_validate_field status "${status}" || return "$?"
  bootstrap_execution_result_validate_field exit_code "${exit_code}" || return "$?"
  bootstrap_execution_result_validate_field action "${action}" || return "$?"
  bootstrap_execution_result_validate_field manager "${manager}" || return "$?"
  bootstrap_execution_result_validate_field package "${package}" || return "$?"
  bootstrap_execution_result_validate_field message "${message}" || return "$?"

  printf '%s|%s|%s|%s|%s|%s\n' \
    "${status}" \
    "${exit_code}" \
    "${action}" \
    "${manager}" \
    "${package}" \
    "${message}"
}

###############################################################################
# @fn bootstrap_execution_results_exit_code()
# @brief Derives a stable process exit code from Execution Result records.
#
# @details
# Execution Results are records, not merely display text.  The CLI should be
# able to render those records for humans and also derive a stable process
# status for automation without duplicating result interpretation in the command
# entry point.
#
# This helper reads pipe-delimited Execution Result records from standard input
# and returns the first non-successful exit code it encounters.  Successful and
# already-satisfied records are treated as zero because both represent a
# satisfied desired state.  Failed and not-executed records return their attached
# exit code when one is present.  Unknown statuses fail conservatively with the
# generic execution failure code because the engine cannot honestly report that
# an unrecognized execution outcome was successful.
#
# The function intentionally produces no standard output.  It exists to make the
# process status contract explicit while leaving user-facing rendering to
# bootstrap_print_execution_results().
#
# @retval 0 All execution records represent satisfied desired state.
# @retval 69 At least one record reports unsupported or not-executed work.
# @retval 70 At least one record reports failed or unknown execution.
# @retval 71 At least one record reports unavailable privilege escalation.
###############################################################################
bootstrap_execution_results_exit_code() {
  local action
  local exit_code
  local final_exit_code
  local manager
  local message
  local package
  local status

  final_exit_code="${BOOTSTRAP_EXIT_SUCCESS}"

  while IFS='|' read -r status exit_code action manager package message || [[ -n "${status:-}" ]]; do
    : "${action:-}" "${manager:-}" "${message:-}" "${package:-}"

    case "${status}" in
    already-satisfied | success)
      ;;
    failed | not-executed)
      if ! bootstrap_execution_result_validate_exit_code "${exit_code:-}" >/dev/null 2>&1; then
        if [[ "${status}" == "not-executed" ]]; then
          final_exit_code="${BOOTSTRAP_EXIT_UNSUPPORTED}"
        else
          final_exit_code="${BOOTSTRAP_EXIT_EXECUTION}"
        fi
      elif [[ "${exit_code}" != "0" ]]; then
        final_exit_code="${exit_code}"
      elif [[ "${status}" == "not-executed" ]]; then
        final_exit_code="${BOOTSTRAP_EXIT_UNSUPPORTED}"
      else
        final_exit_code="${BOOTSTRAP_EXIT_EXECUTION}"
      fi
      break
      ;;
    *)
      final_exit_code="${BOOTSTRAP_EXIT_EXECUTION}"
      break
      ;;
    esac
  done

  return "${final_exit_code}"
}
