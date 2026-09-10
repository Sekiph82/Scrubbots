# SCRUBBOTS Versioned Claude Log Policy

Status: LOCKED
Coordination schema: scrubbots-coordination/v4

## Canonical bundle

Every ChatGPT prompt version has one matching Claude evidence file in the same cycle:

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

Prompt/log version matching is mandatory.

## Ownership

- ChatGPT owns `CHATGPT_PROMPT_VNN.md`, `CHATGPT_AUDIT_CRITERIA_VNN.md`, and `CHATGPT_AUDIT_VNN.md`.
- Claude owns `CLAUDE_LOG_VNN.md` only.
- Claude never creates/edits ChatGPT artifacts or assigns an audit verdict.
- ChatGPT never fabricates Claude logs.

## Root TASKS tracking [OWNER-LOCKED — 2026-09-10]

Root `TASKS.md` is the only live project-status tracker and H!veAI current-state surface. Former `.hiveai/*`, dashboard, cycle-map, progress-snapshot and session-index trackers are retired historical evidence. Do not create or synchronize a competing tracker.

Claude may update root `TASKS.md` only as authorized by the active prompt for truthful lifecycle handoff (`IN_PROGRESS`, `AWAITING_AUDIT`, or truthful `BLOCKED`). Claude must not mark independent-audit completion or close audit-owned task rows. ChatGPT performs independent audit closure, task-row closure, progress update and next-frontier update in root `TASKS.md`.

## Claude log requirements

`CLAUDE_LOG_VNN.md` records prompt/criteria/prior-audit references, starting commit, changed files, exact validation commands/results, failures/fixes, scope/governance checks, commit/push evidence, blockers and final handoff. Aggregate green totals never substitute for individually mandated checks.

## GitHub-only evidence

For M12-C001 and later work, durable handoff evidence lives in GitHub. Historical Desktop logs are not a required live coordination surface.

## Non-self-referential final SHA rule

A Git-tracked Claude log must not be edited merely to insert the SHA of the commit containing that same log. ChatGPT verifies final remote state directly.

## Strict-v2 adversarial validation

Critical milestones may use later validation-heavy prompt versions. Final closure remains ChatGPT-owned under `coordination/AUDIT_POLICY.md`.

## Progress reporting

Progress is recalculated from canonical root `TASKS.md`, never from archived `.hiveai` files or deprecated dashboards.
