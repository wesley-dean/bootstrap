# ADR-012: Use Make as the Local and CI Orchestration Interface

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes `make` as the primary
developer-facing and automation-facing orchestration interface for the
project.

The purpose of this decision is to keep validation, testing, formatting,
and artifact generation reproducible across local development and
continuous integration.

GitHub Actions may automate project workflows, but the workflow logic
should delegate to Makefile targets whenever practical.

## Context

The project uses several small, focused tools:

-   ShellCheck for static analysis;
-   `shfmt` for formatting;
-   Bats for tests;
-   build steps for producing `dist/bootstrap.bash`;
-   GitHub Actions for continuous integration and release automation.

Without a shared orchestration layer, these commands are likely to be
copied into multiple places. Local documentation, developer habits, CI
workflows, and release workflows may drift apart.

That drift creates avoidable confusion.

A command that passes locally may differ from the command used in CI.

A release workflow may build the artifact differently than a developer
does.

A future contributor may need to inspect multiple files to understand
how the project is actually validated.

The project should avoid that fragmentation.

## Decision

The project shall use a Makefile as the canonical command interface for
common development, validation, testing, build, and release-preparation
tasks.

At minimum, the Makefile should define targets such as:

``` text
check
format
test
test-report
all
clean
```

Additional targets may be added as the project evolves.

GitHub Actions workflows should invoke Makefile targets rather than
duplicating the underlying implementation commands whenever practical.

For example, a workflow should prefer:

``` bash
make check test
```

or:

``` bash
make ci
```

over directly embedding the full ShellCheck, Bats, and build commands in
the workflow file.

## Rationale

Make provides a small, widely available, language-neutral orchestration
layer.

It is appropriate for this project because the toolchain is
intentionally simple. The project does not need a heavy build system,
package manager, task runner, or custom automation framework.

Using Make keeps the developer experience familiar:

``` bash
make check
make format
make test
make all
```

It also keeps CI understandable. GitHub Actions remains responsible for
providing an execution environment, installing dependencies, and
invoking the appropriate project command. The Makefile remains
responsible for defining what those commands mean.

This separation reduces duplication and makes local reproduction of CI
behavior straightforward.

## Alternatives Considered

### Embed Commands Directly in GitHub Actions

The project could place all validation, testing, and build commands
directly inside workflow YAML files.

This was rejected because it risks divergence between local development
and CI. It also makes the workflow files responsible for project
behavior rather than automation.

### Use a Custom Bash Task Runner

The project could create its own task runner using shell functions or
scripts.

This was rejected because Make already provides the needed behavior with
less project-specific machinery.

### Use a Language-Specific Task Runner

The project could adopt a Node, Python, or other ecosystem-specific task
runner.

This was rejected because the project intentionally avoids adding those
ecosystems as core bootstrap or development dependencies.

## Consequences

The Makefile becomes part of the project's public developer interface.

Changes to target names or behavior should be treated as meaningful
project changes rather than incidental edits.

GitHub Actions workflows should stay thin and readable.

Documentation should reference Make targets whenever possible.

Developers should be able to reproduce CI behavior locally without
mentally translating workflow YAML into shell commands.

## Non-Goals

This ADR does not require Make to perform every possible action.

It does not prohibit small workflow-specific commands where they are
genuinely specific to GitHub Actions, such as uploading artifacts or
publishing test reports.

It also does not require sophisticated Make dependency graphs. Simple
phony targets are sufficient unless the project later needs more complex
behavior.

## Future Considerations

Future Make targets may include:

-   `ci` for the complete continuous-integration command set;
-   `release-check` for release readiness;
-   `dist` for building `dist/bootstrap.bash`;
-   `install-tools` for local development dependency hints;
-   `lint-yaml` or `lint-markdown` if additional checks are adopted.

Any such additions should preserve the Makefile's role as a clear and
discoverable command interface.

## Summary

Make is the project's canonical orchestration surface for development
and CI.

GitHub Actions automates execution.

The Makefile defines behavior.

Keeping that boundary clear reduces drift, improves reproducibility, and
makes the project easier to understand, test, and release.
