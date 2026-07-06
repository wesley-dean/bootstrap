# ADR-024: Provide a Stable and Explicit Command-Line Interface

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
the bootstrap engine's command-line interface (CLI).

The CLI is the project's primary public interface. It should be stable,
predictable, and intentionally conservative.

## Context

Previous ADRs establish that the project favors explicit configuration,
human-readable manifests, conservative execution, and inspectable
behavior.

Those same principles should guide the command-line interface.

Although it is tempting to add convenience options, overloaded flags, or
context-sensitive behavior, each such addition increases cognitive load
and makes documentation more difficult to maintain.

The command-line interface should express user intent clearly without
requiring users to memorize hidden behaviors.

## Decision

The bootstrap engine shall provide a stable command-line interface based
on the following principles.

-   Long options are preferred for clarity.
-   Short options are convenience aliases rather than the primary
    interface.
-   Options should be orthogonal and perform one logical function.
-   Option behavior shall not change based on unrelated arguments.
-   Defaults shall be deterministic and documented.
-   Errors shall be reported rather than silently corrected.

Mutually exclusive options shall be rejected with clear diagnostics.

The CLI should evolve conservatively to preserve compatibility for
scripts, documentation, and users.

## Rationale

The command line is often the first part of the project that users
encounter.

A consistent CLI reduces documentation burden and makes automation
easier.

Stable interfaces also reduce maintenance costs because examples, blog
posts, and automation scripts remain useful across releases.

Explicit options reinforce the project's philosophy of making user
intent visible rather than inferred.

## Alternatives Considered

### Context-Sensitive Commands

The bootstrap engine could alter option behavior depending on detected
configuration, current directory, operating system, or other runtime
state.

This was rejected because it obscures user intent and complicates both
documentation and troubleshooting.

### Convenience Over Consistency

The project could introduce numerous aliases, overloaded options, or
abbreviated syntaxes.

This was rejected because convenience should not come at the expense of
predictability.

## Consequences

Documentation should primarily use long options.

Examples should demonstrate explicit invocation.

Future CLI additions should fit naturally into the existing interface
rather than introducing special cases.

Changes that affect existing command lines should be treated as
significant public interface changes.

## Non-Goals

This ADR does not define the complete set of command-line options.

It does not prescribe a particular argument-parsing library or
implementation.

It does not prohibit adding new options where they improve functionality
while remaining consistent with the project's philosophy.

## Future Considerations

Future versions may introduce subcommands or additional operational
modes.

Such additions should preserve backwards compatibility whenever
practical and maintain the principle that the CLI communicates intent
clearly.

## Summary

The bootstrap engine's command-line interface is a public contract.

It should remain explicit, stable, orthogonal, and easy to understand,
making the engine approachable for both interactive users and
automation.
