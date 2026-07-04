# ADR-003: Treat Native Package Managers as the Source of Truth

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the relationship between
the bootstrap engine and the operating system's package manager.

The bootstrap engine is responsible for interpreting the user's desired
state. The operating system's package manager remains responsible for
determining how software is acquired, validated, resolved, and
installed.

This ADR applies to all supported platforms, although the initial
implementation targets Debian-family systems.

## Context

After deciding that configuration should describe the desired outcome
rather than installation procedures (ADR-002), the next architectural
question is where package-management responsibility belongs.

It would be possible for this project to implement its own package
resolver, dependency engine, repository management, or version-selection
logic. Doing so would provide additional control, but it would also
duplicate decades of work already invested in mature package managers.

Modern package managers already solve difficult problems including:

-   dependency resolution;
-   package authenticity and trust;
-   repository configuration;
-   version selection;
-   conflict detection;
-   download and installation;
-   upgrade policy; and
-   distribution-specific behavior.

Reimplementing these capabilities would substantially increase the
project's complexity while moving it away from its primary purpose:
helping users realize their desired workstation state.

## Decision

The bootstrap engine shall treat the operating system's package manager
as the authoritative implementation of package-management policy.

For Debian-family systems this means relying on tools such as:

-   `apt-get`
-   `apt-cache`
-   `dpkg`

The bootstrap engine is responsible for:

-   reading package manifests;
-   validating manifest syntax;
-   determining whether requirements appear to be satisfied;
-   selecting the appropriate package-manager operations; and
-   presenting clear diagnostics.

The package manager remains responsible for:

-   dependency resolution;
-   package installation and removal;
-   version comparison semantics;
-   repository trust;
-   package authenticity;
-   and all distribution-specific policy.

The bootstrap engine shall orchestrate package managers rather than
replace them.

## Rationale

This project is intentionally small in scope.

Its purpose is not to become another package manager. Its purpose is to
provide a simple, inspectable, and maintainable way to transform a
freshly installed system into a useful workstation.

Delegating package-management behavior to native tooling provides
several benefits.

First, it reduces implementation complexity. The bootstrap engine can
remain focused on expressing intent rather than reproducing mature
package-management algorithms.

Second, it improves correctness. Native package managers already
understand their own version formats, repository layouts, dependency
graphs, and distribution policies.

Third, it improves portability. Supporting another Linux distribution
becomes primarily a matter of adding a backend adapter rather than
redesigning the configuration language.

Finally, it keeps responsibilities well defined. The bootstrap engine
decides *what* should happen. The package manager decides *how* it
happens.

## Alternatives Considered

### Reimplement Package Management

The project could parse repositories, compare versions, resolve
dependencies, and install packages directly.

This alternative was rejected because it duplicates mature software
while providing little value for the intended workstation-bootstrap use
case.

### Shell Out Without Architectural Boundaries

Another possibility would be to invoke package-manager commands
opportunistically without defining clear ownership.

This was rejected because it blurs responsibility between the bootstrap
engine and the package manager, making future maintenance more
difficult.

## Consequences

The bootstrap engine remains relatively small and understandable.

Platform-specific behavior is isolated behind package-manager adapters.

Users benefit from improvements made by their operating system's package
manager without changes to the bootstrap engine.

The project intentionally accepts that some package-manager behavior
will vary between operating systems. Such variation is considered a
feature of native integration rather than a defect to be abstracted
away.

## Non-Goals

This ADR does not define the package-manifest format.

It does not attempt to normalize package names across operating systems.

It does not provide identical behavior across every supported platform.

Instead, it embraces the strengths and conventions of each native
package manager.

## Future Considerations

Future versions may support additional package managers including DNF,
Pacman, Zypper, APK, Homebrew, or others.

Each backend should implement a common conceptual interface while
preserving the semantics expected by its native ecosystem.

The bootstrap engine should avoid forcing all package managers into the
lowest common denominator when doing so would reduce clarity or
correctness.

## Summary

The bootstrap engine coordinates package installation but does not own
package management.

Native package managers remain the authoritative source of truth for
package resolution, installation, and operating-system policy.

This separation keeps the bootstrap engine focused on expressing user
intent while allowing mature package-management software to perform the
work it was designed to do.
