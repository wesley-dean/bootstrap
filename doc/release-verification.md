# Release Verification

Bootstrap releases include a generated executable, a SHA-256 checksum, and a
GitHub artifact attestation. These mechanisms answer related but different
questions about a downloaded release.

The checksum confirms that the downloaded file matches the digest published
with the release. The artifact attestation confirms that the file was produced
by the release workflow in the `wesley-dean/bootstrap` repository.

Neither mechanism establishes that the source code is free from defects. Users
should continue to inspect the release artifact before executing it, especially
when Bootstrap will run with elevated privileges.

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

## Verify the GitHub artifact attestation

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
