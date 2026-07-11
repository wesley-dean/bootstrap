# ADR-049: Preflight All Manifests Before Execution

Date: 2026-07-11

## Status

Proposed

## Intent and Documentation Posture

This ADR records the intended command-line and execution semantics for processing
multiple manifest files in one Bootstrap invocation.

The decision is intentionally described in detail because error handling is part
of Bootstrap's public safety contract. Future implementation work should preserve
both the selected behavior and the reasoning behind it rather than treating
multiple-manifest support as a simple argument-parsing convenience.

## Context

Bootstrap currently accepts one manifest file per invocation. Users who divide
their desired packages into focused manifests, such as core, containers,
security, or language-specific manifests, must invoke Bootstrap repeatedly.

A natural command-line extension is to accept multiple manifest paths:

```bash
bootstrap.bash core.manifest containers.manifest security.manifest
```

Shell glob expansion should also work without Bootstrap implementing its own
file discovery:

```bash
bootstrap.bash *.manifest
```

Concatenating files before passing them to Bootstrap is not an equivalent
solution:

```bash
cat core.manifest containers.manifest | bootstrap.bash -
```

When standard input is used, the parser sees `-` as the input source. An error
can therefore be reported only against that synthetic source and its combined
line number. The diagnostic cannot reliably identify which original file
contained the error or which line number applied within that file.

Human-friendly diagnostics are a central benefit of Bootstrap. Errors should
identify the actual manifest path and original line number whenever that
information is available. Multiple-manifest support must preserve that
provenance through parsing, planning, resolution, explanation, and reporting.

The initial discussion considered behavior similar to invoking Bootstrap once
per file. That approach preserves provenance, but a direct sequence such as:

```bash
bootstrap.bash a.manifest && bootstrap.bash b.manifest
```

would execute the first manifest before the second manifest had been parsed or
planned. A malformed later manifest could therefore be discovered only after
an earlier manifest had already modified the system.

The preferred model is stronger. Bootstrap should first preflight the complete
set of supplied manifests. Execution should begin only when every unignored
error condition has been resolved successfully.

The discussion also identified a legitimate future need for explicitly
permissive modes. A user may prefer to report and skip an individual package
failure or abandon one failed manifest while continuing with other manifests.
Those behaviors should be possible only through explicit command-line options.
They must not weaken Bootstrap's conservative default.

## Decision Drivers

The decision is guided by the following concerns:

- Diagnostics should identify the actual manifest filename and original line
  number associated with an error.
- No system changes should occur before Bootstrap knows whether the complete
  requested run can be parsed, planned, and resolved.
- Existing single-manifest behavior should remain compatible.
- Input order should remain explicit and deterministic.
- The default should stop on the first error and avoid partial system changes.
- More permissive behavior should require affirmative user intent.
- Reported errors should remain visible and understandable even when the user
  permits processing to continue.
- The implementation should compose the existing parser, planner, resolver,
  executor, and reporting stages rather than introduce a parallel pipeline.
- Exit status should distinguish complete success from partial or incomplete
  completion.

## Decision

Bootstrap shall accept one or more manifest operands in a single invocation.

Each manifest shall retain its own source identity. Records and diagnostics
produced from a manifest shall preserve the original manifest path and line
number throughout the pipeline.

Bootstrap shall process multiple manifests using two broad phases:

1. Preflight all supplied manifests.
2. Execute eligible resolved actions only after preflight permits execution.

Preflight includes, at minimum:

1. Reading each manifest in command-line order.
2. Parsing and validating each manifest.
3. Planning the requested actions.
4. Resolving those actions for the selected package-manager backend.

By default, the first error encountered during preflight shall stop the run.
Bootstrap shall execute no actions from any supplied manifest when an
unignored preflight error occurs.

If every supplied manifest completes preflight successfully, Bootstrap shall
execute the resulting resolved actions in manifest argument order and in the
established action order within each manifest.

The default behavior is therefore conceptually:

```text
preflight(a, b, c) && execute(a, b, c)
```

It is deliberately safer than either concatenating the manifests or invoking
Bootstrap independently for each file.

### Global Options

Operational options such as `--dry-run`, `--explain`, `--verbose`, `--quiet`,
and `--package-manager` shall apply to the complete invocation and therefore to
every supplied manifest.

Manifest paths shall be processed in the order received from the shell.
Bootstrap shall not implement implicit manifest discovery or reorder operands.

### Standard Input

The `-` operand shall continue to represent standard input.

Because standard input cannot normally be replayed and has no original file
identity, at most one `-` operand should be accepted in one invocation. Its
source shall remain `-`, and diagnostics shall use line numbers from that input
stream.

Users who require original filename provenance should supply manifest paths
rather than concatenate files into standard input.

