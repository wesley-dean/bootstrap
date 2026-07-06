# ADR-035: Prefer Data Over Code

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
should prefer declarative data over executable code when representing
user intent.

Users should describe the desired outcome. The bootstrap engine should
determine how to realize that outcome.

## Context

Earlier ADRs establish that:

-   manifests describe desired state;
-   the manifest language remains intentionally small;
-   execution is separated into parsing, validation, planning, and
    execution;
-   explicit intent is preferred over implicit behavior;
-   the core engine should remain small and focused.

As the project grows, there will be opportunities to embed additional
logic in configuration files. Examples include shell commands,
conditionals, loops, templating, or platform-specific scripting.

While powerful, executable configuration makes validation more
difficult, reduces inspectability, and increases the gap between what
users write and what the engine understands.

## Decision

The bootstrap engine shall prefer declarative data structures over
executable configuration.

Package manifests should express *what* the user wants rather than *how*
to achieve it.

When additional capabilities are required, the preferred order is:

1.  Extend the manifest language with a new declarative concept.
2.  Introduce a higher-level composition mechanism.
3.  Create a companion tool.
4.  Embed executable logic only when no reasonable declarative
    alternative exists.

Executable configuration should require explicit architectural
justification.

## Rationale

Declarative inputs are easier to validate, test, document, and reason
about.

They support dry-run mode, planning, diagnostics, and future tooling
because the engine can understand intent without executing arbitrary
code.

This philosophy also improves security by reducing opportunities for
unexpected behavior within configuration.

## Alternatives Considered

### Execute Shell Code from Manifests

The project could allow arbitrary shell commands within manifests.

This was rejected because it blurs the distinction between configuration
and implementation, complicates validation, and makes behavior less
predictable.

### Treat Configuration as a Programming Language

The project could evolve the manifest format into a general-purpose
language.

This was rejected because the project's purpose is to interpret package
requirements, not to become another scripting environment.

## Consequences

Future feature proposals should first ask whether the capability can be
represented as data.

Parser complexity should grow more slowly than implementation
complexity.

Documentation remains focused on describing a small declarative language
rather than a programming model.

## Non-Goals

This ADR does not prohibit implementation code within the bootstrap
engine.

It does not prohibit companion tools from using scripting where
appropriate.

It does prohibit treating manifests as arbitrary executable programs
without a compelling architectural reason.

## Future Considerations

Future composition mechanisms should continue to represent intent
declaratively, allowing planning, diagnostics, and validation to operate
without executing user-provided code.

## Summary

Configuration should describe desired state, not executable procedures.

The bootstrap engine should continue to favor declarative data because
it is more predictable, more inspectable, and more amenable to
validation than embedded code.
