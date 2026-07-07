# shellcheck shell=bash
###############################################################################
# @file lib/planner/action-record.bash
# @brief Defines constructors for immutable planner action records.
#
# @details
# Action Records are the planner output described by ADR-047.  They represent
# what the bootstrap engine intends to do without encoding how that work will be
# performed on a particular operating system or package manager.
#
# The current implementation serializes action records as pipe-delimited text so
# empty fields are preserved safely when Bash reads the record back.  This
# encoding is an implementation detail rather than the architectural contract.
# Callers should create records through the constructor functions in this module
# instead of assembling records by hand.
###############################################################################

###############################################################################
# @fn bootstrap_action_record_create_install_package(package, operator, version, source, line_number)
# @brief Creates an immutable action record for a package installation intent.
#
# @details
# The planner emits this action when a manifest entry declares that a package
# should be present.  The record intentionally does not include a package
# manager, command line, repository decision, installation status, or platform
# binding.  Those details belong to later resolver and executor phases.
#
# The operator and version fields are preserved from the manifest parser when
# present.  They remain uninterpreted here because version comparison semantics
# belong to the package backend rather than the planner.
#
# The source and line-number fields preserve provenance.  They let dry-run and
# explain output show where the planned action came from without requiring later
# stages to re-read or reinterpret the manifest.
#
# @param package Package name from a parsed manifest entry.
# @param operator Optional version constraint operator from the manifest entry.
# @param version Optional version constraint value from the manifest entry.
# @param source Optional manifest source path from the manifest entry.
# @param line_number Optional manifest line number from the manifest entry.
# @returns A pipe-delimited Action Record on standard output.
# @retval 0 The action record was created successfully.
# @retval 65 The package field was empty or invalid for planning.
###############################################################################
bootstrap_action_record_create_install_package() {
  local line_number
  local operator
  local package
  local source
  local version

  package="$1"
  operator="${2:-}"
  version="${3:-}"
  source="${4:-}"
  line_number="${5:-}"

  if [[ -z "${package}" ]]; then
    bootstrap_log_error 'cannot plan package action without package name'
    return "${BOOTSTRAP_EXIT_MANIFEST}"
  fi

  printf 'install-package|%s|%s|%s|%s|%s\n' \
    "${package}" \
    "${operator}" \
    "${version}" \
    "${source}" \
    "${line_number}"
}