### Conservative Default

Without an explicit continuation option, any error shall stop processing and
prevent execution.

This includes errors associated with:

- manifest access;
- syntax or validation;
- action planning;
- platform or package-manager resolution; and
- execution.

Execution failures necessarily occur after the preflight barrier. By default,
an execution failure shall stop further execution and cause the overall run to
fail.

### Explicit Continuation Policies

Future or accompanying CLI work may provide two independent continuation
policies:

```text
--continue-on-package-error
--continue-on-manifest-error
```

These names are preferred over `--ignore-*` forms because the errors are not
ignored. Bootstrap still explains, records, and reports them. The option changes
whether the error halts subsequent work.

The precise spelling remains part of the CLI design and may be refined before
implementation, but the semantic separation is architectural.

#### Package-Level Continuation

When package-level continuation is enabled, a failure attributable to one
package may be reported and skipped while Bootstrap continues processing other
eligible packages.

Package-level failures may arise during parsing, planning, resolution, or
execution. An implementation shall distinguish failures that can be safely
isolated to one package from failures that invalidate the enclosing manifest or
runtime state.

A package-level option shall not require Bootstrap to guess the intended meaning
of malformed or ambiguous input. If a failure cannot be safely isolated to one
package record, it remains a manifest-level or run-level failure.

#### Manifest-Level Continuation

When manifest-level continuation is enabled, a failure that invalidates one
manifest may be reported, that manifest may be excluded from execution, and
preflight may continue with later manifests.

Successful manifests may become eligible for execution only after preflight has
completed for the full invocation and no remaining unignored run-level failure
exists.

Manifest-level continuation shall not merge a failed manifest's partial plan
with executable plans from successful manifests.

#### Combined Continuation

When both continuation policies are enabled:

- safely isolated package failures may be reported and omitted;
- an unrecoverable manifest failure may exclude that manifest;
- later manifests may still be preflighted; and
- execution may proceed only for the surviving resolved actions after the
  complete preflight phase.

The hierarchy is:

```text
run
  manifest
    package
```

Each continuation policy relaxes failure handling only at its stated level.

### Exit Status

Continuation does not convert an incomplete run into complete success.

If any package or manifest error occurred, the overall command should return a
nonzero status even when an explicit continuation option allowed additional
work to proceed.

The final exit-code mapping may be specified separately, but callers must be
able to distinguish:

- complete success;
- successful completion with reported and skipped work;
- preflight failure with no execution; and
- execution failure after preflight.

A future explicit option could request success status for acknowledged skipped
errors, but that behavior is not part of this decision and shall not be implied
by continuation alone.

### Reporting

Diagnostics shall remain human-readable and shall identify the narrowest useful
scope available:

- run-level errors;
- manifest path;
- original manifest line number;
- package requirement, when known;
- pipeline stage that detected the error; and
- whether processing stopped, skipped a package, skipped a manifest, or
  continued under an explicit policy.

Dry-run and explain modes should make the global preflight boundary visible.
They should distinguish actions by source manifest and explain that execution
was either prohibited or intentionally omitted.

## Considered Alternatives

### Accept Only One Manifest

Bootstrap could retain the existing one-manifest CLI and require users to invoke
it repeatedly.

This preserves the current implementation and provenance behavior, but it
creates repetitive command lines and does not provide a global preflight safety
barrier across a related manifest set.

### Concatenate Manifests Before Parsing

Bootstrap or the user could concatenate all input files and process the result
as one logical manifest.

This is mechanically simple and permits one parser invocation. It was rejected
because it loses or complicates original source provenance. Error messages may
refer only to `-`, a temporary combined file, or a combined line number that is
not directly useful to the user.

Concatenation also blurs manifest boundaries, making file-level continuation and
reporting difficult.

### Execute Each Manifest Immediately

Bootstrap could loop over manifest operands and run the existing complete
pipeline for each one before moving to the next.

This preserves filenames and line numbers and may require relatively little
orchestration work. It was rejected as the default because an early manifest
could modify the system before a later manifest's parse, planning, or resolution
failure was discovered.

### Parse and Plan All Manifests, Then Resolve During Execution

Bootstrap could establish a global barrier after parsing and planning while
deferring package-manager resolution until each manifest is about to execute.

This reduces retained preflight state, but it allows a later resolution error to
be discovered after earlier execution has begun. Resolution is therefore part
of preflight for this decision.

### Merge All Action Records into One Plan

Bootstrap could preserve source metadata while combining every manifest's
Action Records into a single plan and resolved action stream.

This may simplify global optimization or duplicate elimination. It was not
selected as the required model because merging can obscure manifest boundaries,
complicate manifest-level continuation, and introduce policy questions about
cross-file ordering and duplicate requirements.

