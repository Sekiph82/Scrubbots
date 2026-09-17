# M22-C001 V05 — Final Validation-Only Direct-State Evidence — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit closed: `coordination/sessions/M22-C001/CHATGPT_AUDIT_V04.md`
Handoff state: `AWAITING_AUDIT`

V05 is **validation-only and production-immutable**. No production `scripts/`/`scenes/`,
historical M21 evidence, or root `TASKS.md` changed. No `BLOCKED` condition —
direct observation matched accepted V03 behavior.

## 1. Commit identities

- **Starting `origin/main` SHA (pre-work):** `2ccc9145701bf930e60cbb780488ede32f33a80c`.
- **V05 validation commit SHA:** `b707fe85413768bd562c10a5c1887aee3e1f75a6`
  (`test(M22-C001 V05): final validation-only direct-state evidence`) — pushed
  before this log existed.
- **This log** is a separate evidence commit on top of the validation SHA.
- Accepted production baseline: `8ded3580a8eacee1c64364e530142e23d6f115db`.

Sync: fast-forward `7a39f28..2ccc914`; clean tree; no force/reset/clean.

## 2. Exact changed files (validation commit b707fe8)

- `tests/m22_v05_final_state_evidence.gd` — NEW validation-only evidence script (only file).

Handoff evidence commit adds `coordination/sessions/M22-C001/CLAUDE_LOG_V05.md`.
Root `TASKS.md` absent from the V05 diff.

## 3. Production byte-identity proof (M22-V05-005 / M22-V05-068)

```text
$ git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes
(empty — production scripts/ and scenes/ byte-identical to V03 impl 8ded358)

$ git status --short
?? tests/m22_v05_final_state_evidence.gd     (only the new validation script)

$ git diff --check
(clean)
```

## 4. F-M22-V04-EVIDENCE-001 — C08 authenticated-arrival reservation/dispatcher cleanup

Real production authority chain (same classes/level/`CompleteClearingLoop.activate_slot`
path a real SlotCell Button triggers; production exposes no ReservationState accessor
and is immutable, so the chain is rebuilt on the real Hazard Bot level). Slot 2 (C08),
below-board start `(9.222222, 24.0)` → railroad → TargetSelector picks `380/(0,19)`.

Pre-dispatch baseline: `reservation_count = 0`, `dispatcher_active = 0`.

In-flight (direct, both directions):

```text
A_INFLIGHT owner_id=0 res.get_owner(380)=0 res.get_target_for_owner(owner)=380
           disp.has_owner=true disp.get_target_for_owner(owner)=380 disp.agent_matches=true
```

After authenticated arrival + deferred cleanup:

```text
A_POST cleared_380=true res_count=0/0(baseline) get_owner(380)=-1 res.t4o(owner)=-1
       disp_active=0/0(baseline) has_owner=false disp.t4o(owner)=-1 agent_null=true agents=0
```

All M22-V05-010..016 observations hold (reservation both-direction + dispatcher
map + agent-map cleanup + board clear + zero orphan agents).

## 5. F-M22-V04-EVIDENCE-002 — all-aligned-blocked reverse-map / dispatcher-map absence

Isolated one-candidate fixture (20×20, all color 1 ACTIVE except color-0 target at
(10,10)=index 210). `pending_owner = dispatcher.peek_next_owner_id() = 0`.

```text
B_PRE  pending_owner=0 res.get_owner(tgt)=-1 res.t4o(pending)=-1
       disp.has(pending)=false disp.t4o(pending)=-1 res_count=0 disp_active=0

B_POST result_success=false reason=NO_REACHABLE_TARGET
       res.get_owner(tgt)=-1 res.t4o(pending)=-1
       disp.has(pending)=false disp.t4o(pending)=-1 disp.agent(pending)_null=true
       res_count=0 disp_active=0 pending_after=0 agents=0
       board_identical=true target_active=true
```

All M22-V05-020..027 hold: both reservation directions absent pre/post; dispatcher
has/target/agent absent; counts unchanged; **owner-id counter did not advance**
(`peek_next_owner_id` stays 0) on `NO_REACHABLE_TARGET`; BoardState identical;
target remains ACTIVE; no alternate clear; no agent spawned.

## 6. F-M22-V04-EVIDENCE-003 — shortest / tie-break candidate measurement

Validation helper computes each aligned-side total = connector + `ScrubRailGeometry.
rail_path` dist + final approach, with legality from authoritative
`ProductionAccessQuery.is_segment_traversable` (no production policy copy).

**Shortest** (board 20×20, start `(18,21)`, target `380/(0,19)`):

