#!/usr/bin/env bats

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
}

@test "resolver converts install-package action records into apt resolved actions" {
    run bash -c "source '$SCRIPT'; printf 'install-package|git||||\n' | bootstrap_resolver_resolve_action_records apt"

    [ "$status" -eq 0 ]
    [ "$output" = "install-package|apt|git||||" ]
}

@test "resolver preserves version constraints and provenance" {
    run bash -c "source '$SCRIPT'; printf 'install-package|openssl|>=|3.0|packages.txt|7\n' | bootstrap_resolver_resolve_action_records apt"

    [ "$status" -eq 0 ]
    [ "$output" = "install-package|apt|openssl|>=|3.0|packages.txt|7" ]
}

@test "resolver detects apt when apt-get and dpkg are available" {
    if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
        skip "apt-get and dpkg are not available in this test environment"
    fi

    run bash -c "source '$SCRIPT'; bootstrap_resolver_detect_package_manager"

    [ "$status" -eq 0 ]
    [ "$output" = "apt" ]
}

@test "resolver rejects unsupported package managers" {
    run bash -c "source '$SCRIPT'; printf 'install-package|git||||\n' | bootstrap_resolver_resolve_action_records imaginary"

    [ "$status" -eq 69 ]
    [[ "$output" == *"unsupported package manager"* ]]
    [[ "$output" == *"Supported package managers in this release: auto, apt, apk, dnf."* ]]
}

@test "resolver rejects unsupported action records" {
    run bash -c "source '$SCRIPT'; printf 'configure-service|ssh||||\n' | bootstrap_resolver_resolve_action_records apt"

    [ "$status" -eq 69 ]
    [[ "$output" == *"unsupported action record"* ]]
}

@test "resolver rejects malformed action records" {
    run bash -c "source '$SCRIPT'; printf '|||||\n' | bootstrap_resolver_resolve_action_records apt"

    [ "$status" -eq 69 ]
    [[ "$output" == *"missing action type"* ]]
}
