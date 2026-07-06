# ADR-013: Fail Conservatively and Avoid Surprising System Changes

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the operational philosophy
of the bootstrap engine when interacting with user systems.

The bootstrap engine may execute with elevated privileges and modify
operating system packages. Consequently, it shall prefer predictable,
conservative behavior over aggressive automation.

Whenever uncertainty exists, the bootstrap engine should fail rather
than guess.

## Context

The purpose of the bootstrap engine is to help transform a freshly
installed system into a useful workstation.

Unlike many installation tools, it is not intended to continuously
enforce configuration drift or completely own the machine. Instead, it
performs deliberate, user-initiated changes.

Because those changes frequently occur with elevated privileges,
unexpected behavior can have significant consequences.

Examples include:

-   installing unintended packages;
-   removing existing software;
-   downgrading packages;
-   silently accepting malformed manifests;
-   interpreting ambiguous input differently than the user intended.

The project seeks to minimize surprises, even when doing so requires
stopping execution and asking the user to correct a problem.

## Decision

The bootstrap engine shall prefer conservative behavior.

Specifically:

-   malformed manifests shall produce errors;
-   ambiguous package requirements shall produce errors;
-   package removals shall never occur implicitly;
-   package downgrades shall require explicit user intent;
-   unsupported syntax shall not be silently ignored;
-   diagnostics shall clearly explain why execution stopped.

When user intent cannot be determined with confidence, the bootstrap
engine shall terminate with an informative error rather than making
assumptions.

## Rationale

Unexpected automation is itself a source of incidents.

By failing conservatively, the bootstrap engine helps users understand
both what it intends to do and why it refuses to proceed when it cannot
safely continue.

This philosophy complements the project's emphasis on inspectability,
transparency, and deliberate execution.

## Alternatives Considered

### Attempt Automatic Recovery

The bootstrap engine could infer missing information, skip malformed
entries, or continue after recoverable errors.

This alternative was rejected because different users may reasonably
expect different interpretations. Guessing increases the risk of
unintended changes.

### Ignore Invalid Input

The project could silently skip lines that it cannot parse.

This was rejected because silent failures frequently lead to partially
configured systems that are difficult to diagnose.

## Consequences

Manifest parsing should be intentionally strict.

Error reporting becomes a first-class feature of the project.

Future capabilities should be evaluated not only for functionality but
also for how predictable they remain under failure conditions.

## Non-Goals

This ADR does not define exit codes, error message formats, or
confirmation prompt behavior.

Those are implementation details that may evolve independently.

## Future Considerations

Future versions may introduce:

-   `--dry-run`;
-   `--explain`;
-   structured diagnostics;
-   machine-readable output.

Such capabilities should reinforce, rather than weaken, the project's
conservative operating philosophy.

## Summary

The bootstrap engine should never surprise its users.

When uncertainty exists, it should stop, explain the situation clearly,
and allow the user to decide how to proceed.
