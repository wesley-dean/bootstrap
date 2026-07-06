#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/planner"
    mkdir -p "$WORK_DIR"
}

@test "planner converts package manifest entries into install-package action records" {
    manifest="${WORK_DIR}/packages.txt"
    cat >"$manifest" <<'MANIFEST'
git
curl
jq
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_planner_plan_manifest_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "install-package|git|||$manifest|1" ]
    [ "${lines[1]}" = "install-package|curl|||$manifest|2" ]
    [ "${lines[2]}" = "install-package|jq|||$manifest|3" ]
}

@test "planner preserves version constraints without resolving them" {
    manifest="${WORK_DIR}/versions.txt"
    cat >"$manifest" <<'MANIFEST'
openssl>=3.0
foo == 1.2.3
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_planner_plan_manifest_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "install-package|openssl|>=|3.0|$manifest|1" ]
    [ "${lines[1]}" = "install-package|foo|==|1.2.3|$manifest|2" ]
}

@test "planner ignores comments and blank lines through the parser boundary" {
    manifest="${WORK_DIR}/comments.txt"
    cat >"$manifest" <<'MANIFEST'
# no package here

   # still no package here
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_planner_plan_manifest_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "planner propagates manifest parser failures" {
    manifest="${WORK_DIR}/invalid.txt"
    cat >"$manifest" <<'MANIFEST'
git curl
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_planner_plan_manifest_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
}

@test "planner rejects incomplete manifest records" {
    run bash -c "source '$SCRIPT'; printf '||||\n' | bootstrap_planner_plan_manifest_records"

    [ "$status" -eq 65 ]
    [[ "$output" == *"missing package name"* ]]
}
