#!/usr/bin/env bash

bootstrap_test_tmpdir() {
    local base
    local test_dir

    base="${BATS_TEST_TMPDIR:-}"
    if [[ -z "$base" ]]; then
        base="${BATS_TMPDIR:-}"
    fi
    if [[ -z "$base" ]]; then
        base="${TMPDIR:-/tmp}/bootstrap-bats-${$}"
    fi

    mkdir -p "$base"

    test_dir="$(mktemp -d "${base%/}/test.XXXXXX")"
    printf '%s\n' "$test_dir"
}
