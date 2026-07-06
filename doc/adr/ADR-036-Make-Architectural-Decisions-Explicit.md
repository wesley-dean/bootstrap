# ADR-036: Make Architectural Decisions Explicit

Date: 2026-07-04

## Status

Proposed

## Intent and Scope

This Architecture Decision Record establishes the project's philosophy
for recording significant architectural decisions.

Decisions that materially influence the project's long-term structure,
behavior, or evolution should be documented explicitly rather than
relying on tribal knowledge or commit history.

## Context

The bootstrap engine intentionally emphasizes documentation-first
development.

As the project grows, contributors will inevitably ask why particular
design choices were made.

Source code explains how the software works.

Tests explain expected behavior.

Neither reliably explains why one architectural approach was chosen over
another.

Without explicit records, architectural intent is easily lost as
contributors change and memories fade.

## Decision

The project shall document significant architectural decisions using
Architecture Decision Records (ADRs).

An ADR should describe:

-   the problem or decision being addressed;
-   the surrounding context;
-   the selected approach;
-   the rationale for that approach;
-   reasonable alternatives that were considered;
-   the consequences of the decision.

Architectural changes that materially affect public interfaces,
execution behavior, project philosophy, or long-term maintainability
should normally be accompanied by a new ADR.

Existing ADRs should not be rewritten to reflect later decisions.
Instead, subsequent ADRs should supersede or refine earlier ones while
preserving the historical record.

## Rationale

Architecture is easier to preserve than to reconstruct.

Documenting decisions at the time they are made reduces future
uncertainty, improves onboarding, and provides reviewers with the
context needed to evaluate new proposals.

The ADR collection becomes a durable engineering asset that explains not
only what the project is, but why it became that way.

## Alternatives Considered

### Rely on Git History

Commit messages and pull requests could serve as the project's
architectural history.

This was rejected because implementation history rarely captures the
broader engineering tradeoffs that motivated a decision.

### Document Only Major Releases

The project could summarize architectural evolution in release notes.

This was rejected because release notes describe changes, not the
reasoning behind them.

## Consequences

Contributors should consult existing ADRs before proposing significant
architectural changes.

Architectural discussions become easier because proposals can reference
established principles rather than re-litigating earlier decisions.

The ADR collection becomes an important part of the project's
documentation.

## Non-Goals

This ADR does not require every implementation detail to receive its own
ADR.

It does not prevent architectural decisions from evolving over time.

It does require that significant changes be documented explicitly.

## Future Considerations

As the project matures, the ADR collection may be supplemented by
architecture overviews, contributor guides, and design documentation.

Those documents should summarize and organize architectural knowledge
rather than replace the ADRs themselves.

## Summary

Important architectural decisions should be documented deliberately.

An ADR records not only what was decided, but why, providing future
contributors with the context needed to understand, evaluate, and evolve
the project responsibly.
