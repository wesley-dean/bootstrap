#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/phase9-planner"
    mkdir -p "$WORK_DIR"
}

@test "planner preserves provenance when manifest lacks trailing newline" {
    manifest="${WORK_DIR}/packages.txt"
    printf 'git\n\n# comment\ncurl >= 8.0' >"$manifest"

    run bash -c "source '$SCRIPT'; bootstrap_planner_plan_manifest_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "install-package|git|||$manifest|1" ]
    [ "${lines[1]}" = "install-package|curl|>=|8.0|$manifest|4" ]
}
