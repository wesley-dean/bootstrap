# ADR-052: Publish Development, Stripped, and Minified Artifacts

Date: 2026-08-18

## Status

Accepted

## Intent and Documentation Posture

This ADR defines Bootstrap's generated release-artifact flavors and the build-time
use of Bash-Minifier. It preserves the repository's modular-source architecture
while producing three executable representations of the same Bootstrap program.

This decision changes build, test, checksum, and release behavior. It does not
change Bootstrap's runtime package-management contract or add a runtime dependency
on Bash-Minifier, bashdeps, `dependencies.txt`, or `vendor/`.

## Context

ADR-009 and ADR-010 established a deliberately small distribution surface: modular
maintained source is assembled into one executable `dist/bootstrap.bash` artifact.
That artifact historically removed full-line comments from maintained source while
retaining a small generated header.

There are now three useful audiences for generated Bootstrap artifacts:

1. contributors and reviewers who benefit from a fully commented assembled script;
2. ordinary consumers who benefit from the familiar comment-stripped standalone
   script; and
3. consumers who value the smallest practical standalone representation and are
   willing to trade source readability for size.

A single generated representation cannot optimize for all three purposes. The
source tree should remain the maintained source of truth, while the build can
produce multiple equivalent consumer representations from the same ordered source
set.

Love Borgström's Bash-Minifier project provides a state-aware Bash minifier that
can consume a script from standard input and emit a minified Bash script to
standard output. Bootstrap already centralizes ordinary external build/development
artifacts through bashdeps under ADR-051, so Bash-Minifier fits the established
manifest-managed dependency boundary.

Introducing Bash-Minifier also changes one repository-specific consequence of
ADR-051. At the time ADR-051 was accepted, Bootstrap's `make build` required no
external artifact and therefore succeeded from a clean checkout without a
`vendor/` tree. A minified build flavor necessarily requires an already-prepared
minifier. The network boundary remains unchanged: `make build` still does not
acquire or repair dependencies, but it now fails clearly when the prepared
minifier is absent.

## Decision Drivers

- Preserve one maintained modular source tree while serving different artifact
  readability and size needs.
- Keep the existing `bootstrap.bash` filename as the ordinary/default flavor.
- Make all released flavors derive from the complete assembled program, including
  all imported project libraries.
- Keep build-time dependency acquisition explicit and centralized through
  bashdeps.
- Pin Bash-Minifier to immutable reviewed bytes rather than a moving branch.
- Keep `make build` network-free and non-repairing.
- Apply the same functional regression suite to every executable flavor.
- Publish a checksum for every released executable artifact.
- Preserve executable permissions across all three flavors.
- Keep Bash-Minifier completely outside Bootstrap's runtime dependency surface.

## Decision

### Build three executable flavors

`make build` SHALL produce these executable files:

```text
dist/bootstrap.dev.bash
dist/bootstrap.bash
dist/bootstrap.min.bash
```

The files represent the same Bootstrap program at different transformation
levels.

`bootstrap.dev.bash` is the development artifact. It SHALL contain the generated
release metadata and the complete ordered maintained source with comments intact.
No project-source comment-stripping or minification step is applied to this
artifact.

`bootstrap.bash` remains the ordinary/default artifact. It SHALL be derived from
the complete assembled development artifact by removing full-line comments while
preserving the shebang. Inline comments that are part of executable lines are not
the responsibility of this stripping stage.

`bootstrap.min.bash` SHALL be produced by passing the complete comment-stripped
`bootstrap.bash` bytes through the pinned Bash-Minifier artifact. Minification is
therefore applied after assembly and after full-line comment stripping, so code
originating in any project library receives the same transformation as code from
the entry point.

All three generated scripts SHALL be executable. The build SHALL publish each
artifact only after its corresponding transformation succeeds.

### Build six release files including checksums

`make build` SHALL also produce one SHA-256 checksum file for each executable:

```text
dist/bootstrap.dev.bash.256
dist/bootstrap.bash.256
dist/bootstrap.min.bash.256
```

Each `.256` file SHALL describe the exact bytes of its corresponding executable.
The build SHALL use the repository's supported SHA-256 capability (`sha256sum` or
`shasum -a 256`) and fail clearly when neither implementation is available.

The existing `checksums` Make target MAY remain as a compatibility/convenience
alias, but checksum generation belongs to the ordinary `build` result. A
successful `make build` therefore means that all six expected distribution files
exist.

### Manage Bash-Minifier through bashdeps

Bootstrap SHALL add the Bash-Minifier source artifact to `dependencies.txt`.

The selected upstream bytes are:

```text
repository: Zuzzuc/Bash-minifier
commit:     9c824e20815a5bca2153ec25ecc02a4edea1430e
source:     Minify.sh
destination: vendor/bash-minifier.bash
sha256:     93cb422360db4cc410d19b068eb074da020a4a743f0eebc9c442d1e5acd90e9b
```

The manifest URL SHALL be commit-pinned rather than branch-pinned. The destination
name is a Bootstrap consumer convention; it does not imply that the upstream file
has that name.

Bash-Minifier remains an ordinary manifest-managed development dependency under
ADR-051. Make SHALL NOT add a second direct download path for it.

### Preserve the Make dependency boundary

`make deps` MAY use the network and SHALL materialize the pinned Bash-Minifier
artifact through bashdeps together with the repository's other declared external
artifacts.

`make deps-check` SHALL continue to verify prepared dependency state without
network access or repair.

`make build` SHALL NOT invoke `deps`, `deps-check`, curl, wget, or any other
acquisition mechanism. It SHALL require an already-present
`vendor/bash-minifier.bash` and fail with actionable guidance when that dependency
is missing.

A fresh checkout therefore has two supported preparation paths:

```text
make all
```

or:

```text
make deps
make build
```

`make all` SHALL preserve ADR-051 ordering by completing dependency synchronization
before invoking the network-free `build` target.

This decision supersedes ADR-051 only where ADR-051 states that Bootstrap's clean
`make build` succeeds without a vendor tree. The general ADR-051 dependency and
network boundaries remain in force.

### Test every executable flavor

The behavior-oriented Bats suite SHALL be applied to all three executable build
artifacts rather than treating minification as an untested packaging-only step.

Tests SHOULD assert behavior rather than formatting that is intentionally changed
by minification. Assertions that depend on metadata occupying separate physical
lines, comments being present, or other representation details SHALL be replaced
with behavior- or byte-contract assertions where appropriate.

CI SHALL exercise the same Make test interface used locally and SHALL retain
separate report output when needed so failures can be associated with an artifact
flavor.

Build-specific regression coverage SHALL verify at least:

- a fresh `make build` does not acquire missing Bash-Minifier state and fails
  clearly when that state is absent;
- prepared dependency state allows `make build` to create all six files;
- all three scripts are executable;
- each `.256` file verifies its corresponding script;
- the development artifact retains full-line source comments;
- the ordinary artifact removes full-line comments while preserving the shebang;
- the minified artifact is produced from the stripped artifact and remains
  executable and behaviorally valid; and
- all three consumer artifacts remain functional after `vendor/` is removed.

### Publish all six files in GitHub releases

Release automation SHALL prepare and verify dependencies before building. It SHALL
publish all six generated distribution files and include all six in release
provenance/attestation scope where the workflow supports attestation.

The three executable artifacts are peer release flavors. `bootstrap.bash` remains
the conventional/default filename so existing download URLs and wrapper examples
continue to refer to the ordinary comment-stripped representation unless a user
chooses another flavor explicitly.

### Runtime isolation remains mandatory

None of the three released executable scripts may require Bash-Minifier,
`bashdeps.bash`, `dependencies.txt`, or `vendor/` after construction.

Bash-Minifier transforms build output only. Its implementation is not embedded as
runtime tooling and it is not invoked by Bootstrap during normal execution.

## Considered Alternatives

### Replace bootstrap.bash with only a minified artifact

This would minimize one download but would make the ordinary artifact materially
harder to inspect and would remove the established readable distribution flavor.
The project instead publishes minification as an explicit additional flavor.

### Keep only the development and minified artifacts

This would eliminate the historical stripped artifact. It was rejected because
`bootstrap.bash` is already the conventional consumer filename and provides a
useful middle ground between fully commented and aggressively minified output.

### Minify the maintained source files individually before assembly

Per-file minification would couple transformation behavior to internal source
layout and could produce different semantics at file boundaries. The project
instead assembles one complete program first, strips that complete program, then
minifies the complete stripped artifact.

### Let Bash-Minifier perform both comment stripping and minification from the development artifact

Bash-Minifier itself removes comments as part of minification, but the requested
artifact model distinguishes the ordinary stripped representation from the
minified representation. Explicitly deriving the minified artifact from
`bootstrap.bash` makes that lineage observable and testable.

### Download Bash-Minifier directly from Make

This would violate ADR-051 by duplicating ordinary dependency acquisition policy
outside bashdeps. Bash-Minifier fits the existing manifest contract and therefore
belongs in `dependencies.txt`.

### Make build invoke make deps automatically

This would make a fresh build convenient but would silently add network access and
repository mutation to the ordinary build target. The project retains explicit
preparation through `deps` or `all`.

### Test only bootstrap.bash and perform smoke checks on the other flavors

A minifier is a semantic source-to-source transformation. Treating the minified
artifact as packaging-only would leave the highest-risk transformation with the
weakest behavioral validation. The full behavior suite therefore applies to each
flavor.

## Consequences

Bootstrap releases become larger in aggregate because they contain three
executable representations and three checksum files. Individual consumers can
still download only the flavor they want.

The build now depends on prepared Bash-Minifier state, so `make build` from a fresh
checkout fails until `make deps` has been run. This is intentional and preserves
the explicit network boundary established by ADR-051.

CI work increases because the behavior suite runs against three generated
representations. That additional cost buys direct evidence that comment stripping
and minification preserve behavior.

The default `bootstrap.bash` release URL remains stable for existing consumers.
Users who want maximum inspectability can choose `bootstrap.dev.bash`; users who
want the smallest representation can choose `bootstrap.min.bash`.

The project takes a build-time dependency on the behavior of a specific reviewed
Bash-Minifier commit. Updating that dependency requires an ordinary
`dependencies.txt` URL/digest change and the same multi-artifact test suite.

## Open Questions and Follow-Ups

Future projects may choose the same three-flavor convention. Bootstrap's ADR does
not require other repositories to share identical source assembly mechanics; it
records the artifact semantics and dependency boundary used here.

If future Bash-Minifier releases introduce a stable release/tag policy that is
preferable to commit pinning, Bootstrap may move to an immutable release reference
through an explicit dependency update without changing the architectural boundary.

If one flavor eventually acquires materially different runtime semantics, this ADR
should be revisited rather than allowing flavor names to imply equivalence that
validation no longer supports.

## Related Decisions

- Supersedes in part: ADR-009 (single published executable artifact)
- Supersedes in part: ADR-010 (single generated distribution artifact)
- Refines: ADR-012 (Make as the orchestration interface)
- Related to: ADR-029 (reproducible and verifiable releases)
- Related to: ADR-039 (observable-behavior testing)
- Related to: ADR-040 (deterministic behavior)
- Related to: ADR-042 (minimize the trusted computing base)
- Related to: ADR-046 (documentation-driven, test-second development)
- Supersedes in part: ADR-051 (clean build requires no prepared vendor state)
