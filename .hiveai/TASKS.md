<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M19 — Scrubbot dispatcher orchestration",
  "currentSprint": "M19-C001 V03 — strict-v2 orchestrator closure second stage",
  "currentTaskId": "M19-C001-V03",
  "currentTaskTitle": "Close remaining M19 strict-v2 orchestration gaps under frozen F-M19-STRICT-001..003",
  "workflowState": "CHANGES_REQUIRED",
  "requiredActor": "CLAUDE",
  "nextAction": "Implement coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md; validate against CHATGPT_AUDIT_CRITERIA_V03.md; write CLAUDE_LOG_V03.md; follow H!veAI IN_PROGRESS -> AWAITING_AUDIT lifecycle and push to origin/main.",
  "blockers": [],
  "progress": {
    "scopeType": "main+ui",
    "scopeId": "scrubbots-main-ui",
    "completed": 278,
    "total": 719,
    "percent": 38.66
  },
  "lastCompletedTaskId": "FOUNDATION-C001-V01",
  "lastCompletedTaskTitle": "BoardState.set_cell_state canonical ACTIVE/CLEARED guard (FOUNDATION-STRICT-001 closed)",
  "updatedAt": "2026-09-09T20:50:18Z",
  "updatedBy": "CHATGPT"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M19 — Scrubbot dispatcher orchestration**
- Current sprint: **M19-C001 V03 — strict-v2 orchestrator closure second stage**
- Current task: **M19-C001-V03 — Close remaining M19 strict-v2 orchestration gaps under frozen F-M19-STRICT-001..003**
- Workflow: **CHANGES_REQUIRED**
- Required actor: **CLAUDE**
- Next action: Implement
  `coordination/sessions/M19-C001/CHATGPT_PROMPT_V03.md`, validate against
  `coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V03.md`, write
  `coordination/sessions/M19-C001/CLAUDE_LOG_V03.md`, follow the canonical
  H!veAI `IN_PROGRESS -> AWAITING_AUDIT` lifecycle, and push to `origin/main`.
- Blockers: none.
- Audit status: V02 independent audit returned **CHANGES_REQUIRED /
  STRICT_V2_SECOND_STAGE_REQUIRED**. F-M19-STRICT-004 is source-accepted/closed;
  remaining closure work stays inside F-M19-STRICT-001..003.

## Milestones

- **M02–M18** — foundation, board, data, palette, candidate index, reservation,
  target selection, routing, agent: audited/closed (see `tasks.md` +
  `coordination/AUDIT_INDEX.md`). Latest accepted gate: **FOUNDATION-C001 V01**
  (`AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED`).
- **M19 — dispatcher orchestration (current).** V01 implementation preserved;
  ChatGPT full-surface re-audit V02 returned `CHANGES_REQUIRED /
  FINDING_SET_FROZEN` (F-M19-STRICT-001..004). V02 prompt issued; awaiting
  Claude implementation, then independent audit.
- **M20+ — arrival resolution / clearing / scoring / slot progression:** planned,
  explicitly out of scope for M19 (see `CHATGPT_PROMPT_V02.md` §10).

## Active / Waiting

- [~] **M19-C001-V03** — required actor CLAUDE. Second-stage closure for:
  mandatory select-access coherence and RefCounted bundle categories (F-001),
  cached-route/factory/assign-result trust seams (F-002), and guard/generation/
  mid-dispatch drift closure (F-003). F-004 remains regression-only.

## Planned

- [ ] M19-C001-V03 independent audit (CHATGPT) -> `CHATGPT_AUDIT_V03.md`.
- [ ] M20 — arrival resolution: BoardState ACTIVE→CLEARED on arrival, reservation
  resolution, scoring, slot progression, follow-up dispatch.

## Completed

- [x] **FOUNDATION-C001 V01** — `AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED`
  (impl `a059b85`). Canonical ACTIVE/CLEARED guard on
  `BoardState.set_cell_state`.
- [x] M11–M18 strict-v2 closures (see `coordination/AUDIT_INDEX.md`).

## Progress

- Main + UI scope: **278 / 719 = 38.66%** (auditor-canonical, M14 V02 /
  FOUNDATION-C001 V01 chain).
- Overall (incl. sidecars): 278 / 943 = 29.48% (reported for context; the
  operational scope above is main + UI).

## History / migration notes

Root `tasks.md` remains the detailed historical/master planning ledger and
retains all task definitions and history. As of the H!veAI GitHub-first v3
migration, `.hiveai/TASKS.md` (this file) is H!veAI's operational
current-state authority. If the two disagree about *current* project state,
this file wins. `.hiveai/STATE.json`, `.hiveai/HANDOFF.md`,
`.hiveai/PROJECT_DASHBOARD.md`, and the other legacy control-plane files are
removed/deprecated as live authority and retained (in git history) as
historical evidence only.
