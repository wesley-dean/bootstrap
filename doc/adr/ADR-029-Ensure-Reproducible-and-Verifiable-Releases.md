# ADR-029: Ensure Reproducible and Verifiable Releases

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
release reproducibility and verification.

Users should be able to understand where a published release originated
and have confidence that it corresponds to the project's
version-controlled source.

## Context

Previous ADRs establish that the project:

-   publishes a single executable release artifact;
-   builds that artifact from modular source;
-   uses GitHub Releases as the canonical distribution mechanism;
-   favors inspectability and explicit behavior.

Those decisions naturally raise another question.

How can users know that a published release faithfully represents the
tagged source from which it was produced?

While the project's initial users may be comfortable reviewing source
code directly, the architecture should support stronger verification as
the project matures.

## Decision

Release artifacts shall be generated from version-controlled source
using the project's documented build process.

Each published release should correspond to a specific immutable Git
revision.

Whenever practical, rebuilding the project from the same tagged revision
should produce a functionally equivalent release artifact.

The project should progressively adopt additional verification
mechanisms, such as published checksums, cryptographic signatures,
software bills of materials (SBOMs), and provenance attestations, as
they become appropriate.

## Rationale

Reproducible releases strengthen trust.

Users should not need to rely solely on the reputation of the publisher.
They should have practical means to verify that a release was produced
from the published source.

Treating release verification as an architectural concern also
encourages build automation to remain deterministic and well documented.

## Alternatives Considered

### Trust Releases Without Verification

The project could publish release artifacts without providing any
additional means of verification.

This was rejected because users executing privileged software benefit
from independent verification whenever practical.

### Commit Generated Artifacts

The project could commit generated release artifacts to version control.

This was rejected because generated artifacts become an additional
source of truth and increase maintenance burden.

## Consequences

Build automation should remain deterministic and transparent.

Release workflows should favor reproducible inputs and documented
processes.

Future verification features should complement, rather than replace, the
project's emphasis on inspectability.

## Non-Goals

This ADR does not require byte-for-byte reproducibility.

It does not mandate a specific signing technology or attestation
framework.

It does not require every release to include every possible verification
artifact.

## Future Considerations

Future releases may publish:

-   SHA-256 checksums;
-   detached signatures;
-   SBOMs;
-   SLSA provenance;
-   in-toto attestations.

Such additions should build upon the project's existing release
architecture without changing the user-facing installation experience.

## Summary

The bootstrap engine should be easy to verify as well as easy to
inspect.

Release artifacts should remain closely tied to their version-controlled
source and should increasingly support independent verification as the
project evolves.
