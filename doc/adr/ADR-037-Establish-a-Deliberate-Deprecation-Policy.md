# ADR-037: Establish a Deliberate Deprecation Policy

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes how the project should
retire features, interfaces, and behaviors.

Deprecation is an architectural activity, not merely an implementation
detail. Users should have sufficient notice and guidance before
compatibility-affecting changes are introduced.

## Context

Previous ADRs establish that the project values stable public
interfaces, semantic versioning, explicit architectural decisions, and
conservative evolution.

Those principles imply that functionality should rarely disappear
without warning. Even when a better design exists, users benefit from a
predictable transition path.

## Decision

The project shall prefer deprecation over immediate removal.

When a public interface is expected to change:

-   the existing behavior should be documented as deprecated;
-   documentation should identify the preferred replacement;
-   migration guidance should be provided;
-   removal should normally occur only in a future major release.

Deprecation notices should explain *why* the change is occurring rather
than simply announcing that it will occur.

Architectural changes that introduce deprecations should normally be
accompanied by an ADR.

## Rationale

A deliberate deprecation process balances architectural improvement with
user stability.

Users, automation, and documentation all require time to adapt.
Predictable transitions reduce operational risk while allowing the
project to continue evolving.

## Alternatives Considered

### Immediate Removal

The project could replace obsolete behavior as soon as a better
alternative is available.

This was rejected because it unnecessarily breaks existing users and
weakens confidence in the stability of the project.

### Permanent Backward Compatibility

The project could retain every historical interface indefinitely.

This was rejected because obsolete behavior accumulates complexity,
increases maintenance burden, and obscures the preferred way of using
the project.

## Consequences

Contributors should consider migration impact whenever proposing changes
to public interfaces.

Documentation should identify deprecated behavior clearly and
consistently.

Release notes should summarize active deprecations and recommended
migration paths.

## Non-Goals

This ADR does not define a fixed deprecation period.

It does not prohibit immediate removal when required to address critical
correctness or security issues.

It does not establish specific warning formats.

## Future Considerations

Future releases may automate deprecation reporting, provide
compatibility checks, or offer migration assistance.

Those capabilities should reinforce the project's commitment to
predictable evolution.

## Summary

Deprecation is a communication process as much as a technical process.

The project should evolve deliberately by giving users clear notice,
practical migration guidance, and reasonable time to adopt improved
interfaces before older ones are retired.
