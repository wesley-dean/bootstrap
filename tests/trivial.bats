#!/usr/bin/env bats

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
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
