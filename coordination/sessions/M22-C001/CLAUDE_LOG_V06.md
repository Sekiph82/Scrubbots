# M22-C001 V06 — Final Real-Demo Validation-Only Evidence — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit closed: `coordination/sessions/M22-C001/CHATGPT_AUDIT_V05.md`
Handoff state: `AWAITING_AUDIT`

V06 is **validation-only and production-immutable**. No production `scripts/`/`scenes/`,
historical M21 evidence, or root `TASKS.md` changed. No `BLOCKED` — the real
demo/Button observation matched accepted behavior.

## 1. Commit identities

- **Starting `origin/main` SHA (pre-work):** `6d4639ec1b4e2e19b3047d3efe1fea064cfd3c41`.
- **V06 validation commit SHA:** `4253da04e04af09c46e8b6a56466d2c857bd9a84`
  (`test(M22-C001 V06): real-demo C08 reservation/dispatcher cleanup evidence`) —
  pushed before this log existed.
- **This log** is a separate evidence commit on top of the validation SHA.
- Accepted production baseline: `8ded3580a8eacee1c64364e530142e23d6f115db`.

Sync: fast-forward `1f51701..6d4639e`; clean tree; no force/reset/clean.

## 2. Exact changed files (validation commit 4253da0)

- `tests/m22_v06_real_demo_state_evidence.gd` — NEW validation-only evidence script (only file).

Handoff evidence commit adds `coordination/sessions/M22-C001/CLAUDE_LOG_V06.md`.
Root `TASKS.md` absent from the V06 diff.

## 3. Production byte-identity / historical-immutability proof

```text
$ git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes
(empty — production scripts/ and scenes/ byte-identical to V03 impl 8ded358)

$ git diff --stat 8ded3580... HEAD -- tests/m21_v08_corridor_validation.gd tests/m21_v09_direct_evidence_reconciliation.gd
(empty — historical M21 evidence untouched)

$ git status --short
?? tests/m22_v06_real_demo_state_evidence.gd     (only the new validation script)

$ git diff --check
(clean)
```

## 4. F-M22-V05-EVIDENCE-001 — real-demo C08 cleanup (CLOSED)

Actual `res://scenes/demo/m22_slot_demo.tscn` instantiated in a real `SubViewport`
(1080×2160), 3 layout frames awaited, exactly five real SlotCell/Button instances.

Exact demo-owned authority objects inspected (no rebuilt chain):

- ReservationState = `inst._loop._reservations` (bound inside the demo's `CompleteClearingLoop`)
- dispatcher = `inst._dispatcher`
- AgentLayer = `inst.get_agent_layer()`

Activation path: real laid-out C08 Button — `panel.get_cell(2).pressed.emit()` →
`SlotView.slot_activated` → panel re-emit → `GameplaySlotDemo._on_slot_activated` →
`request_slot(2)` → `inst._loop.activate_slot(...)` → `inst._last_result`.

### Pre-dispatch (exact demo objects)

```text
V06_PRE res_count=0 disp_active=0 agents=0
```

### Real Button result identity

- `owner_id = 0`, `target = 380`, coordinate `(0,19)` (naturally selected), real agent captured.

### In-flight (exact demo objects)

```text
V06_INFLIGHT owner_id=0 target=380
  res.get_owner(380)=0            (== owner_id)
  res.get_target_for_owner(0)=380
  disp.has_owner(0)=true
  disp.get_target_for_owner(0)=380
  disp.agent_matches=true         (== exact real Button agent)
```

### Post authenticated arrival + deferred cleanup (exact demo objects)

Agent driven to completion via its own `advance()` (the accepted arrival path used
by prior tests); the demo loop/dispatcher performed the authenticated arrival +
clear + release.

```text
V06_POST cleared_380=true
  res_count=0/0(baseline) get_owner(380)=-1 res.t4o(owner)=-1
  disp_active=0/0(baseline) has_owner=false disp.t4o(owner)=-1 agent_null=true
  agents=0
```

All M22-V06-020..040 hold on the actual demo transaction: two-way ReservationState
ownership present in flight then absent; dispatcher owner/target/agent present in
flight then absent; target 380 CLEARED; reservation + dispatcher counts back to
baseline; zero ScrubbotAgent remain. This matches the parallel-chain V05 result on
the real demo objects, closing the finding.

## 5. Literal validation commands / results / exits

Run from repo root `C:\Users\sekip\Desktop\ScrubBots`.

| # | Literal command | Result | Exit |
|---|-----------------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4798, Failures: 0, ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m22_v06_real_demo_state_evidence.gd` | `M22 V06 real-demo state evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | `M22 V05 final state evidence: PASS` | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | `M22 V04 final evidence: PASS` | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | `M22 V03 connector evidence: PASS` | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd` | `M22 railroad responsive smoke: PASS` | 0 |
| 8 | `godot --headless --path . -s res://tests/m22_responsive_smoke.gd` | `M22 responsive/safe-area smoke: PASS` | 0 |
| 9 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | `M21 real-art smoke: PASS` (full 400-cell clear) | 0 |
| 10 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | `M21 V10 final reservation evidence: PASS` | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | `M20 queue_free smoke: PASS` | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd` | `M20 V04 lifecycle smoke: PASS` | 0 |
| 13 | `godot --headless --path . -s res://tests/m20_v05_lifecycle_smoke.gd` | `M20 V05 lifecycle smoke: PASS` | 0 |
| 14 | `godot --headless --path . -s res://tests/m20_v07_lifecycle_smoke.gd` | `M20 V07 lifecycle smoke: PASS` | 0 |
| 15 | `godot --headless --path . -s res://tests/m20_v08_lifecycle_smoke.gd` | `M20 V08 lifecycle smoke: PASS` | 0 |
| 16 | `godot --headless --path . -s res://tests/m20_v09_lifecycle_smoke.gd` | `M20 V09 lifecycle smoke: PASS` | 0 |
| 17 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | `M20 V10 lifecycle smoke: PASS` | 0 |
| 18 | `git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes` | empty (byte-identical) | 0 |
| 19 | `git diff --check` | clean | 0 |

Strict TargetSelector / ReservationState / ScrubbotDispatcher / ScrubbotAgent
regressions run inside item 2 (root suite, 4798 checks, all PASS).

## 6. Historical-only failures (classified; unchanged)

`tests/m21_v08_corridor_validation.gd` (C/043, C/047) and
`tests/m21_v09_direct_evidence_reconciliation.gd` (B) still fail only on the
deliberately superseded exact adjacent-ring / above-board-exterior assertions
(owner ADR-028). Left byte-untouched.

## 7. Statements

- `Magnific/image-generation credits spent = 0`.
- Production source/scenes byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.
- Root `TASKS.md` not modified (absent from the V06 diff).
- No audit verdict authored; no PASS claimed; no M23 work.
