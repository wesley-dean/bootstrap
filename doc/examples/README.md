# Example Manifests

This directory contains small, release-specific starter manifests for
Bootstrap.  The examples are intended to reduce the effort required to begin a
new workstation manifest without implying that every listed package is needed
on every system.

Examples are organized by operating system, distribution, release, and
purpose:

```text
doc/examples/<operating-system>/<distribution>/<release>/<purpose>.manifest
```

The initial example is:

- [`linux/ubuntu/26.04/core.manifest`](linux/ubuntu/26.04/core.manifest), a
  compact collection of generally useful command-line tools for Ubuntu 26.04.

Treat each example as a starting point:

- review the manifest before running it;
- add or remove packages to match the system's purpose;
- remember that package availability depends on configured repositories; and
- prefer unconstrained package names unless a genuine compatibility requirement
  justifies a version constraint.

Inspect an example without changing the system:

```bash
./bootstrap.bash --dry-run --explain \
  doc/examples/linux/ubuntu/26.04/core.manifest
```

Additional purpose-specific manifests may be added alongside `core.manifest`
when a small, well-documented example would help users get started.
