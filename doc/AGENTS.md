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

Before making significant changes, review the relevant ADRs. In
particular:

-   Treat documentation as part of the product.
-   Preserve stable public interfaces.
-   Favor deterministic, inspectable behavior.
-   Prefer composition over special cases.
-   Optimize for the next contributor.

For documentation work, ADR-045 is mandatory guidance.

## Architectural Principles

-   Bash 5+ is the universal bootstrap entry point.
-   Configuration describes desired state.
-   Native package managers remain authoritative.
-   Separate the bootstrap engine from user intent.
-   Support progressive adoption.
-   Preserve a stable public interface.
-   Prefer inspectable execution paths.
-   Prefer explicit behavior over implicit behavior.
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

Do not reimplement package-management behavior already provided by the
operating system.

Avoid `eval`.

Use defensive shell practices.

Favor simple, explicit implementations over clever ones.

## Scope Discipline

Unless the user explicitly requests otherwise, produce the smallest
correct patch that satisfies the request.

Limit changes to the minimum necessary to implement the requested
behavior.

Do not:

-   reformat unrelated code;
-   rewrite unrelated comments or documentation;
-   reorder functions, declarations, or imports for style alone;
-   rename identifiers without a functional reason;
-   modernize syntax unrelated to the request;
-   fix unrelated defects opportunistically;
-   make architectural improvements outside the requested scope.

If additional improvements are identified, report them separately rather
than including them in the patch.

When the request is documentation-only, executable behavior must remain
unchanged. If behavior cannot be confidently preserved, stop and ask for
guidance rather than broadening the scope of the edit.

## Documentation Standards

Follow the documentation-first philosophy established by the ADRs.

When documenting code:

-   explain intent rather than syntax;
-   explain why a construct exists;
-   document assumptions, invariants, failure modes, and safety
    considerations where appropriate;
-   include realistic examples when they improve comprehension.

Documentation should reduce cognitive load for someone reading the code
months or years later.

## Documentation-Only Requests

When asked only to add or improve documentation:

-   do not modify executable behavior;
-   do not refactor implementation;
-   do not reorder logic unless explicitly requested;
-   preserve edge-case handling exactly;
-   verify that only comments or documentation changed.

If behavior cannot confidently be preserved, stop and ask for guidance.

## Handling Ambiguity

Do not invent architectural rationale or implementation intent.

When intent cannot be established with reasonable confidence:

-   preserve the existing code;
-   add a specific `@TODO` identifying what is unclear when appropriate;
-   make uncertainty explicit rather than speculative.

Honest uncertainty is preferred over plausible but incorrect
documentation.

## Validation

When practical:

-   review diffs to ensure requested changes were performed;
-   run the project's linters and tests after code changes;
-   confirm documentation-only requests did not alter executable
    behavior.

## Common Failure Modes for AI Agents

Avoid:

-   rewriting files when only documentation was requested;
-   replacing implementation with stubs;
-   removing edge-case handling;
-   inventing design rationale;
-   silently expanding the scope of a requested change;
-   silently changing public behavior;
-   introducing unnecessary dependencies;
-   violating established ADRs for convenience.

## Final Principle

Every change should leave the repository easier for the next contributor
to understand.

Keep the bootstrap engine small, inspectable, reusable, well-documented,
and focused on helping users describe and realize workstation intent.
