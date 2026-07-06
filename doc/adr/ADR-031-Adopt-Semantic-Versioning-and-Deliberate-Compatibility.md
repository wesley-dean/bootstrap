# ADR-031: Adopt Semantic Versioning and Deliberate Compatibility

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's philosophy
for versioning and compatibility.

Version numbers should communicate the expected impact of a release and
provide users with a predictable framework for adopting updates.

## Context

Previous ADRs establish that the project values stable public
interfaces, human-readable manifests, conservative evolution, and
explicit architectural contracts.

As the project matures, users will rely on version numbers to determine
whether upgrading is expected to be routine or whether additional review
may be appropriate.

The project therefore requires a consistent versioning strategy.

## Decision

The project shall adopt Semantic Versioning as the foundation for
release numbering.

Version increments should communicate the nature of externally visible
changes.

In general:

-   patch releases correct defects and improve implementation without
    changing public interfaces;
-   minor releases introduce backward-compatible capabilities;
-   major releases may introduce intentional incompatibilities with
    documented migration guidance.

Compatibility decisions should be evaluated in terms of the project's
public interfaces as established by previous ADRs rather than internal
implementation details.

## Rationale

Semantic Versioning is widely understood throughout the software
industry.

Using a familiar versioning model reduces ambiguity and allows users,
automation, and downstream documentation to establish appropriate
expectations before upgrading.

It also reinforces the distinction between public contracts and internal
implementation that has become a recurring architectural theme
throughout the project.

## Alternatives Considered

### Calendar Versioning

The project could identify releases primarily by date.

This was rejected because release dates communicate recency but not
compatibility expectations.

### Ad Hoc Versioning

The project could increment version numbers without defined semantics.

This was rejected because users would have no reliable way to judge
upgrade risk.

## Consequences

Release notes should describe compatibility implications in addition to
new features.

Contributors should consider version impact when proposing changes that
affect public interfaces.

Internal refactoring that preserves public behavior should not, by
itself, require a major version increment.

## Non-Goals

This ADR does not define the project's initial version number.

It does not establish support windows or release cadence.

It does not define a formal deprecation process.

## Future Considerations

Future ADRs may define feature lifecycles, deprecation policies, and
compatibility windows.

Those policies should build upon the versioning philosophy established
by this ADR.

## Summary

Version numbers are a communication mechanism.

They should accurately reflect the compatibility impact of each release
and provide users with confidence when deciding whether and how to
upgrade.
