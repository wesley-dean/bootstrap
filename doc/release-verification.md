# Release Verification

Bootstrap releases include three generated executable flavors, a SHA-256 checksum
for each executable, and GitHub build provenance attestations. These mechanisms
answer related but different questions about a downloaded release.

The checksum confirms that the downloaded file matches the digest published with
the release. The signed provenance attestation binds the artifact digest to the
GitHub Actions workflow that produced it in the `wesley-dean/bootstrap`
repository.

Neither mechanism establishes that the source code is free from defects. Users
should continue to inspect the release artifact before executing it, especially
when Bootstrap will run with elevated privileges.

## Release artifact flavors

Each release publishes these executable representations of the same Bootstrap
program:

```text
bootstrap.dev.bash
bootstrap.bash
bootstrap.min.bash
```

`bootstrap.dev.bash` retains the fully assembled comments,
`bootstrap.bash` is the ordinary/default full-line-comment-stripped artifact, and
`bootstrap.min.bash` is derived from the stripped artifact using the pinned
Bash-Minifier build dependency.

Each executable has a corresponding `.256` checksum file:

```text
bootstrap.dev.bash.256
bootstrap.bash.256
bootstrap.min.bash.256
```

All six files are included in release attestation scope.

## Release build dependency preparation

The release workflow explicitly prepares repository build/development dependency
state before release validation. It runs:

```bash
make deps
make deps-check
```

before constructing the release artifacts. The Makefile independently verifies
the pinned released `vendor/bashdeps.bash` bootstrap, and bashdeps verifies the
ordinary external artifacts declared in `dependencies.txt`, including the
commit-pinned Bash-Minifier input used by `make build`.

This dependency relationship is build-time only. `make build` does not acquire or
verify external dependencies. After construction, all three published executable
flavors remain functional without bashdeps, Bash-Minifier, `dependencies.txt`, or
the generated `vendor/` tree. The release workflow verifies that isolation before
attestation and publication.

See ADR-051 for the dependency trust and target boundaries and ADR-052 for the
three-flavor release decision.

## Verify a SHA-256 checksum

Download the executable flavor you want and its matching `.256` file from the same
GitHub release. For the ordinary artifact:

```bash
sha256sum -c bootstrap.bash.256
```

A successful result reports:

```text
bootstrap.bash: OK
```

The same pattern applies to the development and minified flavors:

```bash
sha256sum -c bootstrap.dev.bash.256
sha256sum -c bootstrap.min.bash.256
```

## Verify the GitHub build provenance attestation

Install and authenticate the GitHub CLI, then verify the executable against the
canonical repository. For the ordinary artifact:

```bash
gh attestation verify bootstrap.bash \
  --repo wesley-dean/bootstrap
```

The development and minified executables may be verified the same way:

```bash
gh attestation verify bootstrap.dev.bash \
  --repo wesley-dean/bootstrap

gh attestation verify bootstrap.min.bash \
  --repo wesley-dean/bootstrap
```

The release workflow also attests each `.256` checksum file, which may be verified
separately with the same `gh attestation verify` command.

Verification should fail closed. Do not execute an artifact when its checksum or
attestation does not verify successfully.
