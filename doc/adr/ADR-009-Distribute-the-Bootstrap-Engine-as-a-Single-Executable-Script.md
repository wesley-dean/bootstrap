# ADR-009: Distribute the Bootstrap Engine as a Single Executable Script

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
shall be distributed as a single executable Bash script.

The goal is to optimize for inspectability, portability, and ease of use
during the earliest stages of system bootstrap.

This ADR governs how the bootstrap engine is packaged and distributed.
It does not prohibit the use of external operating-system tools such as
`apt-get`, `apt-cache`, `dpkg`, or other native utilities.

## Context

The project's primary use case is bringing a freshly installed system to
a useful state with as little friction as possible.

A typical user should be able to execute a single command such as:

``` bash
vet https://example.org/bootstrap.bash -- ./packages.txt
```

or, when necessary, download the same script, inspect it, and execute it
locally.

Many bootstrap systems consist of multiple shell libraries, helper
scripts, or directories of supporting code. While modular, those designs
require users to clone repositories, download archives, or otherwise
acquire multiple files before the bootstrap process can begin.

This project deliberately values a smaller distribution surface over
internal modularity.

## Decision

The bootstrap engine shall be distributed as a single executable Bash
script named `bootstrap.bash`.

That script is the public entry point and the complete bootstrap engine.

Internal organization shall be achieved through functions rather than
separate source files.

The script may invoke operating-system tools and other installed
executables, but it shall not require project-specific shell libraries
or auxiliary Bash source files.

## Rationale

A single-file distribution offers several advantages.

It is easy to inspect before execution.

It is easy to distribute from a single URL.

It is straightforward to vendor into another project.

It minimizes ambiguity about the project's entry point.

It aligns with the project's preference for reviewable remote execution
and small bootstrap surfaces.

Although a multi-file implementation may improve code organization, it
also introduces additional distribution complexity. Since the bootstrap
engine is expected to remain modest in size, that tradeoff is not
justified at this time.

## Alternatives Considered

### Multiple Shell Libraries

The project could separate functionality into `lib/`, `src/`, or similar
directories.

This approach was rejected because it complicates distribution and
inspection, particularly for first-time users executing the bootstrap
engine from a single URL.

### Self-Extracting Archive

The project could distribute a single wrapper that downloads or extracts
additional components.

This was rejected because it obscures what code will ultimately execute
and works against the project's emphasis on inspectability.

## Consequences

The repository may contain documentation, examples, tests, and build
tooling, but the executable bootstrap engine remains a single file.

Internal refactoring should prefer well-named functions and clear
organization within that file rather than introducing project-specific
Bash modules.

As the script grows, maintainability should be addressed through
documentation, testing, and disciplined structure before introducing
additional source files.

## Non-Goals

This ADR does not prohibit invoking external programs supplied by the
operating system.

It does not prohibit generating release artifacts from other sources in
the future, provided the published bootstrap engine remains a single
executable script.

It does not establish a maximum script size.

## Future Considerations

If the bootstrap engine eventually grows beyond what can be reasonably
maintained as a single file, the project should revisit this decision
through a new ADR rather than allowing the architecture to drift
incrementally.

Such a reconsideration should weigh the benefits of modularity against
the project's goals of simplicity, inspectability, and ease of
distribution.

## Summary

The bootstrap engine is intentionally packaged as one executable Bash
script.

This decision favors a simple and transparent user experience over
internal modularity, ensuring that the project's public interface
remains easy to obtain, inspect, understand, and execute from a single
location.
