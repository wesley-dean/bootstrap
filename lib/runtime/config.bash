# shellcheck shell=bash
# shellcheck disable=SC2094
# The config parser reads config files but never writes to them. ShellCheck
# cannot infer that helper functions called inside redirected loops are read-only.
###############################################################################
# @file lib/runtime/config.bash
# @brief Loads namespaced bootstrap configuration from .env-style inputs.
#
# @details
# Runtime configuration is intentionally small and data-oriented.  The engine may
# read a `.env` file from the current working directory, but it does not source
# that file as shell code.  Parsing the file as data keeps configuration
# inspectable while avoiding command execution from a file that may also be used
# by other tools.
#
# Only variables with the `BOOTSTRAP_` prefix belong to this tool.  Unprefixed
# variables are ignored so a shared `.env` file can safely contain settings for
# other local tools.  Unknown `BOOTSTRAP_` variables fail conservatively because
# silently ignoring a misspelled bootstrap directive would make configuration
# difficult to trust.
#
# Configuration precedence is applied in the following order:
#
# 1. defaults built into the runtime context;
# 2. values from `./.env`, when that file exists;
# 3. exported process environment variables; and
# 4. explicit command-line options.
#
# Final value validation happens after command-line parsing so a higher-priority
# source can override a lower-priority value that would otherwise be invalid.
###############################################################################

###############################################################################
# @fn bootstrap_config_trim(value)
# @brief Removes leading and trailing shell whitespace from a value.
#
# @details
# The `.env` reader accepts simple whitespace around keys and values so human
# edited configuration files do not become fragile.  This helper avoids external
# commands because configuration loading runs very early in the bootstrap
# process, before the engine should assume much about the target system.
#
# @param value Text to trim.
# @returns The trimmed text on standard output.
# @retval 0 The value was trimmed successfully.
###############################################################################
bootstrap_config_trim() {
  local value

  value="$1"

  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"

  printf '%s\n' "${value}"
}

