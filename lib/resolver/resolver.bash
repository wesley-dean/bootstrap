# shellcheck shell=bash
###############################################################################
# @file lib/resolver/resolver.bash
# @brief Resolves abstract Action Records into platform-bound Resolved Actions.
#
# @details
# The resolver sits between the planner and executor.  It consumes immutable
# Action Records that describe what should happen, then produces Resolved Actions
# that describe how the current platform would perform that work.
#
# This module deliberately does not execute commands.  It may inspect the
# environment to determine whether a supported package manager is available, but
# installation and mutation remain executor responsibilities for later roadmap
# phases.
###############################################################################

###############################################################################
# @fn bootstrap_resolver_detect_package_manager()
# @brief Detects the supported package manager for the current environment.
#
# @details
# Phase 3 keeps resolver support deliberately narrow.  Debian-family systems are
# considered supported when both apt-get and dpkg are available.  The bootstrap
# engine relies on both tools in later phases: apt-get for package operations and
# dpkg for installed-package inspection.
#
# @returns The detected package manager identifier on standard output.
# @retval 0 A supported package manager was detected.
# @retval 69 No supported package manager was detected.
###############################################################################
bootstrap_resolver_detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1; then
    printf 'apt\n'
    return "${BOOTSTRAP_EXIT_SUCCESS}"
  fi

  printf 'bootstrap.bash: no supported package manager detected\n' >&2
  return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
}

###############################################################################
# @fn bootstrap_resolver_resolve_action_record(action, package, operator, version, source, line_number, manager)
# @brief Resolves one Action Record into one Resolved Action.
#
# @details
# The planner emits platform-independent Action Records.  This function adds the
# package-manager binding needed by future executor phases while preserving the
# original action intent and provenance fields.
#
# The manager argument may be an explicit package-manager identifier, such as
# `apt`, or the special value `auto`, which asks the resolver to inspect the
# current environment.
#
# @param action Action Record type.
# @param package Package name from the Action Record.
# @param operator Optional version constraint operator.
# @param version Optional version constraint value.
# @param source Optional manifest source path.
# @param line_number Optional manifest line number.
# @param manager Package manager identifier or `auto`.
# @returns A pipe-delimited Resolved Action on standard output.
# @retval 0 The Action Record was resolved successfully.
# @retval 69 The Action Record could not be resolved on this system.
###############################################################################
bootstrap_resolver_resolve_action_record() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  action="$1"
  package="$2"
  operator="${3:-}"
  version="${4:-}"
  source="${5:-}"
  line_number="${6:-}"
  manager="${7:-auto}"

  if [[ "${manager}" == "auto" ]]; then
    manager="$(bootstrap_resolver_detect_package_manager)" || return "$?"
  fi

  case "${action}" in
  install-package)
    case "${manager}" in
    apt)
      bootstrap_resolved_action_create_install_package \
        "${manager}" \
        "${package}" \
        "${operator}" \
        "${version}" \
        "${source}" \
        "${line_number}"
      ;;
    *)
      printf 'bootstrap.bash: unsupported package manager: %s\n' "${manager}" >&2
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
      ;;
    esac
    ;;
  *)
    printf 'bootstrap.bash: unsupported action record: %s\n' "${action}" >&2
    return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    ;;
  esac
}

###############################################################################
# @fn bootstrap_resolver_resolve_action_records(manager)
# @brief Resolves Action Records from standard input into Resolved Actions.
#
# @details
# This stream-oriented helper is the resolver counterpart to the planner's
# record processing function.  It keeps tests and future CLI integration focused
# on observable records rather than private arrays or global state.
#
# @param manager Optional package manager identifier, defaulting to `auto`.
# @returns Pipe-delimited Resolved Actions on standard output.
# @retval 0 All Action Records were resolved successfully.
# @retval 69 At least one Action Record could not be resolved.
###############################################################################
bootstrap_resolver_resolve_action_records() {
  local action
  local line_number
  local manager
  local operator
  local package
  local source
  local version

  manager="${1:-auto}"

  while IFS='|' read -r action package operator version source line_number || [[ -n "${action:-}" ]]; do
    if [[ -z "${action}" ]]; then
      printf 'bootstrap.bash: malformed action record: missing action type\n' >&2
      return "${BOOTSTRAP_EXIT_UNSUPPORTED}"
    fi

    bootstrap_resolver_resolve_action_record \
      "${action}" \
      "${package}" \
      "${operator:-}" \
      "${version:-}" \
      "${source:-}" \
      "${line_number:-}" \
      "${manager}" || return "$?"
  done

  return "${BOOTSTRAP_EXIT_SUCCESS}"
}
