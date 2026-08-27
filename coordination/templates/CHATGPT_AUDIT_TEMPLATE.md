---
coordinationSchema: scrubbots-coordination/v3
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

State which prompt version(s), Claude implementation-log entries, commits, files, tests, task refs, audit criteria, and prior audit learnings were reviewed. Use absolute GitHub URLs.

Claude self-audits are not part of the current workflow. Historical self-audit files, if present, are non-authoritative and should not be used as independent proof.

## Repository evidence

- Baseline commit: `<GitHub commit URL>`
- Audited commit/head: `<GitHub commit URL>`
- Active prompt(s): `<absolute GitHub URLs>`
- Prior ChatGPT audit(s): `<absolute GitHub URLs or none>`
- Claude implementation log: `<absolute GitHub URL>`
- Audit criteria, if used: `<absolute GitHub URL or none>`
- Changed files reviewed: ...
- Independent commands/checks run or cross-checked: ...

## Independence rule

Claude-run tests are implementation evidence only. A green Claude result is never automatically converted to `AUDITED_PASS`.

When ChatGPT cannot independently rerun a claimed check, record `NOT_INDEPENDENTLY_VERIFIED` or explain why repository/diff evidence is sufficient for the scoped requirement.

## Requirement-by-requirement audit

| Requirement / criterion | Claude implementation evidence | ChatGPT audit result | Independent evidence | Notes |
| --- | --- | --- | --- | --- |
| ... | log/command/URL | `AUDITED_PASS` / `AUDITED_FAIL` / `NOT_INDEPENDENTLY_VERIFIED` / `BLOCKED` / `OWNER_REQUIRED` | URL/command/diff | ... |

## Test-quality audit

Review as relevant:

- whether every prompt-mandated command was actually recorded;
- happy path and negative/error path;
- min/max boundaries;
- rectangular/variable-size behavior;
- malformed input;
- state transitions;
- regression against prior audited baseline;
- scale/performance claim validity;
- fixture freshness;
- mock/stub overreach;
- false-positive risk;
- tolerance/quantization correctness;
- claims that exceed what was measured.

## Prior-audit comparison

Compare the current implementation/test log against relevant prior `CHATGPT_AUDIT_VNN.md` findings and `AL-XXX` learnings.

| Prior audit finding / learning | Expected current behavior | Current evidence | Result |
| --- | --- | --- | --- |
| ... | ... | ... | `AUDITED_PASS` / `AUDITED_FAIL` / `NOT_INDEPENDENTLY_VERIFIED` |

## Architecture / locked-rule compliance

Check relevant `CLAUDE.md`, `tasks.md`, ADRs, gameplay rules, scope boundaries, owner/design gates, source-preservation rules, and other locked constraints.

## Findings

Use severities only when useful:

- `BLOCKER`
- `HIGH`
- `MEDIUM`
- `LOW`
- `NOTE`

Never invent findings.

## Decision

Use one cycle decision:

- `AUDITED_PASS`
- `CHANGES_REQUIRED`
- `BLOCKED`

A critical `AUDITED_FAIL` prevents `AUDITED_PASS`.

Owner-controlled gates may remain `OWNER_REQUIRED` when the prompt explicitly excludes closing them.

## Required follow-up

If changes are required, list exact corrections. Publish the next ChatGPT prompt version in the same cycle and cite this audit by absolute GitHub URL.

## Reusable audit learnings

Update:

https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

when this audit adds or supersedes a reusable verification rule.

## Task-truth impact

State which `tasks.md` items remain complete/open, need correction, or are unaffected.

## Dashboard / index synchronization

Confirm updates to:

- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
