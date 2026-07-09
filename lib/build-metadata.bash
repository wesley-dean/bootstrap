# shellcheck shell=bash
## @file lib/build-metadata.bash
## @brief Documents and reports metadata embedded in the generated artifact.
## @details
## The Phase 1 build process writes BOOTSTRAP_VERSION, BOOTSTRAP_BUILD_DATE, and
## BOOTSTRAP_BUILD_COMMIT into dist/bootstrap.bash before this source fragment is
## concatenated. The default assignments below keep this module safe to analyze,
## source, or execute outside the generated artifact.
##
## Metadata is informational. It helps users and contributors understand which
## source revision produced an artifact, but it does not control package
## installation, planning, configuration, or command-line behavior.
##
## @par Examples
## @code
## bootstrap_print_version
## @endcode

## @var BOOTSTRAP_VERSION
## @brief Human-readable version string embedded by the build process.
## @details
## Defaults to `0.0.0-dev` when the build process does not provide a version.
BOOTSTRAP_VERSION="${BOOTSTRAP_VERSION:-0.0.0-dev}"

## @var BOOTSTRAP_BUILD_DATE
## @brief Source revision timestamp embedded by the build process.
## @details
## Defaults to `unknown` when the build process does not provide a timestamp.
BOOTSTRAP_BUILD_DATE="${BOOTSTRAP_BUILD_DATE:-unknown}"

## @var BOOTSTRAP_BUILD_COMMIT
## @brief Short Git commit identifier embedded by the build process.
## @details
## Defaults to `unknown` when the build process does not provide a commit.
BOOTSTRAP_BUILD_COMMIT="${BOOTSTRAP_BUILD_COMMIT:-unknown}"

## @fn bootstrap_print_version()
## @brief Prints public version information for the generated artifact.
## @details
## The version output is intentionally short, stable, and easy to read from both
## interactive terminals and automated logs. It exposes build metadata without
## requiring users to inspect the generated script manually.
##
## The build metadata is embedded by the Makefile when dist/bootstrap.bash is
## generated. Local source execution uses the safe defaults above, which makes
## this function predictable even outside the generated artifact.
##
## @returns Version metadata on standard output.
## @retval 0 Version metadata was printed successfully.
## @par Examples
## @code
## bootstrap_print_version
## @endcode
bootstrap_print_version() {
  printf 'bootstrap.bash %s\n' "${BOOTSTRAP_VERSION}"
  printf 'build_date=%s\n' "${BOOTSTRAP_BUILD_DATE}"
  printf 'commit=%s\n' "${BOOTSTRAP_BUILD_COMMIT}"
}
