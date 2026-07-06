#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
}

@test "execution result constructor creates pipe-delimited records" {
    run bash -c "source '$SCRIPT'; bootstrap_execution_result_create success 0 install-package apt git 'completed without changes'"

    [ "$status" -eq 0 ]
    [ "$output" = "success|0|install-package|apt|git|completed without changes" ]
}

@test "executor skips apt-get when apt package is already installed" {
    fake_bin="${TEST_TMPDIR}/bin"
    apt_log="${TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
printf 'install ok installed\n'
exit 0
STUB
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${APT_GET_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/dpkg-query" "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$apt_log" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apt|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"already-satisfied|0|install-package|apt|git|package already installed"* ]]
    [ ! -e "$apt_log" ]
}

@test "executor invokes apt-get for missing apt packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${APT_GET_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/dpkg-query" "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apt|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"success|0|install-package|apt|git|package installation completed"* ]]
    [ "$(cat "$log_file")" = "install -y git" ]
}

@test "executor preserves package identity in apt failure results" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dpkg-query" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/usr/bin/env bash
exit 42
STUB
    chmod +x "${fake_bin}/dpkg-query" "${fake_bin}/apt-get"

    run env PATH="${fake_bin}:$PATH" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apt|openssl|>=|3.0|packages.txt|7\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"failed|70|install-package|apt|openssl|apt-get exited with status 42"* ]]
}

@test "executor reports privilege failure before apt-get runs" {
    fake_bin="${TEST_TMPDIR}/bin"
    apt_log="${TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dpkg-query" <<'STUB'
#!/bin/sh
exit 1
STUB
    cat >"${fake_bin}/apt-get" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${APT_GET_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/dpkg-query" "${fake_bin}/apt-get"

    run env PATH="${fake_bin}" APT_GET_LOG="$apt_log" "$BASH" -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '1000\n'; }; printf 'install-package|apt|nano||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 71 ]
    [[ "$output" == *"privilege escalation requires sudo or doas"* ]]
    [[ "$output" == *"failed|71|install-package|apt|nano|privilege escalation unavailable"* ]]
    [ ! -e "$apt_log" ]
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

@test "execution result exit code treats satisfied records as success" {
    run bash -c "source '$SCRIPT'; printf 'already-satisfied|0|install-package|apt|git|package already installed\nsuccess|0|install-package|apt|curl|package installation completed\n' | bootstrap_execution_results_exit_code"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "execution result exit code returns first failed record status" {
    run bash -c "source '$SCRIPT'; printf 'success|0|install-package|apt|git|package installation completed\nfailed|71|install-package|apt|curl|privilege escalation unavailable\nfailed|70|install-package|apt|vim|apt-get failed\n' | bootstrap_execution_results_exit_code"

    [ "$status" -eq 71 ]
    [ -z "$output" ]
}

@test "execution result exit code fails conservatively for unknown statuses" {
    run bash -c "source '$SCRIPT'; printf 'surprising|0|install-package|apt|git|unexpected result\n' | bootstrap_execution_results_exit_code"

    [ "$status" -eq 70 ]
    [ -z "$output" ]
}

@test "execution result constructor rejects reserved pipe delimiters" {
    run bash -c "source '$SCRIPT'; bootstrap_execution_result_create success 0 install-package apt git 'message with | delimiter'"

    [ "$status" -eq 69 ]
    [[ "$output" == *"execution result message contains reserved delimiter"* ]]
}

@test "execution result constructor rejects non-numeric exit codes" {
    run bash -c "source '$SCRIPT'; bootstrap_execution_result_create failed nope install-package apt git 'bad exit code'"

    [ "$status" -eq 69 ]
    [[ "$output" == *"execution result exit code is not numeric: nope"* ]]
}

@test "execution result constructor rejects exit codes outside shell range" {
    run bash -c "source '$SCRIPT'; bootstrap_execution_result_create failed 300 install-package apt git 'bad exit code'"

    [ "$status" -eq 69 ]
    [[ "$output" == *"execution result exit code is outside 0-255: 300"* ]]
}

@test "execution result exit code fails conservatively for malformed failed records" {
    run bash -c "source '$SCRIPT'; printf 'failed|not-a-number|install-package|apt|git|bad record\n' | bootstrap_execution_results_exit_code"

    [ "$status" -eq 70 ]
    [ -z "$output" ]
}

@test "execution result exit code fails conservatively for malformed not-executed records" {
    run bash -c "source '$SCRIPT'; printf 'not-executed|not-a-number|install-package|apt|git|bad record\n' | bootstrap_execution_results_exit_code"

    [ "$status" -eq 69 ]
    [ -z "$output" ]
}
