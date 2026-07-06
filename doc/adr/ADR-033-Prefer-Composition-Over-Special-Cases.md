# ADR-033: Prefer Composition Over Special Cases

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes a guiding principle for
extending the bootstrap engine.

When introducing new capabilities, the project should favor composing
existing building blocks rather than introducing feature-specific
exceptions or one-off behaviors.

## Context

Previous ADRs establish a layered architecture, a small manifest
language, stable public interfaces, and a preference for evolving
through addition rather than mutation.

As the project grows, new feature requests will inevitably arise.

Without a consistent architectural principle, there is a risk that
individual features will introduce special-case logic that bypasses
established execution phases or behaves differently from the rest of the
system.

Over time, those exceptions become difficult to document, test, and
maintain.

## Decision

The bootstrap engine shall prefer composition over special cases.

New capabilities should, whenever practical, be implemented by combining
existing architectural layers and interfaces.

Contributors should first ask:

-   Can this feature reuse an existing execution phase?
-   Can this capability be expressed through composition?
-   Does this proposal introduce a special rule that applies only to one
    case?

Features that require exceptional behavior should provide a clear
architectural justification.

## Rationale

Composition encourages consistency.

Features that reuse existing parser, planner, backend, logging, and
diagnostic facilities inherit the same behavior, documentation patterns,
and testing approach as the rest of the project.

Special cases, by contrast, tend to multiply over time.

Each exception introduces another rule that contributors and users must
remember.

Reducing exceptional behavior lowers cognitive load and preserves the
architectural coherence established by earlier ADRs.

## Alternatives Considered

### Implement Feature-Specific Logic

Each new capability could introduce its own execution path tailored to
that feature.

This was rejected because feature-specific paths frequently duplicate
existing behavior and make future maintenance more difficult.

### Optimize Individual Features Independently

The project could optimize each capability without regard for
architectural consistency.

This was rejected because local optimizations often increase global
complexity.

## Consequences

Contributors should evaluate proposals in terms of how well they compose
with the existing architecture.

Code reviews should identify unnecessary exceptions and encourage reuse
of existing execution phases.

Documentation benefits because composed features naturally follow
familiar behavioral patterns.

## Non-Goals

This ADR does not prohibit specialized behavior where required by
platform constraints or correctness.

It does not require every implementation to be identical internally.

Rather, it encourages reuse of established architectural concepts
whenever practical.

## Future Considerations

As additional package backends, manifest capabilities, or operational
modes are introduced, preference should continue to be given to
extending existing interfaces instead of creating parallel
implementations.

Future ADRs should explicitly identify when an exception to this
principle is being introduced and explain why composition is
insufficient.

## Summary

The bootstrap engine should grow by composing existing architectural
building blocks rather than accumulating special-case behavior.

Favoring composition strengthens consistency, simplifies maintenance,
and helps preserve the project's long-term architectural integrity.
