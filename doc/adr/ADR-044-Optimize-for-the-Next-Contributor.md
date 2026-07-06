# ADR-044: Optimize for the Next Contributor

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's philosophy
for making design and implementation decisions with future contributors
in mind.

Every meaningful change should leave the project easier to understand,
easier to maintain, or easier to extend for the next person who works on
it---even if that person is the original author months or years later.

## Context

The bootstrap engine is intentionally documentation-first and
architecture-led.

Previous ADRs establish that the project values:

-   explicit intent;
-   stable public interfaces;
-   deterministic behavior;
-   composition over special cases;
-   human-centered diagnostics;
-   documentation as part of the product;
-   explicit architectural decisions.

These principles all reduce the effort required to understand the
project.

A sustainable project should assume that future contributors will not
possess the context, memory, or assumptions of today's contributors.

## Decision

The project shall optimize for the next contributor.

When evaluating competing designs, preference should generally be given
to the approach that:

-   is easier to understand without historical context;
-   reduces unnecessary cognitive load;
-   makes architectural intent more obvious;
-   preserves consistency with existing concepts;
-   improves documentation alongside implementation.

Contributor convenience should be considered an architectural concern
rather than merely a documentation concern.

## Rationale

Time is the greatest source of complexity.

Even a solo-maintained project eventually has multiple contributors
across time, as the same person returns after weeks, months, or years.

Designs that depend upon memory, unwritten conventions, or implicit
knowledge become progressively more difficult to maintain.

Optimizing for future contributors preserves architectural continuity
and reduces the cost of long-term ownership.

## Alternatives Considered

### Optimize Only for the Current Implementation

The project could prioritize the quickest implementation regardless of
its long-term readability.

This was rejected because short-term convenience often creates long-term
maintenance costs.

### Assume Architectural Knowledge

The project could expect contributors to reconstruct design intent from
source code and commit history.

This was rejected because architecture should be discoverable rather
than inferred.

## Consequences

Contributors should consider maintainability as part of correctness.

Documentation, examples, ADRs, and code organization should work
together to reduce onboarding effort.

Architectural reviews should ask whether a proposal makes the project
easier or harder for the next contributor to understand.

## Non-Goals

This ADR does not require optimizing for every conceivable preference or
coding style.

It does not discourage efficient implementations.

It does encourage choosing solutions whose reasoning remains clear over
time.

## Future Considerations

As the project grows, contributor guides, architecture overviews, and
development workflows should continue to reinforce the principles
established throughout the ADR collection.

The project should remain welcoming to occasional contributors as well
as long-term maintainers.

## Summary

The bootstrap engine should be designed for longevity.

Every architectural decision should help the next contributor understand
not only how the project works, but why it works that way, preserving
clarity and continuity across time.
