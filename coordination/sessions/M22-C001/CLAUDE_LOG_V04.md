# M22-C001 V04 — Final Validation-Only Railroad Evidence — Claude Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (unchanged; not installed/upgraded)
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
Audit closed: `coordination/sessions/M22-C001/CHATGPT_AUDIT_V03.md`
Handoff state: `AWAITING_AUDIT`

V04 is **validation-only and production-immutable**. No production source/scene,
historical M21 test/audit/log, or root `TASKS.md` was modified. No `BLOCKED`
condition was encountered — direct observation matched accepted V03 behavior.

## 1. Commit identities

- **Starting `origin/main` SHA (pre-work):** `5e9dc848536e74f7e40735df2065f425a688cffe`
  (`prompt(M22-C001 V04): final Railroad validation-only evidence closure`).
- **V04 validation commit SHA:** `325232900ae8676c65617250f7f045f00292863d`
  (`test(M22-C001 V04): final validation-only Railroad evidence`) — pushed to
  `origin/main` BEFORE this log existed (non-circular).
- **This log** is added in a separate evidence commit on top of the validation SHA.
- Accepted V03 implementation commit (production baseline): `8ded3580a8eacee1c64364e530142e23d6f115db`.

Sync: fast-forward `60336c4..5e9dc84`; clean tree; no force/reset/clean.

## 2. Exact changed files (validation commit 3252329)

- `tests/m22_v04_final_evidence.gd` — NEW validation-only evidence script (only file).

Handoff evidence commit adds `coordination/sessions/M22-C001/CLAUDE_LOG_V04.md`.
No other file changed. Root `TASKS.md` absent from the V04 diff.

## 3. Production byte-identity proof (M22-V04-005 / M22-V04-072)

```text
$ git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes
(empty — production scripts/ and scenes/ are byte-identical to V03 impl 8ded358)

$ git status --short
?? tests/m22_v04_final_evidence.gd     (only the new validation script)

$ git diff --check
(clean)
```

`ProductionRoutingSystem` still contains no `_is_ring` / adjacent-ring seeding or
search (removed in V03 and unchanged); every outside start uses Railroad V1.
TargetSelector / ReservationState / CompleteClearingLoop / single-source geometry
+ view / `bind_colors` fail-closed all unchanged and green (root suite).

## 4. F-M22-V03-EVIDENCE-001 — five real post-layout global anchors + mapped starts

Real `m22_slot_demo.tscn` in a real `SubViewport` (1080×2160), 3 layout frames
awaited; direct runtime observation (global anchors NOT inferred from mapped):

```text
V04_ANCHORS viewport=(1080, 2160)
  SLOT 0 global_anchor=(120.0, 984.0) mapped_start=(1.666667, 24.0)
  SLOT 1 global_anchor=(256.0, 984.0) mapped_start=(5.444445, 24.0)
  SLOT 2 global_anchor=(392.0, 984.0) mapped_start=(9.222222, 24.0)
  SLOT 3 global_anchor=(528.0, 984.0) mapped_start=(13.0, 24.0)
  SLOT 4 global_anchor=(664.0, 984.0) mapped_start=(16.77778, 24.0)
```

Five mapped starts distinct and one-to-one with slot ids (asserted).

## 5. F...EVIDENCE-004 (part) — exact C08 transaction + relayout

Fresh real C08 (slot 2) Button, post-layout:

```text
V04_C08 global_anchor=(392.0, 984.0) mapped_start=(9.222222, 24.0)
        route=[(9.222222, 24.0), (9.222222, 22.5), (0.5, 22.5), (0.5, 19.5)]
```

- target 380 / (0,19) arises naturally (asserted).
- route point 0 == independently mapped slot-2 anchor `(9.222222, 24.0)`.
- route point 1 == `bottom_entry(9.222222)` = `(9.222222, 22.5)`; connector non-zero.
- rail-domain clean (connector → BOTTOM centreline → aligned exit); final segment
  orthogonal to `(0.5, 19.5)`.
- authenticated arrival: after driving the agent to arrival, `BoardState[380] ==
  CLEARED`, dispatcher active-assignment count returned to its pre-dispatch value,
  and zero ScrubbotAgent remain in the AgentLayer after deferred cleanup.

Second viewport / re-layout (1290×2796, panel moved +（53,41）):

