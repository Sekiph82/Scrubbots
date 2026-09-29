# M25-C003 — CLAUDE LOG V01 (exact-safe target prefilter S1 + laid-out 59x59 harness S0, SB-M25-034)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Matrix: `IMPLEMENTATION_MATRIX_V01.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- `main` fast-forwarded (`--ff-only`) to the M25-C002 audit + M25-C003 prompt commits; no conflict.
- Root `TASKS.md` read, **not edited**. Local `project.godot` drift and untracked owner files preserved, not committed.
- Only S0 + S1 implemented. **No** S2 routing/Dijkstra change, **no** D2 inside-origin guard, no speed/economy/level/scheduler change.

## Optional prefilter API (S1-B)

`ProductionTargetAccess.prefilter_maybe_targetable(index: int) -> Variant`

- `false`: the exact M52 necessary condition fails (not a perimeter cell and not 4-adjacent to a perimeter-connected CLEARED cell) for an outside origin, so `compute_route` would be NO_ROUTE. It also clears the one-shot route memo, which is the same observable side effect as the `is_targetable()` false path.
- `true`: the candidate *may* be targetable. It is never a success verdict.
- `null`: unsupported. This covers a non-BoardState board, an invalid index, a non-finite origin, or an inside-board (debug interior planner) origin.

In `TargetSelector._select_core`, the loop checks `has_method("prefilter_maybe_targetable")` once. For each int candidate in the unchanged canonical order it asks the capability, and **only `typeof == TYPE_BOOL and false` skips**. Every other candidate runs the unchanged strict body: board validity, state and colour checks; `is_reserved`; `_op_coherent`; the authoritative `is_targetable()`; `_op_coherent`; the owner re-check; `reserve`. The selector builds no mask and reads no topology.

## Touch-mask ownership and invalidation (S1-A)

- Owned by `ProductionTargetAccess` (the access/HOW side). `reach[i]` and `touch[i]` are `PackedByteArray`s built once per `(BoardState instance id, revision)`. `touch` = perimeter, or 4-adjacent to `reach`, which is exactly the former per-call `_could_reach` rule.
- Stored per instance and in the existing **single-slot** static shared cache (one board state; it never grows).
  - The hot path is one revision compare plus a byte read, ~0.5 µs.
  - A rebuild is O(W·H) from one detached `BoardState.get_cell_states_copy()`, about 0.7–1.9 ms on 59x59.
- Any revision change (every cell write, and `restore_all_active` for Retry) causes a rebuild. A different BoardState instance never reuses the mask.
- `_could_reach` (used by `is_targetable`) is now `prefilter != false`: same verdicts, O(1).

## S0: laid-out 59x59 harness

- `tests/m29_c002_tempo_retune.gd` s8 now builds every fixture host as a real 1080x2160 production host. The sequence is SubViewport → settle → build → relayout → settle, then re-settle after +1 Slot, then `reset_runtime()`.
- It asserts that every slot origin is finite and below the board: 59x59 `y = 72.75`/`72.78`, 32x32 `y = 41.0`.
- The corrected evidence is in `coordination/sessions/M29-C002/evidence/v02_laidout_m25c003/` (with a README). V01 evidence is untouched.
- M29 suite: **PASS**. On laid-out 59x59 dense windows, per-route-probe cost is ~0.8–1.0 ms and max selection is ≤ 3.0 ms.

## Tests

- **`tests/m25_c003_exact_prefilter.gd`: PASS (0 failures).**
  - **t1:** 2,094,180 mask checks against a verbatim reference of the old condition, over 288 states, 16 boards and 6 outside origins, including restore. **0 mismatches, 0 false negatives.** Inside-board, non-finite and invalid-index cases return `null`.
  - **t2:** 3,744 filtered-vs-baseline selection transactions (first-10 production levels plus stripe boards, revisions, reservation pressure). **0 diffs** in winner, no-target result or ReservationState. Strict-body entries fell from 39,440 to 2,696, and no impossible candidate entered the strict body.
  - **t3:** missing and malformed capabilities give the exact old loop; `true` never selects; `false` skips only its own candidate; drift and re-entrancy doubles stay safe; an inside-board canonical access runs the identical old loop.
  - **t4:** revision, restore and identity invalidation; the shared cache is a single slot.
  - **t5:** full laid-out 59x59 run, all 3481 cells cleared, WON:
    - prefilter, capability-hidden baseline and uninstrumented production give identical dispatch order, clear order and final board;
    - zero duplicates and zero residue; every origin is below the board;
    - `compute_route` ≤ 1 per lane and **0 failed route probes**;
    - strict-body iterations per lane: **max 1**, against up to 590 candidates.
