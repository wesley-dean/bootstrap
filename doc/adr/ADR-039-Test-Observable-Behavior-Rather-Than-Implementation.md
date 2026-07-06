# ADR-039: Test Observable Behavior Rather Than Implementation

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's philosophy
for testing.

Tests should validate the observable behavior promised by the project's
public interfaces rather than the internal implementation used to
realize that behavior.

## Context

Previous ADRs establish that the project values stable public
interfaces, layered responsibilities, composition, and conservative
evolution.

The implementation of the bootstrap engine will naturally evolve over
time. Functions may be renamed, logic may be reorganized, and internal
algorithms may be improved without changing the behavior experienced by
users.

Tests that depend upon implementation details make such improvements
more difficult by coupling the test suite to internal structure instead
of external contracts.

## Decision

The project's automated tests shall primarily verify observable
behavior.

Examples include:

-   manifest parsing results;
-   execution planning;
-   command-line behavior;
-   diagnostics;
-   logging;
-   exit code categories;
-   generated artifacts.

Tests should avoid depending upon:

-   private helper function names;
-   source file organization;
-   implementation sequencing that is not externally visible;
-   incidental formatting unrelated to documented behavior.

When implementation details must be tested directly, those tests should
be treated as exceptions rather than the default testing strategy.

## Rationale

Behavior-oriented tests support refactoring.

Developers can improve internal architecture with confidence that
meaningful behavior remains unchanged.

This philosophy also aligns with the project's emphasis on stable public
interfaces. If the observable behavior has not changed, implementation
improvements should rarely require widespread changes to the test suite.

## Alternatives Considered

### Test Internal Functions Directly

The project could build tests around individual Bash functions.

This was rejected because such tests tightly couple the suite to the
current implementation and discourage architectural improvements.

### Minimize Automated Testing

The project could rely primarily on manual verification.

This was rejected because repeatable automated testing is essential for
preserving long-term stability and confidence.

## Consequences

Acceptance tests become the primary measure of correctness.

Refactoring internal implementation should usually leave
behavior-oriented tests unchanged.

Contributors should consider whether new tests verify public contracts
or implementation details before adding them.

## Non-Goals

This ADR does not prohibit targeted unit tests for complex internal
logic.

It does not prescribe a specific testing framework beyond the project's
current tooling.

It does not require every observable behavior to be tested immediately.

## Future Considerations

Future testing may include integration tests, golden-file comparisons,
property-based testing, or backend-specific validation.

Regardless of technique, preference should continue to be given to
verifying observable behavior over implementation details.

## Summary

Tests should protect the project's public contracts rather than its
current implementation.

By validating behavior instead of structure, the test suite supports
confident refactoring while preserving the stable interfaces established
throughout the project.
