---
coordinationSchema: scrubbots-coordination/v3
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

This file is Claude's append-only implementation and test record for one coordination cycle.

Claude does not audit itself. Final audit decisions are published only by ChatGPT.

Audit policy:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md

Audit learning index:
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md

## Inputs read

- Active ChatGPT prompt: <absolute GitHub URL>
- Prior ChatGPT audit(s): <absolute GitHub URLs or none>
- Audit criteria, if supplied: <absolute GitHub URL or none>
- Audit learnings applied: <AL-XXX IDs>
- Owner notes: <absolute GitHub URLs or none>
- tasks.md: https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- Relevant docs/ADRs: <absolute GitHub URLs>

---

## Claude Session <N> - <ISO-8601 timestamp>

### Session status

`IN_PROGRESS`, `IMPLEMENTATION_COMPLETE`, `BLOCKED`, or `FAILED`.

### Repository start state

- Branch:
- Starting commit + GitHub URL:
- Working tree:
- Baseline checks run:

### Prior audit feedback applied

Record exactly how relevant prior ChatGPT findings and `AL-XXX` learnings changed implementation or testing.

| Audit/finding/learning | Change applied in this pass |
| --- | --- |
| `<audit URL / finding ID / AL-XXX>` | ... |

### Work performed

Describe actual implementation, not intent.

### Files created

- `<repository path>` - `<absolute GitHub URL when committed>`

### Files modified

- `<repository path>` - `<absolute GitHub URL>`

### Architecture / decisions

Record implementation decisions and where durable project decisions were documented.

### Tests and checks run by Claude

Claude-run checks are implementation evidence only. They are not audit verdicts.

For every prompt-mandated command/check, record a separate row.

| Command/check | Expected | Explicit fail condition | Actual | Result |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | `CLAUDE_TEST_PASS` / `CLAUDE_TEST_FAIL` / `NOT_RUN` / `BLOCKED` / `OWNER_REQUIRED` |

### Negative / boundary / regression coverage

Record the extra checks selected because of current risk or prior ChatGPT audit findings.

### False-positive risks / unverified assumptions

Record ways the current checks could pass without proving the intended behavior, plus any remaining unverified assumption. Do not hide them behind an aggregate green count.

### Failures and debugging history

Keep failures, root causes, and fixes. Do not erase them after success.

### Performance evidence

Record only measurements actually taken. Never present headless CPU timing as on-screen GPU/FPS evidence.

### Prompt deviations

State any requirement not implemented exactly and why. Use `None` when there were no deviations.

### Task / documentation updates

- `tasks.md` items changed:
- Docs/ADR/changelog changed:

### Git evidence

- Ending commit + GitHub URL:
- Commit message:
- Push result:
- PR if used:

### Remaining / blocked

- ...

### Handoff state

When implementation/testing evidence is ready for ChatGPT review:

- update `coordination/SESSION_INDEX.md`;
- update `.hiveai/PROJECT_DASHBOARD.md`;
- set the cycle to `AWAITING_AUDIT`;
- stop.

Do not create any audit or self-audit file.

Confirm before ending:

- [ ] Desktop phase log updated.
- [ ] This implementation log appended.
- [ ] Active ChatGPT prompt read.
- [ ] Relevant prior ChatGPT audits and `AUDIT_INDEX.md` read/applied.
- [ ] Every prompt-mandated validation command is individually recorded.
- [ ] `coordination/SESSION_INDEX.md` updated.
- [ ] `.hiveai/PROJECT_DASHBOARD.md` updated.
- [ ] GitHub evidence uses absolute GitHub URLs.
- [ ] No ChatGPT prompt/audit files were rewritten.
- [ ] No Claude self-audit file was created.
- [ ] No secrets were committed.
