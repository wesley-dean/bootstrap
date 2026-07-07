#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
}

@test "manifest parser reads standard input when path is dash" {
    run bash -c "printf '%s\n' 'git' 'jq >= 1.6' '# comment' 'curl' | { source '$SCRIPT'; bootstrap_manifest_parse_file '-'; }"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "git|||-|1" ]
    [ "${lines[1]}" = "jq|>=|1.6|-|2" ]
    [ "${lines[2]}" = "curl|||-|4" ]
}
