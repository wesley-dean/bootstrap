# Architectural Decision Summary

`doc/decisions.md` is a derived operational index of the architectural and
consequential engineering decisions recorded in `doc/adr/ADR*.md`.  It does not
replace the ADR corpus.  When a summary is incomplete, ambiguous, or inconsistent
with its source ADR, the source ADR is authoritative.

Each entry below reports the status recorded by its source ADR.  A `Proposed`
entry is summarized because it is part of the repository's decision history; its
presence here does not promote it to `Accepted`.  Where a later ADR explicitly
supersedes or refines part of an earlier decision, the summary notes that
relationship.

## ADR-000: Capability Scope, Epistemic Honesty, and Separation of Concerns

**Status:** Accepted

Systems operating under this decision must be explicit about capabilities and
limits, prefer accuracy over agreement, separate concerns, avoid anthropomorphic
or sycophantic framing, ground claims in evidence, and refuse performative
over-commitment.  These constraints are treated as correctness requirements
rather than presentation preferences.

Source: [ADR-000](adr/ADR-000-capability-scope-and-epistemic-honesty.md)

## ADR-001: Use a Single Bash 5+ Script as the Bootstrap Entry Point

**Status:** Proposed

Bootstrap proposes Bash 5+ as the universal first-run surface so a fresh system
can begin becoming useful from one inspectable script with minimal prerequisites.
The Bash entry point coordinates native package-management tools rather than
becoming a full configuration-management system; tools such as Ansible may be
used later but are not required for the initial bootstrap.

Source: [ADR-001](adr/ADR-001-bash-tooling.md)

## ADR-002: Describe Desired State Rather Than Installation Procedures

**Status:** Proposed

Configuration should describe what a system should become rather than embed the
commands used to construct it.  Procedural implementation belongs in the
Bootstrap engine whenever practical, allowing user intent to remain readable and
to survive changes in the mechanism used to realize it.

Source: [ADR-002](adr/ADR-002-Describe-Desired-State-Rather-Than-Installation-Procedures.md)

## ADR-003: Treat Native Package Managers as the Source of Truth

**Status:** Proposed

Bootstrap should interpret package intent while leaving dependency resolution,
version semantics, repository trust, package authenticity, and installation
policy to the operating system's native package manager.  The engine orchestrates
package managers rather than reimplementing them.

Source: [ADR-003](adr/ADR-003-Treat-Native-Package-Managers-as-the-Source-of-Truth.md)

## ADR-004: Separate the Bootstrap Engine from User Intent

**Status:** Proposed

Reusable Bootstrap behavior should remain separate from user- or
organization-specific policy such as manifests, profiles, dotfiles, and host
configuration.  The engine consumes those external intent artifacts without
owning them, allowing implementation and policy to evolve independently.

Source: [ADR-004](adr/ADR-004-Separate-the-Bootstrap-Engine-from-User-Intent.md)

## ADR-005: Design the Bootstrap Experience Around Progressive Adoption

**Status:** Proposed

Bootstrap should provide useful value at the smallest level of adoption and make
later capabilities additive rather than mandatory prerequisites.  Users should
be able to stop after any useful stage without being forced to adopt the entire
ecosystem.

Source: [ADR-005](adr/ADR-005-Design-the-Bootstrap-Experience-Around-Progressive-Adoption.md)

## ADR-006: Preserve a Stable Bootstrap Interface While Allowing Internal Evolution

**Status:** Proposed

The command-line interface, manifest semantics, and user workflow should remain
small and stable while internal implementations may evolve.  Refactoring,
platform adapters, helper tools, or later implementation changes are acceptable
when they preserve the established external contract.

Source: [ADR-006](adr/ADR-006-Preserve-a-Stable-Bootstrap-Interface-While-Allowing-Internal-Evolution.md)

## ADR-007: Prefer Inspectable and Reviewable Bootstrap Execution

**Status:** Proposed

The preferred execution path should let users inspect Bootstrap before it runs,
with `vet` and manual download-and-review workflows favored over blind remote
execution.  A direct `curl | bash` form may exist as a convenience or recovery
path, but it is not the preferred trust model.