An implementation may use a combined internal stream only if source provenance,
manifest boundaries, deterministic ordering, and continuation semantics remain
fully preserved.

### Silently Continue After Errors

Bootstrap could report errors and continue by default.

This was rejected because partial provisioning can be difficult to detect and
may leave a system in an unexpected state. Conservative fail-fast behavior
remains the default.

### Treat Continued Errors as Success

Bootstrap could return status zero whenever it completed all work that remained
after skipped failures.

This was rejected because automation would be unable to distinguish a complete
bootstrap from a partial one. Continued work and successful work are not the
same outcome.

### Use One General `--continue-on-error` Option

A single option could permit all failures to be skipped when possible.

This is convenient but too broad. Package-level and manifest-level failures have
different safety boundaries and consequences. Separate policies make user
intent more explicit and reduce surprising behavior.

## Consequences

### Positive

- Users can compose focused manifests in one explicit invocation.
- Errors retain actual filename and line-number provenance.
- The complete manifest set is checked before package changes begin.
- Dry-run and explain behavior can present a coherent run-wide preflight view.
- Existing parser, planner, resolver, executor, and reporting concepts remain
  reusable.
- Conservative behavior remains the default.
- Advanced users can eventually request partial progress at a clearly defined
  package or manifest boundary.
- Automation can detect partial completion through nonzero exit status.

### Negative

- Bootstrap must retain or otherwise manage the preflight results for multiple
  manifests until execution begins.
- Temporary-file ownership and cleanup become more complex.
- The CLI context must represent an ordered collection of manifest paths rather
  than one manifest path.
- Parser, planner, and resolver code may need richer error accumulation to
  support package-level continuation.
- Manifest-level and package-level summaries add reporting complexity.
- Duplicate or conflicting package requirements across manifests remain a
  policy question unless explicitly defined elsewhere.
- A large manifest set may consume more temporary storage during preflight.
- Continuation policies increase the test matrix substantially.

### Implementation Impact

The intended design should extend the existing layered pipeline rather than
replace it.

Likely implementation work includes:

- collecting an ordered list of manifest operands;
- preserving per-manifest source context;
- producing and retaining per-manifest or provenance-preserving Action Records;
- resolving all eligible actions before execution;
- representing preflight outcomes at package, manifest, and run scope;
- enforcing a global execution barrier;
- executing surviving Resolved Actions deterministically;
- aggregating human-readable summaries and exit status; and
- adding regression tests for default and continuation behavior.

Package-level continuation may require deeper parser, planner, resolver, or
executor changes than basic multiple-manifest support. It may therefore be
implemented after the global preflight and manifest-level behavior, provided the
public design remains consistent with this ADR.

## Open Questions and Follow-Ups

The following details require additional design or implementation validation:

- The final spelling of the package-level and manifest-level continuation flags.
- Whether the first implementation should include continuation policies or only
  establish the conservative global preflight behavior.
- The exact exit codes used for partial completion and multiple simultaneous
  failure categories.
- Whether preflight should report only the first error by default or collect
  additional errors while still refusing execution.
- Which malformed-line failures can be safely isolated to a package under
  package-level continuation without guessing user intent.
- Whether duplicate requirements across manifests are preserved independently,
  coalesced, or diagnosed.
- How conflicting version constraints across manifests are reported.
- Whether execution summaries should be per manifest, aggregate, or both.
- Whether a manifest-level continuation policy permits execution when every
  manifest failed and therefore no actions survive.
- Whether an explicit option should ever convert acknowledged skipped errors to
  a successful exit status.

These questions do not change the central decision: preserve provenance,
preflight the complete invocation before execution, fail conservatively by
default, and require explicit policy for partial progress.

## Related Decisions

- Related to ADR-013: Fail Conservatively and Avoid Surprising System Changes
- Related to ADR-014: Separate Manifest Parsing from Package Installation
- Related to ADR-016: Provide Dry-Run and Explain Modes for Planned Changes
- Related to ADR-021: Layer the Bootstrap Engine Around Well-Defined
  Responsibilities
- Related to ADR-023: Prefer Explicit Configuration Over Implicit Discovery
- Related to ADR-024: Provide a Stable and Explicit Command-Line Interface
- Related to ADR-025: Provide Human-Centered Logging with Progressive Levels of
  Detail
- Related to ADR-028: Favor the Principle of Least Surprise
- Related to ADR-033: Prefer Composition Over Special Cases
- Related to ADR-039: Test Observable Behavior Rather Than Implementation
- Related to ADR-040: Prefer Deterministic Behavior
- Related to ADR-047: Represent Planned Bootstrap Operations as Immutable Action
  Records
- Related to ADR-048: Execution SHALL Consume Only Resolved Actions
