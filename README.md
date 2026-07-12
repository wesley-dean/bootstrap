# Bootstrap

Bootstrap is a declarative package bootstrapper for reproducible system
provisioning.

Instead of writing an imperative shell script that decides how to install each
package, you write a small manifest that describes the packages a system should
have. Bootstrap parses that manifest, plans the requested package operations,
resolves them through a native package-manager backend, and then either explains
or executes the resulting plan.

The goal is not to replace the operating system package manager. The goal is to
make bootstrap intent easier to read, review, test, and repeat.  The
distribution's package maanger is used on the backend.  This is not a
replacement, but a wrapper.

## Features

- Plain-text package manifests.
- Comments and blank lines for human-readable manifests.
- Package version constraints such as `>=`, `=`, `==`, `<`, and `>`.
- Dry-run mode for reviewing planned work before changing a system.
- Explain mode for understanding how manifest entries become planned actions.
- Native package-manager delegation for APT, Alpine APK, and DNF.
- Visible per-package installation progress outside quiet mode.
- Per-package installation timeouts when GNU `timeout` is available.
- APT installations that omit automatically recommended packages.
- Conservative diagnostics that stop rather than guessing when input is unclear.
- A single generated `bootstrap.bash` release artifact.
- Support for multiple system package managers:
  - APT: Ubuntu / Debian variants
  - DNF: RedHat variants
  - APK: Alpine

## Install

The published release artifact is a standalone Bash script.

To download the latest release with `curl`:

```bash
curl -fsSL \
  https://github.com/wesley-dean/bootstrap/releases/latest/download/bootstrap.bash \
  -o bootstrap.bash
chmod +x bootstrap.bash
```

### Optional shell function

If you use Bootstrap frequently, you may prefer a shell function that keeps the
latest release artifact in `~/.local/bin/bootstrap.bash` and lets you provide a
small package manifest directly as command-line arguments.

For example, after defining the function below, this command:

```bash
bootstrap git curl jq
```

is equivalent to passing this manifest to Bootstrap through standard input:

```text
git
curl
jq
```

The function intentionally keeps the wrapper small. If the local copy of the
release artifact is missing, it downloads the latest published `bootstrap.bash`
artifact and marks it executable. It then writes each argument on its own line
and pipes that generated manifest into Bootstrap.

```bash
bootstrap() {

  local bootstrap_path="${bootstrap_path:-${HOME}/.local/bin/bootstrap.bash}"
  local bootstrap_url="${bootstrap_url:-https://github.com/wesley-dean/bootstrap/releases/latest/download/bootstrap.bash}"
  local -a bootstrap_args=("${bootstrap_args[@]:-}")

  if [[ ! -x "${bootstrap_path}" ]]; then
    mkdir -p "${bootstrap_path%/*}" \
                                    && curl -fsSL \
        "$bootstrap_url" \
        -o "${bootstrap_path}" \
                               && chmod +x "${bootstrap_path}"
  fi

  for package in "$@"; do
    printf '%s\n' "${package}"
  done | "${bootstrap_path}" "${bootstrap_args[@]}" -
}
```

## Quick start

Create a manifest file. This example uses `packages.manifest`:

```text
#------------------------------------------------------------------------------
# Bootstrap starter manifest
#
# Each logical line describes one package requirement. Blank lines and comments
# are ignored. Inline comments are also supported.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Unconstrained packages
#
# These packages may be installed at the package manager's candidate version.
#------------------------------------------------------------------------------
git
curl
jq

# Inline comments are allowed after package requirements.
ca-certificates # useful for HTTPS package repositories and downloads

#------------------------------------------------------------------------------
# Minimum versions
#
# These entries require the package manager's candidate version to satisfy the
# lower bound before Bootstrap will plan installation.
#------------------------------------------------------------------------------
shellcheck >= 0.10
shfmt >= 3.10
bats >= 1.12

#------------------------------------------------------------------------------
# Exact versions
#
# A single equals sign and a double equals sign are both supported for exact
# version requirements.
#------------------------------------------------------------------------------
yq = 4.45.4
openssl == 3.0

#------------------------------------------------------------------------------
# Upper bounds
#
# Upper bounds can be useful when a later major version is not yet supported by
# the workstation, project, or operational environment being bootstrapped.
#------------------------------------------------------------------------------
python3 < 3.14
nodejs < 23

#------------------------------------------------------------------------------
# Greater-than constraints
#
# This form is available when the candidate version must be strictly newer than
# a known baseline.
#------------------------------------------------------------------------------
make > 4.0
```

