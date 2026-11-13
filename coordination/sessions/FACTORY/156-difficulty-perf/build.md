STATUS: READY

# Build: ScrubBots game: faster Difficulty V1 analysis and proof kernel, identical output

## Summary
Commit `6534537c` on `factory/156-difficulty-perf` (not pushed). Profiling showed that one
generic railroad Dijkstra (`ProductionRoutingSystem`, TOTAL_TRAVEL_COST, about 37-43 ms each on 56x56)
dominated all three slow parts. `ProductionTargetAccess.is_targetable()` ran one for every candidate
the touch mask let through, but its callers only needed the true/false verdict.

- `scripts/gameplay/dispatch/production_target_access.gd`: new opt-in `verdict_only` (default false,
  so runtime dispatch is unchanged). The mode applies only for an outside (rail) origin and the exact
  canonical stack, checked by script identity: BoardState, a bound ProductionAccessQuery, and
  ProductionRoutingSystem at TOTAL_TRAVEL_COST. In that case `is_targetable(i)` returns
  `touch[i] == 1 and ACTIVE` from the existing exact reach/touch masks and builds no route. Why this
  is exact: every non-BLOCKED perimeter cell is a rail ingress source, so the Dijkstra finds the target
  exactly when the target is on the perimeter or next to a reach cell. The finished route (outside
  connector and rail, orthogonal ingress, unit steps over CLEARED cells, final arrival) is clean for
  RouteValidator by construction. No route is memoized, so `consume_route` returns null.
- `scripts/gameplay/solver/proof_kernel.gd`: the per-lane access sets `verdict_only = true`. The
  kernel never uses the probe route, and the observer still computes its own full route.
- `scripts/difficulty/level_difficulty_analyzer_v1.gd`: `peel_waves()` and `_reach()` set
  `verdict_only = true`.
- `tests/difficulty_v1_identical_output.gd` (new) plus `tests/fixtures/difficulty_v1_identical/`:
  the regression, the golden digests and the two Factory levels (level + supply plan).
- `.github/workflows/android-family-first10.yml`: the suite is added to the CI list with an exact
  guard, `Difficulty V1 identical output: PASS (8/8 cases, 0 fail)`.

No constant, formula, iteration order, tie-break or game rule changed. TASKS.md was not edited, as
the orchestrator instructed.

## Timings (old -> new, seconds)
The old numbers are from commit 5d19621c and the new ones from 6534537c, using the scratch harness
`perf_harness.gd` in this job folder. That harness runs `measure()` with the intended clicks, then a
bare ProofKernel replay. Most baseline runs had one other Godot process running at the same time.
The LF-000147 new run was solo; the LF-000148 new run had one other process running.

| Part | LF-000147 old | LF-000147 new | LF-000148 old | LF-000148 new |
|---|---|---|---|---|
| measure() total | 440.2 | 70.5 | 950.1 | 80.3 |
| decision states (+ rest) | 256.6 | 3.9 | 739.9 | 4.1 |
| 89 placements (with route observer) | 126.2 | 66.4 | 143.0 | 76.1 |
| peel_waves | 57.4 | 0.15 | 67.2 | 0.08 |
| apply_placement mean, bare kernel (ms) | 764.0 | 99.9 | 861.2 | 105.1 |
| apply_placement max, bare kernel (ms) | 2056.8 | 220.4 | 2080.6 | 166.2 |

- `measure()` is 6.2x faster on LF-000147 and 11.8x faster on LF-000148.
- `apply_placement()` is 7.6x faster on LF-000147 and 8.2x faster on LF-000148.
- Not optimized: the observer's own route per claim (needed for the route-length metrics), about
  1300 Dijkstras of roughly 40 ms each. It is now about 80% of `measure()` and is the next candidate.
  It was left out to keep the change exact and minimal.

## Acceptance criteria
1. [x] `measure()` is at least 2x faster on LF-000147 and LF-000148: see the table (6.2x and 11.8x).
2. [x] Identical output on campaign, anchors and the Factory levels. The golden digests were written
   by the test itself on unmodified 5d19621c (`--write`, per set). Each digest is a SHA-256 of the
   canonical JSON of four records:
   - `measure()` without `timing`,
   - `score()`,
   - a fresh ProofKernel replay (clears, active_after, placed, placed_slot, ACTIVE-mask hash per step),
   - SolvabilitySolver status, visited, trace and trace_hash, for the 24 anchors and Level 1.

   Results on the new code:
   - Full local run of campaign (30 levels) and anchors (24): `PASS (58/58 cases, 0 fail)`, 11.7 min.
   - Factory run (`--sets=factory`): `PASS (5/5 cases, 0 fail)`. LF-000147 and LF-000148 identical.
     LF-000147 reproduces the Factory's challengeScore 52.18883.
   - Both runs include the verdict-only vs full-probe case: 20096 cells checked, 2318 targetable,
     0 mismatches.

   L20 and L30 intended plans are not legal under kernel timing (known divergence). They are measured
   up to their last legal placement (95 and 68 steps), so their decision states and score are covered.
3. [x] The regression catches a change. In a scratch run, `ProofKernel.ORIGIN_BELOW` was changed from
   4.0 to 5.0 and the test was run with `--sets=anchors --only=easy_frame5_24`. It printed
   `FAIL: anchors/easy_frame5_24 identical (differs: measure,score)` and
   `Difficulty V1 identical output: FAIL (3/4 cases, 1 fail)` with exit 1. The change was then
   reverted, and the committed diff has no such change.
4. [x] Full headless suite: see Validation for the exact counts.
5. [~] One commit: `6534537c`. Not pushed: the orchestrator said not to push and to commit only on the
   job branch.

## Validation
- CI subset (default run of the new suite, as CI runs it): `Difficulty V1 identical output: PASS
  (8/8 cases, 0 fail)`, 66 s with one other Godot process running.
- CI suite list, `python tools/run_suites.py`, in two shards running in parallel (94 suites,
  including the new one): 94/94 LOCAL_PASS, 0 failures (shard A `aggregate=PASS (47/47)`, shard B `aggregate=PASS (47/47)`). This includes m46_performance (22/22), real_play_levels (4/4), real_play_file_cli (6/6), campaign_l11_l30 (5/5) and difficulty_v1_identical_output (8/8).
- Non-CI solver, proof and difficulty suites, all LOCAL_PASS (exit 0, diag 0): m25_c003_exact_prefilter,
  m25_claim_model_evidence, m25_scale_evidence, m25_v03_exact_work_binding_evidence,
  m26_hazard_bot_integration, m27_generation_retry, m27_hazard_bot_solve, m27_scale_59,
  m36_anchor_calibration (126 cases), m36_difficulty_v2 (38/38), m36_frustration_v1 (62 cases),
  m46_slot_rebuild, m52_owner_supply_plans, m52_r01_parallel_runtime, m52_r02_early_slot_release,
  m53_first10_difficulty, m53_c002_difficulty_calibration, void_cells_c001, maint_supply_columns_c001
  (10/10, 0 failures). That is 19 of 19.
- `git diff --cached --check` was clean.

## Log
### Round 1
- Wrote the test and harness first. Generated golden digests and full baseline dumps on unmodified
  code (`golden_full/baseline/` in this job folder) and recorded the baseline timings.
- Profiled with RuntimePerfProbe: route_dijkstra was 355 s of 440 s on LF-000147, and 8409 of the
  9680 routes were access probes. Made the verdict-only change, then re-ran everything as above.
- The one-off `--import` changed the tracked `project.godot` in the worktree. I restored it after
  testing and did not commit it. Untracked import `.uid` files were left alone.
