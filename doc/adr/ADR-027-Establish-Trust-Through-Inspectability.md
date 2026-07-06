# ADR-027: Establish Trust Through Inspectability

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the trust model for the
bootstrap engine.

The project shall earn user trust by making its behavior inspectable
rather than requiring users to trust opaque implementation details.

## Context

The bootstrap engine is intended to be executed with elevated privileges
on freshly installed systems.

Previous ADRs establish that the project:

-   publishes a single executable release artifact;
-   builds that artifact from modular source;
-   favors explicit configuration;
-   performs planning before execution;
-   delegates package management to native tools;
-   provides human-centered diagnostics.

Together, these decisions support a broader objective: users should be
able to understand what the engine is, what it intends to do, and where
it came from before executing it.

## Decision

The project shall optimize for inspectability.

Specifically:

-   release artifacts should remain human-readable;
-   published artifacts should correspond to tagged source revisions;
-   execution should be explainable through planning, logging, and
    diagnostics;
-   documentation should describe both expected behavior and
    architectural rationale.

The project should encourage installation mechanisms that allow users to
inspect artifacts before execution, such as downloading the release
artifact or using tools that support review prior to execution.

Trust should result from transparency rather than obscurity.

## Rationale

Bootstrap software often executes with broad system privileges.

Reducing the effort required to inspect the software improves user
confidence and encourages informed decision making.

Transparency also benefits contributors by making architectural intent
easier to understand and verify.

## Alternatives Considered

### Trust Through Reputation

Users could be expected to trust the project solely because of its
publisher or popularity.

This was rejected because reputation is not a substitute for
transparency.

### Trust Through Complexity

The project could rely on sophisticated build systems, installers, or
generated artifacts that are difficult to inspect.

This was rejected because complexity makes independent review more
difficult and increases the distance between source and execution.

## Consequences

Architectural decisions should continue to favor transparency.

Features that make behavior more difficult to inspect should require a
strong justification.

Documentation becomes part of the project's trust model rather than
merely a reference.

## Non-Goals

This ADR does not require a particular installation mechanism.

It does not mandate cryptographic signatures or provenance attestations,
although those are encouraged as complementary measures.

It does not prohibit future implementation changes provided
inspectability is preserved.

## Future Considerations

Future releases may include detached signatures, SBOMs, provenance
attestations, checksums, and additional verification guidance.

Such features should strengthen the project's trust model while
preserving the ability for users to inspect both the source and the
distributed artifact.

## Summary

Users should not have to choose between convenience and understanding.

The bootstrap engine should earn trust by making its source, behavior,
build process, and published artifacts straightforward to inspect and
explain.
