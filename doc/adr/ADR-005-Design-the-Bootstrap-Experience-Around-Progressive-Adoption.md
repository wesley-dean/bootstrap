# ADR-005: Design the Bootstrap Experience Around Progressive Adoption

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes that the bootstrap engine
shall deliver value immediately while allowing users to adopt additional
capabilities over time.

The project should never require users to commit to the entire ecosystem
before receiving meaningful benefit.

## Context

Many configuration-management systems are designed around complete
adoption.

Users are expected to learn the configuration language, establish
repository structure, understand inventories or roles, and embrace the
project's preferred workflow before they can perform even simple tasks.

This creates a significant adoption barrier.

The intended audience for this project often has a much simpler
immediate goal:

-   install development packages on a new laptop;
-   recreate a workstation after replacing a drive;
-   prepare a Chromebook development container;
-   or recover a machine after a fresh operating-system installation.

In these situations, users should not need to understand the project's
entire architecture before accomplishing useful work.

## Decision

The bootstrap engine shall support progressive adoption.

Each additional capability should build upon the previous one without
making earlier use cases obsolete.

A user should be able to stop after any stage while still possessing a
useful system.

The project should avoid introducing mandatory complexity solely to
support advanced scenarios.

## Rationale

The simplest useful operation should remain simple.

For many users, the first interaction with the project may consist of
installing a curated collection of packages.

Later, the same user may choose to add workstation profiles, dotfiles,
configuration management, desktop customization, filesystem mounts, or
other automation.

These later capabilities should feel like natural extensions rather than
requirements imposed from the beginning.

By allowing adoption to occur incrementally, the project reduces
cognitive load while encouraging experimentation.

## Typical Progression

Although users may enter the workflow at any point, a typical
progression might resemble:

1.  Install packages from a manifest.
2.  Apply one or more workstation profiles.
3.  Install or update dotfiles.
4.  Configure services and desktop behavior.
5.  Enable optional integrations such as centralized management or
    additional automation.

These stages are illustrative rather than prescriptive.

## Alternatives Considered

### Require Complete Configuration Up Front

One alternative would require users to adopt profiles, repositories, and
the full project structure before executing the bootstrap engine.

This approach was rejected because it delays the first successful
experience and increases the learning curve.

### Separate Tools for Every Capability

Another possibility would be to create independent utilities for package
installation, profile management, configuration, and workstation setup.

This was rejected because it fragments the user experience and
duplicates common functionality.

## Consequences

The bootstrap engine should expose a stable interface while permitting
users to adopt only the features they currently need.

Documentation should present capabilities in a layered manner, beginning
with the smallest useful workflow before introducing more advanced
concepts.

Future capabilities should integrate naturally into the existing
architecture without invalidating simpler workflows.

## Non-Goals

This ADR does not define the ordering of internal implementation work.

It does not require every installation to progress through every stage.

It simply establishes that the project should provide value at every
level of adoption.

## Future Considerations

As the project grows, additional capabilities may include
organization-wide profiles, centrally managed repositories, workstation
classification, container-development environments, or optional Ansible
integration.

Such features should remain additive.

Users who only require package installation should not be required to
understand or configure these advanced capabilities.

## Summary

The project shall be useful from its very first command.

Every additional feature should extend that usefulness rather than
becoming a prerequisite for it.

By embracing progressive adoption, the bootstrap engine remains
approachable for newcomers while continuing to scale to more
sophisticated workflows.
