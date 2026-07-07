#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-regression"
    mkdir -p "$WORK_DIR"
}

@test "package manager option requires a following value" {
    run "$SCRIPT" --package-manager

    [ "$status" -eq 64 ]
    [[ "$output" == *"--package-manager requires a value"* ]]
    [[ "$output" == *"Try 'bootstrap.bash --help' for usage."* ]]
}

@test "package manager equals form rejects an empty value" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n' >"$manifest"

    run "$SCRIPT" --dry-run --package-manager= "$manifest"

    [ "$status" -eq 64 ]
    [[ "$output" == *"unsupported package manager:"* ]]
    [[ "$output" == *"Use --package-manager apt for APT"* ]]
}
