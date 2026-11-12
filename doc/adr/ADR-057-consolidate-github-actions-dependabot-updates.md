# ADR-057: Consolidate Scheduled GitHub Actions Dependabot Updates

Date: 2026-11-12

## Status

Accepted

## Intent

Reduce routine GitHub Actions dependency-update PR overhead without weakening
security response, existing GitHub review authority, release-path evidence,
or the public Bootstrap behavior and distribution contracts.

## Context

Bootstrap uses one GitHub Actions Dependabot ecosystem at the repository root,
with a weekly schedule and seven-day cooldown.  The current `minor-and-patch`
group excludes major releases, creating separate major-update PRs alongside
minor/patch groups.  Across a portfolio of related repositories this can
multiply review operations.

The shared `coding_standards@v3.2.0` release introduces the consolidated
Dependabot maintenance standard.  The earlier template-bash rollout and
related-project usage provide a reviewed model for wildcard version-update
grouping.  They do not guarantee how many future PRs will be produced.

Bootstrap has existing source, packaging, release, threat-model, and build
dependency governance.  In particular, ADRs 051 through 055 preserve pinned
Bashdeps acquisition, three release representations and checksums, STRIDE-based
threat modeling, and generated ADR reference documentation.  New dependency
versions in release or publishing actions can affect those trust boundaries.

The existing Dependabot auto-merge workflow consumes
`dependabot/fetch-metadata` and excludes
`version-update:semver-major`.  A group containing a major update is
expected to remain outside the non-major automatic merge path.  CODEOWNERS
files alone do not establish required review; effective GitHub rulesets and
branch protections are independent controls.

## Decision Drivers

- Consolidate ordinary maintenance PRs when dependency updates are compatible.
- Preserve the seven-day cooldown and existing weekly maintenance cadence.
- Keep security advisories and remediation independent of scheduled grouping.
- Retain the existing major-version review boundary.
- Require targeted evidence for high-privilege CI, build, and release actions.
- Avoid suppressing new updates through restrictive open-PR limits.
- Preserve the documented public CLI, runtime, and release artifact contracts.
- Keep architecture choices inspectable and explicitly reviewable.

## Decision

The GitHub Actions ecosystem SHALL retain its existing repository-root
directory, weekly schedule, seven-day version-update cooldown, and
commit-message conventions.

One group named `actions-version-updates` SHALL use
`applies-to: version-updates` and `patterns: ["*"]`.  It SHALL NOT
restrict `update-types`, so eligible major, minor, and patch routine
updates can be grouped together.  No restrictive
`open-pull-requests-limit` is introduced.

Dependabot security updates SHALL remain outside routine grouping and SHALL
NOT be deliberately delayed by this weekly schedule or cooldown.  Effective
security-update behavior depends on separate GitHub dependency-graph,
alerting, and security-update settings, which must be verified independently.

The existing non-major-only Dependabot auto-merge gate SHALL remain unchanged.
A group with a major update is expected to require ordinary review.  Existing
GitHub required checks, CODEOWNER approval, branch protections, and workflow
permissions remain independent authorities and SHALL NOT be weakened as part
of this change.

Reviewers SHALL evaluate the highest-risk update within a group, including
actions able to access credentials, change tags, publish release artifacts,
write to the repository, or execute code from external dependencies.  A
passing test that does not exercise the changed release action is not
evidence that the release boundary remains compatible or secure.

When one dependency requires isolation, maintainers MAY use a narrowly
documented exclusion or separate group, with a rationale and a review date.
Major version alone does not require isolation, but it does require risk-based
review rather than automatic approval.

Existing open Dependabot PRs SHALL remain open until a later actual grouped
PR is observed and verified to cover their changes.  The grouping cannot
promise exactly one PR per cycle, retroactive consolidation, safe updates,
or reduced review effort in every release window.

## Threats and Residual Risk

A malicious, vulnerable, or incompatible upstream action may gain authority
over release products or repository state.  Large groups may hide the cause
of a failure, and a passing ordinary unit-test suite may not exercise the
release, provenance, or publication path.  If security-update features are
disabled, separating security updates in YAML does not enable them.

Mitigations include immutable action pins, review of the full group by
highest risk, preserving non-major auto-merge exclusions and effective
review protections, and targeted validation of affected release paths.
These measures are reductions in risk, not proof of upstream integrity.

## Alternatives Considered

### Continue minor/patch grouping and individual major PRs

Maintains narrow major review units but perpetuates repetitive maintenance
work and does not follow the shared preferred model.  Rejected as a
portfolio-wide default; explicit exceptions remain available.

### Automatically merge grouped major changes

Reduces review operations further but introduces potential breaking and
privileged updates without adequate evidence.  Rejected.

### Group vulnerability remediation with routine versions

Can delay urgent security corrections and obscure advisory priority.
Rejected in favor of independent security triggers.

### Set a low open-PR cap

May hide outstanding maintenance work and prevent newer updates while
stale PRs occupy the cap.  Deferred until measured backlog behavior
justifies an explicit threshold.

### Switch to monthly updates or combine multiple ecosystems

Changes time-to-update and merges different verification surfaces without
project-specific evidence.  Deferred as unrelated policy changes.

## Compatibility and Migration

Only the Dependabot routine version-update policy and supporting repository
documentation are altered.  This decision SHALL NOT change Bootstrap's
package-manager behavior, public CLI, manifest grammar, runtime Bash
compatibility, three release flavors, checksum conventions, verification
or publication workflow permissions, or locally accepted ADRs.

Open Dependabot PRs #53, #68, and #71 remain open unless independently
superseded by a future observed group; PR #60 is unrelated documentation.
A maintainer should inspect future grouped PRs and relevant validation
before concluding that review workload has actually decreased.

## Relationships and Expected Outcomes

ADR-056 establishes pinned shared standards adoption beneath accepted
local governance.  ADRs 051 through 055 remain authoritative for
dependency acquisition, executable distribution, checksums, threat
modeling, and reference documentation.  This ADR applies the new shared
Dependabot policy without superseding those architectural decisions.

The expected outcome is fewer routine PRs while retaining review and
security controls.  The result must be judged from actual Dependabot and
CI behavior after the configuration is merged.