Source: [ADR-007](adr/ADR-007-Prefer-Inspectable-and-Reviewable-Bootstrap-Execution.md)

## ADR-008: Define a Human-Centered Package Manifest Format

**Status:** Proposed

The package manifest should be plain UTF-8 text with one package requirement per
logical line, comments and blank lines for readability, insignificant surrounding
whitespace, and a deliberately small set of optional version constraints.  It
should express package requirements rather than package-manager commands.

Source: [ADR-008](adr/ADR-008-Define-a-Human-Centered-Package-Manifest-Format.md)

## ADR-009: Distribute the Bootstrap Engine as a Single Executable Artifact

**Status:** Proposed

Bootstrap may be maintained as modular source, while users receive standalone
executable Bash artifacts rather than the source tree.  The original decision
named `dist/bootstrap.bash` as the single canonical release artifact; ADR-052
later supersedes the single-artifact portion by defining three standalone release
flavors.

Source: [ADR-009](adr/ADR-009-Distribute-the-Bootstrap-Engine-as-a-Single-Executable-Script.md)

## ADR-010: Build the Distribution Artifact from Modular Source Files

**Status:** Proposed

Maintained Bash source should be organized by responsibility and assembled by the
build system into generated distribution output under `dist/`, which is not a
source of truth.  The build should be deterministic for the same source and
inputs; ADR-052 later supersedes the single-output portion by defining three
artifact flavors derived from the assembled program.

Source: [ADR-010](adr/ADR-010-Build-the-Distribution-Artifact-from-Modular-Source-Files.md)

## ADR-011: Publish Release Artifacts Through GitHub Releases

**Status:** Proposed

GitHub Releases should be the canonical publication mechanism for generated
Bootstrap artifacts built from tagged, validated source, while `dist/` remains
uncommitted build output.  Later accepted decisions expand the release surface
beyond the single `bootstrap.bash` asset described by this original proposal.

Source: [ADR-011](adr/ADR-011-Publish-Release-Artifacts-Through-GitHub-Releases.md)

## ADR-012: Use Make as the Local and CI Orchestration Interface

**Status:** Proposed

Make should provide the canonical project interface for recurring development,
validation, testing, build, and release-preparation operations.  CI workflows
should invoke project-owned Make targets whenever practical instead of duplicating
the underlying commands in workflow configuration.

Source: [ADR-012](adr/ADR-012-Use-Make-as-the-Local-and-CI-Orchestration-Interface.md)

## ADR-013: Fail Conservatively and Avoid Surprising System Changes

**Status:** Proposed

Bootstrap should stop with useful diagnostics when user intent is malformed,
ambiguous, or unsupported rather than guess.  Package removals must not occur
implicitly, downgrades require explicit intent, and unsafe continuation is
rejected in favor of predictable system changes.

Source: [ADR-013](adr/ADR-013-Fail-Conservatively-and-Avoid-Surprising-System-Changes.md)

## ADR-014: Separate Manifest Parsing from Package Installation

**Status:** Proposed

Bootstrap should completely parse and validate manifests into an internal
representation before package installation begins.  Installation consumes that
validated representation rather than reading manifests directly, keeping parsing
and mutation independently testable and preventing late parse failures after
earlier system changes.

Source: [ADR-014](adr/ADR-014-Separate-Manifest-Parsing-from-Package-Installation.md)

## ADR-015: Perform a Planning Phase Before Making System Changes

**Status:** Proposed

After parsing, Bootstrap should construct a complete execution plan describing the
intended operation for each request before making system modifications.  Planning
is a distinct phase that supports validation, testing, dry-run behavior, and
explanation independently of execution.

Source: [ADR-015](adr/ADR-015-Perform-a-Planning-Phase-Before-Making-System-Changes.md)

## ADR-016: Provide Dry-Run and Explain Modes for Planned Changes

**Status:** Proposed

Bootstrap should provide non-mutating dry-run behavior that performs parsing,
validation, package-manager queries, and planning without changing the system.
Explain-oriented output should expose why actions were selected or rejected so
users can inspect the engine's reasoning before privileged work occurs.

Source: [ADR-016](adr/ADR-016-Provide-Dry-Run-and-Explain-Modes-for-Planned-Changes.md)

