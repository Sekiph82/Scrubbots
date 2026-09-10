<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M19 — Scrubbot dispatcher orchestration",
  "currentSprint": "M19-C001 V06 — auditor-authored validation-only final gate",
  "currentTaskId": "M19-C001-V06",
  "currentTaskTitle": "Run the auditor-authored validation-only final gate over the V05 dispatcher production blob",
  "workflowState": "CHANGES_REQUIRED",
  "requiredActor": "CLAUDE",
  "nextAction": "Execute coordination/sessions/M19-C001/CHATGPT_PROMPT_V06.md without committed production changes; validate against CHATGPT_AUDIT_CRITERIA_V06.md; write CLAUDE_LOG_V06.md; follow H!veAI IN_PROGRESS -> AWAITING_AUDIT lifecycle. If V06 passes independent ChatGPT audit, close SB-M19-001..012.",
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
  "updatedAt": "2026-09-10T16:27:00Z",
  "updatedBy": "CHATGPT"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M19 — Scrubbot dispatcher orchestration**
- Current sprint: **M19-C001 V06 — auditor-authored validation-only final gate**
- Current task: **M19-C001-V06 — Run the auditor-authored validation-only final gate over the V05 dispatcher production blob**
- Workflow: **CHANGES_REQUIRED**
- Required actor: **CLAUDE**
- Next action: Execute
  `coordination/sessions/M19-C001/CHATGPT_PROMPT_V06.md` with **zero committed production change**, validate against
  `coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V06.md`, write
  `coordination/sessions/M19-C001/CLAUDE_LOG_V06.md`, and follow H!veAI
  `CHANGES_REQUIRED -> IN_PROGRESS -> AWAITING_AUDIT`. If independent V06 audit passes, ChatGPT may close SB-M19-001..012.
- Blockers: none.
- M15 status: **M15-C002 V03 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED**.
- M19 status: V05 production correction is **SOURCE_CORRECTION_ACCEPTED** by `coordination/sessions/M19-C001/CHATGPT_AUDIT_V05.md`. No material new production defect was found. V06 is the required strict-v2 auditor-authored validation stage because V05 changed critical/stateful production and ChatGPT cannot independently execute Godot.
- Process note: V05 corrected the earlier H!veAI local-ordering nonconformance. Its IN_PROGRESS transition was pushed and remote-verified before any V05 production/test edit.

## Milestones

- **M02–M14 and FOUNDATION-C001** — audited/closed.
- **M15 — TargetSelector:** M15-C001 and M15-C002 independently audited/closed. F-M15-STRICT-004/005 closed.
- **M16–M18** — audited/closed and preserved.
- **M19 — dispatcher orchestration:** **M19-C001 V06 is current**. F-M19-STRICT-001..003 have source-accepted corrections pending validation-only V06; F-M19-STRICT-004 is closed/regression-only.
- **M20+** — arrival resolution / clearing / scoring / slot progression remains planned and out of scope.

## Active / Waiting

- [~] **M19-C001-V06** — CHANGES_REQUIRED, actor CLAUDE. Validation-only: lock the V05 dispatcher production blob, add auditor-selected adversarial tests, execute at least two temporary sensitivity mutations then restore, run the full root suite, and hand back AWAITING_AUDIT. Any real production defect discovered in V06 must BLOCK rather than be patched inside V06.

## Planned

- [ ] M19-C001 V06 validation-only implementation + independent final audit.
- [ ] If V06 AUDITED_PASS: close root SB-M19-001..012, update progress, then advance to the next authorized milestone/task.
- [ ] M20 — arrival resolution: BoardState ACTIVE→CLEARED on arrival, reservation resolution, scoring, slot progression, follow-up dispatch.

## Completed

- [x] **FOUNDATION-C001 V01** — `AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED` (impl `a059b85`).
- [x] **M15-C002 V03** — `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED` (impl `9f41866`).
- [x] Historical M11–M14, M15-C001, M16–M18 strict closures remain accepted.
- [x] **M19-C001 V05 production correction** — source-accepted by ChatGPT audit; final task closure intentionally deferred to validation-only V06.

## Progress

- Main + UI scope: **278 / 719 = 38.66%**.
- Overall (incl. sidecars): **278 / 943 = 29.48%**.
- M19 root task rows remain open until the independent V06 final audit. On final closure, expected progress becomes **290 / 719 = 40.33%** main+UI and **290 / 943 = 30.75%** overall.

## History / migration notes

Root `tasks.md` remains the detailed historical/master planning ledger and retains task definitions and history. As of the H!veAI GitHub-first v3 migration, `.hiveai/TASKS.md` is H!veAI's operational current-state authority. If the two disagree about current project state, this file wins. `.hiveai/STATE.json`, `.hiveai/HANDOFF.md`, `.hiveai/PROJECT_DASHBOARD.md`, `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md`, and `coordination/SESSION_INDEX.md` are removed/deprecated as live authority and retained only as historical evidence.
