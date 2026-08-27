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

# SCRUBBOTS — ChatGPT Prompt

## Objective

State exactly what Claude must accomplish in this cycle.

## Repository baseline

- Repository: `Sekiph82/Scrubbots`
- Branch: `main` unless explicitly stated otherwise
- Starting commit: `<sha>`
- Current milestone/task refs: `<ids>`
- Relevant prior cycle/audit: `<links or none>`

## Authoritative sources to read first

- `CLAUDE.md`
- `tasks.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/README.md`
- `coordination/SESSION_INDEX.md`
- relevant `docs/`
- every earlier prompt/audit/owner note in this cycle

## Locked constraints

List only constraints relevant to this scope. Reference existing authority instead of duplicating the whole project spec.

## In scope

- ...

## Out of scope

- ...

## Implementation requirements

1. ...

## Validation requirements

Record exact commands/tests/evidence required before completion.

## Logging and communication requirements

- Continue the correct Desktop phase log.
- Create/update `coordination/sessions/<CYCLE_ID>/CLAUDE_IMPLEMENTATION_LOG.md` as append-only evidence.
- Update `tasks.md` only when validated task truth changes.
- Update `coordination/SESSION_INDEX.md`.
- Update `.hiveai/PROJECT_DASHBOARD.md` Latest Session Summary before ending the session.
- Never edit this prompt file after acting on it. If instructions require revision, wait for `CHATGPT_PROMPT_V02.md` or later.

## Stop conditions

State what Claude must not begin in this cycle.

## Expected Claude final response

Require a concise summary containing cycle ID, implementation status, test results, commit/push evidence, log path, blockers, and readiness for ChatGPT audit.
