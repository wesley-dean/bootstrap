# ADR-055: Publish Ephemeral ADR Navigation as the Reference Landing Page

Date: 2026-09-09

## Status

Accepted

## Context

Bootstrap publishes generated Doxygen reference documentation through GitHub
Pages.  The existing Doxygen configuration documents maintained Bash source, but
the generated site does not provide the richer Architecture Decision Record
navigation that has become useful in related projects.

The repository already has a substantial ADR corpus and a hand-maintained
`doc/adr/README.md`.  That README contains useful thematic and explanatory prose,
but maintaining a complete linked ADR list by hand creates a synchronization
obligation whenever a decision is added or renamed.  Committing a generated copy
would move the same problem into a different form: contributors and CI would have
to keep generated Markdown synchronized with its source inputs.

The `adrctl` project provides a released `generate toc` capability that can derive
a linked ADR list from the current corpus.  Related repositories have adopted a
model in which maintained framing remains in `README.intro.md` and
`README.outro.md`, while the complete `README.md` consumed by Doxygen is generated
only for the documentation build and remains ignored repository state.

Bootstrap already has a governing dependency boundary in ADR-051.  Make directly
bootstraps only the pinned `bashdeps.bash` release, and ordinary external build or
development artifacts are declared in `dependencies.txt`, synchronized by
`make deps`, and verified offline by `make deps-check`.  Documentation generation
consumes prepared dependency state and must not silently acquire or repair it.

Bootstrap also maintains a STRIDE threat model under ADR-054.  That document
contains maintained Mermaid trust-boundary diagrams.  The documentation landing
page work must not remove, rewrite, duplicate, or implicitly reinterpret those
diagrams, nor should it broaden the Doxygen corpus in a way that turns Mermaid
source into broken reference output under Doxygen versions that do not natively
render it.

## Decision Drivers

- Preserve the useful human-authored explanatory material in the existing ADR
  README.
- Provide a complete linked ADR index without requiring contributors to maintain
  the list manually.
- Make the generated ADR page the useful landing page for published Doxygen
  reference documentation.
- Avoid committing a reproducible generated Markdown derivative merely to support
  Pages publication.
- Preserve ADR-051's single manifest-driven dependency boundary rather than add a
  second acquisition mechanism for documentation tooling.
- Preserve the explicit network boundary between dependency preparation and
  documentation generation.
- Generate the intermediate Markdown atomically so interruption cannot publish a
  partially assembled landing page.
- Keep generated documentation state disposable and clearly owned.
- Preserve the current STRIDE threat model and its Mermaid diagrams exactly as
  maintained security documentation.
- Avoid reintroducing automatically generated ADR relationship graphs into
  routine documentation.
- Keep Bootstrap's runtime and release-artifact dependency boundaries unchanged.

## Decision

### Maintain ADR landing-page framing as source

The repository SHALL maintain these source files:

```text
doc/adr/README.intro.md
doc/adr/README.outro.md
```

`README.intro.md` SHALL contain the maintained introduction and contextual framing
that should appear before the generated ADR list.  `README.outro.md` SHALL contain
maintained material that should follow the generated list, including thematic and
usage guidance.

The ADR files under `doc/adr/` remain the authoritative source records.  The
framing files organize those records for readers but do not supersede or replace
an ADR.

### Generate README.md as ephemeral documentation input

The complete documentation landing page SHALL be generated at:

```text
doc/adr/README.md
```

The generated file SHALL NOT be committed.  `doc/adr/.gitignore` SHALL identify
`README.md` as generated state.

The generated page SHALL be assembled from:

1. maintained `README.intro.md` content;
2. a linked ADR list generated from the current ADR corpus by `adrctl generate
   toc`; and
3. maintained `README.outro.md` content.

The generated page is an intermediate documentation artifact.  It is not a new
source of architectural requirements and SHALL NOT be edited manually.

