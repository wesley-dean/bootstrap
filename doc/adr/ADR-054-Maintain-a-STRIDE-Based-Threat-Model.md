# ADR-054: Maintain a STRIDE-Based Threat Model

Date: 2026-08-30

## Status

Proposed

## Intent and Documentation Posture

This ADR establishes a repository-level threat-modeling practice for Bootstrap.
The project SHALL maintain a current threat model at `doc/threat_model.md` and
SHALL use STRIDE as the primary structured method for enumerating threats.

The threat model is intended to make security reasoning inspectable.  It should
identify what the project protects, where trust changes, what can go wrong, what
controls the project provides, what responsibilities remain with users or
operators, and what residual risks remain after those controls are considered.

This decision deliberately separates several kinds of security documentation.
ADRs preserve why architectural choices were made.  The threat model describes
the current security model and the threats relevant to it.  Tests and other
validation provide evidence for specific controls.  `SECURITY.md` describes how
security concerns should be reported.

The structure defined here is intentionally portable.  Related tools and
libraries may adopt the same structure in their own repositories while replacing
Bootstrap-specific assets, actors, boundaries, assumptions, threats, and
controls with those appropriate to each project.

## Context

Bootstrap is a small Bash program with a comparatively large potential blast
radius.  It consumes user-controlled configuration and package manifests,
interacts with native package-management facilities, may cross from an ordinary
user context into elevated privilege through `sudo` or `doas`, and ultimately
causes system software to be installed.

The repository already contains security-relevant architectural decisions and
controls.  Examples include conservative failure behavior, parsing configuration
and manifests as data rather than executable shell, preflighting complete input
before mutation, separating planning from execution, delegating package trust to
native package managers, minimizing the trusted computing base, pinning and
verifying build dependencies, publishing checksum companions, and providing
release provenance attestations.

Those properties are currently documented where each decision is made.  That is
appropriate for architectural history, but it makes a different question harder
to answer:

> Given the system as it exists now, what are its meaningful attack surfaces,
> trust boundaries, threats, mitigations, assumptions, and residual risks?

A security reviewer should not need to reconstruct the current threat model from
source code, ADRs, tests, CI workflows, release documentation, and tribal
knowledge.  Contributors should also have a durable place to determine whether a
new feature introduces a new trust boundary, changes an existing one, or
invalidates an earlier security assumption.

Threat modeling is an analytical aid rather than a security guarantee.  A threat
model can be incomplete, assumptions can become invalid, and new attacks can
appear after the document is written.  The model therefore needs to state its
scope and uncertainty explicitly and remain maintainable as the project evolves.

## Decision Drivers

- Make the project's security assumptions and trust boundaries visible.
- Identify attack surfaces systematically rather than relying on memory or
  intuition alone.
- Use a widely understood threat taxonomy that is lightweight enough for small
  command-line tools and libraries.
- Keep the security model in reviewable, version-controlled Markdown alongside
  the source it describes.
- Distinguish controls implemented by the project from precautions and controls
  expected of users or operators.
- Record residual and accepted risk rather than implying that every identified
  threat has been eliminated.
- Connect important mitigations to evidence such as tests, static analysis,
  build controls, release verification, or architectural constraints.
- Keep threat modeling useful to humans and AI-assisted contributors without
  requiring proprietary tooling or opaque model formats.
- Make the practice reusable across related repositories without forcing every
  project to have the same assets, threats, or architecture.
- Avoid process weight that would discourage the threat model from being kept
  current.

## Decision

### Maintain a canonical repository threat model

Bootstrap SHALL maintain its current threat model in:

```text
doc/threat_model.md
```

The threat model SHALL be maintained as source documentation and reviewed through
the same repository change process as other consequential documentation.

The threat model SHALL describe the current system.  Historical reasoning belongs
in ADRs and Git history.  When architecture changes, the threat model should be
updated to reflect the resulting current security posture rather than retaining
obsolete threats or boundaries solely for historical completeness.

