# ADR-014: Separate Manifest Parsing from Package Installation

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the architectural boundary
between parsing package manifests and performing package installation.

The bootstrap engine should treat these as independent responsibilities
that communicate through a well-defined internal representation.

## Context

The package manifest is the user's declaration of intent.

The package manager performs the installation.

Between these two concerns lies the responsibility of understanding the
manifest itself.

As the project evolves, additional capabilities may be introduced,
including:

-   richer diagnostics;
-   dry-run mode;
-   explain mode;
-   multiple package-manager backends;
-   manifest validation;
-   profile composition.

If parsing and installation are tightly coupled, each new capability
becomes more difficult to implement and test.

## Decision

The bootstrap engine shall parse package manifests completely before
beginning package installation.

Manifest parsing shall produce an internal representation of user
intent.

Package installation shall operate only on that parsed representation
rather than directly reading the manifest.

Validation errors shall be reported before any package installation
begins.

## Rationale

Separating parsing from installation produces a cleaner architecture.

The parser becomes responsible for understanding the manifest language.

The installer becomes responsible for realizing validated intent using
the native package manager.

This separation improves testability.

Parser behavior can be validated without requiring package-manager
access.

Installer behavior can be tested against known parsed inputs without
exercising the parser.

The resulting architecture also enables richer future capabilities such
as displaying the parsed manifest, explaining planned actions, or
validating multiple manifests before performing any privileged
operations.

## Alternatives Considered

### Parse During Installation

The bootstrap engine could read one manifest line, immediately process
it, and continue until the end of the file.

This approach was rejected because errors discovered later in the
manifest may occur only after earlier package installations have already
modified the system.

### Delegate Parsing to the Package Manager

The bootstrap engine could simply forward manifest lines to the package
manager.

This was rejected because manifest syntax is a project concern rather
than an operating-system concern.

The project should validate and understand its own configuration
language.

## Consequences

Manifest validation becomes a distinct phase of execution.

Package installation begins only after successful parsing.

Future capabilities such as `--dry-run`, `--explain`, and profile
composition can reuse the parsed representation without reparsing the
manifest.

The parser and installer may evolve independently provided their shared
internal representation remains stable.

## Non-Goals

This ADR does not prescribe the internal representation used by the
bootstrap engine.

It does not define manifest syntax.

It does not require every manifest to be loaded into memory
simultaneously, provided the bootstrap engine can validate user intent
before making system changes.

## Future Considerations

Future versions may expose the parsed representation through debugging,
structured logging, or machine-readable output.

Such capabilities should build upon the parser rather than introducing
alternative parsing paths.

## Summary

Manifest parsing and package installation are distinct architectural
responsibilities.

The bootstrap engine shall validate and understand user intent before
making changes to the system, producing a cleaner, safer, and more
testable design.
