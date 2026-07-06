# ADR-015: Perform a Planning Phase Before Making System Changes

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
shall determine all required package operations before invoking the
operating system package manager.

The planning phase is distinct from manifest parsing and package
installation.

## Context

ADR-014 separates manifest parsing from package installation.

Once the manifest has been parsed into an internal representation, the
bootstrap engine must determine what work, if any, is required.

For each requested package the engine may need to determine whether:

-   the package is already installed;
-   the installed version satisfies the requested constraint;
-   installation is required;
-   an upgrade is required;
-   the requested constraint cannot be satisfied.

If these decisions are made immediately before each installation, the
overall plan remains opaque and difficult to explain, test, or review.

## Decision

The bootstrap engine shall construct a complete execution plan before
making any system modifications.

The execution plan shall describe the intended operation for every
requested package.

Only after the plan has been successfully constructed shall package
installation begin.

The execution plan is an internal implementation detail and need not be
exposed to users, although future features may present it.

## Rationale

Planning before execution complements the project's conservative
operating philosophy.

It allows the bootstrap engine to identify errors before privileged
operations begin.

It also creates a natural foundation for future capabilities such as:

-   `--dry-run`;
-   `--explain`;
-   structured logging;
-   richer diagnostics;
-   machine-readable output.

The planning phase also simplifies testing because planning logic can be
validated independently of package installation.

## Alternatives Considered

### Plan and Execute Simultaneously

The bootstrap engine could inspect one package, immediately perform the
required action, and continue to the next.

This was rejected because it prevents complete validation before
modifying the system and makes future explanation features more
difficult.

### Delegate Planning to the Package Manager

The bootstrap engine could invoke the package manager immediately and
rely upon it to determine the required operations.

This was rejected because the project intentionally owns the
interpretation of user intent and should be able to explain its own
decisions.

## Consequences

Execution naturally divides into phases:

1.  Parse manifests.
2.  Validate intent.
3.  Construct an execution plan.
4.  Execute the plan.
5.  Report results.

Future enhancements should build upon these phases rather than bypassing
them.

## Non-Goals

This ADR does not define the structure of the execution plan.

It does not require optimization of package operations.

It does not prescribe whether planning should query the package manager
once or multiple times.

## Future Considerations

Future versions may expose the execution plan to users through
`--dry-run`, `--plan`, or `--explain` modes.

Such features should reuse the planning phase rather than implementing
independent decision logic.

## Summary

Before modifying the system, the bootstrap engine shall determine what
changes are required.

Separating planning from execution improves safety, testability,
diagnostics, and future extensibility while remaining consistent with
the project's conservative operating philosophy.