## ADR-017: Delegate Package Operations to Native Package Managers

**Status:** Proposed

Package discovery, dependency resolution, version comparison, and installation
should use native package-manager facilities instead of custom Bootstrap
implementations.  Bootstrap owns interpretation and planning; native package
managers own the mechanics and ecosystem-specific semantics of package
operations.

Source: [ADR-017](adr/ADR-017-Delegate-Package-Operations-to-Native-Package-Managers.md)

## ADR-018: Define a Stable Manifest Grammar

**Status:** Proposed

The manifest language should remain intentionally minimal: blank lines, comments,
one package requirement per logical line, and optional version constraints.
Malformed input should be rejected rather than inferred, and future grammar
changes should preserve backward compatibility whenever practical.

Source: [ADR-018](adr/ADR-018-Define-a-Stable-Manifest-Grammar.md)

## ADR-019: Define Stable Version Constraint Semantics

**Status:** Proposed

The initial manifest grammar proposes package-only requirements plus `=`, `==`,
`>`, and `>=` constraints, with `=` and `==` treated as equivalent exact-version
operators.  Version comparison belongs to native package-manager facilities, and
unsupported or invalid constraints should fail clearly rather than be compared as
shell strings.

Source: [ADR-019](adr/ADR-019-Define-Stable-Version-Constraint-Semantics.md)

## ADR-020: Provide Human-Centered Diagnostics

**Status:** Proposed

Diagnostics should be written for humans first and, where practical, explain what
happened, where it happened, why Bootstrap stopped, and what the user can do next.
Warnings are for conditions where execution can safely continue; errors should
stop execution when continuation would violate the conservative safety model.

Source: [ADR-020](adr/ADR-020-Provide-Human-Centered-Diagnostics.md)

## ADR-021: Layer the Bootstrap Engine Around Well-Defined Responsibilities

**Status:** Proposed

Bootstrap should be organized as a pipeline of configuration loading, manifest
parsing, validation, planning, backend execution, and reporting/diagnostics.
Each responsibility consumes the preceding stage's output rather than
reinterpreting input or taking on another layer's work.

Source: [ADR-021](adr/ADR-021-Layer-the-Bootstrap-Engine-Around-Well-Defined-Responsibilities.md)

## ADR-022: Define a Stable Package Backend Interface

**Status:** Proposed

Operating-system-specific package behavior should be isolated behind a small
backend interface that exposes capabilities without leaking native command syntax
into planners or parsers.  Backends translate engine intent into native package
operations, allowing additional package managers to be added without branching
higher architectural layers by platform.

Source: [ADR-022](adr/ADR-022-Define-a-Stable-Package-Backend-Interface.md)

## ADR-023: Prefer Explicit Configuration Over Implicit Discovery

**Status:** Proposed

Primary inputs should be supplied explicitly whenever practical, while any default
locations must be few, deterministic, documented, and easy to explain.
Bootstrap should not recursively discover configuration, guess among competing
sources, or silently resolve configuration conflicts.

Source: [ADR-023](adr/ADR-023-Prefer-Explicit-Configuration-Over-Implicit-Discovery.md)

## ADR-024: Provide a Stable and Explicit Command-Line Interface

**Status:** Proposed

The CLI should be a stable public contract built around clear, orthogonal,
deterministic options, with long options preferred for clarity and contradictory
input rejected explicitly.  CLI evolution should be conservative because users,
documentation, and automation depend on its behavior.

Source: [ADR-024](adr/ADR-024-Provide-a-Stable-and-Explicit-Command-Line-Interface.md)

## ADR-025: Provide Human-Centered Logging with Progressive Levels of Detail

**Status:** Proposed

Default logging should communicate meaningful execution phases, decisions,
installation progress, and completion without exposing unnecessary implementation
detail.  Debugging detail should be available through explicit verbosity controls,
keeping progress, diagnostics, and verbose output conceptually distinct.

Source: [ADR-025](adr/ADR-025-Provide-Human-Centered-Logging-with-Progressive-Levels-of-Detail.md)

## ADR-026: Define a Stable Exit Code Philosophy

**Status:** Proposed

