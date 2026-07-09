# shellcheck shell=bash
## @file lib/executor/execution-result.bash
## @brief Defines constructors for executor output records.
## @details
## Execution Results are the executor output that follows Resolved Actions. They
## describe what happened when an executor attempted to perform a resolved piece
## of work.
##
## ADR-048 establishes that executors consume only Resolved Actions. This module
## complements that boundary by giving executor output a small, explicit record
## shape. Later reporting code can consume Execution Results without needing to
## understand manifest syntax, planning internals, resolver decisions, or package
## manager command lines.
##
## The current implementation serializes results as pipe-delimited text. That
## representation is an implementation detail; callers should use constructor
## functions instead of assembling records directly.
## @par Examples
## @code
## bootstrap_execution_result_create success 0 install-package apt curl 'installed package'
## @endcode

## @fn bootstrap_execution_result_create()
## @brief Creates an Execution Result record.
## @details
## This constructor captures the observable outcome of an executor attempt. The
## record is intentionally small during the initial executor-framework phase.
## Future executor work may add richer result records, but this shape is enough to
## establish that execution produces data rather than only process exit status.
## @param status Human-readable result status, such as `success` or `not-executed`.
## @param exit_code Process-style exit code associated with the result.
## @param action Resolved Action type the executor attempted to handle.
## @param manager Package manager or backend selected by the resolver.
## @param package Package name associated with the resolved action.
## @param message Short human-readable result message.
## @par Standard Output
## A pipe-delimited Execution Result.
## @retval 0 The Execution Result was created successfully.
## @retval 69 Required execution result fields were missing.
## @par Examples
## @code
## bootstrap_execution_result_create success 0 install-package apt curl 'installed package'
## bootstrap_execution_result_create not-executed 69 install-package unknown curl 'unsupported executor backend'
## @endcode
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
    bootstrap_log_error 'cannot create execution result without status'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  if [[ -z "${exit_code}" ]]; then
    bootstrap_log_error 'cannot create execution result without exit code'
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
  fi

  printf '%s|%s|%s|%s|%s|%s\n' \
    "${status}" \
    "${exit_code}" \
    "${action}" \
    "${manager}" \
    "${package}" \
    "${message}"
}
