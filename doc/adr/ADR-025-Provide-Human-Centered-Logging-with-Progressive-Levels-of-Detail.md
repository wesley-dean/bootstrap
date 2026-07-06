# ADR-025: Provide Human-Centered Logging with Progressive Levels of Detail

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
runtime logging produced by the bootstrap engine.

Logging communicates what the engine is doing during execution. It
should help users understand progress without overwhelming them with
implementation details.

## Context

The bootstrap engine is expected to be used interactively during
workstation bootstrapping as well as within automated environments.

Previous ADRs establish that the project values:

-   inspectability;
-   explicit intent;
-   conservative execution;
-   human-centered diagnostics.

Runtime logging should reinforce those principles.

The bootstrap engine should communicate meaningful progress while
avoiding unnecessary verbosity.

## Decision

The bootstrap engine shall produce human-readable logging by default.

Default output should communicate:

-   major execution phases;
-   significant decisions;
-   package installation progress;
-   completion status.

Implementation details that are primarily useful for debugging shall be
hidden unless explicitly requested.

The engine should support progressively more detailed output through
verbosity controls rather than emitting all information unconditionally.

## Rationale

Most users care about what the engine is doing rather than how it is
implemented.

Keeping default output concise improves readability while still allowing
advanced users to request additional detail when troubleshooting.

Progressive verbosity also provides a natural foundation for future
structured logging without complicating the default user experience.

## Alternatives Considered

### Always Verbose

The bootstrap engine could display every command it executes.

This was rejected because it obscures meaningful progress beneath
implementation details.

### Minimal Output

The bootstrap engine could report only fatal errors.

This was rejected because users benefit from understanding long-running
operations and knowing which execution phase is currently active.

## Consequences

The bootstrap engine should distinguish between:

-   progress reporting;
-   verbose debugging;
-   diagnostics.

Future logging enhancements should extend these categories rather than
merging them.

Documentation should illustrate default output rather than only verbose
examples.

## Non-Goals

This ADR does not define specific verbosity levels.

It does not require log files.

It does not require structured logging.

Those capabilities may be introduced independently in the future.

## Future Considerations

Future versions may provide:

-   `--verbose`;
-   `--quiet`;
-   JSON logging;
-   timestamps;
-   progress indicators.

Such enhancements should preserve the principle that the default
experience is optimized for interactive human use.

## Summary

Logging should help users understand what the bootstrap engine is doing
without requiring them to understand how it is implemented.

The default experience should remain concise, human-readable, and
progressively expandable when additional detail is requested.