Exit statuses should form a stable public contract representing broad outcome
categories rather than every internal failure condition.  Nonzero statuses should
be accompanied by human-readable diagnostics, while compatibility-sensitive exit
meanings should evolve deliberately.

Source: [ADR-026](adr/ADR-026-Define-a-Stable-Exit-Code-Philosophy.md)

## ADR-027: Establish Trust Through Inspectability

**Status:** Proposed

Bootstrap should earn trust through transparent source, build, release, planning,
logging, diagnostics, and documentation rather than require opaque trust in the
publisher or implementation.  Released executables should remain inspectable and
traceable to source revisions, with stronger verification mechanisms complementing
rather than replacing transparency.

Source: [ADR-027](adr/ADR-027-Establish-Trust-Through-Inspectability.md)

## ADR-028: Favor the Principle of Least Surprise

**Status:** Proposed

When several behaviors are reasonable, Bootstrap should favor the most explicit,
deterministic, documented, and predictable one.  Hidden state, guesses, and silent
changes to user intent should be minimized, and surprising behavior should require
strong architectural justification.

Source: [ADR-028](adr/ADR-028-Favor-the-Principle-of-Least-Surprise.md)

## ADR-029: Ensure Reproducible and Verifiable Releases

**Status:** Proposed

Release artifacts should be generated from version-controlled source through a
documented build process and tied to immutable source revisions.  Rebuilds should
be functionally equivalent whenever practical, while checksums, signatures, SBOMs,
and provenance may progressively strengthen independent verification.

Source: [ADR-029](adr/ADR-029-Ensure-Reproducible-and-Verifiable-Releases.md)

## ADR-030: Preserve Stable Public Interfaces

**Status:** Proposed

Manifest semantics, CLI behavior, exit-code categories, documented behavior, and
release artifact formats should be treated as architectural contracts.
Compatibility-affecting changes should be deliberate and normally receive a new
ADR and migration guidance, while undocumented internal implementation may evolve
more freely.

Source: [ADR-030](adr/ADR-030-Preserve-Stable-Public-Interfaces.md)

## ADR-031: Adopt Semantic Versioning and Deliberate Compatibility

**Status:** Proposed

Bootstrap proposes Semantic Versioning so release numbers communicate expected
compatibility impact: patches correct defects without public-interface changes,
minor releases add backward-compatible capabilities, and majors may introduce
documented incompatibilities.  Version impact should be judged against public
contracts rather than internal refactoring.

Source: [ADR-031](adr/ADR-031-Adopt-Semantic-Versioning-and-Deliberate-Compatibility.md)

## ADR-033: Prefer Composition Over Special Cases

**Status:** Proposed

New capabilities should reuse and compose existing parsing, planning, backend,
logging, diagnostic, and execution concepts wherever practical.  Feature-specific
exceptions require explicit architectural justification because one-off paths
increase long-term cognitive and maintenance cost.

Source: [ADR-033](adr/ADR-033-Prefer-Composition-Over-Special-Cases.md)

## ADR-034: Keep the Core Engine Small

**Status:** Proposed

The core should remain focused on manifest interpretation, validation, execution
planning, backend delegation, logging, and diagnostics.  Optional policy or
workstation-specific capabilities should generally live in higher-level data,
profiles, or companion tools rather than expanding the engine itself.

Source: [ADR-034](adr/ADR-034-Keep-the-Core-Engine-Small.md)

## ADR-035: Prefer Data Over Code

**Status:** Proposed

User intent should be represented as declarative data rather than executable
configuration whenever practical.  New needs should first be addressed through
declarative concepts, then composition, then companion tools, with embedded
executable logic reserved for cases where a reasonable declarative alternative
does not exist.

Source: [ADR-035](adr/ADR-035-Prefer-Data-Over-Code.md)

## ADR-036: Make Architectural Decisions Explicit

**Status:** Proposed

Significant architectural decisions should be recorded in ADRs that preserve the
problem, context, selected approach, rationale, alternatives, and consequences.
Existing ADRs should remain historical records; later changes should supersede or
refine them with new ADRs rather than rewriting the original reasoning.

Source: [ADR-036](adr/ADR-036-Make-Architectural-Decisions-Explicit.md)

## ADR-037: Establish a Deliberate Deprecation Policy

