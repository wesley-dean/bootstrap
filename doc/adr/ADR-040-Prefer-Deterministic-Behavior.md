# ADR-040: Prefer Deterministic Behavior

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes determinism as a guiding
architectural principle for the bootstrap engine.

Given the same inputs and operating environment, the bootstrap engine
should produce the same observable behavior whenever practical.

## Context

Previous ADRs establish that the project favors explicit configuration,
conservative execution, stable public interfaces, planning before
execution, human-centered diagnostics, reproducible releases, and
behavior-oriented testing.

A common thread throughout these decisions is determinism.

Deterministic behavior simplifies reasoning, testing, troubleshooting,
documentation, and automation. It reduces surprises by ensuring that
users can predict how the engine will behave before executing it.

## Decision

The bootstrap engine shall prefer deterministic behavior throughout its
architecture.

Where practical, the engine should produce consistent results for
identical inputs.

Examples include:

-   deterministic manifest parsing;
-   deterministic configuration precedence;
-   deterministic execution planning;
-   deterministic package ordering where ordering is under the engine's
    control;
-   deterministic diagnostics;
-   deterministic logging;
-   deterministic release artifacts whenever practical.

Sources of nondeterminism should be introduced only when they provide
clear architectural value.

When deterministic behavior cannot be guaranteed because of external
systems, the project should make those dependencies explicit.

## Rationale

Predictability is fundamental to trust.

Deterministic behavior enables users to reproduce problems, compare
results, write reliable automation, and understand the relationship
between inputs and outputs.

It also strengthens the project's testing strategy because expected
behavior can be verified consistently across environments.

## Alternatives Considered

### Allow Opportunistic Behavior

The project could optimize for convenience or performance by allowing
behavior to vary based on runtime conditions that are not visible to the
user.

This was rejected because hidden variability increases cognitive load
and makes failures more difficult to reproduce.

### Accept Incidental Nondeterminism

The project could ignore ordering, formatting, or behavioral differences
that appear harmless.

This was rejected because small inconsistencies often accumulate into
larger maintenance and debugging challenges over time.

## Consequences

Contributors should evaluate new features for their impact on
determinism.

Where multiple correct implementations exist, preference should
generally be given to the one that produces the most consistent
observable behavior.

Documentation should identify cases where external tools or
operating-system behavior may introduce unavoidable variability.

## Non-Goals

This ADR does not require controlling behavior that belongs to external
package managers or operating systems.

It does not prohibit concurrency or optimization where correctness and
predictability are preserved.

It does not require byte-for-byte identical output in every
circumstance.

## Future Considerations

Future capabilities should preserve deterministic behavior whenever
practical.

If new features introduce unavoidable nondeterminism, they should
document the conditions under which behavior may vary and explain why
that tradeoff is necessary.

## Summary

Deterministic behavior makes the bootstrap engine easier to understand,
test, document, and trust.

Whenever practical, identical inputs should produce identical observable
behavior, reinforcing the project's broader commitment to explicit
intent, predictability, and conservative evolution.
