#!/usr/bin/env bats

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    WORK_DIR="${BATS_TEST_TMPDIR}/cli-dry-run"
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
    [[ "$output" == *"install package: git"* ]]
    [[ "$output" == *"install package: curl"* ]]
    [[ "$output" == *"Summary: 2 action(s) planned."* ]]
}

@test "dry-run manifest output preserves version constraints" {
    manifest="${WORK_DIR}/versions.txt"
    cat >"$manifest" <<'MANIFEST'
openssl >= 3.0
MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"install package: openssl (>= 3.0)"* ]]
}

@test "dry-run explain output describes abstract planning boundary" {
    manifest="${WORK_DIR}/explain.txt"
    cat >"$manifest" <<'MANIFEST'
jq
MANIFEST

    run "$SCRIPT" --dry-run --explain "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Explanation:"* ]]
    [[ "$output" == *"abstract Action Records only"* ]]
    [[ "$output" == *"No package manager was selected"* ]]
    [[ "$output" == *"Action provenance:"* ]]
    [[ "$output" == *"$manifest:1 requested package jq"* ]]
    [[ "$output" == *"Planner action: install-package"* ]]
}

@test "dry-run empty manifest reports no planned package actions" {
    manifest="${WORK_DIR}/empty.txt"
    cat >"$manifest" <<'MANIFEST'
# Nothing here yet

MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"no package actions planned"* ]]
    [[ "$output" == *"Summary: 0 action(s) planned."* ]]
}

@test "dry-run manifest propagates parser failures" {
    manifest="${WORK_DIR}/invalid.txt"
    cat >"$manifest" <<'MANIFEST'
git curl
MANIFEST

    run "$SCRIPT" --dry-run "$manifest"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
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