The document SHALL identify the date on which the threat model was last reviewed.
Changing that date means that the model itself was reviewed against the current
architecture; unrelated documentation edits SHALL NOT refresh the review date.

### Use STRIDE for structured threat enumeration

Threat identification SHALL use STRIDE as the primary structured enumeration
method:

- **S - Spoofing:** pretending to be another actor, component, artifact, or
  authority.
- **T - Tampering:** unauthorized modification of input, configuration, state,
  code, dependencies, artifacts, or communications.
- **R - Repudiation:** consequential actions that cannot be attributed,
  reconstructed, or adequately evidenced when attribution matters to the
  project's security model.
- **I - Information Disclosure:** unintended exposure of secrets, private data,
  sensitive paths, credentials, configuration, or other protected information.
- **D - Denial of Service:** exhausting resources, blocking progress, causing
  unreasonable delay, or making the tool or affected system unavailable.
- **E - Elevation of Privilege:** obtaining or exercising authority beyond what
  an actor, input, or component should possess.

STRIDE SHALL be used as an enumeration aid rather than as the document's primary
organization.  The threat model should remain organized around the system,
attack surfaces, components, trust boundaries, and security objectives so a
reader can understand where each threat exists.

A threat MAY carry more than one STRIDE classification.  Contributors SHALL NOT
force a realistic threat into only one category when multiple classifications are
meaningful.

STRIDE is not assumed to be exhaustive.  The threat model SHOULD supplement the
taxonomy with project-specific abuse cases, misuse cases, dependency or supply
chain scenarios, and other adversarial analysis when those reveal risks that a
mechanical STRIDE pass would miss.

### Document a minimum common structure

`doc/threat_model.md` SHALL contain, at minimum, the following concepts.  Exact
heading names may vary when necessary for readability, but the information itself
should remain identifiable.

#### Purpose, scope, and exclusions

The document SHALL explain what is being modeled, what execution or deployment
contexts are covered, and what is explicitly outside the model.

Scope exclusions SHALL be stated narrowly enough that they do not silently remove
important threats.  For example, an attacker who already has unrestricted root
control of the host may reasonably be outside Bootstrap's model, while hostile
manifest input supplied to an otherwise uncompromised invocation remains within
scope.

#### Security objectives

The model SHALL identify the security properties the project is attempting to
preserve.  Depending on the project, these may include host integrity, user data
integrity, confidentiality, predictable execution, least privilege, build and
release integrity, provenance, and availability.

#### Assets

The model SHALL identify assets whose compromise would matter.  Assets are not
limited to stored secrets.  They may include host integrity, user files,
credentials available to the process, configuration, package-manager authority,
build inputs, release artifacts, source provenance, and service availability.

#### Actors and external systems

The model SHALL identify relevant actors and external systems, including trusted,
partially trusted, and untrusted participants where those distinctions matter.

Examples may include ordinary users, privileged users, contributors, CI systems,
native package managers, package repositories, dependency publishers, malicious
local users, and remote attackers.

#### Trust assumptions and trust boundaries

The model SHALL state important assumptions about components or authorities the
project relies upon.  It SHALL identify locations where data, control, privilege,
or responsibility crosses a meaningful trust boundary.

Assumptions SHOULD be concrete and reviewable.  Statements such as "the
operating-system kernel is trusted" or "native package-manager repository and
package-authenticity policy is delegated to the configured package manager" are
more useful than an undefined assumption that "the environment is secure."

#### System and trust-boundary diagram

When a diagram materially improves understanding, the threat model SHOULD include
a Mermaid diagram showing important actors, components, data or control flows,
and trust or privilege boundaries.

Mermaid is preferred because the diagram remains plain text, reviewable in diffs,
and renderable by common Markdown tooling.  Subgraphs or equivalent grouping
SHOULD identify trust zones, while edges SHOULD identify significant data,
control, or privilege transitions where practical.