```text
V04_RELAYOUT viewport=(1290, 2796)
  global_before=(392.0, 984.0)  global_after=(445.0, 1025.0)
  mapped_after=(10.69444, 25.13889)  route0=(10.69444, 25.13889)
```

Route point 0 follows the NEW measured anchor (`≠` the prior anchor) — proves no
stale cached connector geometry; C08 still naturally selects 380.

## 6. F-M22-V03-EVIDENCE-002 — all-aligned-blocked full-lifecycle, no side effects

Validation-only fixture (20×20): every cell color 1 ACTIVE except an ISOLATED
color-0 target at `(10,10)` (index 210). Slot 0 (color 0) therefore has exactly one
candidate, whose four aligned Railroad approaches are all blocked by non-target
ACTIVE cells. Driven through the REAL chain: `ColorCandidateIndex` → `TargetSelector`
→ `ProductionTargetAccess`/`ProductionRoutingSystem`/`ProductionAccessQuery` →
`ScrubbotDispatcher` → `CompleteClearingLoop.activate_slot(0, (10,21), 6.0)`.

Pre-activation: target ACTIVE, color 0, unreserved; directly not targetable
(`_rail(...)` → `NO_ROUTE`). Post-activation (2 frames):

```text
V04_ALLBLOCKED target_idx=210 coord=(10,10) color=0
  result_success=false  reason=NO_REACHABLE_TARGET
  res_count=0  disp_active=0  active_cells_before=400  after=400
```

Directly proven: activation fails cleanly (no successful assignment); **no agent
spawned** (AgentLayer empty after deferred cleanup); ReservationState count
unchanged at 0 with no `target->owner` mapping (`get_owner(210) == -1`); dispatcher
active-assignment count unchanged at 0; BoardState snapshot **identical**
before/after (full per-cell state array equal); ACTIVE count 400→400 (no clear, no
silent substitution); the blocked target itself remains ACTIVE. No production
mismatch — not `BLOCKED`. (The loop reports `NO_REACHABLE_TARGET`; the routing
helper reports `NO_ROUTE`; both are the correct fail-closed verdicts at their
respective layers.)

## 7. F-M22-V03-EVIDENCE-004 — exact runtime route arrays

All printed directly from runtime (`_all_active_board` fixtures unless noted):

```text
far-left/bottom   board=20x20 start=(10,21) target=380/(0,19) exit=BOTTOM
  [(10.0,21.0), (10.0,22.5), (0.5,22.5), (0.5,19.5)]

far-right/top     board=20x20 start=(10,21) target=(19,0) chosen_exit=RIGHT
  [(10.0,21.0), (10.0,22.5), (22.5,22.5), (22.5,0.5), (19.5,0.5)]
  (connector (10,21)->(10,22.5); BOTTOM rail ->(22.5,22.5) BR corner; RIGHT rail
   ->(22.5,0.5); orthogonal approach ->(19.5,0.5))

two-side fallback board=20x20 start=(10,21) target=(0,5) same_target_retained=true
  [(10.0,21.0), (10.0,22.5), (-2.5,22.5), (-2.5,5.5), (0.5,5.5)]
  (BOTTOM entry -> BL corner (-2.5,22.5) -> LEFT rail -> orthogonal approach)

shortest          board=20x20 start=(18,21) target=380/(0,19) chosen_exit=BOTTOM
  [(18.0,21.0), (18.0,22.5), (0.5,22.5), (0.5,19.5)]

tie-break         board=21x21 start=(10.5,22) target=(10,10) competing=LEFT,RIGHT
                  chosen=LEFT  (BOTTOM->LEFT->RIGHT->TOP)
  [(10.5,22.0), (10.5,23.5), (-2.5,23.5), (-2.5,10.5), (10.5,10.5)]

all-blocked       board=20x20 target_idx=210/(10,10) success=false
                  reason=NO_ROUTE retained_target=210   (zero BoardState mutation)

rectangular       board=40x24 start=(20,25) target=(0,23)
  [(20.0,25.0), (20.0,26.5), (0.5,26.5), (0.5,23.5)]

59x59             board=59x59 start=(29,60) target=(0,58)
  [(29.0,60.0), (29.0,61.5), (0.5,61.5), (0.5,58.5)]
```