###############################################################################
# @fn bootstrap_config_unquote(value)
# @brief Removes one matching layer of simple .env quoting from a value.
#
# @details
# This parser supports the common `.env` forms `KEY=value`, `KEY="value"`, and
# `KEY='value'`.  It deliberately does not implement shell expansion, command
# substitution, escape processing, or nested quoting.  Those features would turn
# configuration into executable behavior and would enlarge the trusted computing
# base for little benefit during bootstrap.
#
# @param value Value text read after the `=` separator.
# @returns The unquoted value on standard output.
# @retval 0 The value was normalized successfully.
###############################################################################
bootstrap_config_unquote() {
  local value

  value="$1"

  if [[ "${value}" == \"*\" && "${value}" == *\" ]]; then
    value="${value:1:${#value}-2}"
  elif [[ "${value}" == \'*\' && "${value}" == *\' ]]; then
    value="${value:1:${#value}-2}"
  fi

  printf '%s\n' "${value}"
}

###############################################################################
# @fn bootstrap_config_apply_assignment(key, value, source, line_number)
# @brief Applies one parsed namespaced configuration assignment.
#
# @details
# The parser ignores non-bootstrap keys because `.env` files are commonly shared
# by several local tools.  Once a key uses the `BOOTSTRAP_` namespace, however,
# it becomes part of this tool's public configuration surface and must be known.
# That fail-closed behavior catches typos such as `BOOTSTRAP_PACKAGE_MANGER`
# before the user trusts a run that did not actually use the intended setting.
#
# @param key Variable name from a configuration source.
# @param value Variable value from a configuration source.
# @param source Human-readable source name used in diagnostics.
# @param line_number Optional source line number used in diagnostics.
# @retval 0 The assignment was applied or intentionally ignored.
# @retval 64 The assignment used an unknown `BOOTSTRAP_` key.
###############################################################################
bootstrap_config_apply_assignment() {
  local key
  local line_number
  local source
  local value

  key="$1"
  value="$2"
  source="$3"
  line_number="${4:-}"

  case "${key}" in
    BOOTSTRAP_PACKAGE_MANAGER)
      bootstrap_context_set_package_manager "${value}"
      ;;
    BOOTSTRAP_*)
      if [[ -n "${line_number}" ]]; then
        bootstrap_print_usage_error \
          "unknown configuration key in ${source}:${line_number}: ${key}"
      else
        bootstrap_print_usage_error \
          "unknown configuration key in ${source}: ${key}"
      fi
      return "${BOOTSTRAP_EXIT_USAGE}"
      ;;
    *)
      :
      ;;
  esac
}

###############################################################################
# @fn bootstrap_config_load_file(path)
# @brief Loads supported assignments from a .env-style configuration file.
#
# @details
# The file reader accepts blank lines, full-line comments, optional `export`,
# and simple `KEY=VALUE` assignments.  It intentionally avoids source-compatible
# execution semantics.  A line must be readable as data before it can influence
# bootstrap behavior.
#
# @param path Configuration file path to read.
# @retval 0 The file was loaded successfully.
# @retval 64 The file contained malformed or unsupported bootstrap configuration.
###############################################################################
bootstrap_config_load_file() {
  local key
  local line
  local line_number
  local path
  local value

  path="$1"
  line_number=0

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_number=$((line_number + 1))
    line="$(bootstrap_config_trim "${line}")"

    if [[ -z "${line}" || "${line}" == \#* ]]; then
      continue
    fi

    if [[ "${line}" == export[[:space:]]* ]]; then
      line="${line#export}"
      line="$(bootstrap_config_trim "${line}")"
    fi

    if [[ "${line}" != *=* ]]; then
      bootstrap_print_usage_error \
        "invalid configuration line in ${path}:${line_number}: expected KEY=VALUE"
      return "${BOOTSTRAP_EXIT_USAGE}"
    fi

    key="$(bootstrap_config_trim "${line%%=*}")"
    value="$(bootstrap_config_trim "${line#*=}")"
    value="$(bootstrap_config_unquote "${value}")"

    if [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      bootstrap_print_usage_error \
        "invalid configuration key in ${path}:${line_number}: ${key}"
      return "${BOOTSTRAP_EXIT_USAGE}"
    fi

    bootstrap_config_apply_assignment \
      "${key}" \
      "${value}" \
      "${path}" \
      "${line_number}" || return "$?"
  done < "${path}"
}

###############################################################################
# @fn bootstrap_config_load_default_file()
# @brief Loads `./.env` when the current directory provides one.
#
# @details
# The default file is optional.  Missing configuration is not an error because
# the engine has documented built-in defaults.  The lookup is intentionally
# limited to the current working directory; it does not walk parent directories
# or consult user-level locations.
#
# @retval 0 No default file existed, or the default file loaded successfully.
# @retval 64 The default file contained invalid bootstrap configuration.
###############################################################################
bootstrap_config_load_default_file() {
  if [[ -f .env ]]; then
    bootstrap_config_load_file .env
  fi
}

###############################################################################
# @fn bootstrap_config_apply_environment()
# @brief Applies supported exported environment variables to runtime context.
#
# @details
# The environment has higher precedence than `./.env` because it is supplied by
# the invoking process and can represent a deliberate one-off override.  Only
# known environment variables are read.  Unknown exported `BOOTSTRAP_` variables
# are not rejected because parent shells and CI systems may carry unrelated
# namespaced values that this invocation did not ask to interpret.
#
# @retval 0 Supported environment variables were applied successfully.
###############################################################################
bootstrap_config_apply_environment() {
  if [[ -v BOOTSTRAP_PACKAGE_MANAGER ]]; then
    bootstrap_context_set_package_manager "${BOOTSTRAP_PACKAGE_MANAGER}"
  fi
}

###############################################################################
# @fn bootstrap_config_validate_package_manager(value)
# @brief Validates a package-manager configuration value.
#
# @details
# The current stable backend surface supports automatic detection and APT.  The
# validation function is deliberately small so future package managers, such as
# APK, can be added by extending one explicit allowlist instead of scattering
# string checks through the command-line and runtime code.
#
# @param value Effective package-manager selector.
# @retval 0 The value is supported.
# @retval 64 The value is not supported.
###############################################################################
bootstrap_config_validate_package_manager() {
  local value

  value="$1"

  case "${value}" in
    auto | apt)
      return "${BOOTSTRAP_EXIT_SUCCESS}"
      ;;
    *)
      bootstrap_print_usage_error \
        "unsupported package manager: ${value}"
      bootstrap_recovery_unsupported_package_manager "${value}"
      return "${BOOTSTRAP_EXIT_USAGE}"
      ;;
  esac
}

###############################################################################
# @fn bootstrap_config_validate_effective_runtime()
# @brief Validates effective runtime configuration after precedence is applied.
#
# @details
# Validation runs after command-line parsing because CLI options have the highest
# precedence.  This allows an explicit CLI override to replace a lower-priority
# environment or `.env` value before the effective configuration is judged.
#
# @retval 0 Effective runtime configuration is valid.
# @retval 64 Effective runtime configuration is invalid.
###############################################################################
bootstrap_config_validate_effective_runtime() {
  bootstrap_config_validate_package_manager \
    "$(bootstrap_context_get_package_manager)"
}
