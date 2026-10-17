# CLAUDE LOG — M46-RM-003 FTUE moving-robot coach copy (V01)

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM003_FTUE_MOVING_COACH_PERFORMANCE_PROMPT_V01.md
- Criteria: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_RM003_FTUE_MOVING_COACH_AUDIT_CRITERIA_V01.md
- Master: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_MASTER_REMEDIATION_V02.md
- Frozen finding: V2-P1 in https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M46-PERFORMANCE-C001/CHATGPT_M46_FULL_SURFACE_REAUDIT_V02.md
- Source/test commit: `19c3240a23c1c16dd1e51da4001f8de85bcaf770` (https://github.com/Sekiph82/Scrubbots/commit/19c3240a23c1c16dd1e51da4001f8de85bcaf770). Base: `b9cc502c` (ChatGPT V02 tracker/prompts) over test tree `0fa6ee24` and R07 production `76e4aff8`.
- Evidence class: Claude-run local Godot 4.7.2 (E1/E2). Not a ChatGPT audit. **ZERO GitHub Actions**; workflow job guards untouched (`if: ${{ false }}`). Root `TASKS.md` not edited.
- Status: **AWAITING_MASTER_RM004** (master continues with RM004; final joint handoff in `CLAUDE_LOG_M46_RM004_V01.md`).

## 1. Root cause (confirmed) and change

`main.refresh_coachmark` rebuilds the L2 tip copy at most every `COACH_COPY_REFRESH_MS = 2000` (the 200 ms `COACH_TICK_S` timer only re-shows the cached copy). `FtueDirector.step_copy` asked `host.booster_legality_offframe(id)` per advertised booster. With robots in flight `needs_offframe_proof` is false, so it fell to `booster_legality(SELECTOR)` → `eligible_safe_batches()`: for every remaining batch a reordered scratch supply + scratch slots + placement were built even though the in-flight shortcut then answers PROGRESSABLE. The tooltip needs only yes/no.

Change (3 production files, +22/−4):
- `production_gameplay_host.gd`: `booster_legality(id, list_targets := true)` and `booster_legality_offframe(id, list_targets := true)`. With `list_targets == false`:
  - Selector → `adapter.has_eligible_safe_batch()` (same proof, stops at the first safe batch; shares the cache, budget and resume offset); reason `"" / proof_timeout / not_eligible` exactly as `_selector_legality` would give for an empty / partial-empty / non-empty list; `targets: []`.
  - Tornado → `adapter.has_present_color()` (see below); reason `color_not_present` as before.
  - +1 Slot and Random unchanged (Random has no list; its in-flight proof is ~1.5 ms on L2).
  - All gates before the switch are unchanged (economy/adapter missing, terminal, `_proof_closed` → `exiting`, still-moment → `checking` + worker, never a synchronous still-moment proof when a worker can start).
- `production_booster_adapter.gd`: `has_present_color()` = `_board.get_cell_states_copy().has(ACTIVE)`. `present_colors()` is non-empty exactly when some cell is ACTIVE (VOID cells are CLEARED), so the verdict is identical; native byte search instead of a 3481-cell script loop.
- `ftue_director.gd`: `step_copy` passes `false`. The copy strings, the "not now" rule and the "checking → no suffix" rule are unchanged.

The popup (`AcquisitionFlow._refresh_booster` / `booster_model`), the rewarded-grant completion (`_apply_reward_outcome`), `request_booster` and `execute_booster` all still call the list form (default `true`), so chips are still the proven list and every purchase still runs the per-target proof (`BoosterService.apply_selector` → `is_batch_eligible`).

## 2. Sibling call-site sweep (RM003-01)

| Call site | Needs | Disposition |
|---|---|---|
| `main.gd:527` `refresh_coachmark` → `ftue.step_copy` | yes/no | **changed** (via step_copy) |
| `ftue_director.gd:137` `step_copy` L2 A (+1, Selector) | yes/no | **changed**: Selector was the 23–28 ms hitch |
| `ftue_director.gd:137` `step_copy` L2 B (Random, Tornado) | yes/no | **changed** for Tornado: measured 2.7 ms per copy on L2 (3481-cell script loop at 59x59) — the second repeated full scan in the same copy; Random unchanged (no list, ~1.5 ms) |
| `acquisition_flow.gd:324` `_refresh_booster` (popup) | full chips | unchanged; runs on open / state change / settle, not periodically |
| `acquisition_flow.gd:308` `booster_model` default | full | unchanged |
| `acquisition_flow.gd:671` `_apply_reward_outcome` | exact proof before use | unchanged |
| `host.request_booster` (HUD tap / hold) | exact proof | unchanged |
| `host.execute_booster` → `BoosterService` | per-target proof | unchanged |
| `host.booster_states()` (HUD) | inventory / capacity only, O(4) | not a proof, unchanged |
| `host.next_start_prover` (Need-a-Hand) | owner-locked unbudgeted | **not touched** (owner reservation) |
| `run_offframe` (worker) | full list | unchanged (off the main thread) |

No other periodic main-thread caller of `booster_legality` exists in production scripts (grep of `booster_legality|eligible_safe_batches|has_eligible_safe_batch|is_batch_eligible|step_copy(`).

## 3. Evidence (local Godot 4.7.2, Windows desktop)

Command: `godot --headless --path . -s res://tests/m46_rm003_ftue_coach_performance.gd` → `M46 RM003 FTUE COACH: PASS (4 case groups)`, exit 0, 77 s. Contention: no other Godot engine process was running (only `godot-ai` MCP helper processes).

### C1 real L2 app, `main.refresh_coachmark` (RM003-02, RM003-06)
20 warm samples after 3 warm-ups. Every sample: robots in flight and an empty slot (23/23), the copy actually rebuilt through `main.refresh_coachmark` (timestamp + step id), body == oracle built from the FULL list legality of the same state (20/20), no worker started.

| Step | New copy (mean / p95 / p99 / max) | Old full-list path, same state | Frame incl. copy (max) |
|---|---|---|---|
| L2 A (+1, Selector) | 1.76 / 2.75 / 3.04 / 3.04 ms | 34.82 / 55.28 / 85.15 / 85.15 ms | 5.56 ms |
| L2 B (Random, Tornado) | 1.65 / 2.07 / 2.07 / 2.07 ms | 4.66 / 5.71 / 6.00 / 6.00 ms | 2.60 ms |

Per booster hint: +1 0.04, Selector 1.38, Random 1.53, Tornado 0.04 ms mean. (Earlier runs in this cycle: A 1.20–1.42 ms vs old 22.6–22.9 ms; B 4.26–4.59 ms *before* the Tornado change, failing the 4 ms mean — this is what surfaced the Tornado sibling.)
Still moment, step B: copy says nothing for Random while "checking" (worker running, no main-thread proof); after the settle the copy == oracle from the cached verdict, still no main-thread Random proof.

### C2 truth equivalence, hint == non-empty full list (RM003-03)
Selector and Tornado hint vs the list form on the same state, verdict + reason + no targets:
- L1 still, real classifier, both unbudgeted: start (19 listed), cached partial-empty verdict (both `proof_timeout`), cached proven verdict, empty supply (test fixture; both `not_eligible`), 5 slots full, +1 → 6 slots with one empty (14 listed), 6 slots full.
- missing adapter (`economy_unavailable`), `_proof_closed` (`exiting`, no worker), L1 played to WON (`terminal`, and `has_present_color() == false == present_colors().is_empty()`).
- 59x59 stripes and 59x59 VOID-pocket boards with robots in flight (117 / 104 listed), 59x59 slots full while moving.
- 59x59 moving cost: hint 3.54 mean / 6.64 p95 / 6.85 max ms vs full list 250.89 / 330.83 / 400.32 ms.
All 12 state classes reached with the expected verdict.

### C3 popup and spending (RM003-04)
L2 still: the hint said `checking`; after the worker the real Selector popup shows 12 chips (= `MAX_TARGET_CHIPS`), each a proven id, equal to the first ids of the proven list; the hint agrees. `execute_booster(selector, "NO_SUCH_BATCH")` and `(selector, null)` refused, charge and SB unchanged; a real chip id executes, charge −1 once, SB unchanged. (The L2 still list hit the 5 s cap — partial — so an unlisted id is refused as `proof_timeout`: unproven, fail-closed, per the V02 RM002 clarification.)

### C4 timers / lifecycle (RM003-07)
With robots held in flight, 2.5 s of real frames (≈12 ticks of 200 ms): exactly 1 copy rebuild and 1 Selector question (one per 2000 ms, never per tick). A modal open: coach hidden, 0 rebuilds, 0 hint proofs over 2.5 s; shown again after close. Retry: new state key, copy rebuilt, == oracle once proven, no worker left running. (Home / Results hiding and route-to-Home worker join are covered by `m46_rm002_adversarial` T06 and `m44_ftue`, re-run below.)

### Sensitivity (RM003-05), each a temporary edit, run, then restored byte-identical (`cmp` against a scratch backup)
| Mutant | Edit | Caught by |
|---|---|---|
| M1 old path | step_copy passes `true` (full list) | C1 A: copy mean 21.49 / max 26.01 ms > 4.0 / 16.7 |
| M2 inverted hint | Selector hint `legal: not any` | C1 A 0/20 oracle; C2 every Selector row; state-class check |
| M3 "in flight ⇒ legal" | `any = _inflight() > 0 or has_eligible…` | C2 "59x59 slots full while moving" hint true vs list false; C4 Selector question count 0 |
| M4 inverted Tornado | `.has(CLEARED)` | C1 B 0/20 oracle; C2 every Tornado row; WON terminal check |

### Regression on the RM003 source (all sequential, local, exit 0)
m44_ftue 23/23 · m39c_boosters PASS · m39_v03_integration PASS · m39_v04_integration PASS · m28_c002_c003_final_gate 22/22 · m28_c002_c001_gameplay_v02 14/14 · m43_c003_c001_acquisition 34/34 · m43_c004_c001_fail_need_a_hand 40/40 · m46_r07_ui_legality PASS · m46_rm002_adversarial 8/8 · m46_slot_rebuild PASS · m55_core_chaos PASS · run_tests ALL PASS.
The full 22-case `tests/m46_performance.gd` runs once on the final pinned master source after RM004 (master instruction), reported in the RM004 log.

## 4. Criterion dispositions

| Criterion | Status | Evidence |
|---|---|---|
| RM003-01 SOURCE_PROOF | PASS (E1) | §2 sweep; FTUE moving path has no list build; still path is cache or worker |
| RM003-02 DIRECT_TEST | PASS (E2) | C1 A and B, real main copy + oracle |
| RM003-03 DIRECT_TEST | PASS (E2) | C2, 12 state classes, 5/6, 59x59 stripes + pocket |
| RM003-04 DIRECT_TEST | PASS (E2) | C3 chips proven-only, refusal unspent, one spend |
| RM003-05 SENSITIVITY | PASS (E2) | M1–M4 caught, sources restored |
| RM003-06 DIRECT_TEST | PASS on this desktop (E2) | ≤ 4 ms mean, < 16.7 ms max on L2 A/B and 59x59; no phone claim |
| RM003-07 DIRECT_TEST | PASS (E2) | C4 + re-run m46_rm002 T06 / m44_ftue |
| RM003-08 LOG_GOVERNANCE | PASS (interim) | 13 suites on this source; full 22 at master end |
| RM003-09 OWNER_GATE/POLICY | OPEN gates preserved | Need-a-Hand untouched; 400 ms / 5 s, strings unchanged; F5, phone/GPU, cloud CI OPEN; no Actions; owner files untouched |

## 5. Owner-local provenance (V2-P4)
Tests ran with the owner's local `project.godot`, which differs from GitHub main (read-only `git diff`): extra autoload `_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"` (prints `[godot_ai game_helper] registered mcp capture` at start), GameFeelFlow autoload by UID instead of path, `[audio] buses/default_bus_layout` removed, `godot_ai` editor plugin enabled. Not modified. Clean-main runtime parity stays **OWNER_LOCAL_PROJECT_PARITY_OPEN**.

## 6. Notes
- A fresh-context peer review was not run for RM003 alone; any peer review is for the joint RM003+RM004 handoff and is not a ChatGPT audit.
- Observation (not a defect claim): with the off-frame worker a fresh detached adapter starts its Selector list at offset 0, so at 59x59 the 5 s partial list always shows the first ~15 batches in column-major order; the live adapter's resume offset applies only to the synchronous fallback. Fail-closed and within the accepted "partial list" semantics; reported for the auditor (also in RM004).
