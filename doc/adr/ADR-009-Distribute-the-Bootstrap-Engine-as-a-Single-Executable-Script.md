# ADR-009: Distribute the Bootstrap Engine as a Single Executable Artifact

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes how the bootstrap engine
is distributed to users.

The project shall publish the bootstrap engine as a single executable
Bash script, regardless of how the source code is organized within the
repository.

This ADR governs the published artifact rather than the internal source
layout.

## Context

Earlier architectural decisions established that the bootstrap engine
should be easy to obtain, inspect, and execute. Initially, this led to
the idea that the repository itself should contain a single Bash file.

As the project evolved, another requirement emerged.

Maintaining a single growing Bash file would eventually become more
difficult than maintaining a collection of focused source files.
Splitting the source into logical modules improves readability, testing,
and maintainability without changing the user's experience.

The project's primary concern is therefore not how the source is
organized, but how the bootstrap engine is delivered.

## Decision

The repository may organize its source code into multiple Bash source
files.

Typical layouts may include:

``` text
src/
lib/
tests/
```

The published bootstrap engine shall be produced as a build artifact
named:

``` text
dist/bootstrap.bash
```

Release automation shall build the project (for example, by running
`make all`) and publish `dist/bootstrap.bash` as the canonical release
asset.

Users should obtain and execute the published artifact rather than
individual source files.

## Rationale

Separating source organization from distribution provides the advantages
of both approaches.

Internally, the project benefits from modular source files with clear
responsibilities.

Externally, users continue to receive a single, inspectable bootstrap
script that can be reviewed, downloaded, and executed from one location.

This preserves the project's goals of simplicity and inspectability
while allowing the implementation to evolve.

## Alternatives Considered

### Maintain a Single Source File

Keeping all implementation in one file minimizes build complexity.

This alternative was rejected because it unnecessarily couples
maintainability to the distribution format.

### Publish a Multi-file Repository

Users could clone the repository and execute the source directly.

This was rejected as the primary distribution mechanism because it
increases bootstrap complexity and weakens the project's "single
artifact" philosophy.

## Consequences

The repository may contain:

-   source modules;
-   documentation;
-   tests;
-   build tooling;
-   examples.

The `dist/` directory should contain generated artifacts and should not
normally be committed to source control.

## Non-Goals

This ADR does not prescribe how source files are combined into the final
artifact.

It does not require a particular build system.

## Future Considerations

Future versions may embed version metadata, generated documentation, or
other derived content into the release artifact as part of the build
process.

Regardless of those changes, the externally visible distribution should
remain a single executable Bash script unless superseded by a future
ADR.

## Summary

The project values a simple distribution experience and a maintainable
source tree.

To achieve both goals, the bootstrap engine is developed as modular
source code but published as a single executable Bash script produced
during the release process.
