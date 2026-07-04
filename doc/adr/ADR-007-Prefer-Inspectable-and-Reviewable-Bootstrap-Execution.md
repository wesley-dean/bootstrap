# ADR-007: Prefer Inspectable and Reviewable Bootstrap Execution

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's trust model
for executing bootstrap logic obtained from remote sources.

The project favors execution paths that encourage inspection, review,
and deliberate user consent before privileged operations are performed.

## Context

Bootstrap software is frequently executed on freshly installed systems.

Historically, many projects have promoted commands such as:

``` bash
curl -fsSL https://example.org/bootstrap.bash | sudo bash
```

Although convenient, this pattern asks users to execute privileged code
that they have not had a meaningful opportunity to inspect.

The convenience is attractive, particularly during a workstation
rebuild, but it also creates a habit of trusting opaque remote
execution.

This project seeks to encourage a healthier balance between convenience
and transparency.

## Decision

The preferred execution path shall allow users to inspect a bootstrap
script before it executes.

The recommended mechanism is `vet`, which provides an opportunity to
review a remote script before approving execution.

The project shall also document manual download-and-review workflows.

A direct `curl | bash` invocation may be documented as a convenience or
recovery mechanism, but it is not the preferred execution model.

The bootstrap engine itself should remain a single, readable Bash script
that users can reasonably inspect.

## Rationale

The project's objective is to reduce operational surprises.

Encouraging review before execution aligns with that objective.

Because the bootstrap engine is intentionally small, users can
realistically understand what it will do. This inspectability would be
undermined if the recommended workflow discouraged inspection
altogether.

The project therefore optimizes for informed execution rather than blind
trust.

## Alternatives Considered

### Recommend Only `curl | bash`

This approach minimizes typing and is common across many projects.

It was rejected as the primary recommendation because it normalizes
execution of privileged code without prior inspection.

### Require Manual Download and Inspection

This approach maximizes transparency.

It was rejected as the only supported workflow because it introduces
friction that may discourage adoption during routine workstation
rebuilds.

The project instead recommends a middle ground by preferring `vet` while
continuing to support manual inspection and documenting a convenience
fallback.

## Consequences

Documentation should present the preferred workflow first.

The bootstrap script should remain concise, well documented, and
suitable for human review.

New features should be evaluated not only for functionality but also for
their effect on the inspectability of the bootstrap engine.

## Non-Goals

This ADR does not attempt to define a complete software supply-chain
security model.

It does not guarantee that a reviewed script is free from defects.

It establishes only the project's preferred interaction model between
users and remote bootstrap code.

## Future Considerations

Future versions may support additional verification mechanisms such as
signed releases, checksum verification, reproducible artifacts, or other
provenance technologies.

Such mechanisms should complement, rather than replace, the ability for
users to inspect the bootstrap engine.

## Summary

The bootstrap engine should be easy to inspect and easy to trust.

The project therefore recommends review-oriented execution paths,
prefers `vet` for remote execution, supports manual inspection
workflows, and treats direct `curl | bash` usage as a documented
convenience rather than the architectural ideal.
