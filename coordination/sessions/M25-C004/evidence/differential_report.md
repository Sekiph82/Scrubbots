# M25-C004 differential report: optimized production vs frozen pre-S2 oracle

Suite: `tests/m25_c004_railroad_differential.gd`. Raw data: `differential_report.json`. Run log: `differential_run.log`.
Oracle: `tests/support/m25_c004_railroad_baseline.gd`. It is a verbatim copy of `scripts/gameplay/routing/production_routing_system.gd` at `aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`; only a 4-line header comment was prepended. `diff <(git show aadc5725:…) <(tail -n +5 oracle)` is empty.

## Equality rule (per comparison)

Both implementations run the same `RouteRequest` on the same `BoardState`, with the same access object and the same `interior_step_cost`. The results must match on all of the following:

- `success`;
- `String(failure_reason)`;
- `target_index`;
- `point_count`;
- `get_points().to_byte_array()`, a **byte-exact** comparison of every point coordinate in order.

## Result: **48,202 comparisons, 0 diffs**

- 37,902 compared successes and 10,300 compared failures (all `NO_ROUTE`).
- 228,983 route points compared byte-exact.
- 477 generated board states.

| Group | Comparisons | What it covers |
|---|---|---|
| t1:prod | 19,830 | Production levels 1..10 (20x20 Hazard Bot, 32x32, 33x33, 38x38), 9 topology generators × 3 params, both routing modes |
| t1:syn | 14,708 | Synthetic 20x20, 24x40, 40x24, 32x32, 38x38, 23x31, 59x59, 45x27 |
| t1:tunings | 1,792 | `interior_step_cost` 0.5 / 2 / 500 / 999 / 1000 (generic-fallback proof) |
| t1:inside_origin | 648 | Inside-board debug origins (interior BFS planner unchanged) |
| t2:subclass_access | 984 | `ProductionAccessQuery` subclass (script ≠ canonical, so the generic path runs) |
| t2:wrapper_access | 984 | Duck-typed wrapper access |
| t2:edge_block_access | 984 | Non-canonical access that blocks one extra cell centre |
| t2:board_subclass | 328 | `BoardState` subclass (snapshot fast path must not engage) |
| t4:tie_guard | 7,584 | Fully open boards, symmetric targets, entry x on / near quarter-integer tie points |
| t4:corridor_tie | 360 | Single cleared corridor row, LEFT vs RIGHT ingress exactly tied at the centre, deltas ±1e-12 … ±0.5 |

Topology generators:

- ring peel with skips (sealed pockets);
- uniform random;
- rooms + random-walk corridors;
- vertical stripes;
- horizontal bands with gaps;
- late-game sparse ACTIVE;
- checkerboard (diagonal-only connectivity);
- bottom-up row peel;
- large open area with walls.

Targets are frontier cells, perimeter cells, and random ACTIVE cells, which includes enclosed ones.

Origins:

- six production-like slot origins below the board (the sixth slot included);
- integer and half-integer tie-prone entries;
- board-edge origins;
- origins beyond the rail span (clamped entry);
- top, left, right and corner outside starts;
- random origins;
- inside-board debug origins.

Modes: `INTERIOR_STEP_COST` (1000.0) gave 27,697 comparisons and `TOTAL_TRAVEL_COST` (1.0) gave 19,069; the other tunings gave 1,436.

## Path accounting (optimized side)

| Path | Count |
|---|---|
| layered (success) | 21,319 |
| layered_no_route (exact NO_ROUTE from the reverse BFS) | 4,106 |
| guard_fallback (near-tie guard tripped, so the generic Dijkstra ran) | 144 |
| generic (not eligible: equal-weight / other tuning / non-canonical access / board subclass / inside origin / invalid) | 22,633 |

## Mutation checks (the suite detects wrong implementations)

The suite was also run against deliberately broken variants of the production file. The original was restored and verified byte-identical afterwards.

- **Per-layer pop-order sort removed:** 179 diffs, FAIL.
- **Side priority reversed in the layered rank key:** 7 diffs, FAIL.
- **Near-tie guard disabled (`_LAYER_TIE_GUARD = -1`):** 18 diffs in t4, FAIL.
  - The guard is load-bearing. At near-ties below `_RAIL_LEN_EPS` (1e-4), the generic Dijkstra's eps-equal comparisons are not a strict order.
  - The optimized path therefore declines those cases and delegates them to the frozen algorithm.
