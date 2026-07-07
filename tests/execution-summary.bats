#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/execution-summary"
    FAKE_BIN="${WORK_DIR}/bin"
    mkdir -p "$FAKE_BIN"
}

write_execution_stubs() {
    cat >"${FAKE_BIN}/apt-cache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
show)
    printf 'Package: %s\n' "$2"
    exit 0
    ;;
policy)
    printf '%s:\n' "$2"
    printf '  Candidate: 1.0\n'
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

    cat >"${FAKE_BIN}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
case "$3" in
already-present)
    printf 'install ok installed\n'
    exit 0
    ;;
*)
    exit 1
    ;;
esac
STUB

    cat >"${FAKE_BIN}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PHASE9_APT_GET_LOG}"
exit 0
STUB

    cat >"${FAKE_BIN}/sudo" <<'STUB'
#!/usr/bin/env bash
"$@"
STUB

    chmod +x \
        "${FAKE_BIN}/apt-cache" \
        "${FAKE_BIN}/apt-get" \
        "${FAKE_BIN}/dpkg" \
        "${FAKE_BIN}/dpkg-query" \
        "${FAKE_BIN}/sudo"
}

@test "execution summary distinguishes already satisfied and installed packages" {
    write_execution_stubs
    manifest="${WORK_DIR}/packages.txt"
    install_log="${WORK_DIR}/apt-get.log"
    printf 'already-present\nnew-package\n' >"$manifest"

    run env \
        PATH="${FAKE_BIN}:$PATH" \
        PHASE9_APT_GET_LOG="$install_log" \
        "$SCRIPT" --package-manager apt "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Execution results:"* ]]
    [[ "$output" == *"apt install-package package already-present: package already installed"* ]]
    [[ "$output" == *"apt install-package package new-package: package installation completed"* ]]
    [[ "$output" == *"total:             2"* ]]
    [[ "$output" == *"already satisfied: 1"* ]]
    [[ "$output" == *"installed:         1"* ]]
    [[ "$output" == *"failed:            0"* ]]
    [[ "$output" == *"not executed:      0"* ]]
    [ "$(cat "$install_log")" = "install -y new-package" ]
}
