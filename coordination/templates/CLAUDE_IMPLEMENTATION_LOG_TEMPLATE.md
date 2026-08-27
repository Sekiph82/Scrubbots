---
coordinationSchema: scrubbots-coordination/v1
artifactType: claude-implementation-log
cycleId: <MXX-CNNN>
createdAt: <ISO-8601>
actor: CLAUDE
status: <CLAUDE_IN_PROGRESS|AWAITING_AUDIT|BLOCKED>
milestone: <MXX>
taskRefs: []
startingCommit: <sha>
currentCommit: <sha-or-uncommitted>
---

# SCRUBBOTS - Claude Implementation Log

This file is append-only within one coordination cycle. Multiple Claude Code sessions working on the same cycle append new session entries here. Do not delete prior failures, commands, or decisions after they are resolved.

Claude's own tests are provisional implementer evidence. Final independent audit status is assigned only by ChatGPT according to:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Before planning verification, read:

- Audit policy: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- Audit index: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- Active ChatGPT prompt(s): <absolute GitHub URLs>
- Prior ChatGPT audit(s) relevant to this cycle/system: <absolute GitHub URLs>

The local Desktop phase log required by `CLAUDE.md` remains mandatory and more detailed. This GitHub log is the durable handoff/evidence layer for ChatGPT, H!veAI, and the owner.

## Inputs read

- ChatGPT prompts: <absolute GitHub URLs>
- ChatGPT audits: <absolute GitHub URLs or none>
- Audit learnings applied: <AL-XXX IDs>
- Owner notes: <absolute GitHub URLs or none>
- tasks.md: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- Relevant docs/ADRs: <absolute GitHub URLs>

---

## Claude Session <N> - <ISO-8601 timestamp>

### Session status

`IN_PROGRESS`, `COMPLETED_PASS`, `BLOCKED`, or `FAILED`.

### Repository start state

- Branch:
- Starting commit + GitHub URL:
- Working tree:
- Baseline tests:

### Audit-informed test plan

Before implementation or completion testing, state which prior audit learnings/findings changed the plan.

| Audit learning/finding | Test/implementation change applied |
| --- | --- |
| AL-XXX / audit URL | ... |

### Work performed

Describe actual implementation, not intent.

### Files created

- `<repository path>` - `<absolute GitHub URL when committed>`

### Files modified

- `<repository path>` - `<absolute GitHub URL>`

### Architecture / decisions

Record decisions made during implementation and where durable decisions were documented.

### Commands and provisional tests

For each material test, include expected result and explicit failure criteria.

| Command/test | Expected | Fail condition | Actual | Classification |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | SELF_PASS / SELF_FAIL / NOT_RUN / BLOCKED |

Do not label Claude-run checks `AUDITED_PASS`.

### Negative/boundary/regression coverage

Record non-happy-path checks selected because of current risk and prior audit learnings.

### Failures and debugging history

Record failed approaches, errors, root cause, and fix. Do not erase this section after success.

### False-positive risks noticed

Record any way current tests might pass without proving intended behavior and how the self-audit will challenge that risk.

### Performance evidence

Record measured evidence when relevant. Never claim measurements that were not run. Never treat headless CPU timing as on-screen GPU/FPS evidence.

### Prompt deviations

State any requirement not implemented exactly, why, and whether owner/ChatGPT follow-up is needed. Use `None` when there were no deviations.

### Task/documentation updates

- `tasks.md` items changed:
- Docs/ADR/changelog changed:

### Git evidence

- Ending commit + GitHub URL:
- Commit message:
- Push result:
- PR if used:

### Self-audit

Before handing work back, create a new immutable:

`coordination/sessions/<CYCLE_ID>/CLAUDE_SELF_AUDIT_VNN.md`

using:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/templates/CLAUDE_SELF_AUDIT_TEMPLATE.md

Self-audit URL:
<absolute GitHub URL>

### Remaining / blocked

- ...

### Handoff state

Set the cycle to `AWAITING_AUDIT` only after the self-audit is ready for ChatGPT independent review, or `BLOCKED` when external/owner input is required.

Confirm before ending:

- [ ] Desktop phase log updated.
- [ ] This implementation log appended.
- [ ] Claude self-audit created for this implementation pass.
- [ ] Audit policy and index read.
- [ ] Relevant prior ChatGPT audits read and applied.
- [ ] `coordination/SESSION_INDEX.md` updated.
- [ ] `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary updated.
- [ ] GitHub-tracked evidence uses absolute GitHub URLs.
- [ ] No ChatGPT prompt/audit files were rewritten.
- [ ] No secrets were committed.
