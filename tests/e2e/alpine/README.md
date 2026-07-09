# Alpine end-to-end test environment

This directory is reserved for the Alpine/APK end-to-end test environment.

It is intentionally not included in `make test-e2e` yet because the Bootstrap
engine does not currently implement the APK backend.  When APK support is added,
this directory should receive its platform-specific Dockerfile, manifest, and
entrypoint script, and `alpine` should be added to `E2E_TEST_PLATFORMS` in the
project Makefile.
