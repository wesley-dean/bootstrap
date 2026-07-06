# ADR-034: Keep the Core Engine Small

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
should remain intentionally small, focused, and opinionated.

The core engine should provide the minimum capabilities necessary to
interpret manifests, construct execution plans, and delegate package
operations. Features that are optional, platform-specific, or narrowly
applicable should be implemented outside the core whenever practical.

## Context

Previous ADRs establish a consistent architectural direction:

-   the manifest language is intentionally small;
-   execution is divided into well-defined layers;
-   public interfaces evolve conservatively;
-   new capabilities should be introduced through composition rather
    than mutation;
-   special cases should be avoided.

Without an explicit boundary around the core engine, there is a natural
tendency for unrelated capabilities to accumulate over time.

Examples might include editor configuration, desktop customization,
secret management, cloud integration, or other workstation-specific
behaviors.

Although individually useful, such features can distract from the
project's primary purpose and increase maintenance burden.

## Decision

The bootstrap engine shall maintain a deliberately small core.

The core engine owns:

-   manifest interpretation;
-   validation;
-   execution planning;
-   backend delegation;
-   logging and diagnostics.

Capabilities that are not essential to those responsibilities should
generally be implemented as higher-level manifests, profiles, or
separate tools rather than incorporated into the engine itself.

The project should prefer enabling extension over embedding policy.

## Rationale

A small core is easier to understand, test, document, and maintain.

Keeping policy outside the engine allows different users to compose
workflows appropriate for their own environments without increasing
complexity for everyone else.

This philosophy also reinforces the project's goal of remaining
inspectable and predictable.

## Alternatives Considered

### Expand the Core Engine

The project could gradually absorb workstation provisioning,
configuration management, and other automation tasks.

This was rejected because it blurs the project's purpose and encourages
feature creep.

### Provide Built-In Support for Every Common Workflow

The engine could include numerous optional behaviors controlled by flags
or configuration.

This was rejected because optional behavior still increases
implementation, testing, and documentation complexity.

## Consequences

Future feature proposals should first consider whether they belong in
the core engine or are better expressed through composition.

Contributors should prefer extending manifests, profiles, or companion
tools before expanding the engine itself.

## Non-Goals

This ADR does not prohibit growth.

It does not prevent introducing new core capabilities when they
strengthen the engine's primary responsibilities.

It does, however, establish that growth should remain deliberate and
aligned with the project's architectural purpose.

## Future Considerations

Future companion projects may provide higher-level provisioning,
workstation profiles, or environment-specific integrations built upon
the bootstrap engine's stable public interfaces.

Such projects should complement the engine rather than redefine its
mission.

## Summary

The bootstrap engine should remain small, focused, and composable.

A deliberately limited core preserves clarity, maintainability, and
long-term architectural integrity while allowing richer workflows to be
built around it.
