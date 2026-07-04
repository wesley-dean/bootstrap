# ADR-006: Preserve a Stable Bootstrap Interface While Allowing Internal Evolution

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the public interface
of the bootstrap engine shall remain intentionally small and stable even
as its internal implementation evolves.

Users should depend upon a consistent invocation model rather than the
internal technologies used to satisfy their requested intent.

## Context

Software that survives for many years rarely retains its original
implementation.

Libraries are replaced.

Operating systems evolve.

New package managers emerge.

Configuration frameworks gain or lose relevance.

The bootstrap engine should be expected to evolve in similar ways.

Today, the implementation may consist primarily of a Bash script
coordinating APT.

A future implementation may invoke helper libraries, Ansible playbooks,
compiled utilities, or platform-specific adapters.

These internal changes should not require users to continually relearn
how the project is used.

## Decision

The project shall expose a stable bootstrap interface.

The command-line interface, manifest semantics, and user workflow should
change only when there is compelling architectural justification.

Internal implementation details may evolve freely provided they preserve
the established contract.

For example, the public interface may remain conceptually similar to:

``` text
bootstrap.bash [options] <intent>
```

regardless of whether the implementation internally calls native package
managers, helper programs, or configuration-management frameworks.

## Rationale

A stable interface reduces cognitive load.

Users should invest their effort in describing workstation intent rather
than tracking implementation changes.

Maintaining a stable interface also encourages internal improvement.

Developers are free to refactor, optimize, or replace implementation
components without disrupting existing workflows.

This separation mirrors the broader philosophy established by earlier
ADRs:

-   configuration expresses intent;
-   native tooling performs specialized work;
-   reusable software remains separate from user policy.

The bootstrap interface becomes the enduring contract that binds these
principles together.

## Alternatives Considered

### Expose Internal Implementation

One approach would expose package-manager commands, helper scripts, or
configuration-framework details directly to users.

This alternative was rejected because it tightly couples user workflows
to the current implementation.

### Freeze the Implementation

Another possibility would be to prohibit significant implementation
changes in order to preserve compatibility.

This was rejected because it would unnecessarily limit future
improvements and adaptation to changing operating systems.

## Consequences

The project gains freedom to evolve internally while preserving a
familiar user experience.

Documentation may describe implementation details where useful, but
those details should not become part of the public contract unless
intentionally adopted as such.

Compatibility should be evaluated from the perspective of user intent
rather than source-code organization.

## Non-Goals

This ADR does not guarantee that every implementation detail remains
unchanged.

It does not prohibit new command-line options or additional
capabilities.

It simply establishes that implementation changes should preserve the
existing bootstrap experience whenever practical.

## Future Considerations

Future versions may introduce helper executables, richer manifest
formats, platform-specific backends, or optional integrations with
external tools.

Such additions should appear as implementation improvements rather than
breaking changes to the user-facing interface.

## Summary

The bootstrap engine's interface is a long-lived architectural contract.

Internal implementation is expected to evolve.

By preserving a stable public interface while allowing implementation
freedom, the project minimizes disruption, encourages continual
improvement, and keeps user attention focused on describing workstation
intent rather than adapting to internal change.
