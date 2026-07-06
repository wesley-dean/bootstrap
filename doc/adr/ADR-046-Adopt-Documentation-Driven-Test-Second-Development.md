# ADR-046: Adopt Documentation-Driven, Test-Second Development

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's preferred
development workflow.

The project shall follow a documentation-driven, test-second approach in
which documentation defines intent, implementation realizes that intent,
and automated tests verify that the implementation behaves as
documented.

## Context

Earlier ADRs establish that:

-   documentation is part of the product;
-   architecture should be explicit;
-   public interfaces are long-term contracts;
-   observable behavior should be tested rather than implementation
    details.

Traditional Test-Driven Development (TDD) places executable tests at the
center of the design process. This project instead places documentation
first because the intended audience includes both humans and AI-assisted
contributors.

The documentation explains *why* a capability exists before code is
written. Tests then become executable evidence that the implementation
faithfully realizes the documented behavior.

## Decision

The project shall adopt the following development sequence:

1.  Document the intended behavior.
2.  Implement the smallest correct change.
3.  Add or update automated tests that verify the observable behavior.
4.  Verify formatting, linting, and tests before considering the work
    complete.

Documentation establishes architectural intent.

Code implements that intent.

Tests verify the implementation.

Whenever functionality is added, removed, corrected, or otherwise
changed, the corresponding tests should be added or updated as part of
the same change. Test work should not be deferred to a later milestone
or pull request.

## Rationale

Documentation provides the shared understanding from which
implementation and tests are derived.

Keeping documentation, implementation, and tests synchronized reduces
the risk of architectural drift and increases confidence that the
software behaves as intended.

Adding tests immediately after implementation also discourages
incomplete changes and helps ensure that regressions are detected early.

## Alternatives Considered

### Traditional Test-Driven Development

The project could require tests to be written before implementation.

This was rejected because the project intentionally treats documentation
as the primary design artifact and architectural record.

### Documentation Without Automated Tests

The project could rely on documentation and manual verification alone.

This was rejected because manually verified behavior is difficult to
reproduce and regressions become more likely over time.

## Consequences

Contributors should update documentation and tests whenever behavior
changes.

Bug fixes should normally include regression tests that would have
failed prior to the fix.

Behavior-oriented tests are preferred over tests tightly coupled to
internal implementation.

A change that modifies functionality without corresponding test updates
should be considered incomplete unless there is a documented
justification.

## Non-Goals

This ADR does not prohibit writing tests before implementation when
useful.

It does not prescribe a particular testing framework.

It does establish the expected relationship between documentation, code,
and tests.

## Future Considerations

Future tooling may automate checks ensuring that code, documentation,
and tests remain synchronized.

Contributor guidance and review checklists should reinforce this
workflow.

## Summary

The project follows documentation-driven, test-second development.

Documentation defines intent.

Implementation realizes that intent.

Automated tests provide executable evidence that the implementation
continues to satisfy the documented behavior.
