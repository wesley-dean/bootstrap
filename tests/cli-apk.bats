#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-apk"
    mkdir -p "$WORK_DIR"
}

create_apk_search_stub() {
    local fake_bin

    fake_bin="$1"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "search" ] && [ "$2" = "-q" ] && [ "$3" = "-x" ]; then
    case "$4" in
    curl|git|jq)
        printf '%s\n' "$4"
        exit 0
        ;;
    esac
fi
exit 1
STUB
    chmod +x "${fake_bin}/apk"
}

@test "cli dry-run resolves explicit apk manifest through apk backend" {
    fake_bin="${TEST_TMPDIR}/bin"
    manifest="${WORK_DIR}/packages.txt"
    create_apk_search_stub "$fake_bin"
    cat >"$manifest" <<'MANIFEST'
git
curl
MANIFEST

    run env PATH="${fake_bin}:$PATH" "$SCRIPT" --package-manager apk --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: $manifest"* ]]
    [[ "$output" == *"Planned actions:"* ]]
    [[ "$output" == *"install package: git"* ]]
    [[ "$output" == *"install package: curl"* ]]
    [[ "$output" == *"Resolved actions:"* ]]
    [[ "$output" == *"apk would install package: git"* ]]
    [[ "$output" == *"apk would install package: curl"* ]]
    [[ "$output" == *"Summary: 2 action(s) planned; 2 action(s) resolved."* ]]
}

@test "cli explain output reports explicit apk selector and apk resolution" {
    fake_bin="${TEST_TMPDIR}/bin"
    manifest="${WORK_DIR}/explain.txt"
    create_apk_search_stub "$fake_bin"
    printf 'jq\n' >"$manifest"

    run env PATH="${fake_bin}:$PATH" "$SCRIPT" --package-manager apk --dry-run --explain "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Package manager selector: apk"* ]]
    [[ "$output" == *"$manifest:1 requested package jq"* ]]
    [[ "$output" == *"$manifest:1 would be handled by package manager: apk"* ]]
    [[ "$output" == *"Executor has not run"* ]]
}

@test "cli stdin manifests work with explicit apk package manager" {
    fake_bin="${TEST_TMPDIR}/bin"
    create_apk_search_stub "$fake_bin"

    run env PATH="${fake_bin}:$PATH" bash -c "printf 'git\n' | '$SCRIPT' --package-manager apk --dry-run -"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: -"* ]]
    [[ "$output" == *"install package: git"* ]]
    [[ "$output" == *"apk would install package: git"* ]]
}

@test "cli apk version constraints fail before package lookup" {
    fake_bin="${TEST_TMPDIR}/bin"
    apk_log="${TEST_TMPDIR}/apk.log"
    manifest="${WORK_DIR}/version.txt"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/apk" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${APK_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/apk"
    printf 'git >= 2.0\n' >"$manifest"

    run env PATH="${fake_bin}:$PATH" APK_LOG="$apk_log" "$SCRIPT" --package-manager apk --dry-run "$manifest"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: apk version-constraints"* ]]
    [[ "$output" != *"install-package|apk|git"* ]]
    [ ! -e "$apk_log" ]
}