### Use the released adrctl artifact through ADR-051

The repository SHALL use a pinned released `adrctl.bash` artifact for ADR index
generation.

Because `adrctl` is an ordinary externally acquired development/documentation
artifact that fits the bashdeps contract, it SHALL be declared in the existing:

```text
dependencies.txt
```

The repository SHALL NOT introduce a direct `curl` or `wget` acquisition path for
`adrctl`, and SHALL NOT create a second documentation-specific dependency manifest
for this capability while ADR-051 establishes `dependencies.txt` as the source of
truth for ordinary external build and development artifacts.

The committed dependency record SHALL use an immutable release URL and an
authoritative SHA-256 digest.  Bashdeps remains responsible for synchronizing and
verifying the declared destination.

At adoption, the documentation dependency is:

```text
wesley-dean/adrctl@0.0.14 -> vendor/adrctl.bash
```

The `adrctl` artifact is documentation tooling only.  It SHALL NOT become an input
to Bootstrap runtime behavior or to the construction of any released
`bootstrap*.bash` consumer artifact.

### Add an offline adr-index Make target

The Makefile SHALL provide:

```text
make adr-index
```

`make adr-index` SHALL consume already-prepared `vendor/adrctl.bash` state.  It
SHALL NOT invoke `make deps`, bootstrap bashdeps, synchronize dependencies, or
otherwise acquire or repair dependency state.

When the required `adrctl` artifact is absent, `make adr-index` SHALL fail with
actionable guidance to prepare dependency state through the existing explicit
`make deps` or `make all` path.

The target SHALL validate that its maintained introduction and conclusion files
are present before publishing the generated page.

### Generate the intermediate atomically

ADR page generation SHALL write to a temporary candidate adjacent to the final
`doc/adr/README.md` destination and move that candidate into place only after the
complete page has been assembled successfully.

The target SHALL remove an incomplete candidate on failure.  A failed generation
must not replace a previously complete generated page with partial output.

The composition SHALL preserve a Markdown section boundary between the generated
ADR list and `README.outro.md`.  The implementation SHALL explicitly provide the
required blank line rather than depend on incidental newline behavior in an
upstream tool version.

### Make docs own the complete generated reference path

`make docs` SHALL remain the canonical reference-documentation target.  It SHALL:

1. require already-prepared Doxygen-filter and `adrctl` dependency state;
2. remove prior generated reference and ADR-index output;
3. generate the current ADR landing page through the project-owned `adr-index`
   target;
4. apply the executable mode required by the Doxygen filter consumer;
5. invoke Doxygen; and
6. leave both the generated Markdown landing page and generated HTML as ignored,
   disposable state.

`make docs` SHALL NOT acquire or repair dependency state.  The existing workflow
in which CI or a contributor explicitly runs `make deps` and `make deps-check`
before documentation generation remains in force.

`make docs-clean` SHALL remove both the generated Doxygen output and the generated
ADR landing page.  `make distclean` SHALL therefore continue to remove all
reference-documentation state transitively.

### Use the generated ADR page as the Doxygen main page

The Doxygen configuration SHALL include maintained Bash source and the ADR corpus.
It SHALL recognize Markdown files in the ADR corpus and SHALL use:

```text
doc/adr/README.md
```

as `USE_MDFILE_AS_MAINPAGE`.

The maintained framing fragments SHALL be excluded as separate Doxygen pages so
readers see the assembled landing page rather than duplicate introduction and
conclusion pages.  ADR templates and other workflow-support material that are not
part of the published ADR corpus MAY likewise remain excluded.

This decision does not require Doxygen to ingest the entire `doc/` tree.
Bootstrap's broader maintained documentation has distinct rendering and content
requirements, including Mermaid diagrams in the current STRIDE threat model.
Keeping the Doxygen expansion scoped to `doc/adr/` avoids turning this landing-page
change into a migration of unrelated documentation formats.

