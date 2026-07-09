# shellcheck shell=bash
## @file lib/runtime/context.bash
## @brief Owns runtime option state for a bootstrap invocation.
## @details
## The command-line parser records operational flags and the optional manifest
## path in this module rather than asking unrelated parts of the program to
## inspect raw arguments.  Later roadmap phases can ask small,
## intention-revealing questions such as bootstrap_context_is_dry_run instead of
## reading global variables directly.
##
## The state remains process-local Bash state.  This is deliberate for the early
## bootstrap engine because it keeps the runtime small, inspectable, and free of
## external dependencies while still creating a clear boundary around invocation
## context.
##
## This internal state deliberately avoids the public `BOOTSTRAP_` configuration
## variable names accepted from `.env` files and the process environment.  Keeping
## the names separate lets the loader distinguish an exported environment
## override from runtime state that was populated by a lower-priority source.

## @var BOOTSTRAP_FLAG_DRY_RUN
## @brief Tracks whether the user requested planning without system changes.
## @details
## Defaults to `false` at process start and after each context reset.
BOOTSTRAP_FLAG_DRY_RUN=false

## @var BOOTSTRAP_FLAG_EXPLAIN
## @brief Tracks whether the user requested explanatory output for planned behavior.
## @details
## Defaults to `false` at process start and after each context reset.
BOOTSTRAP_FLAG_EXPLAIN=false

## @var BOOTSTRAP_FLAG_VERBOSE
## @brief Tracks whether verbose diagnostics are active.
## @details
## Defaults to `false` at process start and after each context reset.
BOOTSTRAP_FLAG_VERBOSE=false

## @var BOOTSTRAP_FLAG_QUIET
## @brief Tracks whether non-essential output should be suppressed.
## @details
## Defaults to `false` at process start and after each context reset.
BOOTSTRAP_FLAG_QUIET=false

## @var BOOTSTRAP_MANIFEST_PATH
## @brief Stores the optional manifest path supplied as the positional argument.
## @details
## Defaults to an empty string until argument parsing records a manifest path.
BOOTSTRAP_MANIFEST_PATH=""

## @var BOOTSTRAP_CONTEXT_PACKAGE_MANAGER
## @brief Stores the effective package-manager selector for this invocation.
## @details
## Defaults to `auto` until configuration or command-line parsing selects another supported manager.
BOOTSTRAP_CONTEXT_PACKAGE_MANAGER="auto"

## @fn bootstrap_context_reset()
## @brief Restores runtime option state to documented defaults.
## @details
## The generated artifact normally runs once per process, but tests and future
## callers may invoke the entry point more than once after sourcing the file.
## Resetting parser state at the start of each invocation prevents state from
## leaking across calls and keeps behavior deterministic.
##
## @retval 0 Runtime option state was reset successfully.
## @par Examples
## @code
## bootstrap_context_reset
## @endcode
bootstrap_context_reset() {
  BOOTSTRAP_FLAG_DRY_RUN=false
  BOOTSTRAP_FLAG_EXPLAIN=false
  BOOTSTRAP_FLAG_VERBOSE=false
  BOOTSTRAP_FLAG_QUIET=false
  BOOTSTRAP_MANIFEST_PATH=""
  BOOTSTRAP_CONTEXT_PACKAGE_MANAGER="auto"
}

## @fn bootstrap_context_enable_dry_run()
## @brief Records that dry-run mode was requested.
## @retval 0 Dry-run state was recorded successfully.
## @par Examples
## @code
## bootstrap_context_enable_dry_run
## @endcode
bootstrap_context_enable_dry_run() {
  BOOTSTRAP_FLAG_DRY_RUN=true
}

## @fn bootstrap_context_enable_explain()
## @brief Records that explanation output was requested.
## @retval 0 Explain state was recorded successfully.
## @par Examples
## @code
## bootstrap_context_enable_explain
## @endcode
bootstrap_context_enable_explain() {
  BOOTSTRAP_FLAG_EXPLAIN=true
}

## @fn bootstrap_context_enable_verbose()
## @brief Records that verbose diagnostics were requested.
## @retval 0 Verbose state was recorded successfully.
## @par Examples
## @code
## bootstrap_context_enable_verbose
## @endcode
bootstrap_context_enable_verbose() {
  BOOTSTRAP_FLAG_VERBOSE=true
}

## @fn bootstrap_context_enable_quiet()
## @brief Records that quiet output was requested.
## @retval 0 Quiet state was recorded successfully.
## @par Examples
## @code
## bootstrap_context_enable_quiet
## @endcode
bootstrap_context_enable_quiet() {
  BOOTSTRAP_FLAG_QUIET=true
}

