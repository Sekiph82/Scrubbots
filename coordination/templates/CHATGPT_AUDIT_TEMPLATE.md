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

# SCRUBBOTS — ChatGPT Audit

## Audit scope

State which prompt version(s), Claude implementation-log entries, commits, files, tests, and task refs were reviewed.

## Repository evidence

- Baseline commit: `<sha>`
- Audited commit/head: `<sha>`
- Changed files reviewed: ...
- Tests/commands independently checked where possible: ...

## Prompt compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| ... | PASS / FAIL / NOT VERIFIED | ... |

## Architecture / locked-rule compliance

Record any relevant checks against `CLAUDE.md`, `tasks.md`, ADRs, gameplay rules, performance rules, and scope boundaries.

## Test and performance review

- Regression result: ...
- New tests: ...
- Performance evidence: ...
- Claims not independently verified: ...

## Findings

Use severities only when useful:

- `BLOCKER`
- `HIGH`
- `MEDIUM`
- `LOW`
- `NOTE`

Never invent a finding to make the audit look substantial.

## Decision

`AUDITED_PASS`, `CHANGES_REQUIRED`, or `BLOCKED`.

Explain why.

## Required follow-up

If changes are required, list exact corrections. The next ChatGPT prompt version in the same cycle must cite this audit instead of opening a duplicate cycle.

## Task-truth impact

State which `tasks.md` items may now be marked complete, remain open, or require no change. `tasks.md` remains authoritative.

## Dashboard / index synchronization

Confirm `coordination/SESSION_INDEX.md` and `.hiveai/PROJECT_DASHBOARD.md` were updated to reflect this audit.
