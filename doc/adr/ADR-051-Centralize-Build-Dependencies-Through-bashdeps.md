# ADR-051: Centralize Build Dependencies Through bashdeps

Date: 2026-08-18

## Status

Accepted

## Intent and Documentation Posture

This ADR defines how Bootstrap acquires, verifies, and consumes external
build/development artifacts.  It establishes `bashdeps.bash` as the single
manifest-driven dependency materializer for ordinary external artifacts while
preserving one deliberately small bootstrap path in Make for `bashdeps.bash`
itself.

This decision concerns repository development, documentation generation, CI, and
release preparation.  It does not add a runtime dependency to the distributed
`bootstrap.bash` artifact.

## Context

Bootstrap intentionally keeps its runtime surface small and delegates operating
system package operations to native package managers.  Its development toolchain
has a different concern: a small number of external files are needed to build,
test, document, or release the project.

Before this decision, the Makefile directly downloaded the Bash Doxygen filter
from the moving `main` branch of `wesley-dean/bash-doxygen`.  That approach was
small, but it duplicated acquisition policy inside Bootstrap and did not bind the
local file to an immutable reviewed byte identity.  A successful download or an
expected filename did not prove that the resulting bytes were the bytes the
repository intended to use.

The `bashdeps` project now provides a deliberately narrow contract for this
problem.  A committed `dependencies.txt` manifest declares an opaque identity, an
HTTPS URL, a project-relative destination, and an authoritative SHA-256 digest.
`bashdeps.bash sync` converges declared destinations to those exact bytes, while
`bashdeps.bash verify` validates already-present state without network access or
repair.

A bootstrap paradox remains: Bootstrap cannot use `bashdeps.bash` to acquire the
first trusted copy of `bashdeps.bash`.  Some component must own that first step.
The project chooses to keep that responsibility explicit rather than hiding it in
another installer, moving URL, or unverified execution path.

This decision also clarifies Make target semantics.  Dependency convergence,
offline verification, ordinary artifact construction, and the convenient
fresh-checkout path are different operations and should remain independently
observable.

## Decision Drivers

- Reduce project-specific dependency acquisition and verification logic.
- Bind external build/development artifacts to committed SHA-256 identities.
- Replace moving dependency URLs with immutable release or tag URLs.
- Keep network access deliberate and reviewable.
- Preserve an actually offline, non-repairing dependency verification target.
- Prevent plain builds from silently acquiring or repairing dependency state.
- Preserve usable cached dependency state when a replacement download fails.
- Keep generated dependency state out of source control.
- Keep the released Bootstrap executable independent of bashdeps and `vendor/`.
- Make local development, CI, documentation, and release behavior agree through
  the Makefile contract established by ADR-012.

## Decision

### Make directly owns only the bashdeps bootstrap

The Makefile SHALL directly manage one external dependency:

```text
vendor/bashdeps.bash
```

That artifact SHALL come from a pinned stable `bashdeps` release using an
immutable release URL and a SHA-256 digest committed in the Makefile.

The bootstrap artifact SHALL NOT appear in `dependencies.txt`.  Requiring
`bashdeps.bash` to materialize the manifest entry that provides
`bashdeps.bash` would create a circular bootstrap dependency.

An existing `vendor/bashdeps.bash` may be reused only when its SHA-256 digest
matches the committed bootstrap digest.  A missing or mismatched bootstrap SHALL
be replaced only through staged acquisition:

1. download candidate bytes to a temporary path;
2. verify the candidate against the committed digest;
3. publish the candidate to `vendor/bashdeps.bash` only after verification;
4. leave the prior destination untouched when acquisition or verification fails.

The bootstrap recipe SHALL verify cached bytes before executing them.

### dependencies.txt is the source of truth for ordinary external artifacts

All other ordinary externally acquired build/development files that fit the
released bashdeps contract SHALL be declared in the committed
`dependencies.txt` manifest.

For the initial migration, Bootstrap has one such artifact:

