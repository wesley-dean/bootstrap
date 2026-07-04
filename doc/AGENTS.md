# AGENTS.md

This file provides guidance for AI coding agents working in this
repository.

Use this file together with `README.md`. The README is the human-facing
project overview. This file is the agent-facing operational map.

## Project Overview

This repository contains a Bash-based bootstrap engine for preparing
fresh or minimally configured development systems.

The project exists to help a machine begin becoming useful from a small,
inspectable entry point. The initial focus is installing curated package
manifests on Debian-family systems, especially Ubuntu, Kubuntu, Debian,
and Chromebook/Crostini environments.

The project is intentionally not a full configuration-management system.
It may later hand off to tools such as Ansible, but Bash is the stable
bootstrap surface.

## Architectural Principles

-   Bash 5+ is the universal bootstrap entry point.
-   Configuration describes desired state.
-   Native package managers remain authoritative.
-   Separate the bootstrap engine from user intent.
-   Support progressive adoption.
-   Preserve a stable public interface.
-   Prefer inspectable execution paths.

## Technology Stack

-   Bash 5+
-   apt-get
-   apt-cache
-   dpkg
-   vet
-   Plain-text manifests

## Coding Guidelines

Prefer small, readable Bash functions. Do not reimplement package
management. Avoid eval. Use defensive shell practices.

## Documentation

Follow the documentation-first philosophy established by the project's
ADRs.

## Final Principle

Keep the bootstrap engine small, inspectable, reusable, and focused on
helping users describe and realize workstation intent.
