# shellcheck shell=bash
###############################################################################
# @file lib/runtime/logging.bash
# @brief Provides minimal output helpers for early runtime behavior.
#
# @details
# The bootstrap engine does not yet have full logging levels, progress output,
# or human-centered diagnostics.  This module establishes the place where that
# behavior will live while keeping the current implementation intentionally
# small.
#
# The first helper only prints non-essential output when quiet mode is disabled.
# Later roadmap phases can add verbose, warning, and error helpers here without
# forcing planning or package-management code to duplicate output policy.
###############################################################################

###############################################################################
# @fn bootstrap_log_info(message)
# @brief Prints an informational message unless quiet mode is active.
#
# @details
# Informational output is considered non-essential.  The --quiet option suppresses
# this helper so callers can silence placeholder and future progress messages
# without suppressing usage errors or other necessary diagnostics.
#
# @param message The message to print on standard output.
# @returns The message on standard output when quiet mode is inactive.
# @retval 0 The logging decision completed successfully.
###############################################################################
bootstrap_log_info() {
  local message

  message="$1"

  if bootstrap_context_is_quiet; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf '%s\n' "${message}"
}

###############################################################################
# @fn bootstrap_log_progress(message)
# @brief Prints an execution progress message unless quiet mode is active.
#
# @details
# Progress output describes major execution phases for a human watching the
# bootstrap engine run.  It is intentionally separate from informational output
# because progress is operational context rather than command result data.
#
# Progress messages are written to standard error.  That keeps structured or
# summary records on standard output easier for callers to capture while still
# making interactive execution understandable.  Quiet mode suppresses progress
# because progress is helpful but non-essential.
#
# @param message Human-readable progress message to print.
# @returns The message on standard error when quiet mode is inactive.
# @retval 0 The logging decision completed successfully.
###############################################################################
bootstrap_log_progress() {
  local message

  message="$1"

  if bootstrap_context_is_quiet; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: %s\n' "${message}" >&2
}

###############################################################################
# @fn bootstrap_log_verbose(message)
# @brief Prints a detailed diagnostic message when verbose mode is active.
#
# @details
# Verbose output is intended for troubleshooting and development.  It should
# reveal implementation details only when the user explicitly asks for them with
# --verbose.  Quiet mode still wins over verbose mode because the command-line
# parser rejects using both options together for normal invocations, and this
# helper should remain safe when called directly from tests or sourced sessions.
#
# @param message Human-readable verbose diagnostic message to print.
# @returns The message on standard error when verbose mode is active.
# @retval 0 The logging decision completed successfully.
###############################################################################
bootstrap_log_verbose() {
  local message

  message="$1"

  if bootstrap_context_is_quiet || ! bootstrap_context_is_verbose; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: verbose: %s\n' "${message}" >&2
}