```text
vendor/doxygen-bash.awk
```

The manifest SHALL use the immutable `bash-doxygen` v0.0.6 tag URL and the
reviewed SHA-256 digest for that exact file rather than the prior moving `main`
URL.

The committed manifest is trusted source code.  The URL identifies where a
candidate may be acquired; the committed digest is authoritative for byte
identity.  A filename, HTTP success status, branch name, tag label, timestamp, or
other metadata does not substitute for digest equality.

### Make target boundaries

The supported development contract SHALL be:

```text
make deps
make deps-check
make build
make all
```

`make deps` MAY use the network.  It SHALL bootstrap or repair the pinned
`bashdeps.bash` artifact when necessary, verify that bootstrap before execution,
and run:

```text
vendor/bashdeps.bash sync dependencies.txt
```

`make deps-check` SHALL NOT use the network and SHALL NOT repair dependency
state.  It SHALL require an already-present valid bashdeps bootstrap and run:

```text
vendor/bashdeps.bash verify dependencies.txt
```

A missing, non-executable, or digest-mismatched bootstrap SHALL make
`deps-check` fail rather than silently invoking the bootstrap download path.

`make build` SHALL build the Bootstrap consumer artifact from already-present
project inputs.  It SHALL NOT invoke `deps`, `deps-check`, bashdeps synchronization,
or bootstrap acquisition.

Bootstrap's current consumer artifact does not itself require the Doxygen filter,
so a clean `make build` is expected to succeed without a `vendor/` tree.  This is
an intentional repository-specific application of the boundary: build remains
independent even though `make all` prepares all declared development dependencies
first.

`make all` SHALL explicitly sequence dependency convergence before the ordinary
build.  Ordering SHALL remain correct under parallel Make execution by completing
`deps` before recursively invoking `build`.

### Documentation generation consumes prepared dependency state

`make docs` SHALL use the manifest-managed `vendor/doxygen-bash.awk` file, but it
SHALL NOT acquire dependencies implicitly.  If the filter is absent, `make docs`
SHALL fail with guidance to run `make deps` or `make all`.

The documentation consumer MAY apply the executable mode Doxygen requires.  File
mode is consumer behavior; bashdeps remains responsible for declared byte
identity and does not infer file purpose from the destination name.

The GitHub Pages workflow SHALL explicitly run dependency synchronization and
offline verification before documentation generation.

### Network access is explicit

Repository-managed external artifact acquisition SHALL occur through explicit
`make deps` or `make all` execution.  Plain `make build`, `make deps-check`, and
`make docs` SHALL NOT silently fetch missing dependency state.

CI and release workflows MAY invoke `make deps` explicitly as part of their
published sequence.  That makes network use visible in workflow review rather
than hiding it behind an ordinary build target.

### Convergence replaces historical accumulation

Dependency correctness is determined from the current manifest and actual bytes,
not from filenames left by earlier dependency versions.  A stale or mismatched
declared destination is state to converge, not state to trust because a file is
present.

Bashdeps owns ordinary manifest convergence.  Bootstrap SHALL NOT duplicate that
policy in Make.

### vendor is generated dependency state

`vendor/` SHALL remain ignored generated state.  `distclean` SHALL remove the
vendor tree so the declared dependency set can be reproduced from the committed
Makefile bootstrap pin and `dependencies.txt`.

Generated Doxygen reference output under `doc/reference/` likewise remains
ignored and reproducible.  CI generates it from maintained source and prepared
dependency state rather than requiring generated documentation to be committed.

### Runtime isolation is mandatory

The distributed `dist/bootstrap.bash` artifact SHALL remain self-contained under
the existing runtime contract.  It SHALL NOT require:

- `bashdeps.bash`;
- `dependencies.txt`;
- `vendor/`;
- the Bash Doxygen filter; or
- network access for build-tool dependency materialization.

Bashdeps is a repository development tool, not a Bootstrap runtime package
manager or runtime dependency mechanism.

