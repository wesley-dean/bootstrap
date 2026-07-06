# shellcheck shell=bash
###############################################################################
# @file lib/runtime/exit-codes.bash
# @brief Defines process exit codes used by the bootstrap command.
#
# @details
# This module gives exit status values a single home.  Keeping the values here
# avoids scattering numeric constants through parser, runtime, planning, and
# execution code as the bootstrap engine grows.
#
# The numeric values are intentionally stable because they are part of the
# observable command-line contract.  A caller may reasonably distinguish a
# successful run from a command-line usage error without parsing diagnostic
# text.
#
# @var BOOTSTRAP_EXIT_SUCCESS
# Exit status used when a command completes successfully.
#
# @var BOOTSTRAP_EXIT_USAGE
# Exit status used when command-line input is unsupported or invalid.
#
# @var BOOTSTRAP_EXIT_MANIFEST
# Exit status used when manifest input cannot be read or parsed.
#
# @var BOOTSTRAP_EXIT_UNSUPPORTED
# Exit status used when the current system cannot resolve a requested action.
###############################################################################

# shellcheck disable=SC2034
BOOTSTRAP_EXIT_SUCCESS=0
BOOTSTRAP_EXIT_USAGE=64
BOOTSTRAP_EXIT_MANIFEST=65
BOOTSTRAP_EXIT_UNSUPPORTED=69
