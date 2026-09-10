<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M15 — TargetSelector upstream repair for M19",
  "currentSprint": "M15-C002 V02 — transactional closure and adversarial validation",
  "currentTaskId": "M15-C002-V02",
  "currentTaskTitle": "Close remaining F-M15-STRICT-004/005 transaction, re-entry and rollback gaps",
  "workflowState": "AWAITING_AUDIT",
  "requiredActor": "CHATGPT",
  "nextAction": "Independently audit M15-C002 V02 against CHATGPT_AUDIT_CRITERIA_V02.md (impl scripts/gameplay/targeting/target_selector.gd; evidence coordination/sessions/M15-C002/CLAUDE_LOG_V02.md; full root suite 2984/2984 green on Godot 4.7.1). Publish CHATGPT_AUDIT_V02.md; on pass, close M15-C002 and issue the frozen M19-C001 V04 remainder.",
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
  "updatedAt": "2026-09-10T09:50:00Z",
  "updatedBy": "CLAUDE"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M15 — TargetSelector upstream repair for M19**
- Current sprint: **M15-C002 V02 — transactional closure and adversarial validation**
- Current task: **M15-C002-V02 — Close remaining F-M15-STRICT-004/005 transaction, re-entry and rollback gaps**
- Workflow: **AWAITING_AUDIT**
- Required actor: **CHATGPT**
- Next action: ChatGPT independently audits M15-C002 V02 against
  `coordination/sessions/M15-C002/CHATGPT_AUDIT_CRITERIA_V02.md`. Implementation
  in `scripts/gameplay/targeting/target_selector.gd`; evidence in
  `coordination/sessions/M15-C002/CLAUDE_LOG_V02.md`; full root suite
  **2984/2984** green on Godot **4.7.1**. On pass, close M15-C002 and issue the
  frozen M19-C001 V04 remainder.
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

- [~] **M15-C002-V02** — AWAITING_AUDIT, actor CHATGPT. Same frozen F-M15-STRICT-004/005 set. Closure implemented in `scripts/gameplay/targeting/target_selector.gd`: guard-before-first-coherence, recursive-select rejection, bind transaction re-entry protection, coherence after every collaborator boundary (incl. is_reserved==true), mutation-before-malformed-return exact-pair rollback, get_owner-independent rollback, and same-owner no-later-query preservation. Adversarial coverage `_run_target_selector_strict_v04_tests`; full root suite 2984/2984 green. No audit verdict claimed by Claude.
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
