# Roadmap

This roadmap describes the recommended sequence for building the
bootstrap engine from today's repository into a usable,
production-quality tool.

It is intentionally incremental. Each milestone should leave the
repository in a working, releasable state.

## Guiding Principles

Before beginning any milestone:

-   Read `AGENTS.md`.
-   Review the relevant ADRs.
-   Produce the smallest correct patch.
-   Preserve stable public interfaces.
-   Prefer explicit behavior over implicit behavior.
-   Update tests and documentation alongside implementation.

No milestone is complete until:

-   `make format`
-   `make check`
-   `make test`

all succeed.

------------------------------------------------------------------------

# Phase 0 -- Foundation (Complete)

## Repository

-   Repository structure established.
-   ADR collection drafted.
-   AGENTS.md established.
-   Makefile present.
-   GitHub Actions configured.
-   Initial bootstrap entry point exists.

**Status:** Complete.

------------------------------------------------------------------------

# Phase 1 -- Build System (Complete)

Goal: produce a releasable bootstrap script from modular sources.

Tasks:

-   Create `src/` and `lib/`.
-   Implement `make all`.
-   Concatenate/build `dist/bootstrap.bash`.
-   Add release metadata (version, build date, commit).
-   Verify generated artifact is reproducible.
-   Update release workflow to publish the artifact.

Deliverable:

A GitHub Release containing a generated `bootstrap.bash`.

------------------------------------------------------------------------

# Phase 2 -- Command-Line Interface (Complete)

Goal: establish the public CLI.

Tasks:

-   `--help`
-   `--version`
-   `--dry-run`
-   `--explain`
-   `--verbose`
-   `--quiet`

Define exit codes consistent with the ADRs.

Write behavior-oriented Bats tests.

Deliverable:

Stable CLI suitable for future compatibility.

------------------------------------------------------------------------

# Phase 3 -- Manifest Parser (Complete)

Goal: interpret package manifests.

Tasks:

-   Finalize grammar.
-   Ignore comments and blank lines.
-   Parse package declarations.
-   Validate syntax.
-   Produce structured internal representation.

Do not install anything yet.

Deliverable:

Parser and parser tests.

------------------------------------------------------------------------

# Phase 4 -- Planning Engine (Complete)

Goal: separate planning from execution.

Tasks:

-   Convert parsed manifest into execution plan.
-   Resolve backend.
-   Order operations deterministically.
-   Produce explainable plan output.

Deliverable:

Planning engine with dry-run support.

------------------------------------------------------------------------

# Phase 5 -- Backend Abstraction

Goal: isolate package management.

Tasks:

-   Backend interface.
-   Initial APT implementation.
-   Package existence checks.
-   Install planning.
-   Error translation.

Deliverable:

APT backend behind stable interface.

------------------------------------------------------------------------

# Phase 6 -- Execution Engine

Goal: execute approved plans.

Tasks:

-   Execute planned operations.
-   Honor dry-run.
-   Logging.
-   Progress reporting.
-   Error handling.
-   Stable exit codes.

Deliverable:

First usable installer.

------------------------------------------------------------------------

# Phase 7 -- Configuration (complete)

Goal: support user customization.

Tasks:

-   Configuration precedence.
    - CLI paramters top priority
    - environment variables second priority
    - .env file third priority
-   Variables namespaced to BOOTSTRAP_
-   Default configuration.
-   Explicit overrides.
-   Validation.
-   Documentation.

Deliverable:

Stable configuration behavior.

------------------------------------------------------------------------

# Phase 8 -- User Experience (complete)

Tasks:

-   Human-friendly diagnostics.
-   Helpful recovery guidance.
-   Explain mode improvements.
-   Consistent log formatting.
-   Documentation examples.

Deliverable:

Pleasant day-to-day user experience.

------------------------------------------------------------------------

# Phase 9 -- Testing

Expand automated testing.

Include:

-   parser tests
-   planner tests
-   CLI tests
-   backend tests
-   integration tests
-   regression tests

Prefer observable behavior over implementation details.

------------------------------------------------------------------------

# Phase 10 -- Release Readiness

Tasks:

-   ShellCheck clean.
-   shfmt clean.
-   Bats passing.
-   GitHub Actions green.
-   Release workflow complete.
-   Release notes.
-   Checksums.
-   Signed release (optional).
-   SBOM (future).

Deliverable:

Version 1.0 candidate.

------------------------------------------------------------------------

# Future Enhancements

Potential future work includes:

-   additional package backends (APK, DNF)
-   manifest composition
-   workstation profiles
-   experimental features
-   package groups
-   verification improvements
-   richer explain output

These should be evaluated against the ADRs before implementation.

------------------------------------------------------------------------

# Working Practices for Future Agentic Development Sessions

A future development session should follow this workflow:

1.  Read `AGENTS.md`.
2.  Read this roadmap.
3.  Review the relevant ADRs before designing a feature.
4.  Work on exactly one roadmap task at a time.
5.  Produce unit tests for any new, changed, updated, deleted code
6.  Produce the smallest correct patch.
7.  Update documentation as part of the implementation.
8.  Add or update behavior-oriented tests.
9.  Run formatting, linting, and tests.
10. Stop after the requested milestone rather than beginning the next
    one.

If uncertainty exists, identify the assumptions, ask only the questions
that materially affect the outcome, and avoid expanding the scope of the
requested work.

------------------------------------------------------------------------

# Definition of Success

The roadmap is complete when the project provides:

-   a single generated bootstrap artifact;
-   a stable documented CLI;
-   deterministic planning;
-   reliable package installation through native package managers;
-   comprehensive tests;
-   excellent documentation;
-   an architecture that remains faithful to the ADRs.

At that point, future work should primarily extend capabilities rather
than reconsider the architecture.
