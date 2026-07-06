#!/usr/bin/env bats

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
    WORK_DIR="${BATS_TEST_TMPDIR}/manifest"
    mkdir -p "$WORK_DIR"
}

@test "manifest parser ignores blank lines and comments" {
    manifest="${WORK_DIR}/comments.txt"
    cat >"$manifest" <<'MANIFEST'
# Development packages

   # Indented comment
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "manifest parser parses package-only requirements" {
    manifest="${WORK_DIR}/packages.txt"
    cat >"$manifest" <<'MANIFEST'
git
vim-gtk3
python3-venv
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "git|||$manifest|1" ]
    [ "${lines[1]}" = "vim-gtk3|||$manifest|2" ]
    [ "${lines[2]}" = "python3-venv|||$manifest|3" ]
}

@test "manifest parser removes inline comments" {
    manifest="${WORK_DIR}/inline-comments.txt"
    cat >"$manifest" <<'MANIFEST'
dnsutils      # provides dig and nslookup
whois         # lookup utility
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "dnsutils|||$manifest|1" ]
    [ "${lines[1]}" = "whois|||$manifest|2" ]
}

@test "manifest parser parses supported version constraints" {
    manifest="${WORK_DIR}/versions.txt"
    cat >"$manifest" <<'MANIFEST'
openssl>=3.0
foo == 1.2.3
bar = 2.0
baz > 1.0
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "openssl|>=|3.0|$manifest|1" ]
    [ "${lines[1]}" = "foo|==|1.2.3|$manifest|2" ]
    [ "${lines[2]}" = "bar|=|2.0|$manifest|3" ]
    [ "${lines[3]}" = "baz|>|1.0|$manifest|4" ]
}

@test "manifest parser rejects unsupported operators" {
    manifest="${WORK_DIR}/unsupported-operator.txt"
    cat >"$manifest" <<'MANIFEST'
git <= 3.0
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
}

@test "manifest parser rejects extra tokens" {
    manifest="${WORK_DIR}/extra-tokens.txt"
    cat >"$manifest" <<'MANIFEST'
git curl
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
}

@test "manifest parser rejects reserved pipe delimiter" {
    manifest="${WORK_DIR}/pipe.txt"
    cat >"$manifest" <<'MANIFEST'
git|curl
MANIFEST

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"malformed manifest line"* ]]
}

@test "manifest parser rejects unreadable manifests" {
    manifest="${WORK_DIR}/missing.txt"

    run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

    [ "$status" -eq 65 ]
    [[ "$output" == *"cannot read manifest"* ]]
}
