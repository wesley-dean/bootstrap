#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-execution"
    mkdir -p "$WORK_DIR"
}

@test "execution reports major progress phases by default" {
    manifest="${WORK_DIR}/packages.txt"
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/apt-get.log"
    mkdir -p "$fake_bin"
    printf 'git\n' >"$manifest"

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

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; main '$manifest'"

    [ "$status" -eq 0 ]
    [[ "$output" == *"bootstrap.bash: planning manifest: $manifest"* ]]
    [[ "$output" == *"bootstrap.bash: resolving planned actions"* ]]
    [[ "$output" == *"bootstrap.bash: executing resolved actions"* ]]
    [[ "$output" == *"bootstrap.bash: rendering execution results"* ]]
    [[ "$output" == *"Execution results:"* ]]
}

@test "quiet execution suppresses progress but still prints results" {
    manifest="${WORK_DIR}/quiet.txt"
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/quiet-apt-get.log"
    mkdir -p "$fake_bin"
    printf 'git\n' >"$manifest"

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

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; main --quiet '$manifest'"

    [ "$status" -eq 0 ]
    [[ "$output" != *"bootstrap.bash: planning manifest"* ]]
    [[ "$output" != *"bootstrap.bash: resolving planned actions"* ]]
    [[ "$output" != *"bootstrap.bash: executing resolved actions"* ]]
    [[ "$output" == *"Execution results:"* ]]
    [[ "$output" == *"package installation completed"* ]]
}

@test "verbose execution includes implementation-level file details" {
    manifest="${WORK_DIR}/verbose.txt"
    fake_bin="${TEST_TMPDIR}/bin"
    log_file="${TEST_TMPDIR}/verbose-apt-get.log"
    mkdir -p "$fake_bin"
    printf 'git\n' >"$manifest"

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

    run env PATH="${fake_bin}:$PATH" APT_GET_LOG="$log_file" bash -c "source '$SCRIPT'; bootstrap_privilege_effective_uid() { printf '0\n'; }; main --verbose '$manifest'"

    [ "$status" -eq 0 ]
    [[ "$output" == *"bootstrap.bash: verbose: action record file:"* ]]
    [[ "$output" == *"bootstrap.bash: verbose: resolved action file:"* ]]
    [[ "$output" == *"bootstrap.bash: verbose: execution result file:"* ]]
}
