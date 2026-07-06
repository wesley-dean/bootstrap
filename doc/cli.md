# Command-Line Interface

This document describes the currently supported public command-line behavior for
`bootstrap.bash`.

The command line is intentionally small during this phase of the roadmap. The
project is establishing a stable option surface before adding manifest parsing,
planning, or package installation.

## Command model

`bootstrap.bash` has one primary operation: run the bootstrap engine.

The project currently uses GNU-style long options to modify that operation. It
does not use subcommands.

This keeps invocation direct and explicit:

```bash
bootstrap.bash --dry-run --verbose
```

## Supported invocations

```bash
bootstrap.bash
bootstrap.bash --help
bootstrap.bash --version
bootstrap.bash --dry-run
bootstrap.bash --explain
bootstrap.bash --verbose
bootstrap.bash --quiet
```

Operational options may be combined when they are not contradictory:

```bash
bootstrap.bash --dry-run --explain --verbose
```

Running `bootstrap.bash` without arguments currently preserves the placeholder
behavior:

```text
bootstrap.bash: not yet implemented
```

This placeholder exists only until later roadmap phases introduce manifest
parsing, planning, and package execution.

## `--help`

`--help` prints a short usage summary and exits successfully.

`--help` must be used by itself. Supplying additional arguments with `--help` is
a usage error.

## `--version`

`--version` prints the bootstrap artifact version metadata embedded by the build
process and exits successfully.

The current version output includes:

- the artifact name and version;
- the build date associated with the source revision;
- the source commit identifier used when the artifact was generated.

The metadata is informational. It helps users and contributors understand the
origin of a generated artifact, but it does not affect runtime behavior.

`--version` must be used by itself. Supplying additional arguments with
`--version` is a usage error.

## `--dry-run`

`--dry-run` records the user's intent to avoid system changes.

At this phase of the roadmap, no package operations exist yet, so `--dry-run`
does not change the placeholder behavior. Later planning and execution phases
will use this flag to prevent package-manager changes.

## `--explain`

`--explain` records the user's intent to receive explanation-oriented output.

At this phase of the roadmap, no execution plan exists yet, so `--explain` does
not change the placeholder behavior. Later planning phases will use this flag to
produce human-readable explanations of planned work.

## `--verbose`

`--verbose` records the user's intent to receive more detailed diagnostic output.

At this phase of the roadmap, no detailed diagnostics exist yet, so `--verbose`
does not change the placeholder behavior.

`--verbose` cannot be combined with `--quiet` because those options express
contradictory output preferences.

## `--quiet`

`--quiet` suppresses non-essential output.

During the placeholder phase, this means the placeholder message is not printed.
Later phases may use quiet mode to reduce diagnostic and progress output while
still reporting errors.

`--quiet` cannot be combined with `--verbose` because those options express
contradictory output preferences.

## Unsupported options and arguments

Unsupported options fail conservatively with a human-readable diagnostic and a
non-zero exit status. This avoids silently accepting misspelled flags or
implying that future roadmap options already work.

Unexpected positional arguments also fail conservatively until later roadmap
phases define manifest input behavior.
