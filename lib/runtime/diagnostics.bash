# shellcheck shell=bash
## @file lib/runtime/diagnostics.bash
## @brief Provides human-centered diagnostic helpers for runtime failures.
## @details
## Diagnostics are the error-facing side of the user experience.  They should
## explain what happened, where it happened, why the engine stopped, and what the
## user can do next.  Keeping that wording in shared helpers prevents parsers,
## planners, resolvers, and executors from each inventing a slightly different
## diagnostic style.
##
## These helpers intentionally write to standard error and are not suppressed by
## quiet mode.  Quiet mode is allowed to hide non-essential progress output, but
## it must not hide information required to understand a conservative failure.


## @fn bootstrap_diagnostic_manifest_unreadable()
## @brief Reports that a manifest file cannot be read.
## @details
## The parser cannot safely continue when the requested manifest is missing or
## unreadable.  This diagnostic names the exact path and gives the user a recovery
## step without guessing whether the failure was caused by a typo, permissions, or
## a missing file.
##
## @param path Manifest path supplied by the user or caller.
## @returns Human-readable diagnostic text on standard error.
## @retval 65 The manifest file could not be read.
## @par Examples
## @code
## if [[ ! -r "${manifest_path}" ]]; then
##   bootstrap_diagnostic_manifest_unreadable "${manifest_path}"
## fi
## @endcode
bootstrap_diagnostic_manifest_unreadable() {
  local path

  path="$1"

  printf 'bootstrap.bash: error: cannot read manifest\n' >&2
  printf '  manifest: %s\n' "${path}" >&2
  printf '  why: the file does not exist, is not a regular readable file, or is blocked by permissions.\n' >&2
  printf '  next step: check the path and permissions, then run the command again.\n' >&2

  return "${BOOTSTRAP_EXIT_MANIFEST}"
}


## @fn bootstrap_diagnostic_manifest_malformed_line()
## @brief Reports one malformed manifest line with recovery guidance.
## @details
## Manifest syntax errors should be understandable without reading the parser
## implementation.  This diagnostic names the source location, shows the
## normalized offending input, explains the accepted forms, and points the user to
## the next corrective action.
##
## @param source Manifest source path used for provenance.
## @param line_number One-based logical line number within the manifest.
## @param input Trimmed manifest input after comments were removed.
## @returns Human-readable diagnostic text on standard error.
## @retval 65 The manifest line was malformed.
## @par Examples
## @code
## bootstrap_diagnostic_manifest_malformed_line \
##   "packages.txt" \
##   12 \
##   "curl <= 8.0"
## @endcode
bootstrap_diagnostic_manifest_malformed_line() {
  local input
  local line_number
  local source

  source="$1"
  line_number="$2"
  input="$3"

  printf 'bootstrap.bash: error: malformed manifest line\n' >&2
  printf '  location: %s:%s\n' "${source}" "${line_number}" >&2
  printf '  input: %s\n' "${input}" >&2
  printf '  expected: PACKAGE or PACKAGE OPERATOR VERSION\n' >&2
  printf '  supported operators: =, ==, >, >=\n' >&2
  printf '  next step: edit the manifest line or remove unsupported syntax.\n' >&2

  return "${BOOTSTRAP_EXIT_MANIFEST}"
}