- `tests/tools/m25_c003_timing_probe.gd`: a standalone before/after timing tool that uses no new API. It was run on the pre-C003 production files (temporarily restored from HEAD, then put back and verified) and on the C003 code, on the same machine in the same session. Dispatch hashes are identical before and after at both 2x and 1x.

## Before / after (full laid-out 59x59 level to WON, uninstrumented RuntimePerfProbe, ms)

| | 2x before | 2x after | 1x before | 1x after |
|---|---|---|---|---|
| selection scan excluding winner route, p50 / p99 / max | 1.44 / 5.62 / 9.57 | **0.43 / 1.78 / 3.21** | 1.18 / 5.90 / 11.39 | **0.40 / 1.82 / 3.03** |
| target_selection p99 / max | 32.0 / 50.6 | 29.9 / 45.2 | 33.3 / 63.5 | 32.9 / 65.5 |
| winner route (`access_compute_route`) p99 / max | 29.7 / 47.6 | 29.8 / 42.5 | 31.0 / 57.5 | 36.4 / 62.2 |
| `route_dijkstra` mean / p99 / max | 9.70 / 27.7 / 44.3 | 9.88 / 27.7 / 39.5 | 9.94 / 28.9 / 53.6 | 10.05 / 33.1 / 57.3 |
| frame p50 / p99 / max | 3.56 / 34.0 / 56.0 | 2.87 / 32.5 / 51.8 | 2.06 / 32.0 / 71.0 | 2.21 / 30.4 / 74.0 |

S1 target met: scan p99 ≤ 3 ms (1.78 / 1.82 ms).

**Remaining hotspot:** the single winning route's Railroad Dijkstra (S2, not touched). Its p99 is ~28–33 ms and max ~40–57 ms, which keeps the frame p99 at ~30–32 ms and the max at 52–74 ms late in the 59x59 level. Whether this blocks the M29 owner tempo playtest is ChatGPT's decision (criterion J).

Measurement notes:
- During the first focused-suite run, three unrelated Godot `m17_canonical_confirmation_v07_r02` processes (not started by me) loaded the machine and roughly doubled all timings. The before/after table comes from the later clean session.
- The prefilter-counting and baseline t5 modes include instrumentation overhead. Their timing is only indicative; their counts are exact.

## Regression

Godot 4.7.2 headless, 6-way parallel, **115 suites** (owner scratch `_m55_diag_tmp` excluded). The two long focused suites (`m25_c003_exact_prefilter`, `m29_c002_tempo_retune`) ran standalone on the final code, and both **PASS**. Details are in `evidence/regression_summary.txt`.

- **113 exit 0.** This covers:
  - root `run_tests.gd`: **Total checks 5323, ALL PASS**, including the M15/M19 strict suites;
  - all M25 claim suites and M26 (scheduler, Hazard integration, 59x59 sanity);
  - M29 (exact slot origin, Hazard smoke, input, presentation, realtime, speed authority, display sync) and M30;
  - all M39 suites, M40–M43, and M52 (R01, R02, owner supply plans);
  - M55 (core chaos, **long session PASS**, economy, heart, timed);
  - routing/railroad (M20–M22, M27 including 59x59) and M31/M32 59x59.
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B) fail with the documented pre-existing baseline signatures, unchanged.
- `SCRIPT ERROR` appears only in the known `m20_v04/v05/v07/v08` lifecycle baseline (exit 0). The `resources still in use at exit` warning is pre-existing in the SubViewport-based suites (also present in M29 V01 and in M28/M29/M30 runs).
- `git diff --check`: clean (CRLF advisories only).

## Files

- Production: `scripts/gameplay/dispatch/production_target_access.gd`, `scripts/gameplay/targeting/target_selector.gd`, `scripts/gameplay/board/board_state.gd` (read-only accessor).
- Tests: `tests/m25_c003_exact_prefilter.gd` (new), `tests/tools/m25_c003_timing_probe.gd` (new, test-only), `tests/m29_c002_tempo_retune.gd` (s8 laid-out + origin assertion).
- Evidence: `coordination/sessions/M25-C003/evidence/`, `coordination/sessions/M29-C002/evidence/v02_laidout_m25c003/`.

`AWAITING_CHATGPT_AUDIT / M25-C003 EXACT-SAFE TARGET PREFILTER V01`
