# shellcheck shell=bash
## @file lib/runtime/exit-codes.bash
## @brief Defines process exit codes used by the bootstrap command.
## @details
## This module gives exit status values a single home.  Keeping the values here
## avoids scattering numeric constants through parser, runtime, planning, and
## execution code as the bootstrap engine grows.
##
## The numeric values are intentionally stable because they are part of the
## observable command-line contract.  A caller may reasonably distinguish a
## successful run from a command-line usage error without parsing diagnostic
## text.
##
## @par Example
## @code
## if ! bootstrap_parse_arguments "$@"; then
##   exit "${BOOTSTRAP_EXIT_USAGE}"
## fi
## @endcode

# shellcheck disable=SC2034
## @var BOOTSTRAP_EXIT_SUCCESS
## @brief Exit status used when a command completes successfully.
## @details
## Uses `0`, the conventional successful shell status.
BOOTSTRAP_EXIT_SUCCESS=0

## @var BOOTSTRAP_EXIT_USAGE
## @brief Exit status used when command-line input is unsupported or invalid.
## @details
## Uses `64` to align with the conventional EX_USAGE category.
BOOTSTRAP_EXIT_USAGE=64

## @var BOOTSTRAP_EXIT_MANIFEST
## @brief Exit status used when manifest input cannot be read or parsed.
## @details
## Uses `65` to distinguish manifest data problems from command-line usage errors.
BOOTSTRAP_EXIT_MANIFEST=65

## @var BOOTSTRAP_EXIT_UNSUPPORTED
## @brief Exit status used when the current system cannot resolve a requested action.
## @details
## Uses `69` to report unsupported package managers, capabilities, or resolution paths.
BOOTSTRAP_EXIT_UNSUPPORTED=69

## @var BOOTSTRAP_EXIT_EXECUTION
## @brief Exit status used when execution of a resolved action fails.
## @details
## Uses `70` for runtime execution failures after planning and resolution succeed.
BOOTSTRAP_EXIT_EXECUTION=70

## @var BOOTSTRAP_EXIT_PRIVILEGE
## @brief Exit status used when required privilege escalation is unavailable.
## @details
## Uses `71` for privilege failures that prevent package-manager execution.
BOOTSTRAP_EXIT_PRIVILEGE=71
