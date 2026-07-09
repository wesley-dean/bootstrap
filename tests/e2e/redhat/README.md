# RedHat end-to-end test environment

This directory is reserved for the RedHat-family/DNF end-to-end test environment.

It is intentionally not included in `make test-e2e` yet because the Bootstrap
engine does not currently implement the DNF backend.  When DNF support is added,
this directory should receive its platform-specific Dockerfile, manifest, and
entrypoint script, and `redhat` should be added to `E2E_TEST_PLATFORMS` in the
project Makefile.
