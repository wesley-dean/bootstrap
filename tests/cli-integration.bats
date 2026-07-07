#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-integration"
    FAKE_BIN="${WORK_DIR}/bin"
    mkdir -p "$FAKE_BIN"
}

write_resolver_stubs() {
    cat >"${FAKE_BIN}/apt-cache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
show)
    case "$2" in
    missing-package)
        exit 100
        ;;
    *)
        printf 'Package: %s\n' "$2"
        exit 0
        ;;
    esac
    ;;
policy)
    printf '%s:\n' "$2"
    printf '  Candidate: 2.1.0\n'
    exit 0
    ;;
*)
    exit 99
    ;;
esac
STUB

    cat >"${FAKE_BIN}/dpkg" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "--compare-versions" ]]; then
    exit 0
fi
exit 99
STUB

    cat >"${FAKE_BIN}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf 'apt-get should not have been called: %s\n' "$*" >>"${PHASE9_MUTATION_LOG}"
exit 42
STUB

    cat >"${FAKE_BIN}/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo should not have been called: %s\n' "$*" >>"${PHASE9_MUTATION_LOG}"
exit 42
STUB

    cat >"${FAKE_BIN}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
printf 'dpkg-query should not have been called: %s\n' "$*" >>"${PHASE9_MUTATION_LOG}"
exit 42
STUB

    chmod +x \
        "${FAKE_BIN}/apt-cache" \
        "${FAKE_BIN}/apt-get" \
        "${FAKE_BIN}/dpkg" \
        "${FAKE_BIN}/dpkg-query" \
        "${FAKE_BIN}/sudo"
}

@test "dry-run resolves package intent without invoking execution tools" {
    write_resolver_stubs
    manifest="${WORK_DIR}/packages.txt"
    mutation_log="${WORK_DIR}/mutation.log"
    printf 'git\njq >= 1.6\n' >"$manifest"

    run env \
        PATH="${FAKE_BIN}:$PATH" \
        PHASE9_MUTATION_LOG="$mutation_log" \
        "$SCRIPT" --dry-run --package-manager apt "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: $manifest"* ]]
    [[ "$output" == *"install package: git"* ]]
    [[ "$output" == *"apt would install package: jq (>= 1.6)"* ]]
    [[ "$output" == *"Summary: 2 action(s) planned; 2 action(s) resolved."* ]]
    [ ! -e "$mutation_log" ]
}

@test "execution stops during resolution when a package is unavailable" {
    write_resolver_stubs
    manifest="${WORK_DIR}/missing.txt"
    mutation_log="${WORK_DIR}/mutation.log"
    printf 'missing-package\n' >"$manifest"

    run env \
        PATH="${FAKE_BIN}:$PATH" \
        PHASE9_MUTATION_LOG="$mutation_log" \
        "$SCRIPT" --package-manager apt "$manifest"

    [ "$status" -eq 69 ]
    [[ "$output" == *"apt package not available: missing-package"* ]]
    [ ! -e "$mutation_log" ]
}

@test "execution of an empty manifest reports zero executed actions" {
    write_resolver_stubs
    manifest="${WORK_DIR}/empty.txt"
    mutation_log="${WORK_DIR}/mutation.log"
    : >"$manifest"

    run env \
        PATH="${FAKE_BIN}:$PATH" \
        PHASE9_MUTATION_LOG="$mutation_log" \
        "$SCRIPT" --package-manager apt "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Execution results:"* ]]
    [[ "$output" == *"no actions executed"* ]]
    [[ "$output" == *"total:             0"* ]]
    [ ! -e "$mutation_log" ]
}
