# ADR-017: Delegate Package Operations to Native Package Managers

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
shall delegate package discovery, dependency resolution, version
comparison, and installation to the native operating-system package
manager.

The bootstrap engine is responsible for interpreting user intent and
constructing an execution plan. The package manager is responsible for
realizing that plan.

## Context

The project's primary objective is to provide a simple, inspectable, and
maintainable bootstrap experience.

Operating-system package managers already solve difficult problems
including:

-   dependency resolution;
-   package acquisition;
-   repository trust;
-   package verification;
-   installation ordering;
-   conflict detection;
-   version comparison.

Attempting to duplicate this behavior would increase complexity, create
opportunities for divergence, and shift maintenance responsibility from
the operating-system distribution to this project.

## Decision

The bootstrap engine shall use native package-manager interfaces
whenever possible.

For Debian-family systems this includes, but is not limited to:

-   `apt-get`
-   `apt-cache`
-   `dpkg --compare-versions`

The bootstrap engine shall not implement its own dependency resolver,
package database, or version-comparison algorithm when suitable native
facilities are available.

The engine's responsibility ends with determining *what* should happen.
Determining *how* packages are installed remains the responsibility of
the package manager.

## Rationale

This decision follows the Unix philosophy of composing specialized tools
rather than replacing them.

It reduces maintenance burden, benefits from decades of package-manager
development, and ensures behavior remains consistent with user
expectations on the target operating system.

It also improves portability. Supporting another operating system
primarily requires implementing another backend that maps the execution
plan onto that system's native package manager rather than rewriting
package-management logic.

## Alternatives Considered

### Implement a Custom Package Manager

The bootstrap engine could manage package metadata, dependency graphs,
and version comparison itself.

This was rejected because it duplicates mature operating-system
functionality while providing little additional value.

### Use Shell Parsing for Version Comparison

The project could compare version strings directly using Bash.

This was rejected because package-version semantics differ between
operating systems and are already implemented correctly by native
tooling.

## Consequences

Backend implementations remain comparatively small.

The project can focus on user experience, manifest interpretation,
planning, and diagnostics.

Future operating-system support can be introduced through additional
package manager adapters rather than changes to the parser or planning
phases.

## Non-Goals

This ADR does not define the package-backend abstraction.

It does not require support for operating systems beyond the project's
initial targets.

It does not prohibit augmenting package-manager behavior with additional
diagnostics or validation.

## Future Considerations

Future versions may introduce backend implementations for additional
operating systems while preserving the same planning and execution
model.

Each backend should expose comparable capabilities while respecting the
native behavior of its underlying package manager.

## Summary

The bootstrap engine interprets intent.

The native package manager performs package management.

Maintaining this separation keeps the project small, predictable, and
aligned with the capabilities and expectations of the host operating
system.