### Preserve the STRIDE threat model and Mermaid diagrams

ADR-054 remains authoritative for `doc/threat_model.md` and its system/trust
boundary diagrams.

This decision SHALL NOT remove, replace, generate, or transform those Mermaid
diagrams.  The threat model remains maintained Markdown outside the Doxygen input
expansion introduced here.

Adding the executable `adrctl` documentation dependency is a security-relevant
review trigger under ADR-054.  That review was performed as part of this decision.
The existing threat model already defines the build-dependency publisher as the
named current tools plus future external build/development dependencies, defines
AS-011 over `bashdeps` and all dependencies declared in `dependencies.txt`, and
defines TM-016 as build-dependency substitution in transit or cache.

The reviewed `adrctl` dependency therefore falls within the existing actor,
attack-surface, trust-assumption, and TM-016 boundaries.  It does not add runtime
authority, a release-artifact input, a new network path, or a new dependency
acquisition mechanism.  In keeping with ADR-054's direction to avoid synthetic
threat-model churn when the security model is unchanged, this review does not
require an edit to `doc/threat_model.md` or a new threat identifier.

### Do not generate an ADR relationship graph

Routine documentation generation SHALL produce the linked textual ADR list only.
It SHALL NOT automatically invoke `adrctl generate graph` or otherwise compose an
ADR relationship diagram into the Doxygen landing page.

This does not remove or constrain `adrctl`'s explicit graph-generation capability.
A contributor may invoke that tool intentionally when a graph is useful for a
specific analysis.  The distinction is between an explicit tool capability and a
routine publication requirement.

### Validate the generated ownership boundary in CI

Continuous integration and Pages publication SHALL validate the generated
reference path after preparing dependencies explicitly.

Validation SHOULD establish at least that:

- `doc/adr/README.md` was generated;
- the generated page contains the current highest-numbered ADR;
- the generated page is ignored by Git;
- `doc/reference/index.html` was generated;
- generated reference output is ignored by Git;
- dependency verification still succeeds after documentation generation; and
- the tracked working tree remains clean.

These checks protect the ownership boundary directly: maintained files are
tracked source, while the generated Markdown and HTML are reproducible build
state.

## Security and Trust Implications

`adrctl.bash` is executable development tooling.  A malicious or incorrectly
approved version could execute with the authority of a developer or CI runner and
could influence generated documentation.

ADR-051's existing controls apply: immutable release identity, committed SHA-256
digest, bashdeps synchronization, offline verification, reviewed dependency
changes, and explicit acquisition targets.  The new dependency does not broaden
the Bootstrap runtime trusted computing base and is not incorporated into release
consumer artifacts.

The published documentation should not be treated as an independent trust root.
The maintained repository source, ADR corpus, dependency declarations, and CI
history remain inspectable inputs from which that documentation is generated.

## Considered Alternatives

### Continue maintaining doc/adr/README.md by hand

The existing README is useful and could remain entirely hand-maintained.  This
would avoid a new documentation dependency, but it would retain a recurring
synchronization obligation for the ADR list and would not reuse the linked TOC
capability already standardized in related repositories.

The maintained prose is therefore preserved while the mechanical list is
generated.

### Generate README.md and commit it

The repository could commit the generated page after every ADR change and have CI
verify that regeneration produces no diff.

This would make the linked index visible when browsing `doc/adr/` on GitHub without
running a build, but it creates a second representation that must remain
synchronized with the ADR corpus and framing inputs.  The published Pages site is
the primary reason for the generated composite, so the synchronization cost is
not justified here.

### Generate a documentation landing page outside doc/adr

The build could write an intermediate such as `build/docs/adr-index.md` and point
Doxygen there.

That approach gives generated input a physically separate directory, but
Bootstrap already has a meaningful ADR-directory README convention and existing
relative links are easiest to preserve when the generated page lives beside the
ADRs.  A nested `.gitignore` makes its generated ownership explicit without
changing the broader ignore file.