A diagram is not mandatory when a project has no meaningful runtime interaction
or when a diagram would add no information beyond the textual model.  If omitted
for a non-trivial project, the threat model SHOULD briefly explain why.

The diagram SHALL NOT contain credentials, secrets, private identifiers, or other
sensitive information merely to make the model more concrete.

#### Attack surfaces

The model SHALL enumerate meaningful attack surfaces.  Depending on the project,
these may include command-line arguments, standard input, configuration files,
environment variables, filesystem paths, external commands, network access,
runtime dependencies, build dependencies, CI workflows, release automation, and
published artifacts.

Attack surfaces SHOULD be described in terms of the authority and data they can
influence rather than as a list of filenames alone.

#### Threat register

The model SHALL maintain a threat register with stable identifiers using the form:

```text
TM-NNN
```

Identifiers SHALL remain stable while a threat remains materially the same.
Deleted or retired threat identifiers SHOULD NOT be reused for unrelated threats.

Each threat entry SHALL identify, at minimum:

- the relevant attack surface, component, or trust boundary;
- one or more STRIDE classifications;
- the threat scenario;
- the expected impact;
- project-provided mitigations or controls;
- user or operator mitigations or responsibilities when applicable; and
- the residual or accepted risk after those controls.

A tabular representation is preferred when it remains readable.  Longer threats
MAY use dedicated subsections when the reasoning cannot be represented clearly in
a table.

#### Abuse and misuse cases

The model SHOULD record concrete adversarial stories when they improve the
analysis.  These cases are especially useful where several components or STRIDE
categories combine into a realistic attack path.

The purpose is to ask how the system might be intentionally used against its
security objectives, not only how an individual component might fail in
isolation.

#### Residual and accepted risk

The model SHALL make unresolved or transferred risk visible.

The default vocabulary SHOULD favor meaningful qualitative states such as:

- mitigated;
- partially mitigated;
- accepted;
- transferred to a trusted dependency or platform control;
- user or operator responsibility; or
- not applicable.

The project SHALL NOT imply that delegating a responsibility eliminates the
underlying risk.  For example, Bootstrap may delegate package authenticity and
repository trust enforcement to a native package manager while still documenting
compromise of the configured package source as a residual ecosystem risk.

Numeric risk scoring is not required.  A project MAY adopt a defined scoring
method when a specific use case requires it, but arbitrary fine-grained scores
SHALL NOT be used merely to create an appearance of precision.

#### Validation and evidence

Where practical, the threat model SHOULD identify evidence supporting important
controls.  Evidence may include automated tests, regression tests, static
analysis, linter configuration, dependency verification, checksum verification,
provenance attestations, CI restrictions, code review requirements, or related
ADRs.

The existence of a test or scanner SHALL NOT be presented as proof that a threat
is impossible.  Evidence describes the control and its verification boundary.

#### Review triggers

The threat model SHALL identify changes that require the model to be reviewed.
The common review triggers established by this ADR apply unless a project has a
stricter repository-local policy.

### Separate project controls from user and operator responsibilities

Threat entries SHALL distinguish controls that the project implements from
controls or precautions expected of users and operators.

This distinction is particularly important for open-source tooling.  A project
may control how it validates input, invokes external commands, verifies build
dependencies, constructs releases, or limits privilege.  It may not control the
trustworthiness of repositories a user configures, permissions on files the user
creates, the security of the host operating system, or whether the user verifies
a downloaded artifact before execution.

When responsibility is shared, the threat model SHOULD state the boundary rather
than assigning the entire threat to either party.

### Preserve distinct documentation responsibilities

The repository SHALL preserve the following separation of concerns:

- **ADRs** explain why consequential security and architectural decisions were
  made, including alternatives and consequences.
- **`doc/threat_model.md`** describes the current threat landscape, trust model,
  controls, user responsibilities, and residual risk.
