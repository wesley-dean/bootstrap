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
    [[ "$output" != *"install-package|apt|missing-package"* ]]
}
