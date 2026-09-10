# SCRUBBOTS Coordination Protocol

## Authority model [OWNER-LOCKED — 2026-09-10]

- GitHub `origin/main` is repository truth.
- Root `TASKS.md` is the **only live project-status tracker** and the only H!veAI current-state surface.
- `CLAUDE.md` and `AGENTS.md` are operating/governance manuals, not status trackers.
- `coordination/AUDIT_POLICY.md` is the audit constitution.
- `coordination/AUDIT_INDEX.md` is ChatGPT-owned reusable audit memory.
- `coordination/sessions/<CYCLE_ID>/` contains versioned evidence artifacts.
- Former `.hiveai/*`, dashboards, ACTIVE_CYCLES, ARTIFACT_MAP, PROGRESS_SNAPSHOT and `coordination/SESSION_INDEX.md` are historical only. Do not maintain them as live state.

## Versioned cycle bundle

```text
CHATGPT_PROMPT_VNN.md
CHATGPT_AUDIT_CRITERIA_VNN.md
CLAUDE_LOG_VNN.md
CHATGPT_AUDIT_VNN.md
```

ChatGPT owns the `CHATGPT_*` artifacts. Claude owns only the matching `CLAUDE_LOG_VNN.md`. Claude never creates an audit verdict or edits a ChatGPT audit artifact.

## Normal cycle flow

1. ChatGPT reads root `TASKS.md`, current source, prior audits and `AUDIT_INDEX.md`.
2. For critical work ChatGPT performs the required full attack-surface sweep, freezes findings, and publishes prompt/criteria.
3. Claude safely syncs `origin/main`, confirms root `TASKS.md` authorizes Claude, then implements/tests.
4. When the prompt requires lifecycle tracking, Claude updates root `TASKS.md` to `IN_PROGRESS` before material edits, commits/pushes it, and later hands off as `AWAITING_AUDIT` with the matching log/evidence.
5. Claude stops. It does not self-audit and does not mark audit-owned task rows complete.
6. ChatGPT independently audits GitHub state. For corrections ChatGPT sets the next `CHANGES_REQUIRED` task/version in root `TASKS.md`; for final PASS ChatGPT closes approved task rows, updates progress and sets the next frontier in root `TASKS.md`.

## Single-tracker rule

There is no second live tracker. Do not mirror current task, actor, progress or next action into `.hiveai/*`, dashboards, session indexes or coordination summary files. Explicit archive/history paths may preserve old snapshots as evidence only.

## Evidence and strict audit

Claude runtime checks are E1/E2 implementer evidence. ChatGPT source/diff/test inspection is E3 audit evidence. Owner-controlled decisions are E4. Only ChatGPT audit files may assign audit verdicts. `coordination/AUDIT_POLICY.md` governs strict-v2 closure, full-surface sweeps, adversarial validation, direct observability and sensitivity.

Canonical repository: `https://github.com/Sekiph82/Scrubbots`
Canonical live tracker: `https://github.com/Sekiph82/Scrubbots/blob/main/TASKS.md`
