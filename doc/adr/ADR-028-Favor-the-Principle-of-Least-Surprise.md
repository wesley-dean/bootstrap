# ADR-028: Favor the Principle of Least Surprise

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the Principle of Least
Surprise as a guiding architectural principle for the bootstrap engine.

Every feature should behave in the way an informed user is most likely
to expect. When multiple reasonable behaviors exist, the project should
favor the one that is easiest to explain, document, and predict.

## Context

Previous ADRs establish a consistent philosophy:

-   manifests express explicit intent;
-   configuration is explicit rather than implicitly discovered;
-   execution is planned before changes occur;
-   diagnostics are human-centered;
-   logging communicates meaningful progress;
-   trust is earned through inspectability.

Taken together, these decisions reflect a broader objective: users
should rarely be surprised by the bootstrap engine.

## Decision

The bootstrap engine shall favor predictable behavior over clever
behavior.

In particular:

-   explicit configuration shall take precedence over implicit behavior;
-   hidden state shall be minimized;
-   defaults shall be deterministic and documented;
-   ambiguous input shall result in diagnostics rather than guesses;
-   automation shall not silently alter user intent.

Features that increase surprise should require a compelling
architectural justification.

## Rationale

Unexpected behavior creates unnecessary incidents.

Users build mental models of software based on documentation and
experience. When those models differ from reality, troubleshooting
becomes more difficult and confidence decreases.

A conservative, predictable engine reduces cognitive load and makes
successful execution easier to reproduce.

## Alternatives Considered

### Optimize for Convenience

The project could prioritize reducing keystrokes through implicit
discovery, context-sensitive behavior, and automatic inference.

This was rejected because convenience gained through hidden behavior
often results in greater long-term complexity.

### Optimize for Maximum Flexibility

The project could expose numerous configuration mechanisms and
behavioral variations.

This was rejected because additional flexibility frequently increases
the number of possible execution paths, making the engine more difficult
to reason about.

## Consequences

Future proposals should consider whether they increase or reduce user
surprise.

Documentation should explain defaults and precedence rules clearly.

Behavioral compatibility should be valued alongside functional
correctness.

## Non-Goals

This ADR does not prohibit adding new features.

It does not require eliminating all defaults.

It does not imply that every user will prefer every design choice.

## Future Considerations

As the project evolves, new capabilities should be evaluated against
this principle.

If a feature cannot be explained succinctly or is likely to surprise
informed users, alternative designs should be considered before
adoption.

## Summary

The bootstrap engine should behave the way users reasonably expect.

Predictability, transparency, and explicit intent are preferred over
cleverness or hidden automation because they reduce surprises and
strengthen trust.
