# ADR-038: Introduce Experimental Features Deliberately

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes how experimental
capabilities should be introduced and evaluated within the project.

Experimental features allow architectural ideas to mature without
immediately becoming part of the project's long-term compatibility
commitments.

## Context

Previous ADRs establish that the project values:

-   stable public interfaces;
-   semantic versioning;
-   deliberate evolution;
-   explicit architectural decisions;
-   predictable deprecation.

Not every worthwhile idea is ready to become a permanent part of the
bootstrap engine. Some capabilities benefit from practical experience
before they are treated as stable public interfaces.

The project requires a consistent approach for introducing such
features.

## Decision

The project may introduce experimental features when they provide an
opportunity to evaluate architectural ideas without prematurely
committing to their long-term design.

Experimental features should:

-   be explicitly identified as experimental;
-   require deliberate opt-in rather than being enabled by default;
-   be documented with their experimental status;
-   avoid altering established behavior unless explicitly requested.

Experimental features shall not be considered stable public interfaces.

They may evolve, be redesigned, or be removed based on experience.

When an experimental feature matures, its promotion to a stable
capability should be accompanied by the appropriate architectural
documentation.

## Rationale

Experimentation encourages innovation.

Separating experimental capabilities from stable interfaces allows the
project to explore new ideas while preserving the predictability
expected by existing users.

Making experimentation explicit also prevents accidental dependence on
behavior that has not yet been fully evaluated.

## Alternatives Considered

### Release Every New Feature as Stable

The project could immediately treat all new capabilities as permanent
public interfaces.

This was rejected because early implementations often improve
significantly after real-world use.

### Avoid Experimental Features Entirely

The project could refuse to expose any capability until its design is
considered final.

This was rejected because practical feedback frequently improves
architectural decisions and reveals tradeoffs that are difficult to
anticipate.

## Consequences

Contributors should distinguish experimental capabilities from stable
public interfaces.

Documentation should clearly identify experimental behavior.

Users should understand that experimental features are intended for
evaluation rather than long-term automation.

## Non-Goals

This ADR does not define how experimental features are enabled.

It does not require the project to introduce experimental capabilities.

It does not establish a fixed evaluation period before stabilization.

## Future Considerations

Future releases may provide dedicated command-line options, manifest
annotations, or configuration mechanisms for enabling experimental
behavior.

The project should continue to ensure that experimentation remains
explicit, discoverable, and isolated from stable workflows.

## Summary

Experimentation is encouraged, but architectural commitments should be
made deliberately.

By treating experimental capabilities as opt-in and distinct from stable
interfaces, the project can continue to evolve while preserving the
predictability and trust established by earlier ADRs.
