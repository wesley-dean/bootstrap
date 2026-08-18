# Testing

This project uses `make` targets to keep local checks, dependency preparation,
builds, tests, and continuous integration behavior consistent.

## Quick Reference

  Task                                      Command
  ----------------------------------------- --------------------
  Synchronize build/development dependencies `make deps`
  Verify dependency state offline           `make deps-check`
  Build the consumer artifact                `make build`
  Synchronize dependencies, then build       `make all`
  Check the source                           `make check`
  Format the source                          `make format`
  Run the test suite                         `make test`
  Generate the CI-style test report          `make test-report`
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

The current manifest-managed dependency is the Bash Doxygen filter used for
reference documentation.

To verify already-present dependency state without network access or repair, run:

``` bash
make deps-check
```

`deps-check` requires an already-present valid bashdeps bootstrap. Missing,
tampered, or stale dependency bytes cause verification to fail rather than being
repaired.

`vendor/` is generated state and is excluded from source control.

## Build the consumer artifact

Build the standalone Bootstrap executable with:

``` bash
make build
```

`build` deliberately does not bootstrap, synchronize, or verify external
dependencies. Bootstrap's current consumer artifact is assembled entirely from
maintained repository source, so a clean `make build` succeeds without creating a
`vendor/` tree.

For the convenient fresh-checkout path that explicitly prepares dependencies
first, run:

``` bash
make all
```

`all` completes `make deps` before invoking `make build`, including under parallel
Make execution.

The generated `dist/bootstrap.bash` artifact remains independent of bashdeps,
`dependencies.txt`, and `vendor/` at runtime.

## Check the source

Run static checks with:

``` bash
make check
```

This target runs the project's configured shell checks.

## Format the source

Format shell source files with:

``` bash
make format
```

Use this before opening a pull request when shell formatting changes are
needed.

## Run the test suite

Run the Bats test suite with:

``` bash
make test
```

The behavior tests include regression coverage for the Make/bashdeps boundary,
including clean builds, safe bootstrap publication, offline verification, target
ordering, and generated-state cleanup.

## Generate a test report

Run the test suite and generate the project test report with:

``` bash
make test-report
```

The GitHub Action at `.github/workflows/test.yml` exercises dependency boundaries,
runs `make test-report`, and publishes the resulting Bats/JUnit results. This
workflow is a required check.

CI also exercises the released bashdeps integration directly: it synchronizes the
real committed manifest, verifies it offline, tampers with the managed Doxygen
filter to prove `deps-check` detects byte drift, and then uses an explicit
`make deps` to converge state again.

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

The E2E targets require only the built consumer artifact and do not implicitly
synchronize development dependencies. Each enabled platform container receives
the generated Bootstrap script and uses Bootstrap inside the container to install
the tools used by the project test environment.

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
fresh-checkout dependency-convergence-and-build path.

That release end-to-end workflow will also be a required check.

## Clean generated state

`make clean` removes the generated distribution artifact.

`make distclean` additionally removes generated reference documentation, test
results, and the entire generated `vendor/` dependency tree. A subsequent
`make deps` or `make all` can reproduce dependency state from the committed
bootstrap pin and `dependencies.txt`.
