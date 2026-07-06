# ADR-042: Minimize the Trusted Computing Base

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's philosophy
for selecting implementation technologies and runtime dependencies.

The bootstrap engine should minimize the amount of software that must be
trusted to correctly and safely perform its work.

## Context

The bootstrap engine is intended to execute with elevated privileges on
freshly installed systems.

Previous ADRs establish that the project values:

-   inspectability;
-   explicit behavior;
-   deterministic execution;
-   human-centered diagnostics;
-   a deliberately small core.

Each additional runtime dependency increases the amount of software that
users must trust, install, maintain, and understand before the bootstrap
engine can run.

Reducing unnecessary dependencies aligns with the project's emphasis on
simplicity and transparency.

## Decision

The project shall minimize its trusted computing base (TCB).

The bootstrap engine should rely primarily on software that is already
expected to exist on the target platform or that provides substantial
architectural value.

Examples include:

-   Bash;
-   the native package manager;
-   Git;
-   Make for development;
-   standard Unix utilities where appropriate.

New dependencies should be introduced only when their long-term value
clearly outweighs the additional complexity, maintenance, and trust they
require.

Whenever practical, existing platform capabilities should be preferred
over project-specific implementations.

## Rationale

A smaller trusted computing base provides several benefits.

Users have fewer prerequisites before the bootstrap engine can be
executed.

Security review becomes easier because fewer components participate in
the critical execution path.

Long-term maintenance improves because dependency lifecycles become
simpler and less coupled to the project.

This philosophy also complements the project's goal of making the
bootstrap engine straightforward to inspect and reason about.

## Alternatives Considered

### Introduce Dependencies Opportunistically

The project could adopt additional libraries or frameworks whenever they
reduce implementation effort.

This was rejected because small convenience gains often accumulate into
a significantly more complex runtime environment.

### Reimplement Platform Facilities

The project could replace operating-system capabilities with custom
implementations.

This was rejected because mature platform tools already solve many
problems reliably and should generally be reused rather than duplicated.

## Consequences

Contributors should consider dependency impact during architectural
reviews.

Dependencies should be justified in terms of enduring architectural
value rather than short-term implementation convenience.

Documentation should explain significant external dependencies and why
they are required.

## Non-Goals

This ADR does not prohibit adding dependencies.

It does not require avoiding all external tools.

It does require that dependencies be introduced deliberately and remain
aligned with the project's architectural philosophy.

## Future Considerations

Future versions may periodically review dependencies to determine
whether they remain justified.

As platform capabilities evolve, opportunities to simplify the trusted
computing base should be evaluated.

## Summary

The bootstrap engine should remain easy to trust because it depends upon
as little additional software as practical.

A deliberately small trusted computing base supports the project's
broader goals of simplicity, inspectability, portability, and long-term
maintainability.
