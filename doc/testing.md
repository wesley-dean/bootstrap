# Testing

This project uses `make` targets to keep local checks, dependency preparation,
builds, tests, and continuous integration behavior consistent.

## Quick Reference

  Task                                      Command
  ----------------------------------------- --------------------
  Synchronize build/development dependencies `make deps`
  Verify dependency state offline           `make deps-check`
  Build all release artifact flavors         `make build`
  Synchronize dependencies, then build       `make all`
  Check the source                           `make check`
  Format the source                          `make format`
  Run the test suite against all flavors     `make test`
  Generate CI-style test reports             `make test-report`
  Generate reference documentation           `make docs`
  Run end-to-end tests                       `make test-e2e`

## Prepare build and development dependencies

Bootstrap uses a pinned released `bashdeps.bash` artifact to manage ordinary
external build/development files declared in `dependencies.txt`.

Run:

``` bash
make deps
```

This is the dependency-convergence target. It may use the network. Make directly
owns only the bootstrap of `vendor/bashdeps.bash`; after verifying that pinned
artifact, it runs bashdeps synchronization against the committed manifest.

The manifest-managed dependencies include:

- `vendor/doxygen-bash.awk`, used for reference documentation; and
- `vendor/bash-minifier.bash`, the commit-pinned Bash-Minifier artifact used to
  derive the minified release flavor.

To verify already-present dependency state without network access or repair, run:

``` bash
make deps-check
```

`deps-check` requires an already-present valid bashdeps bootstrap. Missing,
tampered, or stale dependency bytes cause verification to fail rather than being
repaired.

`vendor/` is generated state and is excluded from source control.

## Build the release artifacts

Build the three standalone Bootstrap executable flavors and their checksum
companions with:

``` bash
make build
```

A successful build creates exactly these release files:

```text
dist/bootstrap.dev.bash
dist/bootstrap.bash
dist/bootstrap.min.bash
dist/bootstrap.dev.bash.sha256
dist/bootstrap.bash.sha256
dist/bootstrap.min.bash.sha256
```

The executable flavors have a deliberate lineage:

1. `bootstrap.dev.bash` assembles the ordered maintained source with comments
   intact.
2. `bootstrap.bash` removes full-line comments from that complete assembled
   program while preserving the shebang.
3. `bootstrap.min.bash` passes the complete stripped artifact through the pinned
   Bash-Minifier dependency.

All three executable artifacts receive mode `0755`. Each `.sha256` file records
the SHA-256 digest of the corresponding executable.

New builds publish only `.sha256` companions. A successful `make build` also
removes stale `.256` companions for the three current executable filenames so a
working tree that contains output from the previous naming convention cannot look
like it has two current checksum contracts.

`make build` deliberately does not bootstrap, synchronize, or verify external
dependencies and therefore remains network-free. It now requires already-prepared
`vendor/bash-minifier.bash`. A fresh checkout should use either:

``` bash
make all
```

or:

``` bash
make deps
make build
```

`all` completes `make deps` before invoking `make build`, including under parallel
Make execution.

After construction, none of the three executable release flavors depends on
bashdeps, Bash-Minifier, `dependencies.txt`, or `vendor/` at runtime.

## Check the source

Run static checks with:

``` bash
make check
```

This target runs the project's configured shell checks against maintained source.
Generated release flavors are tested behaviorally rather than treated as
maintained source for formatting or ShellCheck purposes.

## Format the source

Format shell source files with:

``` bash
make format
```

Use this before opening a pull request when shell formatting changes are needed.

## Run the test suite

Run the Bats test suite with:

``` bash
make test
```

The same complete behavior-oriented suite is applied to all three executable
flavors. Existing tests address `dist/bootstrap.bash` as the consumer path; the
Make test runner temporarily places each built flavor at that path and restores
the ordinary stripped artifact after each suite run. This keeps one behavior
contract while allowing the physical representation to differ.

Tests should not rely on minification-sensitive formatting such as one assignment
per physical line. Assertions should prefer executable behavior and stable public
content.

The behavior tests also include regression coverage for the Make/bashdeps
boundary, including network-free build failure when Bash-Minifier is absent, safe
bootstrap publication, offline verification, target ordering, all six expected
build outputs, checksum validity, removal of stale `.256` companions,
transformation lineage, executable permissions, and generated-state cleanup.

## Generate test reports

Run the suite against all three flavors and generate JUnit reports with:

``` bash
make test-report
```

The target writes separate reports under `test-results/` for the development,
stripped, and minified flavors. The GitHub Action at
`.github/workflows/test.yml` publishes those reports together so a transformation
regression is visible in the same required test workflow.

CI also exercises the released bashdeps integration directly: it synchronizes the
real committed manifest, verifies it offline, tampers with the managed
Bash-Minifier bytes to prove `deps-check` detects byte drift, and then uses an
explicit `make deps` to converge state again.

CI verifies all six release files after a fresh `make all`, checks every
`.sha256` file, confirms no legacy `.256` companion remains, confirms the
development artifact retains the generated comment header, confirms the ordinary
artifact does not, and confirms the minified artifact is not byte-identical to
the stripped artifact.

## Generate reference documentation

Prepare dependencies first:

``` bash
make deps
make deps-check
```

Then generate Doxygen reference documentation with:

``` bash
make docs
```

`make docs` deliberately does not acquire missing dependencies. It consumes the
prepared `vendor/doxygen-bash.awk` file, applies the executable mode required by
Doxygen, and runs Doxygen using the repository `Doxyfile`. If the filter is
missing, the target fails with guidance to prepare dependency state explicitly.

Generated reference documentation is written under `doc/reference/`. Both
`doc/reference/` and `vendor/` are generated build-time artifacts and are
excluded from source control. Regenerate reference documentation rather than
editing generated files manually.

The GitHub Pages workflow at `.github/workflows/static.yml` synchronizes and
verifies dependencies from a clean checkout, generates the reference
documentation, verifies dependency byte identity again, and publishes
`doc/reference/` directly as the Pages artifact. Generated files do not need to
be committed to the repository.

## Run containerized end-to-end tests

Run all currently enabled end-to-end test environments with:

``` bash
make test-e2e
```

The E2E targets require built consumer artifacts and do not implicitly
synchronize development dependencies. The current E2E workflow uses the ordinary
`dist/bootstrap.bash` flavor inside platform containers; equivalence among all
three release flavors is enforced by the complete Bats suite described above.

At present, the Ubuntu/APT, Alpine/APK, and RedHat-family/DNF environments are
enabled:

``` bash
make test-e2e-apt
make test-e2e-apk
make test-e2e-dnf
```

The older platform-named targets remain available as compatibility aliases:

``` bash
make test-e2e-ubuntu
make test-e2e-alpine
make test-e2e-redhat
```

The end-to-end tests are intended to verify that Bootstrap can provision fresh
supported operating-system images using real package managers.

## Release end-to-end check

The GitHub Action at `.github/workflows/e2e.yml` runs the enabled end-to-end
environments as a matrix so each package-manager environment has an independent
result. Its initial `make all` invocation also exercises the explicit
fresh-checkout dependency-convergence-and-build path, including Bash-Minifier
preparation and all six build outputs.

That release end-to-end workflow will also be a required check.

## Clean generated state

`make clean` removes the complete generated `dist/` tree, including all executable
flavors and checksum companions.

`make distclean` additionally removes generated reference documentation, test
results, and the entire generated `vendor/` dependency tree. A subsequent
`make deps` or `make all` can reproduce dependency state from the committed
bootstrap pin and `dependencies.txt`.
