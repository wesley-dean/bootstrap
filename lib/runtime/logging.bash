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
