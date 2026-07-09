# Testing

This project uses `make` targets to keep local checks, formatting,
tests, and continuous integration behavior consistent.

## Quick Reference

  Task                                Command
  ----------------------------------- --------------------
  Check the source                    `make check`
  Format the source                   `make format`
  Run the test suite                  `make test`
  Generate the CI-style test report   `make test-report`
  Run end-to-end tests                `make test-e2e`

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

## Generate a test report

Run the test suite and generate the project test report with:

``` bash
make test-report
```

The GitHub Action at `.github/workflows/test.yml` runs
`make test-report` to verify project functionality. This workflow is a
required check.

## Run containerized end-to-end tests

Run all currently enabled end-to-end test environments with:

``` bash
make test-e2e
```

This target builds each enabled platform container image, copies the generated
Bootstrap script into that platform's container context, and uses Bootstrap
inside the container to install the tools used by the project test environment.

At present, only the Ubuntu/APT environment is enabled:

``` bash
make test-e2e-ubuntu
```

Alpine/APK and RedHat-family/DNF directories are present as reserved test
contexts. They are intentionally not enabled until their corresponding package
manager backends are implemented.

The end-to-end tests are intended to verify that Bootstrap can provision fresh
supported operating-system images using real package managers.

## Release end-to-end check

For releases, the project will add a dedicated end-to-end GitHub Action.
It will look like the existing `.github/workflows/test.yml` workflow,
but it will run:

``` bash
make test-e2e
```

instead of:

``` bash
make test-report
```

That release end-to-end workflow will also be a required check.
