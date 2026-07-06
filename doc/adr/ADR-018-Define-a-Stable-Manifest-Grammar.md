# ADR-018: Define a Stable Manifest Grammar

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the grammar of the package
manifest language.

The manifest language is intentionally small. It exists to express
package requirements clearly rather than to become a general-purpose
programming or configuration language.

## Context

Previous ADRs establish that manifests describe user intent, are parsed
before execution, and are validated before any system modifications
occur.

Those decisions imply that the manifest language itself should be
stable, predictable, and easy to understand.

As the project grows, there may be pressure to introduce variables,
conditionals, loops, includes, templates, or other expressive features.

While each capability may appear useful in isolation, collectively they
would increase parser complexity and make manifests more difficult to
read, review, and maintain.

## Decision

The package manifest language shall remain intentionally minimal.

The initial grammar supports:

-   blank lines;
-   full-line comments beginning with `#`;
-   inline comments beginning with `#`;
-   one package requirement per logical line;
-   optional version constraints.

Whitespace surrounding package names and operators is insignificant
unless required by the package name itself.

Each logical line shall represent exactly one package requirement.

The parser shall reject malformed input rather than attempting to infer
user intent.

Future language additions shall preserve backward compatibility whenever
practical.

## Rationale

A small language is easier to learn, easier to document, and easier to
implement correctly.

Because manifests are expected to be read and maintained by humans over
many years, readability is valued more highly than expressive power.

Users should rarely need to consult documentation to understand an
existing manifest.

This decision also reinforces the project's conservative execution model
by making ambiguous input difficult to express.

## Alternatives Considered

### Build a Feature-Rich Configuration Language

The project could support variables, conditionals, expressions,
includes, templating, and other advanced language constructs.

This was rejected because it shifts the project away from describing
package requirements and toward becoming a configuration language.

### Use Native Shell Syntax

The project could interpret manifests as Bash.

This was rejected because executable configuration obscures intent,
complicates validation, and substantially increases security and
maintenance concerns.

## Consequences

The parser remains comparatively small.

Documentation remains approachable.

Validation can provide precise diagnostics because the language is
narrowly defined.

Future capabilities should generally be introduced through new files or
higher levels of abstraction rather than increasing the complexity of
the manifest language itself.

## Non-Goals

This ADR does not define the exact syntax of version constraints.

It does not define profile composition, variables, or include semantics.

Those capabilities, if adopted, should be specified separately rather
than expanding the core grammar incrementally.

## Future Considerations

Future versions may introduce higher-level concepts such as workstation
profiles or manifest composition.

Those features should reference multiple manifests or multiple sources
of intent rather than making individual manifests substantially more
expressive.

## Summary

The package manifest language is intentionally small.

It should remain stable, human-readable, and focused on expressing
package requirements rather than evolving into a general-purpose
configuration or programming language.
