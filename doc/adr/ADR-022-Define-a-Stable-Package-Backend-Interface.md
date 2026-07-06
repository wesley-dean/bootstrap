# ADR-022: Define a Stable Package Backend Interface

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the architectural boundary
between the bootstrap engine and operating-system-specific package
managers.

The bootstrap engine shall interact with package managers through a
small, well-defined backend interface.

## Context

Previous ADRs establish that the bootstrap engine:

-   parses manifests;
-   validates user intent;
-   constructs an execution plan;
-   delegates package management to native tools.

Those decisions naturally imply another architectural boundary.

The planner should not need to understand APT command-line syntax, nor
should future planners require modification to support additional
operating systems.

Instead, operating-system-specific behavior should be isolated behind a
backend abstraction.

## Decision

The bootstrap engine shall communicate with package managers through an
internal backend interface.

A backend is responsible for translating execution plans into native
package manager operations.

Typical backend responsibilities include:

-   determining whether a package is installed;
-   determining the installed version;
-   determining whether version constraints are satisfied;
-   locating candidate packages;
-   installing requested packages;
-   reporting backend-specific failures.

The planner shall operate only in terms of backend capabilities rather
than backend implementation details.

## Rationale

Separating planning from backend execution reduces coupling.

The execution planner remains focused on user intent.

Backends remain focused on the capabilities and conventions of the
underlying package manager.

This separation makes both components easier to test and reason about.

It also provides a natural path toward supporting additional operating
systems without changing the parser, planner, or diagnostic
architecture.

## Alternatives Considered

### Embed Package Manager Logic Throughout the Engine

The planner and parser could invoke `apt-get`, `apt-cache`, and `dpkg`
directly wherever needed.

This was rejected because operating-system-specific behavior would
become distributed throughout the project, making future maintenance and
portability more difficult.

### One Backend per Manifest Format

The project could tightly couple manifest parsing to package-manager
behavior.

This was rejected because manifest semantics describe user intent and
should remain independent of the mechanism used to realize that intent.

## Consequences

Backend implementations become the only components aware of native
package-manager command syntax.

The parser, validator, planner, and diagnostics remain
backend-independent.

Adding support for another package manager should primarily involve
implementing another backend rather than modifying existing
architectural layers.

## Non-Goals

This ADR does not define the exact Bash functions or data structures
used to implement the backend interface.

It does not require support for additional operating systems.

It does not imply that every backend exposes identical capabilities.

## Future Considerations

Future backends may support operating systems beyond the initial
Debian-family targets.

Capability differences should be surfaced through clear diagnostics
rather than weakening the planner or manifest language.

The backend interface should evolve conservatively to preserve
compatibility between the planner and backend implementations.

## Summary

The bootstrap engine owns the interpretation of user intent.

Package backends own the realization of that intent using native
operating system facilities.

Maintaining a stable boundary between those responsibilities keeps the
architecture modular, testable, and adaptable to future platforms.
