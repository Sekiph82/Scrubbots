STATUS: READY

# Build: Faster route-length measurement in the Difficulty V1 analyzer, identical output (SB-PERF-ROUTE-2026-11-13)

## Summary
Commit `ec1e57a7` is on `factory/157-route-length-perf`, based on 8e8c6fc7, and is not pushed.

After job 156, most of `measure()` was the analyzer observer's own route per claim:
`ProductionRoutingSystem._railroad_route` at TOTAL_TRAVEL_COST, which runs the generic railroad
Dijkstra. Both changes below apply only to the exact canonical `ProductionAccessQuery`, which is the
existing `fast` gate. Every other configuration still runs the unchanged reference code.

- `scripts/gameplay/routing/production_routing_system.gd`
  - **`_railroad_dijkstra_fast()`.** This is the same Dijkstra as before: the same seeding, the same
    relax arithmetic with its epsilon and tie-break, and the same strict pop order by
    (cost, side, seq, cell), so it picks the same parents.
    - It reads one detached snapshot of the cell states instead of calling a method per cell.
    - The binary heap is written out inline over local packed arrays, with no inner-class method
      calls.
    - Pushes from one expansion are queued and done before the next pop. The heap holds the same
      entries when it pops, so the pop order is the same.
  - **`_perimeter_sources()`.** It caches, per (start, w, h) on the routing instance, the list of
    perimeter ingress entries. They keep the same order and the same `cost0` expression. Only the
    board-dependent filter runs per route: a source is kept if it is CLEARED or the target itself.
  - Within one routing instance this saves the rail-distance calls and the lambda/classify calls of
    every route after the first.
- `tests/difficulty_v1_identical_output.gd`: a new case checks, on sampled states of L11 (which has
  VOID cells) and `hard_maze8_24`, that the fast path returns exactly the same points as the generic
  Dijkstra for every third targetable cell. The generic one is forced by `_GenericAccess`, a subclass
  of `ProductionAccessQuery`, which fails the exact script check. The default run now has 9 cases.
- `.github/workflows/android-family-first10.yml`: the guard is now
  `Difficulty V1 identical output: PASS (9/9 cases, 0 fail)`, with a header note.

No rule, constant, formula, golden file or level data changed. TASKS.md was not edited.

## Timings, old (6534537c) -> new (ec1e57a7), seconds
Same harness as job 156 (`perf_harness.gd`).
- Old numbers come from `factory/jobs/156-difficulty-perf/perf_v1_*.log`.
- The LF-000147 runs were solo, both old and new. The LF-000148 runs had one other Godot process
  running, both old and new.

| Part | LF-000147 old | LF-000147 new | LF-000148 old | LF-000148 new |
|---|---|---|---|---|
| measure() total | 70.5 | 27.1 | 80.3 | 29.6 |
| route length: route_sources | 5.68 | 0.41 | 6.20 | 0.43 |
| route length: route_dijkstra | 48.20 | 14.89 | 56.69 | 17.06 |
| route length: route_validate | 0.56 | 0.45 | 0.61 | 0.48 |
| **route length total** | **54.4** | **15.7** | **63.5** | **18.0** |
| 89 placements (with observer) | 66.4 | 23.9 | 76.1 | 26.3 |
| decision states (+ rest) | 3.9 | 3.1 | 4.1 | 3.3 |
| peel_waves | 0.15 | 0.09 | 0.08 | 0.10 |
| apply_placement mean, bare kernel (ms) | 99.9 | 83.3 | 105.1 | 85.1 |

- `measure()` is 2.6x faster on LF-000147 and 2.7x faster on LF-000148. The route-length part is
  3.5x faster on both levels.
- `apply_placement()` does not use this code: the kernel has been verdict-only since job 156 and
  builds no routes. The small change in its mean is run-to-run noise, not a speed-up claim.
- What is left of the route search is about 12 ms per route in GDScript. Going further would need a
  different search algorithm. Its float tie-breaks make exact equality hard to guarantee, so I did not
  attempt it.

## Acceptance criteria
1. [x] `measure()` on LF-000147 and LF-000148 is at least 2x faster than on 6534537c: 2.6x and 2.7x,
   see the table. Parts are reported separately, with the route-length part on its own row.
2. [x] The identical-output regression passes on campaign, anchors and the Factory levels. It
   compares against the goldens committed in job 156, which were made on 5d19621c.
   - `--sets=campaign,anchors`: `PASS (58/58 cases, 0 fail)`.
   - `--sets=factory`: `PASS (5/5 cases, 0 fail)`; LF-000147 and LF-000148 are identical.
   - Default (CI) run: `PASS (9/9 cases, 0 fail)` in 54 s. It includes
     `fast railroad Dijkstra == generic Dijkstra route points on 772 routes (0 mismatches)` and the
     verdict-only check: 20096 cells, 0 mismatches.
3. [x] Mutation check. In a scratch run I swapped the `_rank_lt` argument order in the fast relax step
   and ran the default test. It reported `FAIL (4/9 cases, 5 fail)`:
   - the route case found 484 of 772 routes different;
   - all four levels differed in measure and score.

   The swap was reverted and is not in the commit.
4. [x] Full headless suite: see Validation for the exact counts.
5. [x] One code commit, `ec1e57a7`, not pushed. The orchestrator pushes it.

## Validation
- `git diff --cached --check`: clean.
- CI list (`tools/run_suites.py`, two shards in parallel, 94 suites): 94/94 pass, 0 failures (LOCAL_PASS). Shard A: `aggregate=PASS (47/47)`, including m46_performance (22/22). Shard B: `aggregate=PASS (47/47)`, including real_play_levels (4/4), campaign_l11_l30 (5/5) and difficulty_v1_identical_output (9/9).
- Non-CI solver, proof and difficulty suites: 19/19 pass, every one with exit 0 and no script errors (LOCAL_PASS). The suites: m25_c003_exact_prefilter, m25_claim_model_evidence, m25_scale_evidence, m25_v03_exact_work_binding_evidence, m26_hazard_bot_integration, m27_generation_retry, m27_hazard_bot_solve, m27_scale_59, m36_anchor_calibration (126 cases), m36_difficulty_v2 (38/38), m36_frustration_v1 (62 cases), m46_slot_rebuild, m52_owner_supply_plans, m52_r01_parallel_runtime, m52_r02_early_slot_release, m53_first10_difficulty, m53_c002_difficulty_calibration, void_cells_c001, maint_supply_columns_c001 (10/10, 0 failures).

## Log
### Round 1
- Old numbers reused from job 156 as instructed; no baselines were recreated.
- Ran a one-off `--import`, then profiled. The route Dijkstra took 48 s and the sources 5.7 s of the
  70.5 s on LF-000147.
- Implemented the inlined fast Dijkstra, which brought LF-000147 to 30.9 s. Then added the per-start
  source cache, which brought it to 27.1 s.
- Ran the full identical-output sets, the mutation check and the CI shards and extras once each.
- Afterwards I restored `project.godot` and the `.import` files that the import had changed.
