# ADR-050: Bound Package Installation and Report Progress

Date: 2026-07-11

## Status

Accepted

## Context

Bootstrap delegates package installation to the native APT, APK, and DNF
package managers.  That delegation preserves native package-manager authority,
but it also means Bootstrap inherits package-manager behavior that may wait for
interactive input or otherwise fail to return.

Issue 42 records an APT installation of `chkrootkit` whose recommended
dependencies caused `dpkg` to attempt interaction during a non-interactive
Bootstrap run.  The process appeared to hang indefinitely.  Bootstrap also
suppressed the native package-manager output and printed no package-level
progress, so the user could not distinguish a slow successful installation from
an installation waiting forever.

Three separate concerns are present:

1. APT may install recommended packages that were not explicitly requested and
   that may introduce interactive behavior.
2. Any supported package-manager installation may fail to return.
3. Suppressed output leaves the user without visible evidence that installation
   work is still in progress.

Bootstrap should reduce the known APT trigger, bound package installation when
the host provides the necessary capability, and report visible progress without
corrupting the structured Execution Result stream.

## Decision Drivers

- Package installation should not wait indefinitely when a standard timeout
  facility is available.
- Minimal supported systems should remain usable even when GNU `timeout` is not
  installed.
- A degraded safety boundary must never be hidden from the user.
- APT should install the explicitly requested package without automatically
  expanding the operation to recommended packages.
- Users should be able to distinguish active installation from an apparent hang.
- Quiet mode may suppress routine progress, but it must not suppress warnings,
  errors, or recovery guidance.
- Executor standard output must remain reserved for structured Execution Result
  records.
- The implementation should remain small, deterministic, and shared across APT,
  APK, and DNF where their behavior is equivalent.

## Decision

APT package installation shall use `--no-install-recommends`.

Each mutating APT, APK, and DNF package installation shall be run through GNU
`timeout` when that command is available.  The timeout applies separately to
each package installation.  Its duration is configured by
`BOOTSTRAP_INSTALL_TIMEOUT`, measured in seconds, with a default value of `30`.
The effective value must be a positive whole number.  Invalid values are usage
errors discovered before execution begins.

`timeout` is an optional runtime capability rather than a mandatory dependency.
Bootstrap shall check for it before attempting a package installation.  When it
is unavailable, Bootstrap shall emit one warning per invocation and continue
with unbounded native package-manager installations.  Quiet mode shall not
suppress this warning because it describes a degraded safety mechanism.

A timeout shall produce a failed Execution Result and the existing execution
failure exit category.  Bootstrap shall not introduce a new public exit code for
this condition.  Package-state inspection commands are outside this timeout
boundary.

Immediately before a package installation, Bootstrap shall print the following
progress prefix to standard error when quiet mode is not active:

```text
Installing PACKAGE...
```

The text shall remain on one logical line and shall be completed with `done.` on
success or `failed.` on failure.  Already-satisfied packages shall not print an
installation progress message.  Progress belongs on standard error because
executor standard output carries machine-readable Execution Result records.

Native package-manager output may remain suppressed.  Recovery guidance shall
show the native command a user can run directly for complete diagnostics.  The
APT recovery command shall include `--no-install-recommends`; recovery examples
need not include Bootstrap's timeout wrapper so users may diagnose failures
interactively and deliberately.

## Considered Alternatives

### Add only `--no-install-recommends`

This addresses the known APT trigger but does not protect APK, DNF, or unrelated
APT failures that never return.  It also leaves the user without progress
information.

### Rely only on `DEBIAN_FRONTEND=noninteractive`

That variable can reduce some Debian-family prompts, but it neither prevents all
blocking behavior nor applies to APK and DNF.  It is not a general execution
boundary.

### Require `timeout` and stop when it is missing

This provides the strongest uniform guarantee, but it prevents Bootstrap from
running on otherwise supported minimal systems.  Bootstrap instead continues
with an explicit warning so compatibility is preserved without hiding the
risk.

### Silently continue without `timeout`

This preserves compatibility but falsely implies that the documented safety
boundary is active.  Silent degradation is inconsistent with Bootstrap's
human-centered diagnostics and conservative behavior.

### Apply one timeout to the entire Bootstrap invocation

A run-level timeout would make the permitted duration depend on manifest size
and could interrupt planning, reporting, or several legitimate installations.
A per-package timeout gives each native installation the same explicit bound.

### Show progress only in verbose mode

The original failure is confusing during normal operation.  Installation
progress is useful default feedback and should disappear only when the user
explicitly requests quiet output.

### Expose native package-manager output

This would provide activity feedback, but it would also make output noisy and
backend-dependent.  Small stable progress messages preserve a consistent user
experience while recovery guidance provides a route to native diagnostics.

### Introduce a timeout-specific public exit code

The distinction is useful inside the Execution Result message, but callers already
have an execution-failure category.  A new public code would expand the stable
interface without a demonstrated need.

## Consequences

### Positive

- APT no longer installs recommended packages automatically.
- Package installations are time-bounded on systems that provide GNU `timeout`.
- Minimal systems without `timeout` remain supported.
- Users are explicitly warned when the timeout safety boundary is unavailable.
- Default progress makes slow installation visibly different from silence.
- Quiet mode continues to suppress routine progress without hiding degraded
  safety, errors, or recovery guidance.
- A shared timeout and progress boundary keeps backend behavior consistent.

### Negative

- Systems without `timeout` remain vulnerable to indefinitely blocked native
  package-manager commands after the warning is displayed.
- A 30-second default may be too short for unusually slow repositories or
  systems, requiring an environment or `.env` override.
- Excluding APT recommendations may omit packages some users previously received
  implicitly.
- Progress emitted on standard error becomes part of the observable CLI
  contract.
- A package manager that independently exits with status 124 may be reported as
  a timeout, matching GNU `timeout`'s conventional status.

## Open Questions and Follow-Ups

- Operational experience may justify changing the default timeout in a future
  compatible release.
- Future package-manager backends should explicitly decide whether their
  mutating installation command uses the shared timeout boundary.
- Future work may add a deliberate option to require timeout support rather than
  accepting degraded execution.

## Related Decisions

- Related to: ADR-003 Treat Native Package Managers as the Source of Truth
- Related to: ADR-013 Fail Conservatively and Avoid Surprising System Changes
- Related to: ADR-017 Delegate Package Operations to Native Package Managers
- Related to: ADR-020 Provide Human-Centered Diagnostics
- Related to: ADR-025 Provide Human-Centered Logging with Progressive Levels of Detail
- Related to: ADR-026 Define a Stable Exit Code Philosophy
- Related to: ADR-028 Favor the Principle of Least Surprise
- Related to: ADR-039 Test Observable Behavior Rather Than Implementation
- Related to: ADR-040 Prefer Deterministic Behavior
- Related to: ADR-041 Treat Documentation as Part of the Product
- Related to: ADR-042 Minimize the Trusted Computing Base
- Related to: ADR-045 Documentation-First Source-Code Commenting Standard
- Related to: ADR-046 Adopt Documentation-Driven Test-Second Development
- Related to: ADR-048 Execution Shall Consume Only Resolved Actions
