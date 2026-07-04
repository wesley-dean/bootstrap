ADR-001: Use a Single Bash 5+ Script as the Bootstrap Entry Point

Date: 2026-07-04

Status

Proposed

Context

This project exists to help rebuild and prepare development systems from a fresh or minimally configured state.

The initial use case is a personal workstation or laptop rebuild. A typical target system may have only the operating system installed, with few development tools present. The user may be working from a Kubuntu, Ubuntu, Debian, Chromebook/Crostini, or similarly constrained environment where installing a large configuration framework first may be inconvenient.

The desired first-run experience is intentionally simple:

vet https://example.com/bootstrap.bash -- ./packages.txt

A lower-trust fallback may also be documented:

curl -fsSL https://example.com/bootstrap.bash | sudo bash -s -- ./packages.txt

The tool should be reachable from a single URL and should not require cloning a repository before it can begin useful work.

Decision

The project will use a single Bash 5+ script as its primary bootstrap entry point.

The script will be designed to run directly from a URL through "vet", or through a documented "curl | bash" fallback when appropriate.

The script will be responsible for:

- detecting the supported environment;
- validating required tools;
- reading a package manifest;
- installing missing packages through the native system package manager;
- reporting clear failures;
- and keeping the first-run path small enough to copy, paste, inspect, and understand.

Bash 5+ is selected because it is widely available on the intended Linux-like targets, requires minimal bootstrapping, and can coordinate native package-management tools without becoming a package manager itself.

Considered Option: Ansible

Ansible was considered because it is a strong fit for mature system configuration.

It provides useful capabilities such as:

- idempotent tasks;
- roles;
- reusable community content;
- inventory management;
- privilege escalation;
- package installation;
- service management;
- templating;
- and support for centralized execution.

However, Ansible was not selected as the primary bootstrap entry point.

The main reason is bootstrapping complexity. On a fresh workstation, Ansible may not be installed. Installing it may require package updates, Python availability, repository configuration, SSH assumptions, privilege escalation setup, or other preparatory steps. That creates a larger first-run cliff than this project wants.

Ansible remains a possible later-stage tool, but it should not be required before the bootstrap mechanism can begin.

Rationale

A bootstrap tool should have fewer prerequisites than the environment it creates.

A single Bash script provides the lowest practical barrier for the intended use cases. It can be fetched from one URL, reviewed as plain text, and executed without requiring a prior clone, role installation, inventory setup, or controller machine.

This design also works across several operating modes:

- a fresh laptop where the user is sitting at the keyboard;
- a Chromebook/Crostini environment where inbound SSH management is not natural;
- a personal workstation rebuild;
- a package-only setup;
- and a degraded recovery scenario where only minimal tooling is available.

The Bash script does not attempt to replace APT, dpkg, Ansible, containers, or other higher-level tools. It coordinates them.

Use of "vet"

"vet" is the preferred execution mechanism for remote script execution.

The user’s private dotfiles repository already includes "vet" as a submodule, so the normal expected path is that "vet" will be available before this bootstrap script is run.

Using "vet" improves the safety posture compared with blindly piping remote content into a privileged shell. It allows the script to be reviewed before execution and better matches the project’s preference for inspectable, deliberate automation.

The project may still document a "curl | bash" form for convenience, recovery, or environments where "vet" is unavailable, but that form is not the preferred trust path.

Consequences

The project will prioritize a clear, portable Bash implementation over a role-based Ansible implementation.

The first version should avoid unnecessary external dependencies beyond the native package-management tools required to perform package operations.

For Debian-like systems, the script may rely on tools such as:

apt-get
apt-cache
dpkg

The script should not reimplement package-manager behavior that is already provided by those tools.

This approach makes the bootstrap process easier to start, but it also means the script must be carefully written, well documented, and conservatively scoped.

Non-Goals

This project is not intended to be a full configuration-management system.

It is not intended to replace:

- Ansible;
- Nix;
- Guix;
- Docker;
- cloud-init;
- golden images;
- or full workstation-management platforms.

It is also not intended to provide perfect repeatable builds. For most workstation use cases, unversioned package manifests are acceptable and preferred.

Version constraints may be supported, but they are an escape hatch rather than the main design center.

Future Considerations

A future version may hand off to Ansible after the initial bootstrap has completed.

A future version may also support centrally managed workflows where a controller system, such as Jenkins, orchestrates configuration. Those workflows should remain compatible with the Bash bootstrap model, but they should not make local bootstrap harder.

Custom Ansible roles, if created, should remain optional and should not be required for the single-URL first-run path.

Summary

The project will use Bash 5+ as the universal bootstrap surface because it minimizes first-run complexity.

Ansible remains valuable, but it is better suited for later-stage configuration than for the first command a user runs on a fresh system.

The core design principle is:

A fresh system should be able to begin becoming useful from one inspectable script at one URL.
