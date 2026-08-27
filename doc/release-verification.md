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

Each executable in a current release has a corresponding `.sha256` checksum file:

```text
bootstrap.dev.bash.sha256
bootstrap.bash.sha256
bootstrap.min.bash.sha256
```

All six files are included in release attestation scope.

Historical releases that published `.256` checksum companions remain unchanged.
When verifying one of those releases, use the checksum filename actually attached
to that release. Consumers that automate verification across release generations
should prefer `.sha256` and use `.256` only when the preferred companion is
confirmed absent; transport, authorization, server, malformed-content, and
checksum-verification failures remain failures rather than fallback conditions.

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

Published release checksum companions do not replace the committed SHA-256
digests that authorize build/development dependencies. See ADR-051 for the
dependency trust and target boundaries, ADR-052 for the three-flavor release
decision, and ADR-053 for checksum companion naming and historical-read
compatibility.

## Verify a SHA-256 checksum

Download the executable flavor you want and its matching `.sha256` file from the
same current GitHub release. For the ordinary artifact:

```bash
sha256sum -c bootstrap.bash.sha256
```

A successful result reports:

```text
bootstrap.bash: OK
```

The same pattern applies to the development and minified flavors:

```bash
sha256sum -c bootstrap.dev.bash.sha256
sha256sum -c bootstrap.min.bash.sha256
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

The release workflow also attests each `.sha256` checksum file, which may be
verified separately with the same `gh attestation verify` command.

Verification should fail closed. Do not execute an artifact when its checksum or
attestation does not verify successfully.
