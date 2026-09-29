# M25-C004: Claude Log V01 (exact-equivalent Railroad / Dijkstra acceleration, S2, SB-M25-035)

Date: 2026-09-29
Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Matrix: `IMPLEMENTATION_MATRIX_V01.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- `main` was fast-forwarded (`--ff-only`) from `aadc572` to `7e1c2b4`, which adds the M25-C003 audit and the M25-C004 prompt and criteria. There was no conflict.
- Root `TASKS.md` was read and **not edited**.
- Pre-existing local work is preserved and not committed: the `project.godot` drift, the untracked owner assets, the Godot-generated `.import`/`.uid` files and `tests/_m55_diag_tmp.gd`.
- The change is HOW-only. Nothing else was touched:
  - TargetSelector / ProductionTargetAccess (S1);
  - claims and reservations;
  - scheduler and lane budget;
  - speed and cadence;
  - economy;
  - level data;
  - renderer and UI.

## Frozen oracle (criterion A)

- `tests/support/m25_c004_railroad_baseline.gd` is a verbatim copy of `production_routing_system.gd` at `aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`, with only a 4-line header naming the SHA. `diff <(git show aadc5725:…) <(tail -n +5 oracle)` is empty.
- It was created **before** any production edit and was never modified afterwards.
- No file under `scripts/` or `scenes/`, and not `project.godot`, references it (0 hits).
- `tests/support/m25_c004_baseline_counting.gd` is a test-only work-counting replica of the oracle: the same code plus counters. `tests/m25_c004_host_truth.gd` re-verifies it route-by-route against the oracle (0 diffs over 3,481 live routes).

## Optimization architecture

The approach is Stage B: an exact specialised production fast path. It is gated, and the frozen algorithm stays as the fallback.

**The fallback path is unchanged.** `ProductionRoutingSystem._railroad_route` keeps the pre-S2 source-seeding and Dijkstra code verbatim. The only refactor moves the route tail (connector + rail + ingress + chain → dedup → collinear collapse → RouteValidator) into `_railroad_finish()`, which both paths call.

**The new `_railroad_layered()` runs first**, only when all of the following preconditions hold:

1. `access_query.get_script() == ProductionAccessQuery`: the exact script. Subclasses and duck types are excluded.
2. `board.get_script() == BoardState`: the exact script. Subclasses are excluded.
3. `interior_step_cost == INTERIOR_STEP_COST` (1000.0). Equal-weight mode (1.0) and every other tuning go to the generic path.
4. Internal check: `w + h + 20 < interior_step_cost`, so the whole rail+ingress cost spread is smaller than one interior step. Labels are then strictly lexicographic: interior steps first, then the ingress label.
5. Runtime near-tie guard: every pair of distinct critical-source `cost0` values must be either exactly equal or more than `_LAYER_TIE_GUARD` (1e-3) apart. Otherwise it returns `null` and the generic Dijkstra runs.
6. Outside-board origin only. Inside-board origins never reach `_railroad_route`, so the interior BFS planner is unchanged.

**Algorithm.** It is exact, not heuristic.

1. **Snapshot.** One detached `BoardState.get_cell_states_copy()`, with no per-neighbour method calls.
2. **Reverse BFS from the target** over CLEARED cells, layer by layer. It stops at the first layer that contains a perimeter (ingress) cell; that layer index is K, the minimum number of interior steps. If the BFS exhausts without one, the result is `NO_ROUTE`. This is exactly the generic result: with no route, the generic Dijkstra never pops the target.
3. **Critical sources.** Only the perimeter cells on layer K get their generic seed label. That is the best `(cost0, side, seq)` over their side memberships, using the identical eps + `_rank_lt` seeding rule, `connector_len + rail_dist + ingress`.
4. **Forward sweep.** Each critical layer is sorted with one native `PackedInt64Array.sort()` on `(cost0-rank, side, seq, cell)`. That is the exact pop order of the generic heap `(cost, side, seq, cell)` among equal interior-step counts. Each cell's parent is the first popped neighbour whose reverse distance is one higher, which is exactly the generic first-relaxation rule; later equal-cost relaxations can never win `_rank_lt` because pops come in rank order.
   - Non-critical cells (those not on any minimum-step path) cannot affect the chain: under lexicographic cost they are never cheaper, and a cell adjacent to a critical cell with a reverse distance one lower is itself critical.
5. **Finish.** The chain is reconstructed and then passed through the same `_railroad_finish()` as the generic path, which gives the same dedup, collinear collapse and RouteValidator check.

**Why the near-tie guard exists.** The generic Dijkstra compares costs with `_RAIL_LEN_EPS` (1e-4). With eps-equal but non-identical costs, that relation is not a strict order, and the heap pop order becomes path-dependent. The layered path does not attempt to reproduce this; it delegates such cases. The mutation check below shows the guard is required.

**No cache.** Everything is per call and nothing persists between calls, so there is nothing to invalidate across board revisions or routing modes.

**Debug counters.** `collect_work_counts` (default `false`) and `last_work_counts` are debug/test-only. There is no logging and they are never read by gameplay.

## Differential proof (B/C/D): **48,202 comparisons, 0 diffs**

`tests/m25_c004_railroad_differential.gd` compares `success`, the failure reason, the target, the point count and a byte-exact point array. The run gave **PASS**:

- 37,902 compared successes and 10,300 failures;
- 228,983 points;
- 477 generated states.

Coverage, detailed in `evidence/differential_report.md`:

- production levels 1..10;
- synthetic 20x20 / 24x40 / 40x24 / 32x32 / 38x38 / 23x31 / 59x59 / 45x27 boards;
- 9 topology generators: peel with pockets, random, rooms + corridors, stripes, bands, sparse late-game, checkerboard, row peel, open with walls;
- six production-like slot origins plus tie-prone, clamped, top/left/right/corner and random origins, and inside-board debug origins;
- routing modes 1000.0, 1.0, 0.5, 2, 500 and 999;
- non-canonical access: a subclass, a duck-typed wrapper and an extra edge blocker;
- a BoardState subclass;
- junk, null and unbound inputs, a non-ACTIVE target, an invalid index and a non-finite origin;
- exact-tie and near-tie corridor and open-board sweeps.

Path accounting on the optimized side:

| Path | Count |
|---|---|
| layered success | 21,319 |
| layered NO_ROUTE | 4,106 |
| guard fallback | 144 |
| generic | 22,633 |

**Mutation checks.** In each case the original file was restored and verified byte-identical afterwards.

| Broken variant | Result |
|---|---|
| Per-layer sort removed | 179 diffs |
| Side priority reversed | 7 diffs |
| Near-tie guard disabled | 18 diffs |

In each case the suite FAILs, so it discriminates.

## Real-host truth (E/F): `tests/m25_c004_host_truth.gd` **PASS (0 failed checks)**

Setup:

- Laid-out 1080x2160 host, 59x59 six-stripe level, +1 Slot.
- 6 origins at `y = 72.78`, all below the board.
- S1 prefilter on.
- The live routing instance's script is swapped to a recording subclass of the frozen oracle ("base") or of the optimized routing ("opt").

At 2x and at 1x, base vs opt:

- **every one of the 3,481 `compute_route` calls is identical**: origin, target, success, reason and the full point sequence;
- the dispatch target/colour sequence is identical;
- the authenticated clear sequence is identical;
- the final board is identical;
- 3,481/3,481 clears, WON;
- 0 duplicate dispatches and 0 duplicate clears;
- zero residue;
- `compute_route` ≤ 1 per lane;
- 1 lane per frame;
- **0 failed route probes**.

Shadow run (2x): the optimized routing drives the game while the oracle and the counting replica re-run on the identical live state for every route. The result was 3,481/3,481 identical (0 diffs) and all 3,481 routes took the layered path.

## Work counts (H): `evidence/work_count_report.md`

Per live route (mean / p99):

| Frozen oracle | mean | p99 |
|---|---|---|
| heap pops | 1,187 | 3,172 |
| pushes | 1,242 | 3,191 |
| neighbour checks | 4,572 | 12,459 |
| `get_cell_state` reads | 4,571 | 12,458 |
| sources built (classify + rail_dist each) | 171 | 236 |
| max heap size | 169 | 232 |

Stale pops were 0.

| Optimized layered path | mean | p99 |
|---|---|---|
| snapshots | 1 | 1 |
| reverse-BFS cells | 150 | 880 |
| reverse-BFS neighbour checks (packed reads) | 600 | 3,520 |
| critical sources | 1.02 | 2 |
| forward-sweep cells | 12 | 65 |

**Baseline pops divided by optimized cell visits: mean 31x, p50 16x, p99 174x.**

The speed-up comes from three things:

- **Less work, on an exact basis.** Only the target's radius-K neighbourhood is searched, and only minimum-step cells are swept. The fallback semantics are unchanged.
- **No heap and no per-neighbour method calls.** Native sort plus packed-array reads replace them.
- **Only about one `rail_dist` label per route**, instead of one per perimeter cell.

## Performance (G): `evidence/before_after_performance_report.md`

The measurement is a same-session A/B that alternates oracle and optimized, on the full laid-out 59x59 level to WON, with S1 on (`tests/tools/m25_c004_perf_ab.gd`).

**Primary clean session B** (the machine at full speed; the oracle numbers match the M25-C003-published ~25–28 ms). Two rounds:

| | 2x oracle | 2x optimized | 1x oracle | 1x optimized |
|---|---|---|---|---|
| route_dijkstra p99 / max | 24.9 / 30.1 | **0.25 / 0.34** | 24.8 / 27.4 | **0.25 / 0.31** |
| winner route p99 | 26.7 | **0.52** | 26.8 | **0.51** |
| frame p50 / p99 / max | 2.4 / 29.6 / 39.8 | **2.0 / 4.7 / 7.0** | 1.8 / 27.4 / 34.5 | **1.8 / 4.1 / 5.9** |
| scan excl route p99 | 1.35 | **1.33** | 1.35 | **1.32** |

- Route p99 reduction is **99.0%** at both speeds.
- The dispatch, clear and final hashes are identical between oracle and optimized.

**Clean session A.** No other jobs were running, but the laptop was running about 2.5x slower overall (oracle Dijkstra p99 69 ms):

- optimized Dijkstra p99 0.69 ms, frame p99 12.9 ms, frame max 18.3 ms, 99.0% reduction;
- the **S1 scan p99 was 3.6–3.8 ms for both oracle and optimized in that session**, which is above the 3 ms gate. This is machine state, not S2: the same-session opt and oracle scans are equal, and S2 does not touch the selector.

**Contaminated sessions.** Two unrelated `m17_canonical_confirmation_v07_r02` Godot campaign jobs, not started by me, were running at the start of this task. Both of those runs are kept, labelled and not used for the gates:

- the first C003-probe baseline (`timing_baseline_preS2_CONTAMINATED.json`);
- the first A/B (`timing_ab_CONTAMINATED_m17_jobs.json`).

## Regression (J): `evidence/regression_summary.txt`

Godot 4.7.2 headless, 6-way parallel, **115 suites**. The owner scratch file `_m55_diag_tmp` is excluded, and the 4 long focused suites were run standalone.

- **113 exit 0.** This includes:
  - root `run_tests.gd`, **5323 checks, ALL PASS** (M15/M19 strict);
  - M20–M22 routing/railroad, M25/M26, M27 including 59x59, M28 including `m28_c002_c003_r01_remediation` (railway-first), and M29 including exact slot origin and speed authority;
  - M30, M31/M32 59x59, M36 and M53 difficulty analyzers (equal-weight mode), all M39, M40–M43, M52 and M55 including the long session.
- The standalone suites all passed:
  - `m25_c003_exact_prefilter` **PASS**; its uninstrumented production 2x/1x runs measured Dijkstra p99 0.28 ms, frame p99 5.1 / 4.8 ms and scan p99 1.52 / 1.54 ms;
  - `m29_c002_tempo_retune` **PASS** (9 / 18 cells/s, 1/3 / 1/6 s, one lane per frame);
  - `m25_c004_railroad_differential` **PASS**;
  - `m25_c004_host_truth` **PASS**.
- The only non-zero exits are `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B). These have identical known baseline signatures.
- `SCRIPT ERROR` appears only in the known m20_v04/v05/v07/v08 lifecycle baseline.
- `git diff --check`: clean.

## Files

- Production: `scripts/gameplay/routing/production_routing_system.gd`
  - `_railroad_layered` added;
  - `_railroad_finish` shared tail;
  - gate added in `_railroad_route`;
  - updated doc comments.
- Tests (test-only):
  - `tests/support/m25_c004_railroad_baseline.gd` (frozen oracle);
  - `tests/support/m25_c004_baseline_counting.gd`;
  - `tests/m25_c004_railroad_differential.gd`;
  - `tests/m25_c004_host_truth.gd`;
  - `tests/tools/m25_c004_perf_ab.gd`.
- Evidence (`coordination/sessions/M25-C004/evidence/`):
  - `differential_report.{md,json}` and `differential_run.log`;
  - `host_truth_report.json` and `host_truth_run.log`;
  - `work_count_report.md`;
  - `before_after_performance_report.md`;
  - `timing_ab_clean2.json` (primary), `timing_ab_clean.json`, `timing_ab_CONTAMINATED_m17_jobs.json`, `timing_baseline_preS2_CONTAMINATED.json`;
  - `regression_summary.txt`.

`AWAITING_CHATGPT_AUDIT / M25-C004 EXACT-EQUIVALENT RAILROAD ACCELERATION V01`
