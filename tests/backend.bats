#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    BASH_BIN="$(command -v bash)"
}

@test "backend detects apt when required apt tools are available" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in apt-cache apt-get dpkg; do
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

@test "backend refuses apt detection when apt-cache is unavailable" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    for tool in apt-get dpkg; do
        cat >"${fake_bin}/${tool}" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
        chmod +x "${fake_bin}/${tool}"
    done

    run env PATH="${fake_bin}" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_detect_package_manager"

    [ "$status" -eq 69 ]
    [[ "$output" == *"no supported package manager detected"* ]]
    [[ "$output" == *"bootstrap.bash: recovery: Supported package managers in this release: apt, apk, dnf."* ]]
}

@test "backend apt package existence succeeds when apt-cache has metadata" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "show" ]
[ "$2" = "git" ]
exit 0
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apt git '' ''"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend apt package existence reports unavailable packages" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
exit 100
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apt missing-package '' ''"

    [ "$status" -eq 69 ]
    [[ "$output" == *"apt package not available: missing-package"* ]]
    [[ "$output" == *"bootstrap.bash: recovery: Verify that the package name in the manifest is spelled correctly."* ]]
    [[ "$output" == *"apt search missing-package"* ]]
}

@test "resolver refuses unavailable apt packages before creating resolved actions" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
exit 100
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; printf 'install-package|missing-package||||\n' | bootstrap_resolver_resolve_action_records apt"

    [ "$status" -eq 69 ]
    [[ "$output" == *"apt package not available: missing-package"* ]]
    [[ "$output" == *"apt search missing-package"* ]]
    [[ "$output" != *"install-package|apt|missing-package"* ]]
}

@test "backend apt package version constraint succeeds when candidate satisfies constraint" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
show)
    [ "$2" = "git" ]
    exit 0
    ;;
policy)
    [ "$2" = "git" ]
    printf 'git:\n  Installed: (none)\n  Candidate: 2.43.0-1ubuntu7\n'
    exit 0
    ;;
esac
exit 100
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apt git '>=' '2.40'"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend apt package version constraint reports unsatisfied candidates" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
show)
    [ "$2" = "git" ]
    exit 0
    ;;
policy)
    [ "$2" = "git" ]
    printf 'git:\n  Installed: (none)\n  Candidate: 2.43.0-1ubuntu7\n'
    exit 0
    ;;
esac
exit 100
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apt git '>=' '99.0'"

    [ "$status" -eq 69 ]
    [[ "$output" == *"apt package candidate does not satisfy version constraint"* ]]
    [[ "$output" == *"git candidate 2.43.0-1ubuntu7 does not match >= 99.0"* ]]
    [[ "$output" == *"apt-cache policy git"* ]]
}

@test "backend apt package exact version accepts single equals operator" {
    fake_bin="${TEST_TMPDIR}/bin"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apt-cache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
show)
    [ "$2" = "openssl" ]
    exit 0
    ;;
policy)
    [ "$2" = "openssl" ]
    printf 'openssl:\n  Installed: (none)\n  Candidate: 3.0.13-0ubuntu3.5\n'
    exit 0
    ;;
esac
exit 100
STUB
    chmod +x "${fake_bin}/apt-cache"

    run env PATH="${fake_bin}:$PATH" "${BASH_BIN}" -c "source '$SCRIPT'; bootstrap_backend_package_exists apt openssl '=' '3.0.13-0ubuntu3.5'"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend reports apt package availability capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apt package-availability"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend reports apt version constraint capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apt version-constraints"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend reports apt package execution capability" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apt package-execution"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "backend rejects unknown capabilities explicitly" {
    run bash -c "source '$SCRIPT'; bootstrap_backend_supports_capability apt imaginary-capability"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: apt imaginary-capability"* ]]
}
