# ADR-008: Define a Human-Centered Package Manifest Format

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record defines the structure and philosophy
of the package manifest consumed by the bootstrap engine.

The package manifest is intentionally simple. It exists to describe
package requirements in a format that is easy to read, easy to review,
easy to edit, and suitable for long-term maintenance.

This ADR applies only to the package manifest. Future profile or
workstation description formats are outside its scope.

## Context

The bootstrap engine exists to realize workstation intent rather than
execute a predefined sequence of installation commands.

To support that goal, package manifests should emphasize readability
over expressiveness.

Many dependency-management systems support sophisticated version
expressions, optional dependencies, alternate providers, markers,
hashes, lockfiles, and platform-specific conditionals.

While valuable for application dependency management, those capabilities
are unnecessary for the project's primary use case: rebuilding a
workstation from a fresh operating system installation.

Experience maintaining development workstations over many years suggests
that the overwhelming majority of packages do not require explicit
version constraints. Users generally care that a suitable version is
installed from the operating system's repositories rather than a
specific patch release.

## Decision

The package manifest shall be a plain UTF-8 text file.

Each logical line describes a single package requirement.

Blank lines are ignored.

Lines beginning with `#` are comments.

Inline comments beginning with `#` are permitted.

Whitespace surrounding package names and operators is ignored.

The initial syntax shall support:

-   package only
-   exact version
-   greater-than
-   greater-than-or-equal

Examples:

``` text
git
vim-gtk3
python3-venv

# Networking tools
dnsutils      # provides dig and nslookup
whois
telnet

openssl>=3.0
foo==1.2.3
```

The manifest deliberately does not embed package-manager commands.

## Rationale

The package manifest is intended to be maintained by humans.

Therefore, every feature added to the format must justify its ongoing
maintenance cost.

The preferred entry remains simply:

``` text
vim-gtk3
```

rather than:

``` text
vim-gtk3==9.1.0-2ubuntu4
```

unless a genuine compatibility requirement exists.

By treating version constraints as exceptional rather than routine, the
manifest remains concise and resistant to unnecessary churn as
distributions publish routine updates.

This philosophy encourages users to express intent rather than
implementation.

## Alternatives Considered

### Rich Dependency Language

The project could adopt a syntax similar to language-specific dependency
managers, supporting complex version ranges, optional dependencies,
hashes, and platform markers.

This was rejected because it substantially increases parser complexity
while providing little value for workstation bootstrap.

### Package Manager Command Lists

Embedding commands such as `apt-get install ...` directly into the
manifest was rejected because it mixes desired state with implementation
details and reduces portability.

## Consequences

The parser remains relatively small and understandable.

Most manifests should consist almost entirely of package names.

Version-aware logic is isolated to the comparatively rare cases where
minimum or exact versions are genuinely required.

Future profile formats may reference one or more package manifests
without requiring changes to the manifest syntax itself.

## Non-Goals

This ADR does not define workstation profiles.

It does not define repository management.

It does not define package groups, conditional expressions, variables,
or templating.

Those capabilities may be introduced elsewhere if they become justified.

## Future Considerations

Future versions may support additional metadata through separate files
rather than increasing the complexity of the package manifest itself.

The project should continue to prefer simple, reviewable manifests over
feature-rich dependency languages.

## Summary

Package manifests are intentionally boring.

They should be readable at a glance, maintained with minimal effort, and
focused on expressing workstation intent rather than package-manager
implementation details.
