# Makefile
#
# Common development tasks for the bootstrap project.
#

SHELL := /usr/bin/env bash

SHELL_SCRIPTS := bootstrap.bash
TEST_SCRIPTS := tests/*.bats

.PHONY: all check format test

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
