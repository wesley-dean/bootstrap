# ADR-030: Preserve Stable Public Interfaces

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
the project's public interfaces.

Public interfaces should evolve deliberately because they represent
commitments to users, automation, documentation, and downstream tooling.

## Context

Previous ADRs define several user-facing contracts, including:

-   the manifest language;
-   the command-line interface;
-   exit code philosophy;
-   diagnostics;
-   release artifacts;
-   package backend behavior.

These interfaces are consumed by people as well as automation.
Unnecessary changes increase maintenance costs, invalidate
documentation, and erode user confidence.

The project should distinguish between implementation details, which may
evolve freely, and public interfaces, which should evolve
conservatively.

## Decision

The bootstrap engine shall treat its public interfaces as architectural
contracts.

Changes to public interfaces should be considered compatibility changes
and evaluated intentionally.

Public interfaces include, but are not limited to:

-   manifest syntax and semantics;
-   command-line options;
-   exit code categories;
-   documented behavior;
-   release artifact format.

Internal implementation details, source layout, helper functions, and
build mechanics are not public interfaces unless explicitly documented
as such.

Breaking changes should normally be accompanied by a new ADR and a
documented migration strategy.

## Rationale

Stable interfaces reduce operational friction.

Documentation, blog posts, automation, and user habits remain valuable
across releases when externally visible behavior changes slowly and
predictably.

Separating public contracts from implementation details also gives
developers considerable freedom to improve internal architecture without
disrupting users.

## Alternatives Considered

### Treat All Behavior as Mutable

The project could reserve the right to change any aspect of the software
between releases.

This was rejected because it undermines user confidence and makes
automation fragile.

### Freeze All Behavior

The project could avoid changing any externally visible behavior.

This was rejected because software must continue to evolve to address
defects, new platforms, and improved workflows.

## Consequences

Contributors should identify whether a proposed change affects a public
interface before implementing it.

Compatibility should be evaluated alongside correctness.

Documentation should clearly distinguish stable interfaces from
implementation details.

## Non-Goals

This ADR does not define semantic versioning.

It does not prohibit breaking changes.

It does not establish a deprecation policy.

Those topics are addressed separately.

## Future Considerations

Future ADRs may define:

-   semantic versioning;
-   deprecation procedures;
-   feature lifecycle;
-   compatibility windows.

Those policies should build upon the distinction established by this ADR
between public contracts and internal implementation.

## Summary

The project's public interfaces are long-term commitments.

They should evolve deliberately, remain well documented, and change only
when the benefits clearly outweigh the cost of breaking compatibility.
