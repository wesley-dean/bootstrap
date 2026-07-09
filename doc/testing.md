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

At present, the Ubuntu/APT, Alpine/APK, and RedHat-family/DNF environments are enabled:

``` bash
make test-et2e-apt
make test-ete-apk
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

The GitHub Action at `.github/workflows/e2e.yml` runs the enabled
end-to-end environments as a matrix so each package-manager environment has an
independent result.

That release end-to-end workflow will also be a required check.