**Status:** Proposed

Public behavior should normally be deprecated before removal, with the replacement,
rationale, and migration path documented and removal generally deferred to a
future major release.  Immediate removal remains possible when critical security
or correctness concerns justify it.

Source: [ADR-037](adr/ADR-037-Establish-a-Deliberate-Deprecation-Policy.md)

## ADR-038: Introduce Experimental Features Deliberately

**Status:** Proposed

Experimental capabilities may be used to evaluate ideas without creating stable
compatibility commitments, but they must be explicitly identified, documented,
and opt-in.  They may change or disappear until a deliberate architectural step
promotes them to stable behavior.

Source: [ADR-038](adr/ADR-038-Introduce-Experimental-Features-Deliberately.md)

## ADR-039: Test Observable Behavior Rather Than Implementation

**Status:** Proposed

Automated tests should primarily protect observable contracts such as parsing
results, CLI behavior, diagnostics, logging, exit categories, planning, and
generated artifacts rather than private helper names or incidental internal
structure.  Direct implementation tests are exceptions when they provide
necessary evidence.

Source: [ADR-039](adr/ADR-039-Test-Observable-Behavior-Rather-Than-Implementation.md)

## ADR-040: Prefer Deterministic Behavior

**Status:** Proposed

Given equivalent inputs and operating conditions, Bootstrap should produce the
same observable behavior whenever practical.  Unavoidable variability introduced
by external systems should be made explicit rather than hidden behind
opportunistic or environment-dependent behavior.

Source: [ADR-040](adr/ADR-040-Prefer-Deterministic-Behavior.md)

## ADR-041: Treat Documentation as Part of the Product

**Status:** Proposed

Documentation should be treated as part of Bootstrap's product surface and kept
reasonably current with user-visible behavior.  ADRs preserve architectural
reasoning, contributor guidance preserves project intent, and documentation
changes affecting public understanding deserve the same care as code changes.

Source: [ADR-041](adr/ADR-041-Treat-Documentation-as-Part-of-the-Product.md)

## ADR-042: Minimize the Trusted Computing Base

**Status:** Proposed

Bootstrap should minimize the software that must be trusted in its critical
runtime path and prefer existing platform capabilities where they provide the
needed behavior.  New dependencies require enduring architectural value that
outweighs their added trust, maintenance, and prerequisite cost.

Source: [ADR-042](adr/ADR-042-Minimize-the-Trusted-Computing-Base.md)

## ADR-043: Favor Stable Concepts Over Clever Implementations

**Status:** Proposed

Competing designs should favor the solution that is easier to explain, document,
inspect, maintain, and reconcile with existing architectural concepts rather than
the most novel or compressed implementation.  Sophistication is useful only when
it strengthens rather than obscures architectural clarity.

Source: [ADR-043](adr/ADR-043-Favor-Stable-Concepts-Over-Clever-Implementations.md)

## ADR-044: Optimize for the Next Contributor

**Status:** Proposed

Design choices should reduce the context and cognitive load required by the next
person who must understand or change the project, including the original author
returning later.  Maintainability, discoverable intent, documentation, and
consistency are therefore architectural concerns rather than afterthoughts.

Source: [ADR-044](adr/ADR-044-Optimize-for-the-Next-Contributor.md)

## ADR-045: Documentation-First Source Code Commenting Standard for AI-Assisted Development

**Status:** Accepted

Applicable source should use a narrative-heavy, Doxygen-style documentation
standard aimed at comprehension under stress, covering interfaces, important
state, assumptions, failure modes, safety mechanisms, and realistic examples.
Documentation-only AI-assisted work must be non-destructive: executable behavior
must not be rewritten merely to improve comments, and changes should remain small
and bounded.

Source: [ADR-045](adr/ADR-045-documentation-first-source-code-commenting-standard.md)

## ADR-046: Adopt Documentation-Driven, Test-Second Development

**Status:** Proposed

Development should proceed from documented intent to the smallest correct
implementation and then immediately to automated tests of the observable
behavior, followed by formatting, linting, and test validation.  Functional
changes and bug fixes should update their tests in the same change rather than
defer regression evidence to later work.

