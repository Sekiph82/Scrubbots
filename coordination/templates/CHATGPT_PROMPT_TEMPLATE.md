---
coordinationSchema: scrubbots-coordination/v3
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

State exactly what Claude must implement in this cycle/pass.

## Repository baseline

- Repository: https://github.com/Sekiph82/Scrubbots
- Branch: `main` unless explicitly stated otherwise
- Baseline commit: `<sha>`
- Cycle/task refs: `<ids>`

## Canonical GitHub sources to read first

Include absolute GitHub URLs for:

- https://github.com/Sekiph82/Scrubbots/blob/main/CLAUDE.md
- https://github.com/Sekiph82/Scrubbots/blob/main/tasks.md
- https://github.com/Sekiph82/Scrubbots/blob/main/.hiveai/PROJECT_DASHBOARD.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/README.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/SESSION_INDEX.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_POLICY.md
- https://github.com/Sekiph82/Scrubbots/blob/main/coordination/AUDIT_INDEX.md
- the active prompt URL
- every prior ChatGPT audit URL relevant to this cycle/system
- any cycle-specific ChatGPT audit-criteria URL
- relevant owner-note/docs URLs.

Repository-relative paths may be included only as secondary local-edit references.

## Prior ChatGPT audit findings to apply

List the exact prior audit URL(s), finding IDs, and relevant `AL-XXX` learnings.

Claude must use these as implementation/test-planning input and record in `CLAUDE_IMPLEMENTATION_LOG.md` how each relevant finding changed the current checks.

Claude must not create an audit or self-audit document.

## Locked constraints

List scope-relevant locked rules and authority URLs.

## In scope

- ...

## Out of scope

- ...

## Implementation requirements

1. ...

## Validation requirements

For material checks, specify as appropriate:

- exact command/check;
- expected outcome;
- explicit failure condition;
- negative/boundary/regression coverage required by current risk or prior audits.

Claude runs these checks and records them in the implementation log. Claude-run results are implementation evidence, not audit verdicts.

Every prompt-mandated validation command must appear individually in the implementation log.

## Logging and communication requirements

- Continue the correct local Desktop phase log.
- Create/update only the cycle's append-only `CLAUDE_IMPLEMENTATION_LOG.md` as Claude's GitHub work record.
- Record active prompt URL, prior audit URLs, applied `AL-XXX` learnings, changes, tests, failures/fixes, task/doc changes, and commit/push evidence.
- Update `tasks.md` only when validated task truth changes.
- Update `coordination/SESSION_INDEX.md`.
- Update `.hiveai/PROJECT_DASHBOARD.md` before ending the material session.
- Use absolute GitHub URLs for GitHub-tracked evidence.
- Never create/modify `CHATGPT_AUDIT_VNN.md`.
- Never create a `CLAUDE_SELF_AUDIT_VNN.md`.

## Handoff

When implementation/testing is ready for ChatGPT review, set the cycle to `AWAITING_AUDIT` and stop.

If genuinely blocked, set `BLOCKED` with the exact blocker.

Claude must never mark the cycle `AUDITED_PASS`.

## Stop conditions

State what Claude must not begin in this pass.

## Expected Claude final response

Keep the chat response concise. Require only:

- cycle ID/state;
- implementation commit/push status;
- implementation-log GitHub URL;
- short Claude-run test summary;
- blocker(s), if any;
- `READY FOR CHATGPT AUDIT` when appropriate.


## Coordination v4 prompt requirement

Every new prompt must declare the exact expected Claude evidence filename:

`expectedClaudeLog: CLAUDE_LOG_VNN.md`

where VNN matches the prompt version. Claude must not use
CLAUDE_IMPLEMENTATION_LOG.md for new work.
