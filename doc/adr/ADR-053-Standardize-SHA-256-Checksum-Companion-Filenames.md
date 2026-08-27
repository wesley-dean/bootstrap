# ADR-053: Standardize SHA-256 Checksum Companion Filenames

Date: 2026-08-27

## Status

Accepted

## Intent and Documentation Posture

This ADR standardizes Bootstrap release checksum companions on the
self-describing `.sha256` suffix while preserving verification of historical
releases that published `.256` companions.

The decision is deliberately narrow. It changes checksum filenames, not the
SHA-256 algorithm, checksum-file syntax, three-flavor release model, provenance
attestation, dependency trust model, or Bootstrap runtime behavior.

This ADR supersedes only the checksum-filename portions of ADR-052. ADR-052
remains authoritative for the development, stripped, and minified executable
flavors and the six-file release model.

## Context

ADR-052 established three executable release artifacts and one SHA-256 companion
for each:

```text
bootstrap.dev.bash.256
bootstrap.bash.256
bootstrap.min.bash.256
```

The `.256` suffix is usable because checksum tools do not require a particular
filename extension. It is nevertheless less explicit than `.sha256`: the latter
identifies the digest algorithm directly in the filename and is now the common
convention across the related Bash projects maintained alongside Bootstrap.

Historical releases are immutable records. Renaming or duplicating their assets
would create avoidable churn and would not improve the integrity of already
published bytes. Compatibility therefore belongs on the read side rather than by
publishing both suffixes for new releases.

Bootstrap's build dependency trust boundary is separate. ADR-051 makes the
SHA-256 digests committed in the Makefile and `dependencies.txt` authoritative for
approved external build/development bytes. Published checksum sidecars do not
replace those committed trust data.

## Decision Drivers

- Make the checksum algorithm evident from the companion filename.
- Use one checksum naming convention across related Bash projects.
- Preserve one checksum companion per executable release artifact.
- Preserve conventional `sha256sum` / `shasum -a 256` contents.
- Preserve the six-file release model established by ADR-052.
- Avoid publishing duplicate `.sha256` and `.256` companions.
- Keep historical releases verifiable without rewriting them.
- Fail closed rather than treating unrelated retrieval or verification failures as
  evidence that a legacy filename should be tried.
- Preserve committed digests as the authority for build dependencies.

## Decision

### Publish `.sha256` companions for new builds and releases

A successful `make build` SHALL produce exactly these checksum companions:

```text
dist/bootstrap.dev.bash.sha256
dist/bootstrap.bash.sha256
dist/bootstrap.min.bash.sha256
```

Together with the executable flavors, the build continues to produce six current
release files:

```text
dist/bootstrap.dev.bash
dist/bootstrap.bash
dist/bootstrap.min.bash
dist/bootstrap.dev.bash.sha256
dist/bootstrap.bash.sha256
dist/bootstrap.min.bash.sha256
```

Each `.sha256` file SHALL contain the digest and corresponding executable basename
in conventional checksum-tool format.

New releases SHALL publish only the `.sha256` companion for each executable. They
SHALL NOT publish duplicate `.256` companions for transitional compatibility.

A successful build SHALL remove stale `.256` companions for the three current
executable filenames so a working tree containing output from the prior naming
convention does not appear to contain two current checksum contracts.

### Preserve historical releases through read-side compatibility

Existing release assets SHALL NOT be rewritten solely to adopt the new suffix.

A consumer that retrieves checksum companions across both naming eras SHOULD
request `<artifact>.sha256` first. It MAY retry `<artifact>.256` only when the
preferred resource is confirmed absent, such as an HTTP 404 for the preferred
release asset.

Fallback SHALL NOT occur because of transport, TLS, authorization, server,
malformed-content, or checksum-verification failures. Those conditions remain
failures.

Bootstrap currently does not use published checksum sidecars to authorize its
build dependencies, so no new runtime or dependency-download fallback mechanism
is introduced by this ADR.

### Preserve committed-digest dependency trust

The Makefile SHALL continue to authorize its `vendor/bashdeps.bash` bootstrap with
the SHA-256 digest committed in repository source.

`dependencies.txt` SHALL continue to authorize manifest-managed artifacts through
committed `digest=sha256:...` values.

Neither Make nor bashdeps SHALL dynamically substitute a digest fetched from a
`.sha256` or `.256` release sidecar for those committed expected values as a
consequence of this naming change.

### Verify exact release checksums before publication

Release automation SHALL verify the three final release-version `.sha256` files
before provenance attestation and publication.

CI and build-specific regression tests SHALL verify that every `.sha256`
companion matches its adjacent executable and that current builds do not retain
legacy `.256` companions for those executables.

## Considered Alternatives

### Keep `.256`

This would preserve ADR-052 unchanged but keep a less self-describing suffix and
an unnecessary naming difference from related projects. It is rejected.

### Publish both `.sha256` and `.256`

This would avoid read-side compatibility logic for consumers that hard-code the
old suffix, but it would duplicate the same digest information and expand the
current release surface beyond the six files defined by ADR-052. It is rejected.

### Fall back to `.256` after any `.sha256` retrieval failure

A generic fallback would conflate absence with network, authorization, server, or
verification failures and could conceal a real problem. Compatibility fallback is
therefore limited to confirmed absence.

### Replace per-artifact companions with an aggregate checksum file

An aggregate `SHA256SUMS` file is a common alternative, but ADR-052 deliberately
established one checksum companion per executable. This decision changes only the
filename suffix and does not revisit that relationship.

### Trust published sidecars for build dependencies

Using remote checksum sidecars as live authorization would move the dependency
trust decision from reviewed repository source to remote state and conflict with
ADR-051. It is rejected.

## Consequences

New Bootstrap releases expose self-describing `.sha256` checksum filenames while
retaining the same digest algorithm, checksum contents, executable flavors,
artifact count, and provenance model.

Historical `.256` release assets remain available and valid for their original
releases.

Developers rebuilding in a working tree with old checksum outputs do not retain
those obsolete companions after a successful build.

The release workflow performs an explicit checksum verification of the exact
release-version artifacts before attestation and upload.

The build dependency model remains unchanged: committed SHA-256 digests continue
to authorize external development artifacts.

## Superseded Decisions

This ADR supersedes ADR-052 only where ADR-052:

- names `.256` as the checksum companion suffix;
- requires `.256` files in build-specific validation; and
- requires `.256` files in release publication and attestation scope.

All other ADR-052 decisions remain in force.

ADR-051 remains authoritative for build dependency acquisition and committed
digest trust. ADR-029 remains authoritative for reproducible and verifiable
release goals.

## Related Decisions

- Related to: ADR-029 (reproducible and verifiable releases)
- Related to: ADR-051 (build dependency trust)
- Supersedes checksum-filename portions of: ADR-052
