# ADR-010: Build the Distribution Artifact from Modular Source Files

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes how the published
bootstrap artifact is produced from the project's source tree.

The source code is organized to maximize maintainability. The released
artifact is organized to maximize simplicity for users. These are
separate concerns.

## Context

ADR-009 establishes that users receive a single executable Bash script
as the canonical bootstrap artifact.

Internally, however, the project is expected to grow beyond what can be
comfortably maintained in a single source file. Parsing manifests,
interacting with package managers, logging, argument parsing, and future
capabilities each represent distinct concerns that benefit from modular
organization.

Rather than forcing developers to maintain a monolithic source file, the
project should allow the implementation to be divided into logical
modules and assembled during the build process.

## Decision

The source repository shall contain modular Bash source files organized
by responsibility.

A typical repository layout may resemble:

``` text
src/
    bootstrap.bash

lib/
    logging.bash
    manifest.bash
    apt.bash

tests/
docs/
examples/
dist/
```

The `dist/` directory contains generated artifacts and is not the source
of truth.

The canonical release artifact is produced by the project's build
system, typically through:

``` bash
make all
```

which generates:

``` text
dist/bootstrap.bash
```

The build process shall be deterministic. Given the same source tree and
build inputs, it should produce the same executable artifact.

## Rationale

Source code and distributed software have different audiences.

Developers benefit from modularity, focused files, and isolated
responsibilities.

Users benefit from downloading and reviewing a single executable script.

Separating these concerns allows each audience to receive the form that
best serves its needs without compromising the other.

This decision also enables additional build-time activities such as
embedding version information, expanding templates, generating
documentation headers, or performing validation before release without
exposing those implementation details to users.

## Alternatives Considered

### Develop Directly in the Release Artifact

The project could maintain `bootstrap.bash` as both the source file and
the distributed artifact.

This was rejected because maintainability would degrade as the project
grows.

### Distribute the Source Tree

The project could require users to clone the repository and execute the
source directly.

This was rejected because it weakens the project's emphasis on a small,
inspectable bootstrap surface and complicates first-time use.

## Consequences

Developers work with modular source code.

Users consume a single executable artifact.

The release workflow becomes responsible for constructing the artifact
from the source tree and validating that it is suitable for publication.

Generated artifacts should not normally be committed to the repository.

## Non-Goals

This ADR does not prescribe a specific implementation of the build
process.

It does not require a particular directory structure beyond maintaining
a clear distinction between source files and generated artifacts.

It does not define release automation, which is addressed separately.

## Future Considerations

Future build steps may include embedding release metadata, verifying
shell formatting, concatenating modules, generating documentation, or
performing additional validation.

Such enhancements should remain transparent to users of the published
bootstrap artifact.

## Summary

The bootstrap engine is developed as modular source code but released as
a single executable Bash script.

The build process bridges these two representations, allowing the
project to remain maintainable for developers while preserving a simple,
inspectable distribution for users.
