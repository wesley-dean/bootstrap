# ADR-047: Represent Planned Bootstrap Operations as Immutable Action Records

Date: 2026-07-05

## Status

Accepted

## Context

The bootstrap engine is intentionally divided into distinct phases:

1.  Parse user input.
2.  Plan the desired operations.
3.  Resolve platform-specific implementation details.
4.  Execute the resolved operations.

Without a well-defined representation between these stages, components
become tightly coupled. The planner would require knowledge of package
managers, executors would require knowledge of manifest syntax, and
testing would become increasingly difficult.

The project values deterministic behavior, modularity, portability, and
testability. These values are reflected throughout the existing ADRs and
should also govern the interfaces between the planner, resolver, and
executor.

## Decision

The planner shall produce immutable Action Records.

An Action Record describes what should happen, but never how it will be
performed.

Action Records shall not contain platform-specific implementation details
such as:

-   package manager selection;
-   operating-system-specific commands;
-   shell command lines;
-   distribution-specific package names;
-   other execution-specific implementation details.

Later stages may derive additional information from an Action Record,
but shall not modify the original Action Record.

Instead, subsequent stages shall create new derived objects that enrich
the original Action Record with implementation-specific information.

The architectural pipeline is therefore:

``` text
Manifest
    │
    ▼
Parser
    │
    ▼
Manifest Entry
    │
    ▼
Planner
    │
    ▼
Action Record
    │
    ▼
Resolver
    │
    ▼
Resolved Action
    │
    ▼
Executor
    │
    ▼
Execution Result
```

Each stage is responsible for transforming one representation into the
next while remaining independent of downstream implementation details.

This ADR intentionally does not specify the serialization or in-memory
representation of Action Records. Those are implementation details that
may evolve independently provided the architectural contract remains
unchanged.

## Consequences

The parser remains platform independent.

The planner remains platform independent.

Resolvers can be implemented independently for different operating
systems and package managers.

Executors consume a consistent abstraction regardless of platform.

Dry-run and explain modes consume the same Action Records used for
actual execution.

Unit testing becomes simpler because each stage can be tested
independently.

An additional resolver stage is required.

More internal representations exist within the system.

Slightly more code is required to transform data between stages.

## Rationale

Separating what should happen from how it is performed keeps planning
deterministic, improves portability, reduces coupling, and establishes a
stable architectural contract between the planning and execution portions
of the bootstrap engine.
