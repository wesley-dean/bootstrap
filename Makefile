# Makefile
#
# Common development tasks for the bootstrap project.
#

SHELL := /usr/bin/env bash

SHELL_SCRIPTS := bootstrap.bash
TEST_SCRIPTS := tests/*.bats
TEST_RESULTS_DIR := test-results
BATS_TAP := $(TEST_RESULTS_DIR)/bats.tap

.PHONY: check format test test-report clean
	:
all: check test

##
# Run ShellCheck against all shell scripts.
#
check:
	shellcheck $(SHELL_SCRIPTS)

##
# Format shell scripts using shfmt.
#
format:
	shfmt -w $(SHELL_SCRIPTS)

##
# Run the test suite.
#
test:
	bats $(TEST_SCRIPTS)

test-report:
	mkdir -p $(TEST_RESULTS_DIR)
	bats --formatter junit tests/*.bats --output $(TEST_RESULTS_DIR) $(TEST_SCRIPTS)
