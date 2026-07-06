#!/usr/bin/env bash

bootstrap_test_tmpdir() {
    local base

    base="${BATS_TEST_TMPDIR:-}"
    if [[ -z "$base" ]]; then
        base="${BATS_TMPDIR:-}"
    fi
    if [[ -z "$base" ]]; then
        base="${TMPDIR:-/tmp}/bootstrap-bats-${$}"
    fi

    mkdir -p "$base"
    printf '%s\n' "$base"
}
