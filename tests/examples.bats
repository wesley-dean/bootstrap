#!/usr/bin/env bats

load 'helpers'

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    SCRIPT="${REPO_ROOT}/dist/bootstrap.bash"
}

@test "example manifests are accepted by the manifest parser" {
    example_count=0

    while IFS= read -r manifest; do
        example_count=$((example_count + 1))
        run bash -c "source '$SCRIPT'; bootstrap_manifest_parse_file '$manifest'"

        [ "$status" -eq 0 ]
        [ -n "$output" ]
    done < <(find "${REPO_ROOT}/doc/examples" -type f -name '*.manifest' -print | sort)

    [ "$example_count" -gt 0 ]
}
