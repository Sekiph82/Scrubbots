<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M19 — Scrubbot dispatcher orchestration",
  "currentSprint": "M19-C001 V04 — frozen dispatcher transaction remainder",
  "currentTaskId": "M19-C001-V04",
  "currentTaskTitle": "Close the frozen M19 dispatcher bind, selector-proof, reset-generation and final-commit remainder",
  "workflowState": "AWAITING_AUDIT",
  "requiredActor": "CHATGPT",
  "nextAction": "Independently audit M19-C001 V04 against CHATGPT_AUDIT_CRITERIA_V04.md (impl scripts/gameplay/dispatch/scrubbot_dispatcher.gd; evidence coordination/sessions/M19-C001/CLAUDE_LOG_V04.md; full root suite 3163/3163 green on Godot 4.7.1). Publish CHATGPT_AUDIT_V04.md; per audit policy a narrow auditor-authored validation-only M19 V05 may precede final closure of SB-M19-001..012.",
  "blockers": [],
  "progress": {
    "scopeType": "main+ui",
    "scopeId": "scrubbots-main-ui",
    "completed": 278,
    "total": 719,
    "percent": 38.66
  },
  "lastCompletedTaskId": "M15-C002-V03",
  "lastCompletedTaskTitle": "TargetSelector strict-v2 Variant/re-entry/transactional closure for M19 upstream gate",
  "updatedAt": "2026-09-10T11:35:55Z",
  "updatedBy": "CLAUDE"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M19 — Scrubbot dispatcher orchestration**
- Current sprint: **M19-C001 V04 — frozen dispatcher transaction remainder**
- Current task: **M19-C001-V04 — Close the frozen M19 dispatcher bind, selector-proof, reset-generation and final-commit remainder**
- Workflow: **AWAITING_AUDIT**
- Required actor: **CHATGPT**
- Next action: ChatGPT independently audits M19-C001 V04 against
  `coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V04.md`. Implementation
  in `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`; evidence in
  `coordination/sessions/M19-C001/CLAUDE_LOG_V04.md`; full root suite
  **3163/3163** green on Godot **4.7.1** (IN_PROGRESS pushed before the
  implementation commit). Per audit policy a narrow validation-only M19 V05 may
  precede final closure of SB-M19-001..012.
- Blockers: none.
- M15 status: **M15-C002 V03 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED**. Final audit: `coordination/sessions/M15-C002/CHATGPT_AUDIT_V03.md`.
- M19 status: V02/V03 implementation is preserved. V04 now executes only the remainder frozen by `coordination/sessions/M19-C001/CHATGPT_AUDIT_V03.md`.

## Milestones

- **M02–M14 and FOUNDATION-C001** — audited/closed.
- **M15 — TargetSelector:** M15-C001 and M15-C002 are independently audited/closed. F-M15-STRICT-004/005 are closed.
- **M16–M18** — audited/closed and preserved.
- **M19 — dispatcher orchestration:** **M19-C001 V04 is current**. Frozen remainder covers bind transaction re-entry/reset, selector return + exact reservation proof, immediate reset-generation checks across callback-bearing phases, reset re-entry safety, assign return type, and final add-child coherence before active commit.
- **M20+** — arrival resolution / clearing / scoring / slot progression remains planned and out of scope.

## Active / Waiting

- [~] **M19-C001-V04** — AWAITING_AUDIT, actor CHATGPT. Frozen M19 dispatcher remainder implemented in `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`: bind transaction guard + reset-during-bind (001.D), selector Variant + exact reservation ownership proof (001.E/002.D), generation checks after every callback boundary (003.D), reset re-entry safety (003.E), assign actual-bool gate (002.E), final add-child transaction (001.F/003.F). Adversarial coverage `_run_m19_v04_tests`; full root suite 3163/3163 green. M15 upstream-final and untouched; M20 boundary preserved. No audit verdict claimed by Claude.

## Planned

- [ ] M19-C001 V04 implementation + independent audit.
- [ ] If V04 production correction is clean, auditor-authored validation-only M19 V05 before final task closure, unless independent runtime becomes available.
- [ ] M20 — arrival resolution: BoardState ACTIVE→CLEARED on arrival, reservation resolution, scoring, slot progression, follow-up dispatch.

## Completed

- [x] **FOUNDATION-C001 V01** — `AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED` (impl `a059b85`). Canonical ACTIVE/CLEARED guard on `BoardState.set_cell_state`.
- [x] **M15-C002 V03** — `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED` (impl `9f41866`). TargetSelector dependency/Variant/re-entry/transactional boundary hardening complete; full Claude root run 3024/3024 green.
- [x] Historical M11–M14, M15-C001, M16–M18 strict closures remain accepted.

## Progress

- Main + UI scope: **278 / 719 = 38.66%**.
- Overall (incl. sidecars): **278 / 943 = 29.48%**.
- M15-C002 was a strict overlay over historically checked M15 task rows, so its final closure does not increment progress. M19 task rows remain open until M19 final independent closure.

## History / migration notes

Root `tasks.md` remains the detailed historical/master planning ledger and retains task definitions and history. As of the H!veAI GitHub-first v3 migration, `.hiveai/TASKS.md` is H!veAI's operational current-state authority. If the two disagree about current project state, this file wins. `.hiveai/STATE.json`, `.hiveai/HANDOFF.md`, `.hiveai/PROJECT_DASHBOARD.md`, `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md`, and `coordination/SESSION_INDEX.md` are removed/deprecated as live authority and retained only as historical evidence.