Then run Bootstrap with the manifest:

```bash
./bootstrap.bash packages.manifest
```

Multiple manifests may be supplied in one invocation:

```bash
./bootstrap.bash core.manifest containers.manifest security.manifest
./bootstrap.bash *.manifest
```

Bootstrap parses, plans, and resolves every supplied manifest before executing
any package operation. If preflight fails, no package changes are made, and the
diagnostic retains the original manifest filename and line number.

To inspect the plan without making package-manager changes:

```bash
./bootstrap.bash --dry-run packages.manifest
```

To include a plain-language explanation of the planning boundary:

```bash
./bootstrap.bash --dry-run --explain packages.manifest
```

To select the package-manager backend explicitly:

```bash
./bootstrap.bash --package-manager apt packages.manifest
./bootstrap.bash --package-manager apk packages.manifest
./bootstrap.bash --package-manager dnf packages.manifest
```

## Running without installing

The Bootstrap tool is distributed as a single Bash shell script with no
external library dependencies.  While the source for the tool is spread across
multiple files, the distributed tool is a single file.  Therefore,
"installation" in a traditional sense isn't a hard requirement.

### Running with Vet

[`vet`](https://github.com/vet-run/vet) can be used as a safer replacement for
the common `curl | bash` pattern. It downloads the release artifact, displays
the script for review, and then runs it with the arguments you provide.

To run Bootstrap with `packages.manifest` through `vet`:

```bash
vet https://github.com/wesley-dean/bootstrap/releases/latest/download/bootstrap.bash \
  packages.manifest
```

The same Bootstrap arguments can be passed after the release URL:

```bash
vet https://github.com/wesley-dean/bootstrap/releases/latest/download/bootstrap.bash \
  --dry-run --explain packages.manifest
```

### Running with Curl

It is not recommended, but it's also possible to run Bootstrap by fetching it
first using `curl` (or `wget`).  This is not a recommended approach; it's
included here for completeness.  From a security perspective, it's an
anti-pattern to download and run a shell script -- especially one that makes
changes to the underlying system like installing packages -- without inspecting
the script first.  The source for Bootstrap is openly available and can be
inspected along with the process that the bootstrap.bash script is generated.
The source is heavily commented so that it ought to be clear what every single
function in the script does, how they work, how they're invoked, and any
assumptions made when running them.  The code should be as direct, obvious, and
boring as possible.

If you understand the risks and still prefer this approach, you can invoke
Bootstrap directly.

> [!WARNING]
> Running a script directly from the Internet (for example, `curl ... | bash`)
> executes code before you have an opportunity to inspect it. Download the
> script first, or use `vet`, if you want to review the script before
> execution.

```bash
curl https://github.com/wesley-dean/bootstrap/releases/latest/download/bootstrap.bash \
| bash -s -- --dry-run --explain packages.manifest
```

## Privilege Escalation

Bootstrap is designed to run either with elevated (root) privileges or as a
normal system user in which case it uses `sudo` or `doas` only when needed.

If neither `sudo` nor `doas` are available and Bootstrap is run as a normal
user, Bootstrap will not be able to perform operations that modify the
underlying system.  That is, it won't be able to install packages.

In this case, all is not lost.  Another option would be to use `su` to run
Bootstrap as a user with elevated privileges:

```bash
su -c '/path/to/bash /path/to/bootstrap.bash`
```

## Documentation

The README is intentionally brief. More detailed project documentation is kept
in focused files:

- [`doc/motivation.md`](doc/motivation.md) discusses why this project exists
- [`doc/cli.md`](doc/cli.md) describes the supported command-line interface.
- [`doc/manifest-format.md`](doc/manifest-format.md) describes the manifest
  grammar and parser behavior.
- [`doc/examples/`](doc/examples/) contains small, release-specific starter
  manifests.
- [`doc/adr/`](doc/adr/) contains the project's Architecture Decision Records.
- [`testing.md`](doc/testing.md) describes how to test the tool during development
  work.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) describes contribution expectations.
- [`SECURITY.md`](SECURITY.md) explains how to report security concerns.
- [`Reference Documentation`](https://wesley-dean.github.io/bootstrap/) development reference material

## Project status

Bootstrap is under active development. The current implementation focuses on a
small, reviewable package-manifest workflow with APT, Alpine APK, and DNF
backends. Additional package-manager backends and richer provisioning features
are future work.

## License

See [`LICENSE`](LICENSE) for license information.
