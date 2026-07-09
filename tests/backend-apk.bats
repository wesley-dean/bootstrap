#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    BASH_BIN="$(command -v bash)"
}

@test "backend detects apk when apt is unavailable and apk is available" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_detect_package_manager"

    [ "$status" -eq 0 ]
    [ "$output" = "apk" ]
}

@test "backend keeps apt detection before apk when both are available" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in apt-cache apt-get dpkg apk; do
        cat >"${fake_bin}/${tool}" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
        chmod +x "${fake_bin}/${tool}"
    done

    run env PATH="${fake_bin}" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_detect_package_manager"

    [ "$status" -eq 0 ]
    [ "$output" = "apt" ]
}

@test "backend apk package existence succeeds when apk search returns exact package metadata" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "search" ]
[ "$2" = "-q" ]
[ "$3" = "-x" ]
[ "$4" = "git" ]
printf 'git-2.45.2-r0\n'
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apk git '' ''"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend apk package existence reports unavailable packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "${fake_bin}/apk"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apk missing-package '' ''"

    [ "$status" -eq 69 ]
    [[ "$output" == *"apk package not available: missing-package"* ]]
    [[ "$output" == *"bootstrap.bash: recovery: Verify that the package name in the manifest is spelled correctly."* ]]
    [[ "$output" == *"apk search missing-package"* ]]
}

@test "resolver refuses apk version constraints until apk advertises version support" {
    run bash -c "source '$SCRIPT'; printf 'install-package|git|>=|2.0||\n' | bootstrap_resolver_resolve_action_records apk"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: apk version-constraints"* ]]
    [[ "$output" != *"install-package|apk|git"* ]]
}

@test "backend reports apk package availability capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apk package-availability"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend reports apk package execution capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apk package-execution"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend does not report apk version constraint capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apk version-constraints"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: apk version-constraints"* ]]
}
