# ADR-019: Define Stable Version Constraint Semantics

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record defines how version constraints are
expressed and interpreted within package manifests.

The objective is to provide a small, predictable set of version
operators that cover the project's primary use cases without introducing
unnecessary complexity.

## Context

ADR-018 establishes that the manifest language should remain
intentionally small.

The overwhelming majority of package requirements are expected to
consist only of package names. Version constraints are anticipated to be
uncommon and should therefore remain simple.

Operating-system package managers already implement sophisticated
version comparison algorithms. The bootstrap engine should express user
intent while delegating comparison semantics to the native package
manager whenever possible.

## Decision

The initial manifest language shall support the following forms:

-   `package`
-   `package = version`
-   `package == version`
-   `package > version`
-   `package >= version`

Whitespace surrounding operators is insignificant.

For the purposes of the manifest language, `=` and `==` are synonymous
and represent an exact version requirement.

No additional comparison operators shall be supported initially.

If a version constraint is specified, the bootstrap engine shall
validate it before constructing the execution plan.

Version comparisons shall be performed using native package-manager
facilities rather than shell string comparison.

## Rationale

Supporting a deliberately small set of operators keeps the language easy
to understand and document.

Treating `=` and `==` as equivalent reduces user surprise and allows
users to write manifests naturally without requiring knowledge of a
project-specific distinction.

Limiting the initial grammar also leaves room for future expansion
should a compelling need arise.

## Alternatives Considered

### Support Full Version Expressions

The project could support ranges, compatible releases, exclusions,
unions, wildcards, or other rich dependency syntax.

This was rejected because workstation manifests rarely require that
level of precision and such features would significantly increase parser
complexity.

### Compare Versions in Bash

The bootstrap engine could implement its own version comparison logic.

This was rejected because native package managers already implement the
correct comparison semantics for their respective ecosystems.

## Consequences

Most manifests remain concise and consist almost entirely of package
names.

The parser remains straightforward to implement and test.

Future backends remain responsible for interpreting version semantics
according to their native package manager.

## Non-Goals

This ADR does not define the syntax of package names.

It does not define backend-specific version formats.

It does not require every backend to support identical version
capabilities, provided unsupported constraints fail with clear
diagnostics.

## Future Considerations

If future requirements justify richer constraint expressions, they
should be introduced through a new ADR rather than extending the grammar
incrementally.

The project should continue to favor human readability over expressive
power.

## Summary

Version constraints are intentionally simple.

The bootstrap engine expresses version intent using a small set of
operators while delegating version comparison and interpretation to the
native package manager.
