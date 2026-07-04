#!/usr/bin/env bats

setup() {
    SCRIPT="${BATS_TEST_DIRNAME}/../bootstrap.bash"
}

@test "bootstrap.bash executes successfully" {
    run "$SCRIPT"

    [ "$status" -eq 0 ]
}

@test "bootstrap.bash prints placeholder message" {
    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$output" = "bootstrap.bash: not yet implemented" ]
}
