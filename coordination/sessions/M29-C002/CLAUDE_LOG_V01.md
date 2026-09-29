# M29-C002 — CLAUDE LOG V01 (gameplay tempo retune, SB-M29-010)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Matrix: `IMPLEMENTATION_MATRIX_V01.md`
Owner authority: `coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md` §2
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- Repository `Sekiph82/Scrubbots`, branch `main`. Fast-forwarded 6 commits (`--ff-only`) from `3a21910` to `0bccc1b` (the M29-C002 prompt/criteria/TASKS commits); no conflict.
- Root `TASKS.md` read, **not edited**. The local `project.godot` drift and the untracked owner files (`*.import`, `*.uid`, `tests/_m55_diag_tmp.gd`) are preserved and not committed.
- No reset/clean/force push.

## Production change

The new normal is the baseline itself. Factors are unchanged.

| Seam | Before | After |
|---|---|---|
| `ScrubbotAgent.DEFAULT_SPEED` | `6.0` | **`9.0`**, the only numeric travel baseline |
| `ScrubbotDispatcher.DEFAULT_SPEED` | `6.0` | `ScrubbotAgent.DEFAULT_SPEED` |
| `AutoDispatchScheduler.DEFAULT_SPEED` | `6.0` | `ScrubbotDispatcher.DEFAULT_SPEED` |
| `CompleteClearingLoop.DEFAULT_SPEED` | `6.0` | `ScrubbotDispatcher.DEFAULT_SPEED` |
| `GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL` | `0.5` | **`1.0 / 3.0`** (exact quotient; 2x = `1.0/6.0` bit-exact) |
| `FACTOR_1X / FACTOR_2X` | `1.0 / 2.0` | unchanged |
| `MAX_LANES_PER_FRAME / MAX_STEPS_PER_FRAME` | `1 / 1` | unchanged |

`AutoDispatchScheduler.DEFAULT_SPEED` matters here. The production host binds the scheduler without a speed argument, and the scheduler passes `_speed` to every `dispatch_preclaimed`. Changing only the Agent and Dispatcher would have left production agents at 6.0, so all four defaults now derive from the one Agent constant. No explicit custom-speed call sites were changed. There is no `Engine.time_scale`, no new mode, and no UI, economy, entitlement, price, target, route, claim, accounting, solver or completion change.

Documentation: stale "0.5 s / 0.25 s" wording was removed from the `ProductionRuntimeController` lane-budget comment. It now states the 1/3 s and 1/6 s cadence and the accepted 30 FPS six-lane service limit. The Agent and speed-authority constants document the new baseline and the single-source rule. A search found no other current doc/script that states 6/12 cells/s or 0.5/0.25 s as production truth. Historical audit/evidence files are untouched.

Files: `scripts/gameplay/agents/scrubbot_agent.gd`, `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`, `scripts/gameplay/dispatch/auto_dispatch_scheduler.gd`, `scripts/gameplay/clearing/complete_clearing_loop.gd`, `scripts/gameplay/runtime/gameplay_speed_authority.gd`, `scripts/gameplay/runtime/production_runtime_controller.gd` (comment only).

## Focused suite — `tests/m29_c002_tempo_retune.gd`: **PASS (0 failures)**

| § | What it proves (direct runtime measurement, not constants alone) | Key numbers |
|---|---|---|
| s1 | Canonical constants and single source. Source regex finds no numeric `DEFAULT_SPEED` outside the Agent and no stale 6.0. Production host scheduler `_speed` = 9.0 and a host-dispatched agent carries 9.0. Host cadence base is 1/3 s. `Engine.time_scale` is never assigned in the speed path. | 9.0 / 0.33333333333333331 / 1.0 / 2.0 |
| s2 | Travel on a real 59x59 route of at least 60 cells, measured at 60 and 30 FPS: 1x, 2x new agent, 2x already-moving agent, pause freeze, resume keeps 2x, back to 1x. | 9.0000 / 18.0000 / 18.0000 cells per 1.0 s; ratio 2.00000 |
| s3 | Cadence probe (1/1200 s step, 12 s). A 5 s hitch gives at most 1 wave and at most 1 lane, backlog is clamped to one interval, and there is no catch-up burst. Real-host placement wake queues only the placed lane; the other slot waits for the 1/3 s event. | 1x 0.333333 s, 2x 0.166667 s, ratio 2.000 |
| s4 | 5/6 lanes × 1x/2x × 30/60 FPS bounded-wave probe (20 s each). One lane per frame, no overlapping wave, backlog ≤ one interval. | 60 FPS 6 lanes 2x: service 0.100 s < 0.1667, period 0.1667. **30 FPS 6 lanes 2x: period 0.2000 s (service-limited, accepted)**, overlap 0 |
| s5 | Truth equivalence on production level 2 through the real host. Tempo-normalised run (2x at dt/2) matches 1x in dispatch order, targets and colours (1024), clear identity and order (1024), per-frame slot remaining/committed accounting, final board, WON and zero residue; 2x duration is exactly half. Same 60 FPS clock: both runs WON with the same cleared set and final board. | 215.45 s vs 107.725 s; 60 FPS clock 196.4 s vs 106.4 s |
| s6 | Every existing 2x authority, measured on a live production agent: paid current-level 2x via the real popup, timed 2x on a new level / retry / relaunch, manual 1x during timed, timed expiry, expiry while M23 owns 2x, and free M23 auto-2x. Prices and durations are unchanged. | 18 / 18 / 18 / 18 / 9 / 9 / 18 / 18 cells/s; 200 SB; {900:300, 1800:500, 3600:750} |
| s7 | Retry without a timed entitlement resets to factor 1.0, cadence 1/3 s and 9 cells/s. | 1.0 / 0.333333 / 9.0 |
| s8 | Real host: 32x32 full completion across 5/6 slots × 1x/2x × 30/60 FPS (8 runs), and a 59x59 dense 6 s window across 5/6 slots × 1x/2x × 60 FPS plus 6 slots × 1x/2x × 30 FPS, compared in the same harness against the **historical tempo** (0.5 s / 6 cells/s). | all 8 32x32 runs WON, 1024/1024 clears; every run: ≤ 1 assignment/frame, pending lanes ≤ slot count, backlog ≤ one interval, 0 duplicate dispatch, 0 duplicate clear, cardinalities consistent |

