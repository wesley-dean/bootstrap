# Release Verification

Bootstrap releases include a generated executable, a SHA-256 checksum, and a
GitHub build provenance attestation. These mechanisms answer related but
different questions about a downloaded release.

The checksum confirms that the downloaded file matches the digest published
with the release. The signed provenance attestation binds the artifact digest
to the GitHub Actions workflow that produced it in the
`wesley-dean/bootstrap` repository.

Neither mechanism establishes that the source code is free from defects. Users
should continue to inspect the release artifact before executing it, especially
when Bootstrap will run with elevated privileges.

## Release build dependency preparation

The release workflow explicitly prepares repository build/development dependency
state before release validation. It runs:

```bash
make deps
make deps-check
```

before constructing the release artifact. The Makefile independently verifies the
pinned released `vendor/bashdeps.bash` bootstrap, and bashdeps verifies the
ordinary external artifacts declared in `dependencies.txt`.

This dependency relationship is build-time only. `make build` does not acquire or
verify external dependencies, and the published `bootstrap.bash` artifact remains
functional without bashdeps, `dependencies.txt`, or the generated `vendor/` tree.
The release workflow verifies that isolation before attestation and publication.

See ADR-051 for the trust and target boundaries governing this process.

## Verify the SHA-256 checksum

Download `bootstrap.bash` and `bootstrap.bash.sha256` from the same GitHub
release, place them in the same directory, and run:

```bash
sha256sum -c bootstrap.bash.sha256
```

A successful result reports:

```text
bootstrap.bash: OK
```

## Verify the GitHub build provenance attestation

Install and authenticate the GitHub CLI, then verify the executable against the
canonical repository:

```bash
gh attestation verify bootstrap.bash \
  --repo wesley-dean/bootstrap
```

The release workflow also attests the checksum file. It may be verified
separately:

```bash
gh attestation verify bootstrap.bash.sha256 \
  --repo wesley-dean/bootstrap
```

Verification should fail closed. Do not execute an artifact when its checksum
or attestation does not verify successfully.
