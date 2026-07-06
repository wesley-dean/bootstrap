# shellcheck shell=bash
###############################################################################
# @file lib/runtime/context.bash
# @brief Owns runtime option state for a bootstrap invocation.
#
# @details
# The command-line parser records operational flags in this module rather than
# asking unrelated parts of the program to inspect raw arguments.  Later roadmap
# phases can ask small, intention-revealing questions such as
# bootstrap_context_is_dry_run instead of reading global variables directly.
#
# The state remains process-local Bash state.  This is deliberate for the early
# bootstrap engine because it keeps the runtime small, inspectable, and free of
# external dependencies while still creating a clear boundary around invocation
# context.
#
# @var BOOTSTRAP_FLAG_DRY_RUN
# True when the user requested parsing without system changes.
#
# @var BOOTSTRAP_FLAG_EXPLAIN
# True when the user requested explanatory output for planned behavior.
#
# @var BOOTSTRAP_FLAG_VERBOSE
# True when the user requested more detailed diagnostic output.
#
# @var BOOTSTRAP_FLAG_QUIET
# True when the user requested non-essential output suppression.
###############################################################################

BOOTSTRAP_FLAG_DRY_RUN=false
BOOTSTRAP_FLAG_EXPLAIN=false
BOOTSTRAP_FLAG_VERBOSE=false
BOOTSTRAP_FLAG_QUIET=false

###############################################################################
# @fn bootstrap_context_reset()
# @brief Restores runtime option state to documented defaults.
#
# @details
# The generated artifact normally runs once per process, but tests and future
# callers may invoke the entry point more than once after sourcing the file.
# Resetting parser state at the start of each invocation prevents state from
# leaking across calls and keeps behavior deterministic.
#
# @retval 0 Runtime option state was reset successfully.
###############################################################################
bootstrap_context_reset() {
  BOOTSTRAP_FLAG_DRY_RUN=false
  BOOTSTRAP_FLAG_EXPLAIN=false
  BOOTSTRAP_FLAG_VERBOSE=false
  BOOTSTRAP_FLAG_QUIET=false
}

###############################################################################
# @fn bootstrap_context_enable_dry_run()
# @brief Records that dry-run mode was requested.
# @retval 0 Dry-run state was recorded successfully.
###############################################################################
bootstrap_context_enable_dry_run() {
  BOOTSTRAP_FLAG_DRY_RUN=true
}

###############################################################################
# @fn bootstrap_context_enable_explain()
# @brief Records that explanation output was requested.
# @retval 0 Explain state was recorded successfully.
###############################################################################
bootstrap_context_enable_explain() {
  BOOTSTRAP_FLAG_EXPLAIN=true
}

###############################################################################
# @fn bootstrap_context_enable_verbose()
# @brief Records that verbose diagnostics were requested.
# @retval 0 Verbose state was recorded successfully.
###############################################################################
bootstrap_context_enable_verbose() {
  BOOTSTRAP_FLAG_VERBOSE=true
}

###############################################################################
# @fn bootstrap_context_enable_quiet()
# @brief Records that quiet output was requested.
# @retval 0 Quiet state was recorded successfully.
###############################################################################
bootstrap_context_enable_quiet() {
  BOOTSTRAP_FLAG_QUIET=true
}

###############################################################################
# @fn bootstrap_context_is_dry_run()
# @brief Tests whether dry-run mode is active.
# @retval 0 Dry-run mode is active.
# @retval 1 Dry-run mode is not active.
###############################################################################
bootstrap_context_is_dry_run() {
  [[ "${BOOTSTRAP_FLAG_DRY_RUN}" == true ]]
}

###############################################################################
# @fn bootstrap_context_should_explain()
# @brief Tests whether explanatory output was requested.
# @retval 0 Explain mode is active.
# @retval 1 Explain mode is not active.
###############################################################################
bootstrap_context_should_explain() {
  [[ "${BOOTSTRAP_FLAG_EXPLAIN}" == true ]]
}

###############################################################################
# @fn bootstrap_context_is_verbose()
# @brief Tests whether verbose diagnostics are active.
# @retval 0 Verbose mode is active.
# @retval 1 Verbose mode is not active.
###############################################################################
bootstrap_context_is_verbose() {
  [[ "${BOOTSTRAP_FLAG_VERBOSE}" == true ]]
}

###############################################################################
# @fn bootstrap_context_is_quiet()
# @brief Tests whether non-essential output should be suppressed.
# @retval 0 Quiet mode is active.
# @retval 1 Quiet mode is not active.
###############################################################################
bootstrap_context_is_quiet() {
  [[ "${BOOTSTRAP_FLAG_QUIET}" == true ]]
}
