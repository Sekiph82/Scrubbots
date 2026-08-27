---
coordinationSchema: scrubbots-coordination/v1
artifactType: chatgpt-prompt
cycleId: <MXX-CNNN>
version: 1
createdAt: <ISO-8601>
actor: CHATGPT
status: ISSUED
milestone: <MXX>
taskRefs: []
baselineCommit: <sha>
---

# SCRUBBOTS - ChatGPT Prompt

## Objective

State exactly what Claude must accomplish in this cycle.

## Repository baseline

- Repository: https://github.com/Sekiph82/Scrubbots
- Branch: `main` unless explicitly stated otherwise
- Starting/baseline commit: `<sha>`
- Current milestone/task refs: `<ids>`
- Relevant prior cycle/audit: `<absolute GitHub URLs or none>`

## Canonical GitHub sources to read first

Use absolute GitHub URLs as the primary identifiers for repository sources.

At minimum include:

- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- the active prompt URL
- every prior ChatGPT audit URL relevant to the cycle/system
- every owner-note URL relevant to the cycle
- relevant project docs by absolute GitHub URL

Repository-relative paths may be included only as secondary convenience references.

## Prior audit learnings to apply

List relevant `AL-XXX` entries from `coordination/AUDIT_INDEX.md` and any specific prior `CHATGPT_AUDIT_VNN.md` findings Claude must incorporate into implementation/testing.

Claude must treat these findings as part of the current verification baseline and explicitly state in its self-audit how they changed the test plan.

## Locked constraints

List only constraints relevant to this scope. Reference existing authority instead of duplicating the entire project spec.

## In scope

- ...

## Out of scope

- ...

## Implementation requirements

1. ...

## Validation requirements

For every material requirement define:

- expected behavior;
- explicit failure condition;
- test/check method;
- required negative/boundary/regression checks where applicable.

Claude's own tests are provisional implementer evidence, not independent proof.

Before handing work back, Claude must create a versioned self-audit using:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md

The self-audit must compare current behavior against relevant prior ChatGPT audit findings and `AUDIT_INDEX` learnings.

## Logging and communication requirements

- Continue the correct local Desktop phase log.
- Create/update the cycle's append-only Claude implementation log.
- Create a new immutable `CLAUDE_SELF_AUDIT_VNN.md` for each implementation pass handed to ChatGPT.
- Update `tasks.md` only when validated task truth changes.
- Update `coordination/SESSION_INDEX.md`.
- Update `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary before ending the session.
- Use absolute GitHub URLs for GitHub-tracked prompt/audit/log/index/dashboard evidence.
- Never edit a published ChatGPT prompt or ChatGPT audit.

## Stop conditions

State what Claude must not begin in this cycle.

## Expected Claude final response

Require a concise summary containing cycle ID, implementation state, provisional test results, self-audit URL, implementation-log URL, commit/push evidence, blockers, and readiness for independent ChatGPT audit.
