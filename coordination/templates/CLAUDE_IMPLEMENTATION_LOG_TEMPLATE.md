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

# SCRUBBOTS — Claude Implementation Log

This file is append-only within one coordination cycle. Multiple Claude Code sessions working on the same cycle append new session entries here. Do not delete prior failures, commands, or decisions after they are resolved.

The local Desktop phase log required by `CLAUDE.md` remains mandatory and more detailed. This GitHub log is the durable handoff/evidence layer for ChatGPT, H!veAI, and the owner.

## Inputs read

- ChatGPT prompts: ...
- ChatGPT audits: ...
- Owner notes: ...
- `tasks.md` refs: ...
- Relevant docs/ADRs: ...

---

## Claude Session <N> — <ISO-8601 timestamp>

### Session status

`IN_PROGRESS`, `COMPLETED_PASS`, `BLOCKED`, or `FAILED`.

### Repository start state

- Branch:
- Starting commit:
- Working tree:
- Baseline tests:

### Work performed

Describe actual implementation, not intent.

### Files created

- ...

### Files modified

- ...

### Architecture / decisions

Record decisions made during implementation and where durable decisions were documented.

### Commands and tests

| Command/test | Result | Notes |
| --- | --- | --- |
| ... | PASS / FAIL / NOT RUN | ... |

### Failures and debugging history

Record failed approaches, errors, root cause, and fix. Do not erase this section after success.

### Performance evidence

Record measured evidence when relevant. Never claim measurements that were not run.

### Prompt deviations

State any requirement not implemented exactly, why, and whether owner/ChatGPT follow-up is needed. Use `None` when there were no deviations.

### Task/documentation updates

- `tasks.md` items changed:
- Docs/ADR/changelog changed:

### Git evidence

- Ending commit:
- Commit message:
- Push result:
- PR if used:

### Remaining / blocked

- ...

### Handoff state

Set the cycle to `AWAITING_AUDIT` when implementation evidence is ready for ChatGPT review, or `BLOCKED` when external/owner input is required.

Confirm before ending:

- [ ] Desktop phase log updated.
- [ ] This implementation log appended.
- [ ] `coordination/SESSION_INDEX.md` updated.
- [ ] `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary updated.
- [ ] No ChatGPT prompt/audit files were rewritten.
- [ ] No secrets were committed.