## @fn bootstrap_context_set_manifest_path()
## @brief Records the manifest path supplied by the user.
## @details
## The CLI accepts at most one manifest path.  This function stores the already
## validated positional argument so downstream code can ask for the manifest path
## without reparsing command-line input.
##
## @param path Package manifest path supplied as the positional argument.
## @retval 0 Manifest path was recorded successfully.
## @par Examples
## @code
## bootstrap_context_set_manifest_path ./packages.txt
## @endcode
bootstrap_context_set_manifest_path() {
  BOOTSTRAP_MANIFEST_PATH="$1"
}

## @fn bootstrap_context_set_package_manager()
## @brief Records the package-manager selector for this invocation.
## @details
## Configuration loading and command-line parsing apply precedence before the
## resolver runs.  The context stores the effective selector so dry-run and
## execution paths use the same package-manager decision instead of each path
## hard-coding its own default.
##
## @param manager Package-manager selector such as `auto` or `apt`.
## @retval 0 Package-manager selector was recorded successfully.
## @par Examples
## @code
## bootstrap_context_set_package_manager apt
## @endcode
bootstrap_context_set_package_manager() {
  BOOTSTRAP_CONTEXT_PACKAGE_MANAGER="$1"
}

## @fn bootstrap_context_get_package_manager()
## @brief Prints the effective package-manager selector.
## @returns The package-manager selector on standard output.
## @retval 0 The selector was printed successfully.
## @par Examples
## @code
## manager="$(bootstrap_context_get_package_manager)"
## printf 'package manager: %s\n' "${manager}"
## @endcode
bootstrap_context_get_package_manager() {
  printf '%s\n' "${BOOTSTRAP_CONTEXT_PACKAGE_MANAGER}"
}

## @fn bootstrap_context_has_manifest_path()
## @brief Tests whether a manifest path was supplied.
## @retval 0 A manifest path is available.
## @retval 1 No manifest path was supplied.
## @par Examples
## @code
## if bootstrap_context_has_manifest_path; then
##   bootstrap_context_get_manifest_path
## fi
## @endcode
bootstrap_context_has_manifest_path() {
  [[ -n "${BOOTSTRAP_MANIFEST_PATH}" ]]
}

## @fn bootstrap_context_get_manifest_path()
## @brief Prints the manifest path associated with the current invocation.
## @returns The manifest path on standard output.
## @retval 0 The manifest path was printed successfully.
## @par Examples
## @code
## manifest_path="$(bootstrap_context_get_manifest_path)"
## printf 'manifest: %s\n' "${manifest_path}"
## @endcode
bootstrap_context_get_manifest_path() {
  printf '%s\n' "${BOOTSTRAP_MANIFEST_PATH}"
}

## @fn bootstrap_context_is_dry_run()
## @brief Tests whether dry-run mode is active.
## @retval 0 Dry-run mode is active.
## @retval 1 Dry-run mode is not active.
## @par Examples
## @code
## if bootstrap_context_is_dry_run; then
##   printf '%s\n' 'dry-run mode is active'
## fi
## @endcode
bootstrap_context_is_dry_run() {
  [[ "${BOOTSTRAP_FLAG_DRY_RUN}" == true ]]
}

## @fn bootstrap_context_should_explain()
## @brief Tests whether explanatory output was requested.
## @retval 0 Explain mode is active.
## @retval 1 Explain mode is not active.
## @par Examples
## @code
## if bootstrap_context_should_explain; then
##   printf '%s\n' 'explanation output requested'
## fi
## @endcode
bootstrap_context_should_explain() {
  [[ "${BOOTSTRAP_FLAG_EXPLAIN}" == true ]]
}

## @fn bootstrap_context_is_verbose()
## @brief Tests whether verbose diagnostics are active.
## @retval 0 Verbose mode is active.
## @retval 1 Verbose mode is not active.
## @par Examples
## @code
## if bootstrap_context_is_verbose; then
##   printf '%s\n' 'verbose diagnostics enabled'
## fi
## @endcode
bootstrap_context_is_verbose() {
  [[ "${BOOTSTRAP_FLAG_VERBOSE}" == true ]]
}

## @fn bootstrap_context_is_quiet()
## @brief Tests whether non-essential output should be suppressed.
## @retval 0 Quiet mode is active.
## @retval 1 Quiet mode is not active.
## @par Examples
## @code
## if bootstrap_context_is_quiet; then
##   return "${BOOTSTRAP_EXIT_SUCCESS}"
## fi
## @endcode
bootstrap_context_is_quiet() {
  [[ "${BOOTSTRAP_FLAG_QUIET}" == true ]]
}
