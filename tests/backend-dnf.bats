#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    BASH_BIN="$(command -v bash)"
}

@test "backend detects dnf when apt and apk are unavailable and dnf is available" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in dnf rpm; do
        cat >"${fake_bin}/${tool}" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
        chmod +x "${fake_bin}/${tool}"
    done

    run env PATH="${fake_bin}" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_detect_package_manager"

    [ "$status" -eq 0 ]
    [ "$output" = "dnf" ]
}

@test "backend keeps apt detection before dnf when both are available" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in apt-cache apt-get dpkg dnf rpm; do
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

@test "backend keeps apk detection before dnf when apt is unavailable" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in apk dnf rpm; do
        cat >"${fake_bin}/${tool}" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
        chmod +x "${fake_bin}/${tool}"
    done

    run env PATH="${fake_bin}" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_detect_package_manager"

    [ "$status" -eq 0 ]
    [ "$output" = "apk" ]
}

@test "backend dnf package existence succeeds when dnf list finds metadata" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "-q" ]
[ "$2" = "list" ]
[ "$3" = "git" ]
exit 0
STUB
    chmod +x "${fake_bin}/dnf"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists dnf git '' ''"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend dnf package existence reports unavailable packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
    chmod +x "${fake_bin}/dnf"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists dnf missing-package '' ''"

    [ "$status" -eq 69 ]
    [[ "$output" == *"dnf package not available: missing-package"* ]]
    [[ "$output" == *"dnf search missing-package"* ]]
}

@test "resolver refuses dnf version constraints until dnf advertises version support" {
    run bash -c "source '$SCRIPT'; printf 'install-package|git|>=|2.0||\n' | bootstrap_resolver_resolve_action_records dnf"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: dnf version-constraints"* ]]
    [[ "$output" != *"install-package|dnf|git"* ]]
}

@test "backend reports dnf package availability capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability dnf package-availability"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend reports dnf package execution capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability dnf package-execution"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend does not report dnf version constraint capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability dnf version-constraints"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: dnf version-constraints"* ]]
}