Source: [ADR-046](adr/ADR-046-Adopt-Documentation-Driven-Test-Second-Development.md)

## ADR-047: Represent Planned Bootstrap Operations as Immutable Action Records

**Status:** Accepted

The planner produces immutable, platform-independent Action Records that describe
what should happen without package-manager commands or other execution details.
The resolver derives new Resolved Actions from those records, preserving the
pipeline from manifest input through planning, resolution, execution, and
Execution Results without mutating earlier representations.

Source: [ADR-047](adr/ADR-047-Represent-Planned-Bootstrap-Operations-as-Immutable-Action-Records.md)

## ADR-048: Execution SHALL Consume Only Resolved Actions

**Status:** Accepted

Executors consume only Resolved Actions and are responsible solely for performing
the described work and producing Execution Results.  They must not parse
manifests, plan operations, select package managers, detect operating-system
capabilities, or resolve platform details owned by earlier pipeline stages.

Source: [ADR-048](adr/ADR-048-Execution-SHALL-Consume-Only-Resolved-Actions.md)

## ADR-049: Preflight All Manifests Before Execution

**Status:** Proposed

A single invocation should accept one or more ordered manifest operands while
preserving each record's original source path and line number.  Bootstrap should
parse, validate, plan, and resolve the complete requested set before executing
anything; by default, an unignored preflight error prevents all execution, while
any future continuation behavior must be explicit, scoped, and still reflected
as incomplete work in the final result.

Source: [ADR-049](adr/ADR-049-Preflight-All-Manifests-Before-Execution.md)

## ADR-050: Bound Package Installation and Report Progress

**Status:** Accepted

APT installations use `--no-install-recommends`, and each mutating APT, APK, or
DNF package installation is wrapped by GNU `timeout` when available, using a
positive `BOOTSTRAP_INSTALL_TIMEOUT` value that defaults to 30 seconds.  Missing
`timeout` is a supported degraded mode that produces one unsuppressible warning;
installation progress is written to standard error outside quiet mode, and a
timeout remains within the existing execution-failure exit category.

Source: [ADR-050](adr/ADR-050-Bound-Package-Installation-and-Report-Progress.md)

## ADR-051: Centralize Build Dependencies Through bashdeps

**Status:** Accepted

Make directly bootstraps and SHA-256-verifies only the pinned released
`vendor/bashdeps.bash`; ordinary external build/development files are declared in
committed `dependencies.txt` and synchronized or verified through bashdeps.
`make deps` may acquire and converge state, `make deps-check` is offline and
non-repairing, and ordinary consumer artifacts must remain independent of
bashdeps and `vendor/` at runtime.  ADR-052 later supersedes only ADR-051's
repository-specific statement that a fresh `make build` requires no prepared
vendor state.

Source: [ADR-051](adr/ADR-051-Centralize-Build-Dependencies-Through-bashdeps.md)

## ADR-052: Publish Development, Stripped, and Minified Artifacts

**Status:** Accepted

`make build` produces three executable representations of the same assembled
program: fully commented `bootstrap.dev.bash`, full-line-comment-stripped
`bootstrap.bash`, and `bootstrap.min.bash` derived from the stripped artifact
through a commit-pinned Bash-Minifier managed by bashdeps.  All three receive the
same behavior suite and release treatment, and `make build` remains network-free
while requiring prepared Bash-Minifier state.  ADR-053 supersedes only ADR-052's
`.256` checksum-filename requirements; the three-flavor, six-file release model
remains in force.

Source: [ADR-052](adr/ADR-052-Publish-Development-Stripped-and-Minified-Artifacts.md)

## ADR-053: Standardize SHA-256 Checksum Companion Filenames

**Status:** Accepted

New builds and releases use one `.sha256` companion for each of the three
executable flavors and remove stale current-artifact `.256` outputs.  Historical
`.256` release assets remain unchanged; cross-generation consumers should try
`.sha256` first and fall back to `.256` only when the preferred resource is
confirmed absent, never for transport, authorization, server, malformed-content,
or verification failures.  Committed SHA-256 values remain authoritative for
build-dependency trust.

Source: [ADR-053](adr/ADR-053-Standardize-SHA-256-Checksum-Companion-Filenames.md)
