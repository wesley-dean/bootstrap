# AGENTS.md

This file provides guidance for AI coding agents working in this
repository.

Use this file together with `README.md`. The README is the human-facing
project overview. This file is the agent-facing operational map.

## Project Overview

This repository contains a Bash-based bootstrap engine for preparing
fresh or minimally configured development systems.

The project exists to help a machine begin becoming useful from a small,
inspectable entry point. The initial focus is installing curated package
manifests on Debian-family systems, especially Ubuntu, Kubuntu, Debian,
and Chromebook/Crostini environments.

The project is intentionally not a full configuration-management system.
It may later hand off to tools such as Ansible, but Bash is the stable
bootstrap surface.

## Read the ADRs First

The ADR collection is the canonical source of architectural intent.

Before making significant changes, review the relevant ADRs.
Documentation work shall follow ADR-045. Build/development dependency work
shall preserve the boundaries established by ADR-051. Generated artifact flavor,
minification, checksum, and release work shall preserve ADR-052 as refined by
ADR-053 for checksum companion naming and historical-read compatibility.

## Clarify Before Acting

When a request is ambiguous or incomplete, prefer asking clarifying
questions over making assumptions.

Identify the information needed to produce a high-quality result,
explicitly identify assumptions that would materially affect the
outcome, and ask only the questions necessary to resolve meaningful
ambiguity.

Do **not** ask about conventions whose answers are overwhelmingly common
or whose impact is negligible (for example, using the repository's
primary language, following existing formatting conventions, or avoiding
profanity).

Ask yourself:

> **Would two reasonable answers produce meaningfully different
> software?**

If yes, ask. If no, choose the conventional answer, note any significant
assumption if appropriate, and continue.

A useful guiding principle is:

> **Before you answer, tell me what you need to know to answer well, and
> point out any assumptions you'd otherwise make.**

## Architectural Principles

-   Bash 5+ is the universal bootstrap entry point.
-   Configuration describes desired state.
-   Native package managers remain authoritative.
-   Preserve stable public interfaces.
-   Prefer explicit, deterministic, inspectable behavior.
-   Keep the core engine intentionally small.
-   Keep build/development dependency tooling outside released runtime
    artifacts.

## Technology Stack

Runtime and project implementation:

-   Bash 5+
-   apt-get
-   apt-cache
-   dpkg
-   vet
-   Plain-text manifests

Development/build orchestration also uses Make and the pinned released
`bashdeps.bash` bootstrap described by ADR-051. Bash-Minifier is a
manifest-managed build dependency used only to derive the minified release flavor
under ADR-052.

## Build and Dependency Boundaries

The Makefile directly bootstraps only the pinned `vendor/bashdeps.bash`
artifact. It verifies that artifact against the SHA-256 digest committed in the
Makefile before executing it.

Ordinary externally acquired build/development artifacts are declared in
`dependencies.txt` and synchronized by bashdeps under ADR-051. Do not add new
one-off download rules to Make for dependencies that fit the released bashdeps
contract. Current manifest-managed artifacts include the Bash Doxygen filter and
the commit-pinned Bash-Minifier input at `vendor/bash-minifier.bash`.

Preserve these target semantics:

-   `make deps` may use the network and converges dependency state.
-   `make deps-check` verifies existing dependency state without network access
    or repair.
-   `make build` does not bootstrap, synchronize, or verify external
    dependencies, but it requires already-prepared Bash-Minifier state.
-   A fresh checkout uses `make all` or `make deps` followed by `make build`.
-   `make all` explicitly synchronizes dependencies before invoking `build`.
-   `make docs` consumes already-prepared documentation dependency state and
    does not acquire it implicitly.

`make build` produces six distribution files:

```text
dist/bootstrap.dev.bash
dist/bootstrap.bash
dist/bootstrap.min.bash
dist/bootstrap.dev.bash.sha256
dist/bootstrap.bash.sha256
dist/bootstrap.min.bash.sha256
```

New builds and releases publish only `.sha256` checksum companions. Historical
`.256` release assets remain valid for the releases that contain them. Consumers
that retrieve checksum sidecars across release generations should prefer
`.sha256` and use `.256` only when the preferred companion is confirmed absent;
retrieval or verification failures are not fallback conditions.

