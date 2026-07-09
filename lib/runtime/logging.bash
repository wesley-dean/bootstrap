# shellcheck shell=bash
## @file lib/runtime/logging.bash
## @brief Provides human-centered runtime logging helpers.
## @details
## Runtime output is part of the user experience.  This module keeps log
## formatting centralized so informational messages, warnings, and errors use
## the same visible shape across the bootstrap engine.
##
## The helpers deliberately keep the first implementation small. Informational
## messages are suppressed by --quiet because they are non-essential. Warning
## and error messages are never suppressed here because they explain
## conservative stops, unsupported behavior, or conditions that require user
## attention.
##
## The output format is intentionally plain text:
##
## @code
## bootstrap.bash: info: message
## bootstrap.bash: warning: message
## bootstrap.bash: error: message
## @endcode
##
## Keeping the program name and level stable makes terminal output easier to
## scan and gives future documentation examples a single format to teach.

## @fn bootstrap_log_emit()
## @brief Prints one normalized log line.
## @details
## This private helper is the formatting boundary for runtime log messages.  It
## does not decide whether a message should be shown; callers such as
## bootstrap_log_info(), bootstrap_log_warning(), and bootstrap_log_error() make
## that policy decision before delegating here.
##
## @param level Lowercase severity label such as info, warning, or error.
## @param message Human-readable message to show after the severity label.
## @param stream Output stream selector: stdout or stderr.
## @returns A normalized log line on the requested stream.
## @retval 0 The log line was emitted successfully.
## @retval 69 The requested stream selector is unsupported.
## @par Examples
## @code
## bootstrap_log_emit 'info' 'starting bootstrap' 'stdout'
## bootstrap_log_emit 'error' 'manifest could not be read' 'stderr'
## @endcode
bootstrap_log_emit() {
  local level
  local message
  local stream

  level="$1"
  message="$2"
  stream="$3"

  case "${stream}" in
  stdout)
    printf 'bootstrap.bash: %s: %s\n' "${level}" "${message}"
    ;;
  stderr)
    printf 'bootstrap.bash: %s: %s\n' "${level}" "${message}" >&2
    ;;
  *)
    printf 'bootstrap.bash: error: unsupported log stream: %s\n' "${stream}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

## @fn bootstrap_log_info()
## @brief Prints an informational message unless quiet mode is active.
## @details
## Informational output is considered non-essential.  The --quiet option
## suppresses this helper so callers can silence progress or placeholder
## messages without suppressing usage errors or other necessary diagnostics.
##
## @param message The informational message to print on standard output.
## @returns A normalized info log line on standard output when quiet mode is inactive.
## @retval 0 The logging decision completed successfully.
## @par Examples
## @code
## bootstrap_log_info 'not yet implemented'
## @endcode
bootstrap_log_info() {
  local message

  message="$1"

  if bootstrap_context_is_quiet; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  bootstrap_log_emit 'info' "${message}" 'stdout'
}

## @fn bootstrap_log_warning()
## @brief Prints a warning message on standard error.
## @details
## Warnings describe conditions that do not necessarily stop execution but still
## deserve user attention.  Quiet mode does not suppress warnings because hiding
## them would make conservative behavior harder to understand.
##
## @param message The warning message to print on standard error.
## @returns A normalized warning log line on standard error.
## @retval 0 The warning was printed successfully.
## @par Examples
## @code
## bootstrap_log_warning 'using automatic package-manager detection'
## @endcode
bootstrap_log_warning() {
  local message

  message="$1"

  bootstrap_log_emit 'warning' "${message}" 'stderr'
}

## @fn bootstrap_log_error()
## @brief Prints an error message on standard error.
## @details
## Errors describe conditions that stop the current operation or prevent the
## engine from safely continuing.  Quiet mode must not suppress errors because
## the user still needs to know what failed.
##
## @param message The error message to print on standard error.
## @returns A normalized error log line on standard error.
## @retval 0 The error was printed successfully.
## @par Examples
## @code
## bootstrap_log_error 'unsupported option: --bogus'
## @endcode
bootstrap_log_error() {
  local message

  message="$1"

  bootstrap_log_emit 'error' "${message}" 'stderr'
}
