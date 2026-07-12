#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/config"
    mkdir -p "$WORK_DIR"
}

@test "default .env config in current directory selects package manager" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'BOOTSTRAP_PACKAGE_MANAGER=apt\n' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"apt would install package: git"* ]]
}

@test "environment package manager overrides default .env config" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'BOOTSTRAP_PACKAGE_MANAGER=bogus\n' >"${WORK_DIR}/.env"

    run env BOOTSTRAP_PACKAGE_MANAGER=apt bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"apt would install package: git"* ]]
}

@test "CLI package manager overrides environment package manager" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"

    run env BOOTSTRAP_PACKAGE_MANAGER=bogus "$SCRIPT" --package-manager apt --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"apt would install package: git"* ]]
}

@test "invalid effective package manager fails conservatively" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'BOOTSTRAP_PACKAGE_MANAGER=bogus\n' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 64 ]
    [[ "$output" == *"unsupported package manager: bogus"* ]]
    [[ "$output" == *"Supported package managers in this release: auto, apt, apk, dnf."* ]]
}

@test "unknown BOOTSTRAP-prefixed .env keys fail conservatively" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'BOOTSTRAP_PACKAGE_MANGER=apt\n' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 64 ]
    [[ "$output" == *"unknown configuration key in .env:1: BOOTSTRAP_PACKAGE_MANGER"* ]]
}

@test "non-bootstrap .env keys are ignored" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'OTHER_TOOL_SETTING=true\nBOOTSTRAP_PACKAGE_MANAGER=apt\n' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"apt would install package: git"* ]]
}


@test "unrelated default .env config does not affect bootstrap" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"
    printf 'APP_ENV=dev\nPACKAGE_MANAGER=bogus\nOTHER_TOOL_SETTING=true\n' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && "$2" --dry-run "$3"' _ "$WORK_DIR" "$SCRIPT" "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"would install package: git"* ]]
    [[ "$output" != *"unsupported package manager: bogus"* ]]
}


@test "installation timeout defaults to 30 seconds" {
    run bash -c "source '$SCRIPT'; bootstrap_context_reset; bootstrap_context_get_install_timeout"

    [ "$status" -eq 0 ]
    [ "$output" = "30" ]
}

@test "environment installation timeout overrides the default" {
    run env BOOTSTRAP_INSTALL_TIMEOUT=45 bash -c "source '$SCRIPT'; bootstrap_context_reset; bootstrap_config_apply_environment; bootstrap_config_validate_effective_runtime; bootstrap_context_get_install_timeout"

    [ "$status" -eq 0 ]
    [ "$output" = "45" ]
}

@test "invalid installation timeout fails conservatively" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git
' >"$manifest"

    run env BOOTSTRAP_INSTALL_TIMEOUT=0 "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 64 ]
    [[ "$output" == *"BOOTSTRAP_INSTALL_TIMEOUT must be a positive whole number of seconds: 0"* ]]
}

@test "installation timeout may be loaded from .env" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git
' >"$manifest"
    printf 'BOOTSTRAP_INSTALL_TIMEOUT=12
BOOTSTRAP_PACKAGE_MANAGER=apt
' >"${WORK_DIR}/.env"

    run bash -c 'cd "$1" && source "$2"; bootstrap_context_reset; bootstrap_config_load_default_file; bootstrap_context_get_install_timeout' _ "$WORK_DIR" "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$output" = "12" ]
}
