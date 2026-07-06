# ADR-011: Publish Release Artifacts Through GitHub Releases

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes how the bootstrap engine
is published and distributed after it has been built.

The project distinguishes between source code, generated artifacts, and
published releases. This ADR defines the authoritative distribution
mechanism for users.

## Context

ADR-009 establishes that users consume a single executable bootstrap
script.

ADR-010 establishes that the published artifact is generated from a
modular source tree during the build process.

The remaining architectural question is how that artifact should be
delivered.

Several possibilities exist:

-   execute directly from a cloned repository;
-   commit generated artifacts to source control;
-   publish archives containing the source tree;
-   publish the generated bootstrap script as a release asset.

The project favors a distribution model that minimizes friction for
users while preserving a clean source repository.

## Decision

GitHub Releases shall be the canonical distribution mechanism for
published bootstrap artifacts.

The release workflow shall:

1.  Check out the tagged source revision.
2.  Execute the project's validation targets.
3.  Build the release artifact.
4.  Publish `dist/bootstrap.bash` as a release asset.

The generated `dist/` directory is a build output and shall not normally
be committed to the repository.

Users should download or execute the published release artifact rather
than individual source files.

## Rationale

Source repositories are optimized for development.

Release artifacts are optimized for consumption.

Keeping these concerns separate provides several benefits.

The repository remains free of generated files.

Every release is built using the same automated process.

Users receive a stable, predictable artifact regardless of the
repository's internal organization.

The release workflow also becomes the natural location for future
signing, checksum generation, provenance, and other release-time
activities.

## Alternatives Considered

### Commit Generated Artifacts

The project could commit `dist/bootstrap.bash` to the repository.

This was rejected because generated artifacts become another source of
truth, increase review noise, and risk diverging from the underlying
source.

### Distribute Source Archives

The project could require users to clone or download the repository.

This was rejected because it increases bootstrap complexity and exposes
users to implementation details that are unnecessary for normal
operation.

## Consequences

The repository remains the authoritative source of the project's code.

Git tags identify immutable release inputs.

GitHub Releases publish immutable release outputs.

The release workflow should remain intentionally small, delegating
build, validation, and testing to Makefile targets whenever practical.

## Non-Goals

This ADR does not prescribe a particular GitHub Actions workflow.

It does not require cryptographic signatures, checksums, or provenance
attestations, although those may be added in the future.

## Future Considerations

Future releases may include detached signatures, checksums, SBOMs, or
attestation documents alongside `bootstrap.bash`.

The published bootstrap script should remain reproducible from the
corresponding tagged source revision whenever practical.

## Summary

The source repository is the authoritative representation of the
project.

GitHub Releases are the authoritative distribution mechanism.

The bootstrap engine is built from tagged source, validated through the
normal project workflow, and published as a single executable release
artifact for users to inspect and execute.
