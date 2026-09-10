<!-- HIVEAI_TRACKER_V3_START
{
  "schema": "hiveai-task-tracker/v3",
  "projectKey": "scrubbots",
  "currentMilestone": "M19 — Scrubbot dispatcher orchestration",
  "currentSprint": "M19-C001 V05 — transaction boundary closure",
  "currentTaskId": "M19-C001-V05",
  "currentTaskTitle": "Close the remaining M19 callback-order and direct-observability gaps after V04",
  "workflowState": "AWAITING_AUDIT",
  "requiredActor": "CHATGPT",
  "nextAction": "Independently audit M19-C001 V05 against CHATGPT_AUDIT_CRITERIA_V05.md (impl scripts/gameplay/dispatch/scrubbot_dispatcher.gd; evidence coordination/sessions/M19-C001/CLAUDE_LOG_V05.md; full root suite 3203/3203 green on Godot 4.7.1, IN_PROGRESS pushed+verified before any edit). Publish CHATGPT_AUDIT_V05.md; per audit policy issue a narrow validation-only V06 before final closure of SB-M19-001..012.",
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
  "updatedAt": "2026-09-10T13:45:41Z",
  "updatedBy": "CLAUDE"
}
HIVEAI_TRACKER_V3_END -->

# ScrubBots H!veAI Tracker

## Current

- Current milestone: **M19 — Scrubbot dispatcher orchestration**
- Current sprint: **M19-C001 V05 — transaction boundary closure**
- Current task: **M19-C001-V05 — Close the remaining M19 callback-order and direct-observability gaps after V04**
- Workflow: **AWAITING_AUDIT**
- Required actor: **CHATGPT**
- Next action: ChatGPT independently audits M19-C001 V05 against
  `coordination/sessions/M19-C001/CHATGPT_AUDIT_CRITERIA_V05.md`. Implementation in
  `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`; evidence in
  `coordination/sessions/M19-C001/CLAUDE_LOG_V05.md`; full root suite **3203/3203**
  green on Godot **4.7.1**; IN_PROGRESS pushed+verified before any edit (V04
  ordering nonconformance corrected). Per audit policy a narrow validation-only V06
  precedes final closure of SB-M19-001..012.
- Blockers: none.
- M15 status: **M15-C002 V03 AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED**.
- M19 status: V02/V03/V04 accepted hardening is preserved. V04 independent audit returned **CHANGES_REQUIRED / SAME_FROZEN_SET / V05_REQUIRED**. Remaining work is limited to the callback-order/direct-observability remainder recorded in `coordination/sessions/M19-C001/CHATGPT_AUDIT_V04.md`.
- Process note: V04 durable commit order was correct, but Claude disclosed local dispatcher edits before the IN_PROGRESS push. V05 must not repeat this H!veAI process nonconformance.

## Milestones

- **M02–M14 and FOUNDATION-C001** — audited/closed.
- **M15 — TargetSelector:** M15-C001 and M15-C002 independently audited/closed. F-M15-STRICT-004/005 closed.
- **M16–M18** — audited/closed and preserved.
- **M19 — dispatcher orchestration:** **M19-C001 V05 is current**. Frozen F-M19-STRICT-001..003 remain open only for the V04 audit remainder; F-M19-STRICT-004 remains closed/regression-only.
- **M20+** — arrival resolution / clearing / scoring / slot progression remains planned and out of scope.

## Active / Waiting

- [~] **M19-C001-V05** — AWAITING_AUDIT, actor CHATGPT. Closed in `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`: pending-owner baseline/post-`-1` callback bracketing (001.G/003.G/003.H); reset-generation precedence over ownability/postcondition verdicts (003.I); malformed ownership-proof + real M15-C002 rebind integration evidence. Adversarial coverage `_run_m19_v05_tests` (sensitivity-proven via two recorded/restored mutations); full root suite 3203/3203 green. All accepted V04 behavior preserved. IN_PROGRESS pushed+verified before any edit. No audit verdict claimed by Claude.

## Planned

- [ ] M19-C001 V05 implementation + independent audit.
- [ ] If V05 source/test audit is clean, auditor-authored **validation-only M19 V06** before final closure of SB-M19-001..012, because V05 changes production and ChatGPT cannot independently execute Godot.
- [ ] M20 — arrival resolution: BoardState ACTIVE→CLEARED on arrival, reservation resolution, scoring, slot progression, follow-up dispatch.

## Completed

- [x] **FOUNDATION-C001 V01** — `AUDITED_PASS / FOUNDATION-STRICT-001 CLOSED` (impl `a059b85`).
- [x] **M15-C002 V03** — `AUDITED_PASS / STRICT_V2_FINAL_CLOSURE / UPSTREAM_GATE_CLOSED` (impl `9f41866`).
- [x] Historical M11–M14, M15-C001, M16–M18 strict closures remain accepted.

## Progress

- Main + UI scope: **278 / 719 = 38.66%**.
- Overall (incl. sidecars): **278 / 943 = 29.48%**.
- M19 root task rows remain open until final independent M19 closure. No progress increment is recorded for V04/V05 correction work.

## History / migration notes

Root `tasks.md` remains the detailed historical/master planning ledger and retains task definitions and history. As of the H!veAI GitHub-first v3 migration, `.hiveai/TASKS.md` is H!veAI's operational current-state authority. If the two disagree about current project state, this file wins. `.hiveai/STATE.json`, `.hiveai/HANDOFF.md`, `.hiveai/PROJECT_DASHBOARD.md`, `.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`, `.hiveai/PROGRESS_SNAPSHOT.md`, and `coordination/SESSION_INDEX.md` are removed/deprecated as live authority and retained only as historical evidence.