### Download adrctl directly from Make or GitHub Actions

A dedicated download step would be mechanically small, but it would contradict
ADR-051 by creating another acquisition and integrity-verification path for an
ordinary external development artifact.

The existing bashdeps manifest is the governed mechanism.

### Create dependencies-docs.txt

Related repositories use a documentation-specific manifest where their governing
ADRs establish that model.  Bootstrap's ADR-051 instead establishes
`dependencies.txt` as the source of truth for ordinary external build and
development artifacts.  Introducing a second manifest solely for `adrctl` would
weaken that repository-specific boundary without providing a compensating
benefit.

### Ingest the complete doc tree into Doxygen

Including all Markdown under `doc/` would make more narrative documentation
visible inside the Doxygen site.

This was rejected for this change because the broader documentation set has
independent rendering requirements.  In particular, the STRIDE threat model
contains maintained Mermaid diagrams that are intentionally governed by ADR-054.
A landing-page change should not silently become a Mermaid rendering migration or
publish fenced diagram source as degraded reference content.

A future decision may broaden the Doxygen corpus after evaluating those formats
explicitly.

### Generate an ADR relationship graph as part of the landing page

`adrctl` can generate a relationship graph, so the build could publish one beside
the textual index.

Routine relationship-graph publication has not provided enough value in related
projects to justify its renderer and integration costs.  The linked textual list
provides the navigation required here without introducing Mermaid, Graphviz, or
other graph-rendering behavior into the ADR landing-page contract.

### Use the root README as the Doxygen main page

The root README remains the best repository and user-facing overview.  The Pages
site, however, exists primarily as generated reference documentation, and the ADR
collection provides richer durable context for contributors navigating that
reference material.

Using the assembled ADR page as the reference landing page preserves the root
README's separate repository role.

## Consequences

The repository gains one pinned documentation-only executable dependency in its
existing dependency manifest.

Contributors preparing documentation locally must have synchronized dependency
state before running `make adr-index` or `make docs`.  This is consistent with the
existing Doxygen-filter requirement and does not introduce hidden network access.

The hand-maintained ADR README becomes two maintained framing files plus an
ignored generated composite.  Browsing `doc/adr/` directly on GitHub will no
longer show a tracked `README.md`; the richer composite is produced for local and
published reference documentation instead.

The published Doxygen root will provide thematic ADR context and a current linked
ADR list before readers move into source reference pages.

The reference build gains a deterministic intermediate generation step, while CI
loses the need to police synchronization of a committed generated Markdown file.

The existing STRIDE threat model, its Mermaid diagrams, runtime behavior, build
artifact formats, release process, and explicit `adrctl generate graph` capability
remain unchanged.

## Expected Outcomes

- Published Bootstrap reference documentation has a useful ADR-oriented landing
  page.
- Every current ADR appears in the linked list without hand-maintained TOC drift.
- New ADRs naturally enter the generated landing page when documentation is
  rebuilt.
- Generated Markdown and generated HTML remain clearly disposable state.
- Documentation generation remains reproducible from maintained source plus
  pinned dependency declarations.
- Bootstrap preserves one governed external-development-dependency mechanism.
- Threat-model Mermaid content is preserved without requiring Doxygen Mermaid
  support.

## Related Decisions

- ADR-012 defines Make as the canonical development and CI orchestration surface.
- ADR-036 requires consequential architectural decisions to be recorded rather
  than reconstructed from implementation history.
- ADR-041 treats documentation as part of the product surface.
- ADR-042 requires dependencies to justify their trust and maintenance cost.
- ADR-045 governs documentation-first and non-destructive documentation work.
- ADR-051 governs external build and development dependency acquisition,
  verification, generated vendor state, and target network boundaries.
- ADR-054 governs the current STRIDE threat model, Mermaid trust-boundary
  diagrams, and security-relevant review triggers.