- **Tests and validation artifacts** provide executable or inspectable evidence
  that particular controls behave as intended.
- **`SECURITY.md`** describes how security vulnerabilities or concerns should be
  reported and coordinated.

These documents SHOULD cross-reference one another where doing so reduces
ambiguity, but they SHOULD NOT duplicate large sections of one another.

### Review the threat model when security-relevant boundaries change

The threat model SHALL be reviewed when a change materially affects the current
security model.  Review triggers include, but are not limited to:

- adding a new source of input or configuration;
- changing how input is parsed, interpreted, or executed;
- adding or changing a privilege boundary;
- adding network access or changing an existing network trust relationship;
- adding a runtime, build, development, or release dependency with meaningful
  security impact;
- changing external command execution;
- adding authentication, authorization, credential, secret, or sensitive-data
  handling;
- changing filesystem write scope or persistent state;
- changing build, release, checksum, signing, attestation, or provenance
  behavior;
- adding a supported execution environment whose trust assumptions differ from
  existing environments;
- discovering a vulnerability or security incident that invalidates an existing
  assumption or demonstrates a missing threat; or
- adopting an architectural decision that changes an asset, actor, attack
  surface, trust boundary, or security objective.

A code or documentation change that does not affect the security model does not
require a synthetic threat-model edit merely to create churn.

### Treat the threat model as reviewable analysis, not a warranty

The threat model SHALL avoid claims of completeness, absolute security, or
elimination of all risk.

Controls SHALL be described according to what they actually establish.  For
example, verifying that downloaded bytes match a published checksum establishes
byte identity with that checksum; it does not establish that the corresponding
source or artifact is free from malicious behavior or defects.

Security claims should remain consistent with ADR-000's requirements for
capability scope and epistemic honesty.

### Keep the convention portable across related repositories

The threat-model structure in this ADR is deliberately project-neutral except
where Bootstrap-specific examples are necessary to explain the decision.

Related repositories MAY adopt the same convention, including:

- `doc/threat_model.md` as the canonical location;
- STRIDE classifications;
- stable `TM-NNN` identifiers;
- separation of project and user/operator controls;
- explicit residual risk;
- Mermaid trust-boundary diagrams when useful; and
- security-relevant review triggers.

Each repository remains responsible for its own scope, assets, assumptions,
threats, controls, and residual risks.  Copying Bootstrap's threat entries into a
different tool without re-performing the analysis would defeat the purpose of the
practice.

## Considered Alternatives

### Keep security reasoning distributed across ADRs and implementation docs

The project could continue documenting each security-relevant decision only where
it originates.

This preserves local context, but it requires reviewers to reconstruct the
current security model from many documents and implementation details.  ADRs will
continue to preserve rationale, while the threat model provides the current
cross-cutting view.

### Organize the entire document by the six STRIDE categories

The threat model could use Spoofing, Tampering, Repudiation, Information
Disclosure, Denial of Service, and Elevation of Privilege as its six primary
sections.

This makes taxonomy coverage obvious, but it scatters threats affecting the same
surface or boundary across the document and can encourage mechanical checklist
thinking.  STRIDE is therefore retained as the enumeration and classification
method while the model remains system-oriented.

### Require one STRIDE category per threat

A strict one-category rule would simplify tables and reporting.

Real attacks frequently cross category boundaries.  Release substitution, for
example, may involve both spoofing and tampering, while command injection across
a privilege boundary may involve tampering and elevation of privilege.  Multiple
classifications are therefore allowed.

### Adopt a heavyweight formal threat-modeling methodology

The project could mandate a more elaborate framework with formal process stages,
risk scoring, specialized tooling, or extensive generated artifacts.

Such approaches can be valuable for larger systems or regulated environments,
but the additional process weight would be disproportionate for small Bash tools
and libraries and could make models less likely to remain current.  This ADR
selects a lightweight practice that can be expanded when a project's risk or
compliance context requires it.

