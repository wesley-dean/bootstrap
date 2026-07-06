# shellcheck shell=bash
###############################################################################
# @file lib/runtime/privilege.bash
# @brief Provides privilege escalation helpers for execution backends.
#
# @details
# Package managers often require elevated privileges, but backend modules should
# not need to decide whether to run directly, use sudo, use doas, or fail.  This
# runtime module keeps that policy in one place.
#
# Executors pass a command and its arguments to bootstrap_privilege_run().  This
# module then chooses the safest available way to run that command for the
# current process.
###############################################################################

###############################################################################
# @fn bootstrap_privilege_effective_uid()
# @brief Prints the current effective user identifier.
#
# @details
# This helper exists so tests may override it after sourcing the generated
# artifact.  Production code should treat it as a thin wrapper around `id -u`.
#
# @returns The effective user identifier on standard output.
# @retval 0 The user identifier was printed successfully.
###############################################################################
bootstrap_privilege_effective_uid() {
  id -u
}

###############################################################################
# @fn bootstrap_privilege_command_prefix()
# @brief Selects the command prefix needed for privileged execution.
#
# @details
# If the current process is already running as root, no prefix is needed.  When
# running as a non-root user, sudo is preferred when available, followed by doas.
# If neither tool is available, execution fails conservatively.
#
# @returns Optional privilege command prefix on standard output.
# @retval 0 A usable privilege strategy was selected.
# @retval 71 No usable privilege escalation command was available.
###############################################################################
bootstrap_privilege_command_prefix() {
  local effective_uid

  effective_uid="$(bootstrap_privilege_effective_uid)"

  if [[ "${effective_uid}" == "0" ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if command -v sudo >/dev/null 2>&1; then
    printf 'sudo\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  if command -v doas >/dev/null 2>&1; then
    printf 'doas\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: privilege escalation requires sudo or doas\n' >&2
  return "${BOOTSTRAP_EXIT_PRIVILEGE}"
}

###############################################################################
# @fn bootstrap_privilege_run(command, ...)
# @brief Runs a command using the selected privilege strategy.
#
# @details
# This helper centralizes privileged command execution.  Callers provide the
# command and arguments exactly as they would run them directly.  The helper
# either runs the command directly, prefixes it with sudo or doas, or fails before
# attempting the command when no supported privilege strategy exists.
#
# @param command Command to execute.
# @param ... Command arguments.
# @retval 0 The command completed successfully.
# @retval 71 Required privilege escalation was unavailable.
# @retval * The command's own exit status when it failed.
###############################################################################
bootstrap_privilege_run() {
  local prefix

  prefix="$(bootstrap_privilege_command_prefix)" || return "$?"

  if [[ -n "${prefix}" ]]; then
    "${prefix}" "$@"
    return "$?"
  fi

  "$@"
}
