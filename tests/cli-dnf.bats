#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    TEST_TMPDIR="$(bootstrap_test_tmpdir)"
    WORK_DIR="${TEST_TMPDIR}/cli-dnf"
    mkdir -p "$WORK_DIR"
}

create_dnf_list_stub() {
    fake_bin="$1"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "-q" ]
[ "$2" = "list" ]
case "$3" in
  git|curl|jq)
    printf 'Available Packages\n%s.x86_64 1.0 fedora\n' "$3"
    exit 0
    ;;
esac
exit 1
STUB
    chmod +x "${fake_bin}/dnf"
}

@test "cli dry-run resolves explicit dnf manifest through dnf backend" {
    fake_bin="${TEST_TMPDIR}/bin"
    manifest="${WORK_DIR}/packages.txt"
    create_dnf_list_stub "$fake_bin"
    cat >"$manifest" <<'MANIFEST'
git
curl
MANIFEST

    run env PATH="${fake_bin}:$PATH" "$SCRIPT" --package-manager dnf --dry-run "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: $manifest"* ]]
    [[ "$output" == *"dnf would install package: git"* ]]
    [[ "$output" == *"dnf would install package: curl"* ]]
    [[ "$output" == *"Summary: 2 action(s) planned; 2 action(s) resolved."* ]]
}

@test "cli explain output reports explicit dnf selector and dnf resolution" {
    fake_bin="${TEST_TMPDIR}/bin"
    manifest="${WORK_DIR}/explain.txt"
    create_dnf_list_stub "$fake_bin"
    printf 'git\n' >"$manifest"

    run env PATH="${fake_bin}:$PATH" "$SCRIPT" --package-manager dnf --dry-run --explain "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Package manager selector: dnf"* ]]
    [[ "$output" == *"dnf would install package: git"* ]]
    [[ "$output" == *"$manifest:1 would be handled by package manager: dnf"* ]]
}

@test "cli stdin manifests work with explicit dnf package manager" {
    fake_bin="${TEST_TMPDIR}/bin"
    create_dnf_list_stub "$fake_bin"

    run env PATH="${fake_bin}:$PATH" bash -c "printf 'git\n' | '$SCRIPT' --package-manager dnf --dry-run -"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run plan for manifest: -"* ]]
    [[ "$output" == *"dnf would install package: git"* ]]
}

@test "cli dnf version constraints fail before package lookup" {
    fake_bin="${TEST_TMPDIR}/bin"
    dnf_log="${TEST_TMPDIR}/dnf.log"
    manifest="${WORK_DIR}/versions.txt"
    mkdir -p "$fake_bin"
    cat >"${fake_bin}/dnf" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DNF_LOG}"
exit 0
STUB
    chmod +x "${fake_bin}/dnf"
    printf 'git >= 2.0\n' >"$manifest"

    run env PATH="${fake_bin}:$PATH" DNF_LOG="$dnf_log" "$SCRIPT" --package-manager dnf --dry-run "$manifest"

    [ "$status" -eq 69 ]
    [[ "$output" == *"backend capability not supported: dnf version-constraints"* ]]
    [[ "$output" != *"install-package|dnf|git"* ]]
    [ ! -e "$dnf_log" ]
}
