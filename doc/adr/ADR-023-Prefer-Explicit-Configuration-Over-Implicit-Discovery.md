# ADR-023: Prefer Explicit Configuration Over Implicit Discovery

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the philosophy governing
how the bootstrap engine discovers and consumes configuration.

The project shall prefer explicit user intent over implicit discovery.

Configuration should be supplied deliberately rather than inferred
through search heuristics whenever practical.

## Context

The bootstrap engine is intended to be predictable, inspectable, and
conservative.

Previous ADRs establish that the engine should:

-   describe desired state rather than procedures;
-   fail conservatively when intent is unclear;
-   avoid surprising system changes;
-   provide clear diagnostics;
-   expose execution planning before performing privileged operations.

These principles naturally extend to configuration discovery.

Many tools automatically search the current directory, parent
directories, user configuration directories, or system configuration
directories until they find a plausible configuration file.

While convenient, such behavior can make it difficult for users to
understand why a particular configuration was selected.

Implicit discovery also complicates testing, documentation, and
diagnostics.

## Decision

The bootstrap engine shall prefer explicit configuration.

Users should specify manifests, configuration files, profiles, and other
primary inputs through command-line options whenever practical.

If default locations are supported, they shall be:

-   few in number;
-   clearly documented;
-   deterministic;
-   easy to explain through diagnostics.

The bootstrap engine shall not recursively search arbitrary directory
trees, guess user intent, or silently choose among multiple equally
valid configuration sources.

When conflicting configuration sources are supplied, the engine shall
report the conflict rather than selecting one implicitly.

## Rationale

Explicit configuration improves predictability.

Users can determine exactly why the bootstrap engine behaved as it did
by examining the supplied command line.

Documentation becomes simpler because configuration precedence is easy
to describe.

Testing becomes more reliable because each test can specify all required
inputs directly.

This philosophy is consistent with the project's broader emphasis on
reducing surprises and making behavior inspectable.

## Alternatives Considered

### Automatic Configuration Discovery

The bootstrap engine could search the current working directory, parent
directories, user configuration directories, or system configuration
directories for manifests or configuration files.

This was rejected because hidden discovery rules increase cognitive load
and make behavior more difficult to predict.

### Convention Over Configuration

The project could adopt a convention that a file with a particular name
is automatically used whenever present.

This was rejected because convenience should not come at the cost of
transparency.

Explicitly naming configuration inputs makes execution easier to
understand and reproduce.

## Consequences

Documentation should encourage explicit command lines.

Examples should identify manifests and configuration files directly.

Future features should prefer additional command-line options over
introducing new implicit discovery rules.

Any default configuration locations should remain stable and be treated
as part of the project's public interface.

## Non-Goals

This ADR does not prohibit sensible defaults.

It does not define specific command-line option names.

It does not prevent future support for user or system configuration
files, provided their discovery rules remain deterministic and well
documented.

## Future Considerations

Future versions may support multiple configuration sources with explicit
precedence rules.

Such precedence should be documented, deterministic, and explainable
through diagnostic output.

If automatic discovery is ever introduced, it should be opt-in rather
than the default behavior.

## Summary

The bootstrap engine should do what the user explicitly asked it to do.

Convenience features should never obscure configuration selection or
require users to guess which inputs the engine ultimately chose.
