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
Documentation work shall follow ADR-045.

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

## Technology Stack

-   Bash 5+
-   apt-get
-   apt-cache
-   dpkg
-   vet
-   Plain-text manifests

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
-   verify documentation-only requests changed only documentation.

## Common Failure Modes

Avoid:

-   rewriting files when only documentation was requested;
-   replacing implementation with stubs;
-   silently expanding scope;
-   inventing design rationale;
-   changing public behavior unintentionally.

## Final Principle

Every change should leave the repository easier for the next contributor
to understand.

Keep the bootstrap engine small, inspectable, well-documented,
well-tested, reusable, and faithful to the project's ADRs.
