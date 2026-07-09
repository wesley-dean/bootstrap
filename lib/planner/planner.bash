# shellcheck shell=bash
## @file lib/planner/planner.bash
## @brief Converts parsed manifest records into abstract Action Records.
## @details
## The planner is intentionally platform independent.  It consumes the normalized
## Manifest Entry records produced by lib/manifest/parser.bash and emits immutable
## Action Records that describe what should happen.
##
## This module does not detect package managers, query installed packages,
## resolve operating-system-specific names, or execute commands.  Those
## responsibilities belong to later resolver and executor stages.  Keeping the
## planner abstract makes dry-run output, explain output, and future execution use
## the same planned operation stream.
## @par Examples
## @code
## bootstrap_manifest_parse_file ./packages.txt | bootstrap_planner_plan_manifest_records
## bootstrap_planner_plan_manifest_file ./packages.txt
## @endcode

## @fn bootstrap_planner_plan_manifest_records()
## @brief Converts normalized manifest records from stdin into Action Records.
## @details
## Each input record is expected to use the parser's pipe-delimited Manifest Entry
## representation: package, operator, version, source, and line number.  For every
## package requirement, the planner emits one abstract install-package Action
## Record.
##
## The action stream deliberately preserves manifest order.  Later phases may add
## deterministic sorting or dependency-aware ordering where appropriate, but this
## planner slice keeps the user's stated order visible and testable.
## @par Standard Output
## Pipe-delimited Action Records.
## @retval 0 All manifest records were planned successfully.
## @retval 65 A malformed or incomplete manifest record could not be planned.
## @par Examples
## @code
## printf '%s\n' 'curl|||packages.txt|1' | bootstrap_planner_plan_manifest_records
## @endcode
bootstrap_planner_plan_manifest_records() {
  local line_number
  local operator
  local package
  local source
  local version

  while IFS='|' read -r package operator version source line_number || [[ -n "${package:-}" ]]; do
    if [[ -z "${package}" ]]; then
      bootstrap_log_error 'malformed manifest record: missing package name'
      return "${BOOTSTRAP_EXIT_MANIFEST}"
    fi

    bootstrap_action_record_create_install_package \
      "${package}" \
      "${operator:-}" \
      "${version:-}" \
      "${source:-}" \
      "${line_number:-}" || return "$?"
  done

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}

## @fn bootstrap_planner_plan_manifest_file()
## @brief Parses a manifest file and emits abstract Action Records.
## @details
## This helper composes the parser and planner while preserving the architectural
## boundary between them.  The parser still owns manifest syntax.  The planner
## still owns transformation from Manifest Entry records into Action Records.
##
## No resolver or executor work occurs here.  The resulting Action Records remain
## platform independent and immutable.
## @param path Path to the manifest file to parse and plan.
## @par Standard Output
## Pipe-delimited Action Records.
## @retval 0 The manifest was parsed and planned successfully.
## @retval 65 The manifest could not be parsed or planned.
## @par Examples
## @code
## bootstrap_planner_plan_manifest_file ./packages.txt
## @endcode
bootstrap_planner_plan_manifest_file() {
  local path

  path="$1"

  bootstrap_manifest_parse_file "${path}" | bootstrap_planner_plan_manifest_records
}
