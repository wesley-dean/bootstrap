# ADR-020: Provide Human-Centered Diagnostics

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy and
objectives of the bootstrap engine's diagnostic output.

Diagnostics are the primary interface between the bootstrap engine and
its users when something unexpected occurs. Consequently, they should
optimize for human understanding rather than merely reporting program
state.

## Context

Earlier ADRs establish that the bootstrap engine should:

-   fail conservatively;
-   parse manifests before making system changes;
-   construct an execution plan before execution;
-   expose dry-run and explain capabilities.

These architectural decisions depend upon users understanding what the
engine is doing and why.

Poor diagnostics increase support burden, reduce user confidence, and
encourage trial-and-error rather than deliberate system administration.

## Decision

Diagnostics shall be written for humans first.

Whenever practical, an error should answer four questions:

1.  What happened?
2.  Where did it happen?
3.  Why did the bootstrap engine reject it?
4.  What can the user do next?

Manifest-related diagnostics should identify:

-   the manifest filename;
-   the logical line number;
-   the offending input;
-   a concise explanation of the problem.

Warnings shall be reserved for situations where execution can safely
continue.

Errors shall terminate execution whenever continuing would violate the
project's conservative execution philosophy.

## Rationale

Users should not need to read the source code to understand why
execution stopped.

Well-designed diagnostics shorten debugging sessions, improve trust, and
make the bootstrap engine approachable for both experienced
administrators and occasional users.

This philosophy also improves automated testing because expected
diagnostics become part of the project's observable behavior.

## Alternatives Considered

### Minimal Diagnostics

The bootstrap engine could report only the failing command or exit
status.

This was rejected because such messages rarely provide enough
information for users to resolve configuration problems efficiently.

### Delegate Diagnostics Entirely to the Package Manager

The project could rely exclusively on package-manager error messages.

This was rejected because package managers cannot explain the bootstrap
engine's interpretation of manifests or planning decisions.

The bootstrap engine should explain its own reasoning before delegating
work.

## Consequences

Diagnostic messages become a stable part of the user experience.

Changes to diagnostics should improve clarity without sacrificing
precision.

Tests should validate significant diagnostics where practical.

Documentation should reference common diagnostic messages when
describing expected behavior.

## Non-Goals

This ADR does not prescribe the exact wording of individual messages.

It does not define exit codes.

It does not require localization or machine-readable diagnostics.

Those concerns may be addressed independently in the future.

## Future Considerations

Future versions may provide:

-   structured diagnostics;
-   JSON output;
-   verbosity controls;
-   colorized output;
-   hyperlinks to documentation.

Such enhancements should preserve the principle that human-readable
diagnostics remain the default interface.

## Summary

The bootstrap engine should communicate clearly.

Every diagnostic should help the user understand what happened, why it
happened, and what action, if any, should be taken next.
