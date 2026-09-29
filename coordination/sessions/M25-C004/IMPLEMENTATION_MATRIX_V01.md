# M25-C004 — IMPLEMENTATION MATRIX V01 (exact-equivalent Railroad acceleration S2, SB-M25-035)

Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Log: `CLAUDE_LOG_V01.md`
Focused suites: `tests/m25_c004_railroad_differential.gd` **PASS**, `tests/m25_c004_host_truth.gd` **PASS**
Evidence: `evidence/`

## Production change (HOW only)

| File | Change |
|---|---|
| `scripts/gameplay/routing/production_routing_system.gd` | Adds `_railroad_layered()`, an exact-equivalent layered search. The gate at the top of `_railroad_route` requires all three of: the exact `ProductionAccessQuery` script, the exact `BoardState` script, and `interior_step_cost == INTERIOR_STEP_COST`. If any is missing, or the runtime near-tie guard trips, it returns `null` and the unchanged pre-S2 Dijkstra runs. The route tail moves into a shared `_railroad_finish()`, whose code is identical. It also adds the debug-only `collect_work_counts` / `last_work_counts` (off by default) and updates the doc comments. |

Not changed:

- TargetSelector;
- ProductionTargetAccess (S1);
- claims and reservations;
- scheduler / lane budget;
- speed / cadence;
- economy;
- level data;
- renderer / UI;
- `TASKS.md`.

## Criteria → evidence

| Crit | Requirement | Proof | Result |
|---|---|---|---|
| A | Frozen test-only oracle from `aadc5725`, not loaded by shipping, never modified | `tests/support/m25_c004_railroad_baseline.gd` is verbatim apart from a 4-line SHA header; `diff` against `git show aadc5725:…` is empty. It was created before any production edit. `scripts/` and `scenes/` contain 0 references to it. | PASS |
| B | ≥10,000 point-for-point comparisons, 0 diffs | `m25_c004_railroad_differential`: **48,202 comparisons, 0 diffs**. Each compares success, reason, target, point count and a **byte-exact** point array. Coverage: 37,902 successes, 10,300 failures, 228,983 points, 477 states, production levels 1..10 and 8 synthetic sizes up to 59x59. Mutation checks, where the suite must FAIL: sort removed gives 179 diffs, side priority reversed gives 7, near-tie guard disabled gives 18. | PASS |
| C | Railway-first / tie-break preserved | The sweep order is the exact generic heap order `(cost0 rank, side, seq, cell)`. The first popped neighbour becomes the parent, which is the generic first-relaxation rule. The seed labels use the identical eps + `_rank_lt` rule. The collinear collapse and validator are shared through `_railroad_finish`. Proof: t1 over all 9 topologies, and t4 exact-tie and near-tie sweeps (open boards, LEFT/RIGHT corridor ties, ±1e-12…±0.5), all with 0 diffs. | PASS |
| D | Equal-weight / non-canonical / debug-inside unchanged | Fallback preconditions are explicit. 19,069 equal-weight (1.0) comparisons and 1,436 comparisons at other tunings (0.5/2/500/999) all took the generic path with 0 diffs. Non-canonical access (subclass, wrapper, edge-blocker; 2,952 comparisons), a BoardState subclass (328) and inside-board origins (648) gave 0 diffs. Junk, null or unbound inputs, a non-ACTIVE target, an invalid index and a non-finite origin all produced identical results. M36 and M53 analyzers PASS. | PASS |
| E | Real laid-out 59x59 truth | `m25_c004_host_truth`, at both 2x and 1x, oracle-routing host vs optimized host: all **3,481 compute_route calls identical** (origin, target, success, reason, full points); identical dispatch target/colour sequence, clear sequence and final board; 3481/3481 clears; WON; 0 duplicates; zero residue; origins below the board. In a shadow run on the live state the oracle matched 3,481/3,481. | PASS |
| F | S1 preserved | compute_route ≤ 1 per lane; 0 failed route probes; 1 lane per frame (host truth). Scan excluding route p99 is 1.33 ms in primary session B, and 1.52 / 1.54 ms in the M25-C003 suite's uninstrumented runs. In slow-machine session A it was 3.6–3.8 ms for **both** the oracle and optimized, a machine-speed effect reported in full. `m25_c003_exact_prefilter` PASS. | PASS (≤3 ms in clean full-speed sessions) |
| G | Perf: Dijkstra p99 ≤ 8, frame p99 ≤ 20, ≥ 50% reduction, route-caused max ≤ 33.3 | Primary same-session A/B B: Dijkstra p99 **24.9 → 0.25 ms (2x)** and **24.8 → 0.25 ms (1x)**, a **99.0%** reduction; frame p99 **4.7 / 4.1 ms**, frame max 7.0 / 5.9 ms, winner-route max 0.65 ms. Slow session A: 0.69 ms, frame p99 12.9 ms, max 18.3 ms, 99.0%. Contaminated runs are reported separately. | PASS |
| H | Work-count explanation; no unbounded cache | `evidence/work_count_report.md`: the oracle does per route 1,187 / 3,172 pops (mean / p99), 4,571 / 12,458 `get_cell_state` reads and 171 source labels. The layered path uses 1 snapshot, 150 / 880 reverse-BFS cells, 12 / 65 sweep cells and 1.02 critical labels. Baseline pops over optimized visits: mean 31x, p99 174x. There is no cache and all state is per call. | PASS |
| I | Tempo / scheduler isolation | No scheduler, speed or economy file changed. `m29_c002_tempo_retune` PASS (9 / 18 cells/s, 1/3 and 1/6 s). One lane per frame (host truth). M39 all PASS. | PASS |
| J | Regression / governance | 115 suites in parallel: 113 exit 0, including root 5323/5323 ALL PASS, M15/M19, M22, M25/M26/M27, M28 railway-first, M29, M30, M36/M53, M39, M52 and M55 long session. The 4 long focused suites PASS standalone. The only non-zero exits are m21_v08 (C/043, C/047) and m21_v09 (B), the known signatures. `git diff --check` clean. `TASKS.md` untouched. | PASS |

## Fast-path preconditions / fallbacks (summary)

| Condition | Path |
|---|---|
| Outside origin + exact `ProductionAccessQuery` + exact `BoardState` + `interior_step_cost == 1000.0` + no near-tie among critical sources | layered (exact) |
| Same, but critical-source costs within (0, 1e-3] of each other | generic pre-S2 Dijkstra (guard fallback) |
| `interior_step_cost != 1000.0` (equal-weight analyzers, any tuning) | generic pre-S2 Dijkstra |
| Access subclass, wrapper or any non-canonical access | generic pre-S2 Dijkstra |
| BoardState subclass | generic pre-S2 Dijkstra |
| Inside-board origin | unchanged interior BFS planner |
| Invalid request, access or board | unchanged validation path |
