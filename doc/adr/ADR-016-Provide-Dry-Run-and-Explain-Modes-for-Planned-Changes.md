# ADR-016: Provide Dry-Run and Explain Modes for Planned Changes

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
should support non-mutating modes that allow users to inspect planned
behavior before system changes are made.

This decision builds directly upon ADR-015, which introduced a planning
phase before execution.

## Context

The bootstrap engine may install packages and perform other privileged
operations.

Earlier ADRs establish that the project should be inspectable,
conservative, and resistant to surprising behavior.

Once the engine constructs an execution plan before making system
changes, that plan becomes valuable not only internally but also as a
user-facing explanation.

Users benefit from being able to ask:

-   What would this manifest do?
-   Which packages are already satisfied?
-   Which packages would be installed?
-   Which package requirements cannot be satisfied?
-   Why is the engine refusing to continue?

Without a dry-run or explain mode, users must either read the source
code, trust the implementation, or execute the tool to discover its
behavior.

That does not align with the project's trust model.

## Decision

The bootstrap engine should support a dry-run mode.

Dry-run mode shall parse manifests, validate intent, query the package
manager as needed, construct the execution plan, and report the planned
actions without making system changes.

The bootstrap engine should also support an explain-oriented mode,
either as a separate option or as an extension of dry-run behavior.

Explain-oriented output should help users understand why the engine
selected a particular action or refused to proceed.

The exact command-line options are implementation details, but likely
forms include:

``` bash
bootstrap.bash --dry-run packages.txt
bootstrap.bash --explain packages.txt
```

## Rationale

Dry-run mode reinforces the project's conservative operating philosophy.

It gives users a low-risk way to validate manifests before performing
privileged operations.

It also supports development and testing by allowing package-resolution
logic to be exercised without modifying the host system.

Explain mode reinforces the project's documentation-first posture by
making the engine's reasoning visible.

Together, these modes turn the execution plan from an internal
implementation detail into a trust-building feature.

## Alternatives Considered

### Execute Immediately After Planning

The engine could construct a plan internally and then execute it
immediately without exposing it to users.

This was rejected because it misses an opportunity to improve
transparency and reduce risk.

### Rely on Package Manager Simulation Alone

Some package managers provide simulation or dry-run flags.

Those features remain useful, but they do not explain the bootstrap
engine's own interpretation of the manifest.

The bootstrap engine should be able to describe its own decisions before
delegating work to the package manager.

## Consequences

The planning phase must be designed so that it can be executed
independently of the installation phase.

Output formatting becomes important because users must be able to
understand planned actions clearly.

Future behavior changes should consider how they appear in dry-run and
explain modes.

Tests should cover dry-run behavior separately from mutating
installation behavior.

## Non-Goals

This ADR does not define exact command-line option names.

It does not define the full output format.

It does not require machine-readable output, although such output may be
added later.

It does not require package-manager-level simulation to be used, though
that may be valuable where available.

## Future Considerations

Future versions may support structured output formats such as JSON for
use by automation.

Future versions may also include package-manager-native simulations
alongside the bootstrap engine's own execution plan.

If confirmation prompts are introduced, dry-run output may provide the
same information that users review before approving execution.

## Summary

The bootstrap engine should allow users to see what it intends to do
before it does it.

Dry-run and explain modes strengthen safety, transparency, testability,
and trust by exposing the planned behavior produced by the engine's
parsing, validation, and planning phases.
