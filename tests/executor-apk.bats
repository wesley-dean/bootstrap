#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
}

@test "executor skips apk add when apk package is already installed" {
    fake_bin="${TEST_TMPDIR}/bin"
    apk_log="${TEST_TMPDIR}/apk.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 0
fi
printf '%s\n' "$*" >>"${APK_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}:$PATH" APK_LOG="$apk_log" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apk|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"already-satisfied|0|install-package|apk|git|package already installed"* ]]
    [ ! -e "$apk_log" ]
}

@test "executor invokes apk add for missing apk packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/apk.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 1
fi
printf '%s\n' "$*" >>"${APK_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}:$PATH" APK_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apk|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"success|0|install-package|apk|git|package installation completed"* ]]
    [ "$(cat "$log_file")" = "add git" ]
}

@test "executor preserves package identity in apk failure results" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 1
fi
exit 42
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}:$PATH" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apk|openssl||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"failed|70|install-package|apk|openssl|apk exited with status 42"* ]]
}

@test "executor reports privilege failure before apk add runs" {
    fake_bin="${TEST_TMPDIR}/bin"
    apk_log="${TEST_TMPDIR}/apk.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/bin/sh
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 1
fi
printf '%s\n' "$*" >>"${APK_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}" APK_LOG="$apk_log" "$BASH" -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '1000\n'; }; printf 'install-package|apk|nano||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 71 ]
    [[ "$output" == *"privilege escalation requires sudo or doas"* ]]
    [[ "$output" == *"failed|71|install-package|apk|nano|privilege escalation unavailable"* ]]
    [ ! -e "$apk_log" ]
}

@test "executor provides recovery guidance when apk fails" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/bin/sh
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 1
fi
exit 99
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}" "$BASH" -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apk|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"apk exited with status 99"* ]]
    [[ "$output" == *"bootstrap.bash: recovery: Run the native command directly for full details: sudo apk add git"* ]]
}

@test "executor applies the configured timeout to apk installs" {
    fake_bin="${TEST_TMPDIR}/bin"
    timeout_log="${TEST_TMPDIR}/timeout.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "info" ] && [ "$2" = "-e" ]; then
    exit 1
fi
exit 0
STUB
    cat >"${fake_bin}/timeout" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${TIMEOUT_LOG}"
exit 124
STUB
    chmod +x "${fake_bin}/apk" "${fake_bin}/timeout"

    run env PATH="${fake_bin}:$PATH" TIMEOUT_LOG="$timeout_log" BOOTSTRAP_INSTALL_TIMEOUT=8 bash -c "source '$SCRIPT'; bootstrap_context_reset; bootstrap_config_apply_environment; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|apk|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"package installation timed out after 8 seconds"* ]]
    [ "$(cat "$timeout_log")" = "8 apk add git" ]
}
