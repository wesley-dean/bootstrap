# ADR-026: Define a Stable Exit Code Philosophy

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
process exit codes returned by the bootstrap engine.

Exit codes form part of the project's public interface and should
communicate high-level outcomes consistently to both interactive users
and automation.

## Context

The bootstrap engine is expected to be used interactively, within shell
scripts, and by continuous integration systems.

Previous ADRs establish that diagnostics are written for humans and
logging is optimized for progressive disclosure. Exit codes complement
those interfaces by providing a concise, machine-readable indication of
overall success or failure.

As the project evolves, additional features should not require consumers
to reinterpret existing exit code meanings.

## Decision

The bootstrap engine shall treat exit codes as a stable public contract.

Exit codes should represent categories of outcomes rather than
individual implementation details.

Representative categories include:

-   successful completion;
-   invalid user input;
-   manifest or configuration errors;
-   planning failures;
-   backend or package manager failures;
-   unexpected internal errors.

Each category should remain stable across releases whenever practical.

Human-readable diagnostics shall accompany non-zero exit codes.

## Rationale

Stable exit codes enable reliable automation.

By categorizing failures rather than assigning unique codes to every
possible condition, the project preserves flexibility while remaining
predictable.

Users receive detailed explanations through diagnostics while scripts
receive a stable mechanism for detecting broad classes of outcomes.

## Alternatives Considered

### Single Failure Exit Code

The bootstrap engine could return the same non-zero exit code for every
error.

This was rejected because automation often needs to distinguish user
mistakes from environmental or backend failures.

### Highly Granular Exit Codes

The project could assign a unique exit code to nearly every failure.

This was rejected because such schemes become difficult to document,
maintain, and evolve without breaking consumers.

## Consequences

Exit code assignments should be documented and tested.

Changes to existing exit code meanings should be treated as
compatibility changes.

Future features should map naturally onto existing outcome categories
whenever possible.

## Non-Goals

This ADR does not assign specific numeric exit codes.

It does not define shell signal handling.

It does not require every internal error condition to have a unique exit
code.

## Future Considerations

Future versions may publish a formal exit code reference and expose
structured diagnostics alongside traditional process exit status.

Those additions should complement, rather than replace, the stable exit
code contract.

## Summary

Exit codes are part of the bootstrap engine's public interface.

They should communicate stable categories of outcomes while detailed
diagnostics provide the information needed to understand and resolve
failures.
