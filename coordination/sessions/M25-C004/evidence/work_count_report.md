# M25-C004 work-count report (real laid-out 59x59 six-stripe host, 2x, shadow run)

Source: `tests/m25_c004_host_truth.gd` shadow run — for every one of the 3481 live routes of a full level (one per dispatch; all 3481 took the layered path, 0 generic fallbacks, 0 near-tie guard trips) the optimized production routing returned the route to the game while the frozen pre-S2 oracle AND a work-counting replica of it (`tests/support/m25_c004_baseline_counting.gd`, same algorithm; re-verified identical to the oracle for every route) re-ran on the identical live state. Values: mean / p50 / p99 / max per route.

## Frozen pre-S2 Dijkstra (per route)

| counter | mean / p50 / p99 / max |
|---|---|
| ingress sources built (classify + rail_dist each) | 171.07 / 179 / 236 / 236 |
| heap pops | 1186.6 / 1045 / 3172 / 3358 |
| heap pushes | 1241.5 / 1106 / 3191 / 3371 |
| stale pops | 0.0 / 0 / 0 / 0 |
| relaxations | 1072.49 / 926 / 2968 / 3139 |
| neighbour checks | 4572.45 / 3986 / 12459 / 13192 |
| `board.get_cell_state()` reads | 4571.45 / 3985 / 12458 / 13191 |
| max heap size | 169.01 / 177 / 232 / 232 |

## Optimized layered search (per route)

| counter | mean / p50 / p99 / max |
|---|---|
| BoardState snapshots (one detached `get_cell_states_copy`) | 1.0 / 1 / 1 / 1 |
| interior steps K (minimum, = chain length - 1) | 10.51 / 9 / 34 / 37 |
| reverse-BFS cells expanded | 150.08 / 53 / 880 / 1005 |
| reverse-BFS neighbour checks (packed array reads) | 600.31 / 212 / 3520 / 4020 |
| reverse-BFS cells reached | 170.29 / 67 / 947 / 1079 |
| critical ingress sources evaluated (cost0/rail_dist) | 1.02 / 1 / 2 / 2 |
| forward-sweep cells (min-step-path cells only, sorted per layer) | 12.19 / 9 / 65 / 133 |
| chain cells | 11.51 / 10 / 35 / 38 |

Baseline pops / (optimized reverse-expanded + sweep cells): mean 31.48x, p50 16.1x, p99 174.0x, max 213.5x.

## Why it is faster (exact explanation)

The generic Dijkstra multi-source-expands EVERY board cell reachable in fewer interior steps than the target (from all ~171 perimeter ingress sources), through a binary heap (4-key compare), with one `get_cell_state` method call + Vector2/Dictionary work per neighbour, and builds ~171 source records (a `classify_cell` call and a `rail_dist` per perimeter cell) before searching. With INTERIOR_STEP_COST = 1000 the search is lexicographic (fewest interior steps first), so only cells on minimum-step paths can ever influence the returned chain. The layered search (a) reads board truth once (one detached snapshot, no per-neighbour method call), (b) expands only the radius-K neighbourhood of the *target* (reverse BFS, K = minimum interior steps, typically ~10) instead of the whole cleared region seen from every perimeter cell, (c) evaluates the ingress label (cost0 / rail_dist) only for the critical perimeter cells on layer K (about 1.02 per route) instead of all perimeter cells, (d) replaces the heap by one native `sort()` per layer over the few critical cells (exact pop order (label rank, cell)), and (e) stops at the target's first labelling. The route is identical, not approximate; the algorithm is not Dijkstra-with-a-cache: nothing persists between calls (no cache to invalidate; all arrays are per-call).