Every successful route above passed `_assert_rail_domain` (connector → canonical
TOP/BOTTOM/LEFT/RIGHT centreline segments with side changes only at exact corners →
one orthogonal aligned final approach). far-right/top and tie-break traverse two
rail sides through an exact corner; rectangular (40×24) and 59×59 are inside the
20..59 production envelope and domain-clean.

## 8. F-M22-V03-EVIDENCE-003 — literal validation commands / results / exits

All run from repo root `C:\Users\sekip\Desktop\ScrubBots`. Engine unchanged.

| # | Literal command | Result | Exit |
|---|-----------------|--------|------|
| 1 | `godot --version` | `4.7.2.stable.official.ed1daf0bf` | 0 |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **Total checks: 4798, Failures: 0, ALL PASS** | 0 |
| 3 | `godot --headless --path . -s res://tests/m22_v04_final_evidence.gd` | `M22 V04 final evidence: PASS` | 0 |
| 4 | `godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd` | `M22 V03 connector evidence: PASS` | 0 |
| 5 | `godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd` | `M22 railroad responsive smoke: PASS` | 0 |
| 6 | `godot --headless --path . -s res://tests/m22_responsive_smoke.gd` | `M22 responsive/safe-area smoke: PASS` | 0 |
| 7 | `godot --headless --path . -s res://tests/m21_real_art_smoke.gd` | `M21 real-art smoke: PASS` (full 400-cell clear) | 0 |
| 8 | `godot --headless --path . -s res://tests/m21_v10_final_reservation_evidence.gd` | `M21 V10 final reservation evidence: PASS` | 0 |
| 9 | `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` | `M20 queue_free smoke: PASS` | 0 |
| 10 | `godot --headless --path . -s res://tests/m20_v04_lifecycle_smoke.gd` | `M20 V04 lifecycle smoke: PASS` | 0 |
| 11 | `godot --headless --path . -s res://tests/m20_v05_lifecycle_smoke.gd` | `M20 V05 lifecycle smoke: PASS` | 0 |
| 12 | `godot --headless --path . -s res://tests/m20_v07_lifecycle_smoke.gd` | `M20 V07 lifecycle smoke: PASS` | 0 |
| 13 | `godot --headless --path . -s res://tests/m20_v08_lifecycle_smoke.gd` | `M20 V08 lifecycle smoke: PASS` | 0 |
| 14 | `godot --headless --path . -s res://tests/m20_v09_lifecycle_smoke.gd` | `M20 V09 lifecycle smoke: PASS` | 0 |
| 15 | `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` | `M20 V10 lifecycle smoke: PASS` | 0 |
| 16 | `git diff --stat 8ded3580a8eacee1c64364e530142e23d6f115db HEAD -- scripts scenes` | empty (production byte-identical) | 0 |
| 17 | `git diff --check` | clean | 0 |

- **Strict TargetSelector / ReservationState / ScrubbotDispatcher / ScrubbotAgent
  regressions** run inside item 2 (root suite, 4798 checks, all PASS) — e.g. the
  M15 reservation, M19 dispatcher (incl. production + strict-v2/v3), M18 agent, and
  M20 clearing sections.
- **Headless M22 demo boot (M22-V04-070):** items 3/4/5 load and build
  `m22_slot_demo.tscn` in real SubViewports with **zero SCRIPT/Parse errors** (the
  only lines matching "SCRIPT ERROR"/"parse error" in logs are `ok:` assertion
  strings such as "demo scene loads (no parse error)").

## 9. Historical-only failures (classified; unchanged)

Not run as current acceptance; left byte-untouched (M22-V04-006):

- `tests/m21_v08_corridor_validation.gd` — FAIL: `C/043` (above-origin far-right
  top) and `C/047` (corner uses left+top exterior sides) — superseded above-board
  exterior-ring assertions.
- `tests/m21_v09_direct_evidence_reconciliation.gd` — FAIL: `B` (route crosses
  adjacent `x=-1/x=W` ring cell) — superseded exact-ring assertion.

Their failing assertions encode only the deliberately superseded M21 adjacent ring
(owner ADR-028). Safety intent re-proven by current Railroad V1 tests.

## 10. Statements

- `Magnific/image-generation credits spent = 0`.
- Production source/scenes byte-identical to `8ded3580a8eacee1c64364e530142e23d6f115db`.
- Root `TASKS.md` not modified (absent from the V04 diff).
- No audit verdict authored; no PASS claimed; no M23 work.
