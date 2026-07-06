# ADR-048: Execution SHALL Consume Only Resolved Actions

Date: 2026-07-06

## Status

Accepted

## Context

The bootstrap engine is intentionally organized as a sequence of independent
transformation stages:

1. Parse user input.
2. Plan the desired operations.
3. Resolve implementation details for the current platform.
4. Execute the resolved operations.

ADR-047 established that the planner produces immutable Action Records
describing what should happen. The resolver transforms those Action Records
into Resolved Actions describing how those operations can be performed on the
current system.

Without a clear architectural boundary, execution logic can gradually become
coupled to planning or resolution responsibilities, making the system more
difficult to test, extend, and maintain.

The project values modularity, deterministic planning, portability, and
separation of concerns.

## Decision

Executors shall consume only Resolved Action objects.

Executors shall not:

- parse manifests;
- interpret manifest syntax;
- perform planning;
- select package managers;
- detect operating-system capabilities;
- resolve platform-specific implementation details.

Those responsibilities belong to earlier pipeline stages.

Executors are responsible solely for performing the work described by a
Resolved Action and producing an Execution Result.

An Execution Result shall describe the outcome of execution, including success
or failure and any implementation-specific information required by downstream
reporting.

## Consequences

### Positive

- Planning remains deterministic and platform independent.
- Platform resolution remains isolated from execution.
- Executors remain small and focused.
- Additional executors may be implemented independently.
- Dry-run and explain modes continue to share the same planning and resolution
  pipeline as actual execution.
- Testing becomes simpler because executors can be exercised using synthetic
  Resolved Actions without requiring manifest parsing or planning.

### Negative

- Execution depends on successful completion of prior pipeline stages.
- Additional object transformations exist within the architecture.
- More internal abstractions must be maintained.

## Rationale

Separating execution from planning ensures that each stage of the bootstrap
pipeline has a single responsibility.

The planner determines what should happen.

The resolver determines how those operations can be performed on the current
platform.

The executor performs only the work described by the Resolved Action.

This separation reduces coupling, improves portability, simplifies testing, and
provides a stable architectural foundation for supporting additional operating
systems, package managers, and execution backends.

## Related ADRs

- ADR-047: Represent Planned Bootstrap Operations as Immutable Action Records
