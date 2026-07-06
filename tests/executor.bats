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

@test "executor consumes resolved actions but does not execute unsupported framework work yet" {
    run bash -c "source '$SCRIPT'; printf 'install-package|apt|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 69 ]
    [[ "$output" == *"not-executed|69|install-package|apt|git|executor backend is not implemented"* ]]
}

@test "executor preserves package identity in not-implemented results" {
    run bash -c "source '$SCRIPT'; printf 'install-package|apt|openssl|>=|3.0|packages.txt|7\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 69 ]
    [[ "$output" == *"not-executed|69|install-package|apt|openssl|executor backend is not implemented"* ]]
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
