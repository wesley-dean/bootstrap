#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/phase9-parser"
    mkdir -p "$WORK_DIR"
}

@test "parser preserves line provenance across comments blanks and EOF without newline" {
    manifest="${WORK_DIR}/provenance.txt"
    printf '# heading\n\n  git  # inline comment\n\tjq >= 1.6' >"$manifest"

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "git|||$manifest|3" ]
    [ "${lines[1]}" = "jq|>=|1.6|$manifest|4" ]
}

@test "parser rejects negated version constraints without treating them as package names" {
    manifest="${WORK_DIR}/negated-version.txt"
    printf 'git != 2.0\n' >"$manifest"

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
    [[ "$output" == *"location: $manifest:1"* ]]
    [[ "$output" == *"input: git != 2.0"* ]]
}
