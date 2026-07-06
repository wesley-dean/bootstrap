# shellcheck shell=bash
###############################################################################
# @file lib/manifest/parser.bash
# @brief Parses package manifests into a normalized internal representation.
#
# @details
# The manifest parser is deliberately small.  It understands the minimal package
# requirement grammar described by the ADRs and doc/manifest-format.md, then
# emits normalized records for later planning phases.
#
# This module does not install packages, query package managers, compare package
# versions, or decide whether any system changes are required.  Its sole
# responsibility is to convert human-authored manifest text into validated
# package requirement records.
#
# The normalized representation is a tab-separated line containing package,
# operator, and version fields.  Package-only requirements leave the operator and
# version fields empty.  Later phases may replace this representation if the
# planner needs richer data structures, but the current text form keeps Phase 3
# behavior easy to inspect and test.
###############################################################################

###############################################################################
# @fn bootstrap_manifest_trim(value)
# @brief Removes leading and trailing shell whitespace from a string.
#
# @details
# Bash does not provide a built-in trim operation.  Keeping this helper local to
# manifest parsing avoids depending on external tools such as sed or awk for a
# tiny normalization step that is needed for every parsed line.
#
# @param value The string to trim.
# @returns The trimmed string on standard output.
# @retval 0 The value was trimmed successfully.
###############################################################################
bootstrap_manifest_trim() {
  local value

  value="$1"
  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"

  printf '%s\n' "${value}"
}

###############################################################################
# @fn bootstrap_manifest_parse_line(line, source, line_number)
# @brief Parses one manifest line and emits a normalized package record.
#
# @details
# Comments and blank lines are accepted and produce no output.  Package
# requirements are validated against the intentionally small manifest grammar.
# Malformed lines fail with a manifest-oriented exit code and a diagnostic that
# identifies the source location.
#
# Supported forms are package-only requirements and simple version constraints
# using `=`, `==`, `>`, or `>=`.  The parser validates syntax only; backend code
# remains responsible for interpreting version semantics later.
#
# @param line The raw manifest line to parse.
# @param source Human-readable source name used in diagnostics.
# @param line_number One-based line number used in diagnostics.
# @returns A tab-separated package/operator/version record for requirements.
# @retval 0 The line was blank, a comment, or a valid package requirement.
# @retval 65 The line was malformed manifest input.
###############################################################################
bootstrap_manifest_parse_line() {
  local line
  local source
  local line_number
  local package
  local operator
  local regex
  local trimmed
  local version

  line="$1"
  source="$2"
  line_number="$3"

  line="${line%%#*}"
  trimmed="$(bootstrap_manifest_trim "${line}")"

  if [[ -z "${trimmed}" ]]; then
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  regex='^([^[:space:]<>=!#]+)[[:space:]]*((==|=|>=|>)[[:space:]]*([^[:space:]#]+))?$'

  if [[ ! "${trimmed}" =~ ${regex} ]]; then
    printf 'bootstrap.bash: malformed manifest line: %s:%s\n' \
      "${source}" \
      "${line_number}" >&2
    printf 'bootstrap.bash: %s\n' "${trimmed}" >&2
    return "${BOOTSTRAP_EXIT_MANIFEST}"
  fi

  package="${BASH_REMATCH[1]}"
  operator="${BASH_REMATCH[3]:-}"
  version="${BASH_REMATCH[4]:-}"

  printf '%s\t%s\t%s\n' "${package}" "${operator}" "${version}"
}

###############################################################################
# @fn bootstrap_manifest_parse_file(path)
# @brief Parses a package manifest file into normalized package records.
#
# @details
# The parser reads the entire manifest before later roadmap phases perform any
# planning or system changes.  That separation lets the bootstrap engine report
# syntax errors before package-manager work begins.
#
# The function writes normalized records to standard output and diagnostics to
# standard error.  It intentionally does not hide partial output if a later line
# fails; callers that need all-or-nothing capture can redirect output into a
# temporary file and use the exit status to decide whether to keep it.
#
# @param path Path to the manifest file to parse.
# @returns Tab-separated package/operator/version records on standard output.
# @retval 0 The manifest was read and parsed successfully.
# @retval 65 The manifest path was unreadable or contained malformed input.
###############################################################################
bootstrap_manifest_parse_file() {
  local line
  local line_number
  local path

  path="$1"
  line_number=0

  if [[ ! -r "${path}" ]]; then
    printf 'bootstrap.bash: cannot read manifest: %s\n' "${path}" >&2
    return "${BOOTSTRAP_EXIT_MANIFEST}"
  fi

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_number=$((line_number + 1))
    bootstrap_manifest_parse_line "${line}" "${path}" "${line_number}" || return "$?"
  done <"${path}"

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}