### Require a Mermaid diagram for every repository

A mandatory diagram would make the document format more uniform.

Some libraries have no useful runtime or privilege boundary to draw.  Requiring a
diagram in those cases would reward ceremony rather than understanding.  Mermaid
is preferred when visualization clarifies the model, and omission remains
acceptable when it does not.

### Put the threat model in `SECURITY.md`

Combining vulnerability-reporting instructions and architectural threat analysis
would reduce the number of files.

The documents serve different audiences and change at different rates.  A stable
security reporting policy should not become a long threat register, and a living
threat model should not obscure vulnerability reporting instructions.  They
remain separate and may reference each other.

### Use numeric risk scores for every threat

A mandatory numeric scheme could make threats appear easier to sort or compare.

Architectural threat scenarios often lack the empirical precision needed to
justify fine-grained scores.  False precision can obscure assumptions rather than
clarify them.  Qualitative residual-risk descriptions are the default, with
formal scoring available when a project has a defined need and methodology.

### Generate the threat model entirely from tooling

Automated discovery can assist with dependency analysis, data-flow extraction,
static analysis, or inventory generation.

A threat model also contains architectural assumptions, trust judgments, user
responsibilities, abuse cases, and accepted risks that cannot be inferred
reliably from source alone.  Tooling may provide evidence or suggestions, but the
maintained Markdown document remains the reviewed source of truth for the threat
model.

## Consequences

Bootstrap gains a single current document that explains its security model across
runtime, privilege, dependency, build, release, and user-responsibility
boundaries.

Security reviews become easier to repeat because threats receive stable IDs and
because project controls, user controls, assumptions, and residual risks are
recorded explicitly.

Future architecture work gains an additional review question: does this change an
asset, actor, attack surface, trust boundary, assumption, control, or residual
risk?  When it does, the threat model becomes part of the documentation-first
change.

The project accepts additional documentation maintenance.  A stale threat model
can provide worse assurance than an explicit statement that no model exists, so
review triggers and the last-reviewed date become meaningful maintenance
obligations rather than decorative metadata.

STRIDE provides structure without guaranteeing completeness.  Contributors still
need adversarial reasoning, project knowledge, and review of supply-chain,
operational, and abuse scenarios that do not emerge cleanly from the taxonomy.

The practice is reusable across related repositories, but each repository must
perform its own analysis.  Similar document structure should improve familiarity
without creating a false assumption that different tools have identical threat
models.

## Open Questions and Follow-Ups

- Draft Bootstrap's initial `doc/threat_model.md` using this ADR as the governing
  structure.
- Decide whether a reusable threat-model template should eventually be maintained
  in a shared repository or copied deliberately into each project.
- Evaluate whether contributor guidance or pull-request review checklists should
  explicitly call out the threat-model review triggers.
- Evaluate whether lightweight CI checks should eventually verify only structural
  invariants, such as the presence of the threat-model file, without pretending
  that automation can validate the correctness or completeness of the analysis.
- Apply the convention to related repositories through repository-local decisions
  or equivalent adopted policy, preserving project-specific threat analysis in
  each repository.

## Related Decisions

- Related to: ADR-000 (capability scope and epistemic honesty)
- Related to: ADR-007 (inspectable and reviewable execution)
- Related to: ADR-013 (conservative failure and surprising system changes)
- Related to: ADR-027 (trust through inspectability)
- Related to: ADR-029 (reproducible and verifiable releases)
- Related to: ADR-036 (explicit architectural decisions)
- Related to: ADR-039 (observable-behavior testing)
- Related to: ADR-041 (documentation as part of the product)
- Related to: ADR-042 (minimize the trusted computing base)
- Related to: ADR-046 (documentation-driven, test-second development)
- Related to: ADR-051 (build dependency trust)
- Related to: ADR-052 (release artifact construction and publication)
- Related to: ADR-053 (checksum companion naming and historical compatibility)
