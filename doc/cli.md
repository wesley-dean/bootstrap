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
bootstrap.bash --dry-run packages.txt
bootstrap.bash --dry-run core.manifest security.manifest
bootstrap.bash --dry-run -
bootstrap.bash --package-manager apt
bootstrap.bash --package-manager apk
bootstrap.bash --package-manager dnf
bootstrap.bash --explain
bootstrap.bash --verbose
bootstrap.bash --quiet
```

Operational options may be combined when they are not contradictory:

```bash
bootstrap.bash --dry-run --explain --verbose
```

## Configuration precedence

The command reads configuration from several sources.  Later sources override
earlier sources:

1. built-in defaults;
2. a `.env` file in the current working directory, when one exists;
3. exported process environment variables; and
4. explicit command-line options.

The default `.env` file is optional.  The command does not search parent
directories and does not read user-level or system-level configuration files.

Bootstrap-specific configuration entries use the `BOOTSTRAP_` prefix so a local
`.env` file can also contain settings for other tools.  Non-bootstrap keys are
ignored.  Unknown keys that begin with `BOOTSTRAP_` are rejected because they are
likely misspelled bootstrap directives.

The `.env` reader accepts simple data assignments such as:

```dotenv
BOOTSTRAP_PACKAGE_MANAGER=apt
```

The file is parsed as data rather than sourced as shell code.  Shell expansion,
command substitution, and arbitrary Bash statements are not supported.


Running `bootstrap.bash` without arguments currently preserves the placeholder
behavior:

```text
bootstrap.bash: info: not yet implemented
```

This placeholder exists only until later roadmap phases introduce manifest
parsing, planning, and package execution.


## Manifest arguments

When one or more manifest paths are provided, Bootstrap parses, plans, and
resolves the complete ordered set before beginning execution. If any manifest
fails during this preflight phase, Bootstrap reports the original filename and
line number, returns a non-zero status, and performs no package changes.

For example:

```bash
bootstrap.bash core.manifest containers.manifest security.manifest
bootstrap.bash *.manifest
```

Manifest order is the order supplied by the shell. Bootstrap does not discover,
sort, or merge manifest files. Records retain their original source paths and
line numbers through planning, resolution, dry-run explanation, and execution.

A manifest path of `-` follows the common Unix convention of reading manifest
content from standard input:

```bash
printf '%s\n' git curl shellcheck | bootstrap.bash --dry-run -
```

This is useful for generated manifests, shell pipelines, and temporary package
lists that do not need to be written to a separate file. Standard input may be
specified at most once per invocation. Because its source name is `-`, users who
need per-file provenance should pass manifest paths instead of concatenating
files into standard input.


## Package installation timeout

Bootstrap bounds each mutating APT, APK, and DNF package installation when GNU
`timeout` is available.  The timeout applies separately to each package rather
than to the complete manifest or Bootstrap invocation.

The duration is configured in seconds with `BOOTSTRAP_INSTALL_TIMEOUT`:

```dotenv
BOOTSTRAP_INSTALL_TIMEOUT=30
```

The built-in default is 30 seconds.  The effective value must be a positive
whole number.  Empty, zero, negative, fractional, and nonnumeric values are
usage errors discovered before package execution begins.

`timeout` is an optional runtime capability.  When it is unavailable, Bootstrap
prints one warning for the invocation and continues with unbounded native
package-manager installations.  The warning remains visible under `--quiet`
because it identifies a degraded safety boundary.

A package that exceeds the configured duration produces a failed Execution
Result and Bootstrap's existing execution-failure exit status.  Package-state
inspection is not included in the timeout boundary.

APT installations use `--no-install-recommends`, so packages classified only as
recommended dependencies are not installed automatically.

## Package installation progress

Immediately before installing a missing package, Bootstrap writes a progress
message to standard error:

```text
Installing curl...done.
```

A failed or timed-out installation completes the same line with `failed.` before
printing its normal failure and recovery information.  Already-installed
packages do not produce an installation progress message.  `--quiet` suppresses
this routine progress output, while warnings, errors, and recovery guidance
remain visible.

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

## `--package-manager`

`--package-manager` selects the package-manager backend used by resolver and
execution planning.

Supported values are:

- `auto`, which asks the resolver to detect a supported package manager;
- `apt`, which explicitly selects the APT backend;
- `apk`, which explicitly selects the Alpine APK backend; and
- `dnf`, which explicitly selects the RedHat-family DNF backend.

The same setting may be provided by the environment or by `.env` as
`BOOTSTRAP_PACKAGE_MANAGER`.  The command-line option has the highest
precedence:

```bash
BOOTSTRAP_PACKAGE_MANAGER=auto bootstrap.bash --package-manager dnf --dry-run packages.txt
```

## `--explain`

`--explain` asks the tool to explain the reasoning behind planned behavior.

When used with `--dry-run` and a manifest, the output includes a plain-language
explanation of what was inspected, how manifest lines became planned actions,
how those actions were resolved for the selected package manager, and why the
command stopped before making system changes.

For example:

```bash
bootstrap.bash --dry-run --explain packages.txt
```

The explanation is intentionally tied to the same Action Records and Resolved
Actions used by execution.  That keeps explain mode inspectable without
introducing a separate interpretation path.

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


## Recovery guidance

Bootstrap diagnostics are designed to explain both what failed and what can be
tried next.  Error messages describe the conservative stop.  Recovery messages
then provide concrete follow-up steps using the normalized `recovery` log level.

For example, if APT or APK cannot find a package, bootstrap may report that the
package is unavailable and then suggest checking the manifest spelling, refreshing
native package metadata, or searching through the selected package manager.

Recovery guidance is considered essential output.  The `--quiet` option
suppresses non-essential informational output, but it does not suppress warnings,
errors, or recovery guidance.