Run: `godot --headless --path . -s res://tests/m29_c002_tempo_retune.gd -- <evidence_dir>` (about 10 min, mostly s8).

## Regression

Full sweep: Godot 4.7.2 headless, 6-way parallel, 115 suites (owner scratch `tests/_m55_diag_tmp.gd` excluded). Details are in `evidence/regression_summary.txt`.

- **112 exit 0.** This covers M28 (C001 V02, C002, C002-R01, C003, C003-R01, C004), all M29 suites, M30 (completion, retry, manual playtest), all M39 suites, M40–M43, M52 (R01, R02, owner supply plans), M53, M54, M55 (core chaos, long session **PASS**, economy, heart, timed anti-rollback), routing/clearing/solver (M20–M27, including M26/M27/M31/M32 59x59), palette contract, and root `run_tests.gd` (**Total checks: 5323, ALL PASS**).
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B) are the documented pre-existing baseline, unchanged for several cycles.
- `m29_hazard_bot_runtime_smoke` failed one assertion: `2x completes in no more ticks than 1x (625 <= 622)`.
  - **Cause:** the harness drove the runtime at `DT = 1.0` s per tick, which is a 1 FPS clock. At the retuned 9 cells/s, nearly every Hazard Bot route finishes within one tick even at 1x. Both runs are then bound by the one-lane-per-frame budget, not by speed, so tick count stops measuring speed.
  - **Fix (test harness only):** `DT = 1/60`, `MAX_TICKS` raised to 400000. The awaited pre-play layout frames had let the real-time `_process` feed wall-clock delta into the cadence accumulator, which made the cadence phase differ between runs at 60 FPS. `_make_host` now calls `reset_runtime()` right after `set_process(false)`, before any gameplay. No assertion was removed or loosened.
  - **Result at 60 FPS:** 1x = 4383 ticks, 2x = 2492 ticks. Rerun 3× in parallel: PASS, PASS, PASS.
- `SCRIPT ERROR` appears only in the known `m20_v04/v05/v07/v08` lifecycle baseline (exit 0).
- `git diff --check`: clean (CRLF advisories only).

## Performance / 59x59

- **Tempo invariants hold everywhere:** one lane per frame; no wave overlap; cadence backlog ≤ one interval (a 5 s hitch replays nothing); pending lanes ≤ slot count; zero duplicate claims or clears; transaction cardinalities consistent. All 32x32 full-completion runs WON with zero residue.
- **32x32 real host:** mean tick 1.5–7.2 ms, p99 9–36 ms, max 13–54 ms across the 8 configurations.
- **59x59 wide-stripe dense window (worst case): pre-existing cost, not caused by this change.** A single dispatch lane can spend 0.9–3.4 s in M25 `target_selection`, which issues about 100+ `access_compute_route` probes (1.4–4.9 ms each) over enclosed same-colour candidates.
  - The same harness at the **historical** tempo shows the same spike (2.35 s max) and the same per-probe cost (3.7–3.8 ms historical vs 3.5 ms new at 6 slots/2x/60 FPS). The suite asserts that per-probe cost is unchanged.
  - The budget still holds, so the cost of one frame is at most one lane. What the retune changes is how often lanes are attempted (×1.5 at the same factor), so the mean tick cost rises in dispatch-saturated windows.
  - Accepted production content and the accepted M26/M31/M32 59x59 fixtures do not show this; M55 long session passes.
  - I did **not** optimize it, because that would change M25/TargetSelector and is outside this prompt. It is flagged for a separate ChatGPT/owner decision.
- **Timing noise:** during all measurements the machine was also running three unrelated Godot `m17_canonical_confirmation_v07_r01` processes that I did not start or touch. Absolute ms are therefore noisy; the same-harness historical comparison is the controlled signal.

## Evidence (`coordination/sessions/M29-C002/evidence/`)

- `tempo_report.txt` / `tempo_report.json`: travel per 1 s at 1x/2x (60 and 30 FPS), cadence intervals, five/six-lane 30/60 FPS wave timing, backlog maximum, duplicate assignment/clear counts, real-host 32x32 and 59x59 stress tables, authority rates, reset, truth equivalence.
- `real_host_trace_1x_2x.txt`: real-host level 2 trace with the first dispatches and clears timestamped at 1x and 2x.
- `regression_summary.txt`: per-suite exit codes and times.

## Owner playtest required (criteria K)

1. New 1x feels appropriately faster than the old normal.
2. New 2x feels like exactly twice the new normal, not an uncontrolled jump.
3. No visible dispatch burst/stutter with five/six occupied slots (at 30 FPS with six lanes, 2x waves arrive about every 0.20 s instead of 0.167 s by design).

`AWAITING_CHATGPT_AUDIT / M29-C002 GAMEPLAY TEMPO RETUNE V01`
