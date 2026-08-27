---
coordinationSchema: scrubbots-coordination/v1
artifactType: chatgpt-audit
cycleId: <MXX-CNNN>
version: 1
createdAt: <ISO-8601>
actor: CHATGPT
status: <AUDITED_PASS|CHANGES_REQUIRED|BLOCKED>
milestone: <MXX>
taskRefs: []
auditedPromptVersions: []
auditedCommit: <sha>
---

# SCRUBBOTS - ChatGPT Independent Audit

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Audit scope

State which prompt version(s), Claude implementation-log entries, Claude self-audit(s), commits, files, tests, task refs, and prior audit learnings were reviewed. Use absolute GitHub URLs.

## Repository evidence

- Baseline commit: `<GitHub commit URL>`
- Audited commit/head: `<GitHub commit URL>`
- Active prompt(s): `<absolute GitHub URLs>`
- Claude implementation log: `<absolute GitHub URL>`
- Claude self-audit(s): `<absolute GitHub URLs>`
- Changed files reviewed: ...
- Tests/commands independently checked where possible: ...

## Independence rule

Claude's successful tests are provisional evidence, not independent proof. Do not convert `SELF_PASS` into `AUDITED_PASS` without an independent repository/test/evidence check appropriate to the requirement.

When independent rerun is unavailable, use `NOT_INDEPENDENTLY_VERIFIED` and explain the limitation.

## Requirement-by-requirement audit

| Requirement | Claude self-result | Independent audit result | Evidence | Notes |
| --- | --- | --- | --- | --- |
| ... | SELF_PASS / SELF_FAIL / NOT_RUN / BLOCKED / OWNER_REQUIRED | AUDITED_PASS / AUDITED_FAIL / NOT_INDEPENDENTLY_VERIFIED / BLOCKED / OWNER_REQUIRED | URL/command/diff | ... |

## Test-quality audit

Check not only whether tests are green, but whether they could pass without proving intended behavior.

Review as applicable:

- happy path;
- negative/error path;
- min/max boundaries;
- rectangular/variable-size behavior;
- malformed input;
- state transitions;
- regression against prior audited baseline;
- scale/performance claim validity;
- fixture freshness and relevance;
- mock/stub overreach;
- false-positive risk;
- tolerance/quantization correctness;
- claims that exceed what was actually measured.

## Prior-audit comparison

Compare current implementation and test behavior against relevant `AL-XXX` learnings and prior ChatGPT audit findings.

| Prior learning/finding | Expected current behavior | Current evidence | Result |
| --- | --- | --- | --- |
| ... | ... | ... | AUDITED_PASS / AUDITED_FAIL / NOT_INDEPENDENTLY_VERIFIED |

## Architecture / locked-rule compliance

Record checks against `CLAUDE.md`, `tasks.md`, ADRs, gameplay rules, scope boundaries, owner/design gates, source-preservation rules, and other locked constraints relevant to the cycle.

## Findings

Use severities only when useful:

- `BLOCKER`
- `HIGH`
- `MEDIUM`
- `LOW`
- `NOTE`

Never invent findings to make the audit appear substantial.

## Decision

Use one cycle decision:

- `AUDITED_PASS`
- `CHANGES_REQUIRED`
- `BLOCKED`

Explain why.

A cycle cannot be `AUDITED_PASS` while a critical requirement is `AUDITED_FAIL`, unresolved `BLOCKED`, or improperly treated Claude-only evidence.

Owner-controlled design gates may remain `OWNER_REQUIRED` without failing a cycle when the prompt explicitly excludes closing that gate.

## Required follow-up

If changes are required, list exact corrections. The next ChatGPT prompt version in the same cycle must cite this audit by absolute GitHub URL instead of opening a duplicate cycle.

## Reusable audit learnings

State whether this audit adds, updates, or supersedes any reusable test/verification rule. If yes, update:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

with a new or superseding `AL-XXX` entry.

## Task-truth impact

State which `tasks.md` items may remain complete, be marked complete, be reopened/corrected, or require no change. `tasks.md` remains authoritative.

## Dashboard / index synchronization

Confirm these were updated after the audit:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
