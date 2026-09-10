<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M15 — TargetSelector upstream repair for M19",
  "currentSprint": "M15-C002 V02 — transactional closure and adversarial validation",
  "currentTaskId": "M15-C002-V02",
  "currentTaskTitle": "Close remaining F-M15-STRICT-004/005 transaction, re-entry and rollback gaps",
  "workflowState": "CHANGES_REQUIRED",
  "requiredActor": "CLAUDE",
  "nextAction": "Implement coordination/sessions/M15-C002/CHATGPT_PROMPT_V02.md; validate against CHATGPT_AUDIT_CRITERIA_V02.md; write CLAUDE_LOG_V02.md; follow H!veAI IN_PROGRESS -> AWAITING_AUDIT lifecycle and push to origin/main.",
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
  "updatedAt": "2026-09-10T09:05:17Z",
  "updatedBy": "CHATGPT"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M15 — TargetSelector upstream repair for M19**
- Current sprint: **M15-C002 V02 — transactional closure and adversarial validation**
- Current task: **M15-C002-V02 — Close remaining F-M15-STRICT-004/005 transaction, re-entry and rollback gaps**
- Workflow: **CHANGES_REQUIRED**
- Required actor: **CLAUDE**
- Next action: Implement
  `coordination/sessions/M15-C002/CHATGPT_PROMPT_V02.md`, validate against
  `coordination/sessions/M15-C002/CHATGPT_AUDIT_CRITERIA_V02.md`, write
  `coordination/sessions/M15-C002/CLAUDE_LOG_V02.md`, follow the canonical
  H!veAI `IN_PROGRESS -> AWAITING_AUDIT` lifecycle, and push to `origin/main`.
- Blockers: none for the current M15 task.
- Audit status: M15-C002 V01 independent audit returned **CHANGES_REQUIRED / SAME_FROZEN_SET / V02_REQUIRED**. V01 hardening is preserved; V02 closes the remaining transaction-guard, recursive-selection, per-boundary coherence and exact rollback gaps.
- M19 status: **waiting**. M19-C001 V03 implementation remains preserved. Do not issue/execute M19 V04 until M15-C002 independently passes.

## Milestones

- **M02–M14 and FOUNDATION-C001** — audited/closed.
- **M15 — TargetSelector:** historical M15-C001 remains accepted. M15-C002 V01 confirmed real strict defects and materially hardened the boundary; **M15-C002 V02 is the current closure gate** for the same frozen F-M15-STRICT-004/005 finding set.
- **M16–M18** — audited/closed and preserved.
- **M19 — dispatcher orchestration:** V03 implementation is preserved; M19 has a frozen remainder and waits on M15-C002. After M15-C002 independently closes, ChatGPT will issue M19-C001 V04.
- **M20+** — arrival resolution / clearing / scoring / slot progression remains planned and out of scope.

## Active / Waiting

- [~] **M15-C002-V02** — CHANGES_REQUIRED, actor CLAUDE. Same frozen F-M15-STRICT-004/005 set. Required closure includes guard-before-first-coherence, recursive-select rejection, bind transaction re-entry protection, coherence after every collaborator boundary, mutation-before-malformed-return rollback, malformed ownership-proof cleanup, and same-owner no-later-query preservation.
- [~] **M19-C001-V03** — implementation preserved; independent audit completed with CHANGES_REQUIRED. Waiting on M15-C002 V02, then M19 V04 remainder closure.

## Planned

- [ ] M15-C002-V02 implementation + independent audit.
- [ ] M19-C001 V04 frozen remainder closure after M15-C002 passes.
- [ ] M20 — arrival resolution: BoardState ACTIVE→CLEARED on arrival, reservation resolution, scoring, slot progression, follow-up dispatch.

## Completed

- [x] **FOUNDATION-C001 V01** — `AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED` (impl `a059b85`). Canonical ACTIVE/CLEARED guard on `BoardState.set_cell_state`.
- [x] Historical M11–M14, M15-C001, M16–M18 strict closures remain accepted except for the newly opened M15-C002 finding set described above.

## Progress

- Main + UI scope: **278 / 719 = 38.66%**.
- Overall (incl. sidecars): **278 / 943 = 29.48%**.
- No progress increment is recorded for M15-C002 or M19 until independent audit closes the relevant task truth.

## History / migration notes

Root `tasks.md` remains the detailed historical/master planning ledger and retains task definitions and history. As of the H!veAI GitHub-first v3 migration, `.hiveai/TASKS.md` is H!veAI's operational current-state authority. If the two disagree about current project state, this file wins. `.hiveai/STATE.json`, `.hiveai/HANDOFF.md`, `.hiveai/PROJECT_DASHBOARD.md`, `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md`, and `coordination/SESSION_INDEX.md` are removed/deprecated as live authority and retained only as historical evidence.
