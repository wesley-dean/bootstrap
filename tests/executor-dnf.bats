#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
}

@test "executor skips dnf install when rpm package is already installed" {
    fake_bin="${TEST_TMPDIR}/bin"
    dnf_log="${TEST_TMPDIR}/dnf.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/rpm" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DNF_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/rpm" "${fake_bin}/dnf"

    run env PATH="${fake_bin}:$PATH" DNF_LOG="$dnf_log" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|dnf|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"already-satisfied|0|install-package|dnf|git|package already installed"* ]]
    [ ! -e "$dnf_log" ]
}

@test "executor invokes dnf install for missing dnf packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/dnf.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/rpm" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DNF_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/rpm" "${fake_bin}/dnf"

    run env PATH="${fake_bin}:$PATH" DNF_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|dnf|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 0 ]
    [[ "$output" == *"success|0|install-package|dnf|git|package installation completed"* ]]
    [ "$(cat "$log_file")" = "install -y git" ]
}

@test "executor preserves package identity in dnf failure results" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/rpm" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
exit 42
STUB
    chmod +x "${fake_bin}/rpm" "${fake_bin}/dnf"

    run env PATH="${fake_bin}:$PATH" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|dnf|openssl||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"failed|70|install-package|dnf|openssl|dnf exited with status 42"* ]]
}

@test "executor reports privilege failure before dnf install runs" {
    fake_bin="${TEST_TMPDIR}/bin"
    dnf_log="${TEST_TMPDIR}/dnf.log"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/rpm" <<'STUB'
#!/bin/sh
exit 1
STUB
    cat >"${fake_bin}/dnf" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${DNF_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/rpm" "${fake_bin}/dnf"

    run env PATH="${fake_bin}" DNF_LOG="$dnf_log" "$BASH" -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '1000\n'; }; printf 'install-package|dnf|nano||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 71 ]
    [[ "$output" == *"privilege escalation requires sudo or doas"* ]]
    [[ "$output" == *"failed|71|install-package|dnf|nano|privilege escalation unavailable"* ]]
    [ ! -e "$dnf_log" ]
}

@test "executor provides recovery guidance when dnf fails" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/rpm" <<'STUB'
#!/bin/sh
exit 1
STUB
    cat >"${fake_bin}/dnf" <<'STUB'
#!/bin/sh
exit 99
STUB
    chmod +x "${fake_bin}/rpm" "${fake_bin}/dnf"

    run env PATH="${fake_bin}" "$BASH" -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; printf 'install-package|dnf|git||||\n' | bootstrap_executor_execute_resolved_actions"

    [ "$status" -eq 70 ]
    [[ "$output" == *"dnf exited with status 99"* ]]
    [[ "$output" == *"bootstrap.bash: recovery: Run the native command directly for full details: sudo dnf install -y git"* ]]
}