### CI and release workflows exercise the boundary

CI SHALL exercise the repository-specific forms of the new contract, including:

- a clean `make build` that succeeds without creating dependency state;
- `make deps` from a fresh dependency state;
- offline `make deps-check`;
- rejection of tampered dependency bytes;
- convergence back to the committed manifest through a subsequent explicit
  `make deps`;
- successful `make all` sequencing; and
- ordinary tests against the generated Bootstrap artifact.

Release automation SHALL explicitly synchronize and verify dependency state before
release validation and artifact construction.  The build step itself remains
independent of dependency acquisition.

## Considered Alternatives

### Continue project-specific Makefile download logic

Bootstrap could retain a dedicated `curl` rule for each external file.  This keeps
individual rules locally obvious, but repeats staging, verification, retry,
convergence, and manifest policy across repositories.  It was rejected because
bashdeps now exists specifically to centralize that behavior.

### Keep using a moving branch URL for the Doxygen filter

A moving `main` URL makes future upstream changes silently eligible for download.
Even when paired with a digest, a moving URL creates avoidable ambiguity about the
intended upstream revision.  An immutable tag URL communicates both source intent
and reviewed byte identity.

### Put bashdeps.bash in dependencies.txt

This would make the dependency manager responsible for obtaining the first copy of
itself and therefore creates a circular dependency.  The explicit Make bootstrap
is retained as the one exception.

### Commit vendor/bashdeps.bash and other dependency files

Committing generated dependency state would remove first-use network access, but
would reintroduce vendored binary/script copies as repository source and create
additional update churn.  The project instead commits the trust declarations and
reproduces generated state.

### Make build depend on deps

This would make fresh builds convenient, but would allow an ordinary build to
access the network and mutate dependency state.  The explicit `all` composition
provides convenience without weakening the build boundary.

### Let deps-check repair missing or stale files

A repairing check would no longer be an offline verification primitive.  The
project preserves a strict distinction: `deps` converges; `deps-check` observes.

### Make docs invoke deps automatically

Documentation generation historically fetched its own filter.  Preserving that
behavior through an implicit `docs -> deps` prerequisite would continue hidden
network access from a target whose primary purpose is generation.  Documentation
now consumes prepared state, while Pages explicitly prepares that state first.

## Consequences

Bootstrap gains a committed dependency manifest and a small amount of explicit
bootstrap logic for bashdeps itself.

The Makefile becomes clearer about which targets may access the network and which
targets only consume existing state.

A fresh contributor may use `make all` for the convenient convergence-and-build
path, or use `make deps` followed by narrower development targets.

Offline environments can run `make build`, `make deps-check`, and other targets
that do not require new dependency acquisition once the required local state is
present.

Documentation generation now requires prepared dependency state instead of
silently downloading its filter.

The project depends on the behavior of the pinned released bashdeps artifact for
ordinary dependency synchronization.  That dependency is intentional, explicit,
and independently verified before execution.

The generated consumer artifact remains unaffected by this development-time
relationship.

## Open Questions and Follow-Ups

Future external build/development artifacts should be evaluated for inclusion in
`dependencies.txt` rather than receiving new one-off Make download rules.

A future bashdeps release may change the preferred bootstrap integration pattern.
Bootstrap may adopt such improvements through a deliberate dependency update, but
shall continue preserving independent first-copy verification and the Make target
boundaries defined here unless a later ADR explicitly supersedes them.

## Related Decisions

- Related to: ADR-007 (inspectable and reviewable execution)
- Related to: ADR-010 (generated distribution artifact)
- Refines: ADR-012 (Make as the orchestration interface)
- Related to: ADR-029 (reproducible and verifiable releases)
- Related to: ADR-040 (deterministic behavior)
- Related to: ADR-041 (documentation as part of the product)
- Related to: ADR-042 (minimize the trusted computing base)
- Related to: ADR-046 (documentation-driven, test-second development)
