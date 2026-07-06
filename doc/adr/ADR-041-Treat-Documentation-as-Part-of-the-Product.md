# ADR-041: Treat Documentation as Part of the Product

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that documentation is part
of the bootstrap engine's product surface rather than a secondary
support artifact.

Documentation should help users understand what the project does, why it
behaves the way it does, and how to use it safely.

## Context

The bootstrap engine is designed around explicit intent, inspectability,
conservative execution, stable public interfaces, and human-centered
diagnostics.

Those values cannot be fully realized through code alone.

Users need documentation to understand:

-   the manifest language;
-   supported command-line options;
-   expected execution phases;
-   dry-run and explain behavior;
-   release artifacts;
-   error messages;
-   compatibility guarantees;
-   architectural rationale.

Contributors need documentation to understand why the project is
intentionally small, why it delegates to native package managers, and
why seemingly convenient shortcuts may conflict with established
architectural principles.

## Decision

The project shall treat documentation as part of the product.

User-facing behavior should be documented clearly and kept reasonably
current.

Architectural decisions should be recorded in ADRs.

Contributor-facing guidance should explain not only commands and
repository structure, but also the design philosophy behind the project.

Documentation changes that affect public understanding of the project
should be reviewed with the same care as code changes.

## Rationale

Documentation reduces cognitive load.

A bootstrap tool is often used during recovery, setup, or transition
moments when users may not have full context. Clear documentation helps
users make deliberate decisions rather than relying on guesswork.

Documentation also protects architectural intent. It gives future
contributors a durable record of why decisions were made and helps
prevent accidental drift.

## Alternatives Considered

### Treat Documentation as Secondary

The project could focus primarily on implementation and update
documentation only when convenient.

This was rejected because stale or missing documentation undermines the
project's goals of predictability and inspectability.

### Rely on Source Code as Documentation

The project could expect users and contributors to infer behavior
directly from the implementation.

This was rejected because source code explains how behavior is
implemented but does not reliably explain why the architecture exists.

## Consequences

Documentation becomes part of release readiness.

Public interface changes should include documentation updates.

Examples should be treated as executable guidance where practical and
should avoid demonstrating discouraged patterns.

The documentation set may include README files, ADRs, AGENTS.md,
examples, manual pages, and future architecture overviews.

## Non-Goals

This ADR does not require exhaustive documentation for every internal
helper.

It does not require perfect documentation before implementation begins.

It does require that user-facing behavior and architectural intent be
documented deliberately.

## Future Considerations

Future versions may add generated reference documentation, architecture
overviews, tutorials, or troubleshooting guides.

Such documentation should summarize and organize the project's
principles without replacing the ADRs as the historical record of
architectural decisions.

## Summary

Documentation is part of the bootstrap engine's product experience.

Clear documentation helps users operate the tool safely, helps
contributors preserve architectural intent, and reinforces the project's
commitment to explicit, inspectable, human-centered software.
