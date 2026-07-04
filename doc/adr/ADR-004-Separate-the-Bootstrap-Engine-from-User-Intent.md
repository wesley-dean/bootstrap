# ADR-004: Separate the Bootstrap Engine from User Intent

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the architectural boundary
between the reusable bootstrap engine and the user-specific intent that
it realizes.

The bootstrap engine contains reusable behavior.

User repositories contain policy.

Maintaining this distinction is fundamental to keeping the project
portable, maintainable, and broadly reusable.

## Context

After deciding that the bootstrap system should describe desired state
(ADR-002) and delegate package management to native tooling (ADR-003),
the remaining architectural question is where the desired state should
live.

A tempting approach is to place everything into one repository:
bootstrap logic, package manifests, dotfiles, workstation-specific
configuration, personal scripts, and host-specific exceptions.

While convenient initially, this causes implementation and policy to
become tightly coupled. Reusing the engine requires editing source code,
and personal preferences become inseparable from the software itself.

The project instead recognizes that these concerns evolve at different
rates.

The bootstrap engine changes when capabilities improve.

User intent changes when the user's workflow changes.

They should therefore be maintained independently.

## Decision

The project shall separate reusable implementation from user intent.

The bootstrap engine should be suitable for publication as an
open-source project.

User intent should remain external to the engine and may reside in one
or more repositories controlled by the user or organization.

Examples of user intent include:

-   package manifests;
-   workstation profiles;
-   dotfiles;
-   custom shell scripts;
-   editor preferences;
-   host-specific configuration;
-   organization-specific policies.

The engine consumes these artifacts but does not own them.

## Rationale

This separation keeps responsibilities clear.

The engine answers:

> How is a workstation realized?

User repositories answer:

> What should this workstation become?

This distinction has practical benefits.

The engine can be upgraded without rewriting package manifests.

Package manifests can evolve without modifying executable code.

Organizations may adopt the engine while supplying their own intent
repositories.

The engine remains broadly reusable rather than reflecting the
preferences of a single developer.

## Alternatives Considered

### Single Monolithic Repository

A single repository containing both implementation and configuration is
simple to begin with.

However, it quickly accumulates personal assumptions, making reuse and
review more difficult.

This approach was rejected because it couples policy to implementation.

### Embed Configuration in Source Code

Hard-coding package lists or workstation definitions into the bootstrap
engine reduces flexibility and makes every configuration change a
software release.

This alternative was rejected because user intent should be data rather
than code whenever practical.

## Consequences

The public bootstrap repository remains focused on reusable
capabilities, documentation, testing, and stable interfaces.

Private repositories can contain curated package manifests, dotfiles,
and organization-specific configuration without requiring changes to the
engine.

Multiple intent repositories may target the same bootstrap engine.

## Non-Goals

This ADR does not prescribe the format of package manifests or profiles.

It does not require intent repositories to be private.

It simply establishes that implementation and policy are distinct
architectural concerns.

## Future Considerations

Future versions may support fetching intent from Git repositories, URLs,
archives, or other sources.

The bootstrap engine should define stable interfaces for consuming
intent while remaining agnostic about where that intent originates.

## Summary

The bootstrap engine is reusable software.

User intent is configuration.

Keeping these concerns separate reduces coupling, improves
maintainability, and allows the engine to remain broadly useful while
users retain complete control over how their own systems are described.
