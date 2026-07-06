# shellcheck shell=bash
###############################################################################
# @file lib/build-metadata.bash
# @brief Documents and reports metadata embedded in the generated artifact.
#
# @details
# The Phase 1 build process writes BOOTSTRAP_VERSION, BOOTSTRAP_BUILD_DATE, and
# BOOTSTRAP_BUILD_COMMIT into dist/bootstrap.bash before this source fragment is
# concatenated. The default assignments below keep this module safe to analyze,
# source, or execute outside the generated artifact.
#
# Metadata is informational. It helps users and contributors understand which
# source revision produced an artifact, but it does not control package
# installation, planning, configuration, or command-line behavior.
#
# @var BOOTSTRAP_VERSION
# Human-readable version string embedded by the build process.
#
# @var BOOTSTRAP_BUILD_DATE
# Source revision timestamp embedded by the build process.
#
# @var BOOTSTRAP_BUILD_COMMIT
# Short Git commit identifier embedded by the build process.
###############################################################################

BOOTSTRAP_VERSION="${BOOTSTRAP_VERSION:-0.0.0-dev}"
BOOTSTRAP_BUILD_DATE="${BOOTSTRAP_BUILD_DATE:-unknown}"
BOOTSTRAP_BUILD_COMMIT="${BOOTSTRAP_BUILD_COMMIT:-unknown}"


###############################################################################
# @fn bootstrap_metadata_summary()
# @brief Prints the build metadata associated with this artifact.
#
# @details
# Phase 1 does not introduce a public --version option; that belongs to Phase 2
# of the roadmap. This helper keeps the interpretation of embedded metadata
# explicit without expanding the public CLI ahead of schedule.
#
# Future CLI work can call this function when implementing --version. Until
# then, tests can still inspect the generated artifact directly to verify that
# metadata was embedded during the build.
#
# @returns A single human-readable metadata line on standard output.
# @retval 0 Metadata was printed successfully.
#
# @par Examples
# @code
# bootstrap_metadata_summary
# @endcode
###############################################################################
bootstrap_metadata_summary() {
  printf 'version=%s build_date=%s commit=%s\n' \
    "${BOOTSTRAP_VERSION}" \
    "${BOOTSTRAP_BUILD_DATE}" \
    "${BOOTSTRAP_BUILD_COMMIT}"
}
