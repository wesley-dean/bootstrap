# ADR-002: Describe Desired State Rather Than Installation Procedures

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes a fundamental design
principle for the bootstrap system.

Rather than describing **how** software should be installed,
configuration should primarily describe **what the resulting system
should become**.

This decision influences every layer of the project, from package
manifests and profile definitions to future configuration mechanisms.

Although the initial implementation focuses on package installation,
this ADR intentionally describes a broader architectural direction.

## Context

System bootstrap tools have traditionally been imperative.

A typical installation script might consist of hundreds of lines of
commands:

``` bash
apt-get update
apt-get install git
apt-get install vim-gtk3
apt-get install jq
git clone ...
mkdir ...
cp ...
systemctl enable ...
```

Such scripts answer the question:

> "What commands should be executed?"

They do not answer the more important question:

> "What should this machine become?"

As these scripts grow, intent becomes increasingly difficult to recover.

A future maintainer may understand *what* a command does without
understanding *why* it exists.

Similarly, removing or modifying a command becomes increasingly risky
because the desired end state is never stated explicitly.

The project seeks to reduce this ambiguity.

## Decision

The project shall prefer declarative descriptions of desired system
state over imperative descriptions of installation procedures.

Configuration artifacts should primarily express intent.

The bootstrap engine should determine how to realize that intent using
the facilities provided by the operating system.

Whenever practical, users should describe outcomes rather than
implementation steps.

For example, a package manifest should communicate:

``` text
git
vim-gtk3
jq
```

rather than embedding operating-system-specific installation commands.

Likewise, future configuration should prefer concepts such as:

-   development workstation
-   build server
-   Chromebook development environment
-   documentation workstation
-   CI/CD controller

instead of long sequences of shell commands.

## Rationale

This project exists because rebuilding a development environment is
fundamentally an exercise in recovering intent.

A package list is not valuable because it contains package names.

It is valuable because it communicates something about the machine.

For example:

``` text
vim-gtk3
git
shellcheck
python3-venv
```

does not merely describe software.

It communicates that the machine is intended to be used for software
development.

Similarly,

``` text
podman
buildah
skopeo
```

suggests a container-development environment.

The package list therefore represents only one expression of a larger
concept.

Over time, the project may also express desktop configuration,
filesystem mounts, editor configuration, fonts, language runtimes,
development tools, browser configuration, or other workstation
characteristics.

Treating these artifacts as declarations of desired state allows the
implementation beneath them to evolve without changing the user's
intent.

## Alternatives Considered

### Imperative Shell Scripts

Traditional shell scripts provide complete control over every
installation step.

However, they tightly couple the user's intent to one particular
implementation.

As systems evolve, these scripts tend to accumulate conditionals,
duplicated logic, and distribution-specific workarounds that obscure the
original purpose.

This approach was rejected because it increases maintenance burden and
makes review more difficult.

### Package Manager Command Lists

Another possibility would be to treat configuration files as collections
of package-manager commands.

For example:

``` text
apt-get install git
apt-get install vim-gtk3
```

Although straightforward, this unnecessarily exposes implementation
details.

It also reduces portability and makes future support for additional
operating systems more difficult.

This approach was rejected because it describes execution rather than
desired outcome.

## Consequences

The bootstrap engine becomes responsible for interpreting user intent.

Configuration files become responsible only for expressing that intent.

Configuration becomes easier to read because it focuses on *what* rather
than *how*.

Implementation details remain centralized rather than duplicated across
multiple manifests.

Supporting additional operating systems becomes primarily an
implementation concern rather than a configuration concern.

Reviewers can reason about whether a machine is intended to become a
development workstation without simultaneously reviewing package-manager
syntax.

## Non-Goals

This ADR does not attempt to define a complete configuration language.

It does not specify the syntax of package manifests, profile
definitions, or future configuration files.

Likewise, this ADR does not prohibit imperative operations.

Some installation tasks will necessarily require procedural logic.

The decision is simply that procedural logic belongs in the bootstrap
engine whenever practical rather than in user-authored configuration.

## Future Considerations

The initial implementation may consist solely of plain-text package
manifests.

Future versions may introduce richer concepts such as profiles, feature
groups, or machine classes.

For example:

``` yaml
profiles:
  - developer-workstation
  - kubuntu
  - container-development
```

The architectural principle established by this ADR remains unchanged
regardless of the specific representation.

## Summary

The bootstrap system should describe what a machine should become rather
than how to construct it.

Configuration expresses intent.

The bootstrap engine realizes that intent.

Maintaining this separation improves readability, reduces implementation
coupling, and allows the project to evolve without continually rewriting
user-authored configuration.

This decision establishes a declarative foundation upon which future
package management, workstation configuration, and profile mechanisms
can be built.
