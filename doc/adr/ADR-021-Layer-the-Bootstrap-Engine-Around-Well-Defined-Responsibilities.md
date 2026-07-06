# ADR-021: Layer the Bootstrap Engine Around Well-Defined Responsibilities

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the internal architectural
boundaries of the bootstrap engine.

The engine shall be organized as a sequence of well-defined
responsibilities, with each layer performing a single primary function
before handing control to the next.

## Context

Previous ADRs established several architectural principles
independently:

-   manifests express user intent;
-   parsing is separate from installation;
-   planning precedes execution;
-   native package managers perform package management;
-   diagnostics should explain decisions clearly.

Taken together, these decisions naturally form an execution pipeline.

Making those layers explicit improves maintainability, testing, and
future evolution of the project.

## Decision

The bootstrap engine shall be organized around the following conceptual
responsibilities:

1.  Configuration loading
2.  Manifest parsing
3.  Validation
4.  Planning
5.  Backend execution
6.  Reporting and diagnostics

Each layer should consume the output of the previous layer rather than
reinterpreting user input independently.

Responsibilities should remain clearly separated.

For example:

-   parsers do not install packages;
-   planners do not parse manifests;
-   backends do not reinterpret manifest syntax;
-   reporters explain results rather than making execution decisions.

## Rationale

A layered architecture reduces coupling.

Each responsibility can evolve independently provided its interface
remains stable.

Testing also becomes significantly simpler.

Parser tests need not invoke the package manager.

Planning tests need not parse manifests.

Backend tests need not exercise parser behavior.

Diagnostics can identify which architectural layer detected a problem,
improving both debugging and user understanding.

## Alternatives Considered

### Monolithic Control Flow

The bootstrap engine could process manifests procedurally from top to
bottom, interleaving parsing, validation, planning, execution, and
reporting.

This was rejected because responsibilities become intertwined and future
features become progressively more difficult to implement.

### Object-Oriented Subsystems

The project could organize the engine around large stateful objects.

This was rejected because the project intentionally favors a
straightforward functional Bash implementation over object-like
abstractions.

## Consequences

Future features should extend existing architectural layers before
introducing new ones.

Contributors should identify which layer owns a proposed behavior before
implementing it.

Documentation should describe the execution pipeline consistently with
this layered model.

## Non-Goals

This ADR does not prescribe specific Bash functions or source files.

It does not define internal data structures exchanged between layers.

Those remain implementation details.

## Future Considerations

Additional layers may be introduced if justified by substantial new
capabilities.

Such additions should preserve the principle that each layer has one
primary responsibility and one clear interface to adjacent layers.

## Summary

The bootstrap engine is organized as a pipeline of distinct
responsibilities.

Each layer should perform one job well, communicate through well-defined
interfaces, and avoid duplicating the responsibilities of other layers.
