#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
}

@test "root bootstrap scaffold has been removed" {
    [ ! -e "${REPO_ROOT}/bootstrap.bash" ]
}

@test "generated bootstrap.bash exists" {
    [ -f "$SCRIPT" ]
}

@test "generated bootstrap.bash is executable" {
    [ -x "$SCRIPT" ]
}

@test "generated bootstrap.bash contains release metadata" {
    grep -q '^BOOTSTRAP_VERSION=' "$SCRIPT"
    grep -q '^BOOTSTRAP_BUILD_DATE=' "$SCRIPT"
    grep -q '^BOOTSTRAP_BUILD_COMMIT=' "$SCRIPT"
}

@test "generated bootstrap.bash executes successfully" {
    run "$SCRIPT"

    [ "$status" -eq 0 ]
}

@test "generated bootstrap.bash prints placeholder message" {
    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}

@test "generated bootstrap.bash prints help" {
    run "$SCRIPT" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"bootstrap.bash [options] [manifest]"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--explain"* ]]
    [[ "$output" == *"--verbose"* ]]
    [[ "$output" == *"--quiet"* ]]
}

@test "generated bootstrap.bash prints version metadata" {
    run "$SCRIPT" --version

    [ "$status" -eq 0 ]
    [[ "$output" == bootstrap.bash\ * ]]
    [[ "$output" == *"build_date="* ]]
    [[ "$output" == *"commit="* ]]
}

@test "generated bootstrap.bash accepts dry-run option" {
    run "$SCRIPT" --dry-run

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}

@test "generated bootstrap.bash accepts explain option" {
    run "$SCRIPT" --explain

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}

@test "generated bootstrap.bash accepts verbose option" {
    run "$SCRIPT" --verbose

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}

@test "generated bootstrap.bash accepts combined operational options" {
    run "$SCRIPT" --dry-run --explain --verbose

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}

@test "generated bootstrap.bash quiet option suppresses placeholder output" {
    run "$SCRIPT" --quiet

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "generated bootstrap.bash rejects verbose and quiet together" {
    run "$SCRIPT" --verbose --quiet

    [ "$status" -eq 64 ]
    [[ "$output" == *"--verbose and --quiet cannot be used together"* ]]
}

@test "generated bootstrap.bash rejects unsupported options" {
    run "$SCRIPT" --not-a-real-option

    [ "$status" -eq 64 ]
    [[ "$output" == *"unsupported option: --not-a-real-option"* ]]
}

@test "generated bootstrap.bash executes manifest arguments without dry-run" {
    manifest="${TEST_TMPDIR}/packages.txt"
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"

    cat >"${fake_bin}/sudo" <<'STUB'
#!/bin/sh
"$@"
STUB
    chmod +x "${fake_bin}/sudo"

    printf 'git\n' >"$manifest"

    cat >"${fake_bin}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${APT_GET_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/dpkg-query" "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" "$SCRIPT" "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Execution results:"* ]]
    [[ "$output" == *"package installation completed"* ]]
    [ "$(cat "$log_file")" = "install -y git" ]
}

@test "generated bootstrap.bash requires help to be used alone" {
    run "$SCRIPT" --help --dry-run

    [ "$status" -eq 64 ]
    [[ "$output" == *"--help does not accept additional arguments"* ]]
}

@test "generated bootstrap.bash requires version to be used alone" {
    run "$SCRIPT" --version --dry-run

    [ "$status" -eq 64 ]
    [[ "$output" == *"--version does not accept additional arguments"* ]]
}
