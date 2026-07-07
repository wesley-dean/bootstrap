#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-dry-run"
    mkdir -p "$WORK_DIR"
}

@test "dry-run manifest output renders abstract package actions" {
    manifest="${WORK_DIR}/packages.txt"
    cat >"$manifest" <<'MANIFEST'
git
curl
MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: $manifest"* ]]
    [[ "$output" == *"Planned actions:"* ]]
    [[ "$output" == *"install package: git"* ]]
    [[ "$output" == *"install package: curl"* ]]
    [[ "$output" == *"Resolved actions:"* ]]
    [[ "$output" == *"apt would install package: git"* ]]
    [[ "$output" == *"apt would install package: curl"* ]]
    [[ "$output" == *"Summary: 2 action(s) planned; 2 action(s) resolved."* ]]
}

@test "dry-run manifest output preserves version constraints" {
    manifest="${WORK_DIR}/versions.txt"
    cat >"$manifest" <<'MANIFEST'
openssl >= 3.0
MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"install package: openssl (>= 3.0)"* ]]
    [[ "$output" == *"apt would install package: openssl (>= 3.0)"* ]]
}

@test "dry-run explain output describes abstract planning boundary" {
    manifest="${WORK_DIR}/explain.txt"
    cat >"$manifest" <<'MANIFEST'
jq
MANIFEST

    run "$SCRIPT" --dry-run --explain "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Explanation:"* ]]
    [[ "$output" == *"What happened: bootstrap inspected the manifest"* ]]
    [[ "$output" == *"Safety boundary: --dry-run is active"* ]]
    [[ "$output" == *"Package manager selector: auto"* ]]
    [[ "$output" == *"How to read this output:"* ]]
    [[ "$output" == *"Why these actions are planned:"* ]]
    [[ "$output" == *"$manifest:1 requested package jq"* ]]
    [[ "$output" == *"Planner action: install-package"* ]]
    [[ "$output" == *"Why these package-manager decisions were made:"* ]]
    [[ "$output" == *"$manifest:1 would be handled by package manager: apt"* ]]
    [[ "$output" == *"Executor has not run"* ]]
}

@test "dry-run empty manifest reports no planned package actions" {
    manifest="${WORK_DIR}/empty.txt"
    cat >"$manifest" <<'MANIFEST'
# Nothing here yet

MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"no package actions planned"* ]]
    [[ "$output" == *"no package actions resolved"* ]]
    [[ "$output" == *"Summary: 0 action(s) planned; 0 action(s) resolved."* ]]
}

@test "dry-run manifest propagates parser failures" {
    manifest="${WORK_DIR}/invalid.txt"
    cat >"$manifest" <<'MANIFEST'
git curl
MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
    [[ "$output" == *"location: $manifest:1"* ]]
    [[ "$output" == *"expected: PACKAGE or PACKAGE OPERATOR VERSION"* ]]
    [[ "$output" == *"next step:"* ]]
}

@test "dry-run accepts the manifest argument before operational flags" {
    manifest="${WORK_DIR}/ordered.txt"
    cat >"$manifest" <<'MANIFEST'
make
MANIFEST

    run "$SCRIPT" "$manifest" --dry-run

    [ "$status" -eq 0 ]
    [[ "$output" == *"install package: make"* ]]
}

@test "dry-run rejects multiple manifest arguments" {
    first="${WORK_DIR}/first.txt"
    second="${WORK_DIR}/second.txt"
    printf 'git\n' >"$first"
    printf 'curl\n' >"$second"

    run "$SCRIPT" --dry-run "$first" "$second"

    [ "$status" -eq 64 ]
    [[ "$output" == *"unexpected argument: $second"* ]]
}
