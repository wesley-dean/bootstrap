# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records for the Bootstrap
engine.

The ADRs collectively describe the project's architectural philosophy,
long-term engineering decisions, and the reasoning behind those decisions.  They
are intended to answer a direct question:

> **Why is the project built this way?**

Source code explains *how* the software works.  Tests explain *what* behavior is
expected.  The ADRs explain *why* consequential architectural decisions were made
and what alternatives were considered.

The linked ADR list below is generated from the current ADR corpus when reference
documentation is built.  The prose in this file is maintained source; the
combined `README.md` used by Doxygen is generated and is not committed.

## How to Read This Collection

Although the ADRs are numbered chronologically, they are also organized around a
set of recurring themes.  Readers looking for answers to a specific question may
find it useful to begin with the thematic groupings below and then use the linked
index to open individual decisions.

### Foundation

These ADRs establish the project's goals, philosophy, and overall direction.

- ADR-001 through ADR-010

Topics include project philosophy, distribution, build process, release
artifacts, and modular source organization.

### Execution Model

These ADRs describe how the Bootstrap engine interprets user intent and performs
work.

- ADR-011 through ADR-022

Topics include manifest interpretation, parsing, validation, execution planning,
backend abstraction, and diagnostics.

### User Experience

These ADRs describe how users interact with the Bootstrap engine.

- ADR-023 through ADR-030

Topics include configuration, command-line interface, logging, exit codes, trust,
and compatibility.

### Long-Term Evolution and Engineering Governance

These ADRs describe how the project should evolve and how its engineering
practices remain inspectable over time.

- ADR-031 through ADR-055

Topics include semantic versioning, architectural evolution, composition,
testing, determinism, documentation, trusted computing base, contributor
philosophy, package-installation safeguards, build and development dependencies,
release artifact forms, threat modeling, and generated ADR navigation.

## ADR Index
