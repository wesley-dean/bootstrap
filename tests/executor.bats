#!/usr/bin/env bats

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
}

@test "execution result constructor creates pipe-delimited records" {
    run bash -c "source '$SCRIPT'; bootstrap_execution_result_create success 0 install-package apt git 'completed without changes'"

    [ "$status" -eq 0 ]
    [ "$output" = "success|0|install-package|apt|git|completed without changes" ]
}

@test "executor invokes apt-get for apt install-package resolved actions" {
    fake_bin="${BATS_TEST_TMPDIR}/bin"
    log_file="${BATS_TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${APT_GET_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" bash -c "source '$SCRIPT'; printf 'install-package|apt|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"success|0|install-package|apt|git|package installation completed"* ]]
    [ "$(cat "$log_file")" = "install -y git" ]
}

@test "executor preserves package identity in apt failure results" {
    fake_bin="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
exit 42
STUB
    chmod +x "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" bash -c "source '$SCRIPT'; printf 'install-package|apt|openssl|>=|3.0|packages.txt|7\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"failed|70|install-package|apt|openssl|apt-get exited with status 42"* ]]
}

@test "executor rejects unsupported package-manager backends" {
    run bash -c "source '$SCRIPT'; printf 'install-package|dnf|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 69 ]
    [[ "$output" == *"not-executed|69|install-package|dnf|git|unsupported executor backend"* ]]
}

@test "executor rejects malformed resolved actions" {
    run bash -c "source '$SCRIPT'; printf '||||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 69 ]
    [[ "$output" == *"missing resolved action type"* ]]
    [[ "$output" == *"not-executed|69||||missing resolved action type"* ]]
}

@test "executor rejects unsupported resolved action types" {
    run bash -c "source '$SCRIPT'; printf 'configure-service|systemd|ssh||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 69 ]
    [[ "$output" == *"unsupported resolved action: configure-service"* ]]
    [[ "$output" == *"not-executed|69|configure-service|systemd|ssh|unsupported resolved action"* ]]
}
