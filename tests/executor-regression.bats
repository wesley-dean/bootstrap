#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/executor-regression"
    FAKE_BIN="${WORK_DIR}/bin"
    mkdir -p "$FAKE_BIN"
}

@test "executor stops after the first apt installation failure" {
    install_log="${WORK_DIR}/apt-get.log"

    cat >"${FAKE_BIN}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB

    cat >"${FAKE_BIN}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PHASE9_INSTALL_LOG}"
exit 23
STUB

    chmod +x "${FAKE_BIN}/apt-get" "${FAKE_BIN}/dpkg-query"

    run env PATH="${FAKE_BIN}:$PATH" PHASE9_INSTALL_LOG="$install_log" bash -c "
        source '$SCRIPT'
        bootstrap_privilege_effective_uid() { printf '0\\n'; }
        printf 'install-package|apt|first||||\ninstall-package|apt|second||||\n' |
            bootstrap_executor_execute_resolved_actions
    "

    [ "$status" -eq 70 ]
    [[ "$output" == *"failed|70|install-package|apt|first|apt-get exited with status 23"* ]]
    [ "$(cat "$install_log")" = "install -y --no-install-recommends first" ]
}