The development artifact retains assembled source comments. The ordinary
`bootstrap.bash` artifact removes full-line comments while preserving the
shebang. The minified artifact is derived from that stripped artifact using the
prepared Bash-Minifier dependency. All three executable artifacts represent the
same runtime program and shall remain executable.

`vendor/` and `doc/reference/` are generated state and are excluded from source
control. All three `dist/bootstrap*.bash` consumer artifacts must remain
functional without bashdeps, Bash-Minifier, `dependencies.txt`, or the vendor
tree after construction.

Treat `dependencies.txt` as data. Do not source or evaluate it as shell code.
The committed digest, rather than a filename or URL label, is authoritative for
approved dependency bytes. Published checksum sidecars do not replace committed
dependency digests.

## Coding Guidelines

Prefer small, readable Bash functions.

Avoid `eval`.

Do not reimplement functionality already provided by the operating
system.

Favor simple, explicit implementations over clever ones.

## Scope Discipline

Unless explicitly requested otherwise, produce the smallest correct
patch that satisfies the request.

Do not expand the scope by performing unrelated refactoring, formatting,
renaming, documentation updates, or architectural improvements.

If additional opportunities for improvement are discovered, report them
separately rather than including them in the patch.

Documentation-only requests must preserve executable behavior exactly.

## Documentation Standards

Follow the documentation-first philosophy established by the ADRs.

Documentation should explain intent, assumptions, constraints, safety
considerations, and examples where appropriate.

## Testing

This project follows **documentation-driven development** and
**test-second development**.

Documentation establishes intent first. Immediately after functionality
is added, changed, removed, or corrected, the corresponding automated
tests should be added or updated before considering the work complete.

Do not defer test work to a later milestone.

Every functional change should prompt the question:

-   What observable behavior changed?
-   How can that behavior be verified automatically?

Prefer tests that validate externally observable behavior rather than
implementation details.

When a bug is fixed, add or update a regression test that would have
failed before the fix.

When introducing new functionality:

-   add or update Bats tests as part of the same change;
-   ensure existing tests continue to pass;
-   expand coverage for new public behavior;
-   update examples or documentation when behavior changes.

Build/dependency changes should also exercise the applicable ADR-051 boundaries:
network-free build behavior, explicit dependency synchronization, offline
verification, tamper detection, convergence, and runtime independence from
generated vendor state.

Artifact-generation changes shall apply the observable behavior suite to all
three executable flavors under ADR-052. Tests should avoid assuming that release
metadata or executable statements occupy the same physical lines in the minified
artifact. Build-specific tests should verify all six expected files, executable
permissions, checksum validity, removal of stale `.256` companions,
transformation lineage, and runtime independence from `vendor/`.

A change is normally incomplete if the implementation changes but the
corresponding tests do not.

## Handling Ambiguity

Do not invent architectural rationale or implementation intent.

When intent cannot be determined with reasonable confidence, preserve
the existing code and make the uncertainty explicit.

## Validation

When practical:

-   review the resulting diff;
-   run formatting, linting, and tests;
-   run `make deps` and `make deps-check` when dependency state is relevant;
-   verify all generated consumer artifacts remain functional without `vendor/`;
-   verify every `.sha256` file matches its corresponding executable;
-   verify no stale `.256` companion remains after a successful build;
-   verify documentation-only requests changed only documentation.

## Common Failure Modes

Avoid:

-   rewriting files when only documentation was requested;
-   replacing implementation with stubs;
-   silently expanding scope;
-   inventing design rationale;
-   changing public behavior unintentionally;
-   reintroducing direct Makefile acquisition for manifest-managed dependencies;
-   making `build`, `deps-check`, or `docs` silently repair dependency state;
-   minifying maintained source files individually rather than the complete
    assembled stripped artifact;
-   treating the minified artifact as exempt from the ordinary behavior suite.

## Final Principle

Every change should leave the repository easier for the next contributor
to understand.

Keep the bootstrap engine small, inspectable, well-documented,
well-tested, reusable, and faithful to the project's ADRs.