```text
  candidate BOTTOM: len=22.0000
  candidate LEFT:   len=28.0000
  candidate RIGHT:  ILLEGAL
  candidate TOP:    ILLEGAL
  production_chosen=BOTTOM  expected(min+tiebreak)=BOTTOM
  route=[(18.0,21.0), (18.0,22.5), (0.5,22.5), (0.5,19.5)]
```

≥2 legal candidates; BOTTOM uniquely shortest (22.0 < 28.0); production selects BOTTOM.

**Equal-distance tie-break** (board 21×21, start `(10.5,22)`, target `(10,10)`, row 10
cleared except target):

```text
  lengths BOTTOM=ILLEGAL LEFT=40.5000 RIGHT=40.5000 TOP=ILLEGAL
  production_chosen=LEFT  expected(min+tiebreak)=LEFT
  route=[(10.5,22.0), (10.5,23.5), (-2.5,23.5), (-2.5,10.5), (10.5,10.5)]
```

LEFT and RIGHT both legal and exactly equal (40.5000, within 0.0001); higher/lower
priority BOTTOM and TOP are ILLEGAL (cannot outrank); production selects LEFT per
`BOTTOM → LEFT → RIGHT → TOP`. All M22-V05-030..045 hold.

## 7. Direct all-blocked routing mutation fingerprint (M22-V05-050..052)

```text
E_FINGERPRINT cells=400
  fp_before=b9ad9bbb07a72104fa44dc50618b9102100581f0d6866cd59d549ab5b1749ff4
  fp_after =b9ad9bbb07a72104fa44dc50618b9102100581f0d6866cd59d549ab5b1749ff4
  success=false reason=NO_ROUTE retained_target=210
```

Full BoardState state-vector SHA-256 identical before/after the direct
`compute_route()` all-blocked call; result `NO_ROUTE`, retained target 210.

## 8. Literal validation commands / results / exits (M22-V05-069)

Run from repo root `C:\Users\sekip\Desktop\ScrubBots`.

| # | Literal command | Result | Exit |
|---|-----------------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4798, Failures: 0, ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m22_v05_final_state_evidence.gd` | `M22 V05 final state evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | `M22 V04 final evidence: PASS` | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | `M22 V03 connector evidence: PASS` | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd` | `M22 railroad responsive smoke: PASS` | 0 |
| 7 | `godot --headless --path . -s res://tests/m22_responsive_smoke.gd` | `M22 responsive/safe-area smoke: PASS` | 0 |
| 8 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | `M21 real-art smoke: PASS` (full 400-cell clear) | 0 |
| 9 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | `M21 V10 final reservation evidence: PASS` | 0 |
| 10 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | `M20 queue_free smoke: PASS` | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd` | `M20 V04 lifecycle smoke: PASS` | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_v05_lifecycle_smoke.gd` | `M20 V05 lifecycle smoke: PASS` | 0 |
| 13 | `godot --headless --path . -s res://tests/m20_v07_lifecycle_smoke.gd` | `M20 V07 lifecycle smoke: PASS` | 0 |
| 14 | `godot --headless --path . -s res://tests/m20_v08_lifecycle_smoke.gd` | `M20 V08 lifecycle smoke: PASS` | 0 |
| 15 | `godot --headless --path . -s res://tests/m20_v09_lifecycle_smoke.gd` | `M20 V09 lifecycle smoke: PASS` | 0 |
| 16 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | `M20 V10 lifecycle smoke: PASS` | 0 |
| 17 | `git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes` | empty (byte-identical) | 0 |
| 18 | `git diff --check` | clean | 0 |

Strict TargetSelector / ReservationState / ScrubbotDispatcher / ScrubbotAgent
regressions run inside item 2 (root suite, 4798 checks, all PASS). Headless M22
demo boots with zero SCRIPT/Parse errors inside items 3–6 (V05/V04/V03/responsive
scripts load and build the demo/chain; the only "SCRIPT ERROR"/"parse error" lines
in logs are `ok:` assertion strings).

## 9. Historical-only failures (classified; unchanged)

`tests/m21_v08_corridor_validation.gd` (C/043, C/047) and
`tests/m21_v09_direct_evidence_reconciliation.gd` (B) still fail only on the
deliberately superseded exact adjacent-ring / above-board-exterior assertions
(owner ADR-028). Left byte-untouched; safety intent re-proven by Railroad V1 tests.

## 10. Statements

- `Magnific/image-generation credits spent = 0`.
- Production source/scenes byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.
- Root `TASKS.md` not modified (absent from the V05 diff).
- No audit verdict authored; no PASS claimed; no M23 work.
