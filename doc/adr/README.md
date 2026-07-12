# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records for the
bootstrap engine.

The ADRs collectively describe the project's architectural philosophy,
long-term engineering decisions, and the reasoning behind those
decisions. They are intended to answer a simple question:

> **Why is the project built this way?**

Source code explains *how* the software works.

Tests explain *what* behavior is expected.

The ADRs explain *why* particular architectural decisions were made and
what alternatives were considered.

## How to Read This Collection

Although the ADRs are numbered chronologically, they are also organized
around a set of recurring themes. Readers looking for answers to a
specific question may find it easier to begin with the thematic
groupings below.

### Foundation

These ADRs establish the project's goals, philosophy, and overall
direction.

-   ADR-001 through ADR-010

Topics include:

-   project philosophy;
-   distribution;
-   build process;
-   release artifacts;
-   modular source organization.

### Execution Model

These ADRs describe how the bootstrap engine interprets user intent and
performs work.

-   ADR-011 through ADR-022

Topics include:

-   manifest interpretation;
-   parsing;
-   validation;
-   execution planning;
-   backend abstraction;
-   diagnostics.

### User Experience

These ADRs describe how users interact with the bootstrap engine.

-   ADR-023 through ADR-030

Topics include:

-   configuration;
-   command-line interface;
-   logging;
-   exit codes;
-   trust;
-   compatibility.

### Long-Term Evolution

These ADRs describe how the project should evolve over time.

-   ADR-031 through ADR-050

Topics include:

-   semantic versioning;
-   architectural evolution;
-   composition;
-   testing;
-   determinism;
-   documentation;
-   trusted computing base;
-   contributor philosophy;
-   bounded package installation and visible progress.

## Architectural Themes

Across the collection, several ideas appear repeatedly.

### Make intent explicit

The project consistently favors explicit user intent over implicit
behavior, hidden discovery, or inferred configuration.

### Prefer composition

New capabilities should compose with existing architectural concepts
rather than introducing special cases or redefining established
behavior.

### Keep concepts small

The project intentionally favors a small manifest language, a focused
engine, and narrowly scoped responsibilities.

### Treat public interfaces as contracts

Externally visible behavior evolves deliberately and conservatively.

### Optimize for understanding

The project values inspectability, documentation, diagnostics, and
predictable behavior because software that is easy to understand is
easier to trust.

## Using These ADRs

These documents are intended for several audiences.

### Users

Users can understand what guarantees the project makes and why
particular behaviors exist.

### Contributors

Contributors should consult relevant ADRs before proposing architectural
changes. New ADRs should extend the collection rather than rewriting
history.

### Writers

The ADRs intentionally describe enduring ideas rather than transient
implementation details.

They may therefore serve as source material for articles, presentations,
or long-form writing about software architecture, engineering culture,
and system design. When doing so, prefer synthesizing multiple ADRs
around a common theme rather than treating each ADR as an isolated
essay.

### Automated Tools

The collection is structured so that software can discover related ideas
through recurring themes, consistent section headings, and stable
terminology.

Consumers should treat individual ADRs as atomic architectural decisions
while using this README as a thematic index rather than a source of
additional requirements.

## Writing Future ADRs

When deciding whether something deserves an ADR, ask:

-   Does this materially affect the long-term architecture?
-   Would future contributors reasonably ask "Why was this done?"
-   Would losing this decision make the project harder to understand?

If the answer is yes, an ADR is probably appropriate.

If the decision primarily concerns implementation style, coding
conventions, repository organization, or day-to-day workflow, it is
usually better suited for contributor documentation rather than an ADR.

## Relationship to Other Documentation

The ADRs are the canonical record of architectural decisions.

Other documents---including the project README, contributor guides,
examples, and architecture overviews---should summarize, organize, and
reference these decisions rather than duplicate or replace them.

## Closing Thought

Good architecture is not merely a collection of correct technical
decisions.

It is a collection of decisions that remain understandable long after
the implementation has changed.

That is the purpose of this directory.
