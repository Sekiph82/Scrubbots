# M25-C004 before/after performance (same-session A/B, laid-out 59x59 six-stripe full level to WON)

Baseline = the FROZEN pre-S2 Railroad oracle (`tests/support/m25_c004_railroad_baseline.gd`, verbatim `aadc5725`) swapped (via `set_script`, identity preserved) into the live host routing instance; optimized = production `ProductionRoutingSystem`. S1 prefilter ENABLED in both. 1080x2160 laid-out host, +1 Slot (6 origins, all `y = 72.78` below the board). Runs alternate oracle/opt so both see the same machine state. Tool: `tests/tools/m25_c004_perf_ab.gd`. Times in ms from RuntimePerfProbe per frame (one lane per frame). Identical dispatch/clear/final hashes between oracle and optimized in every session.

## PRIMARY clean session B (machine at full speed; oracle Dijkstra p99 matches the M25-C003 published ~25-28 ms; 2 interleaved rounds)

File: `evidence/timing_ab_clean2.json`

| run | route_dijkstra mean / p50 / p99 / max | winner route p99 / max | frame p50 / p99 / max | scan excl route p99 / max | hashes dispatch / clear / final |
|---|---|---|---|---|---|
| oracle2x r0 | 9.087 / 7.713 / **24.88** / 30.106 | 26.737 / 33.256 | 2.374 / **29.551** / 39.764 | 1.346 / 2.397 | 2865577215 / 3442509311 / 3105958246 |
| opt2x r0 | 0.065 / 0.042 / **0.252** / 0.34 | 0.518 / 0.642 | 2.015 / **4.41** / 5.383 | 1.311 / 1.953 | 2865577215 / 3442509311 / 3105958246 |
| oracle1x r0 | 8.985 / 7.68 / **24.815** / 26.778 | 26.769 / 28.871 | 1.76 / **27.273** / 32.952 | 1.325 / 2.163 | 1234950815 / 533425599 / 3105958246 |
| opt1x r0 | 0.066 / 0.043 / **0.254** / 0.314 | 0.503 / 0.645 | 1.744 / **4.073** / 5.924 | 1.322 / 1.5 | 1234950815 / 533425599 / 3105958246 |
| oracle2x r1 | 8.966 / 7.765 / **24.646** / 26.342 | 26.596 / 28.365 | 2.302 / **29.032** / 33.025 | 1.324 / 1.945 | 2865577215 / 3442509311 / 3105958246 |
| opt2x r1 | 0.065 / 0.043 / **0.252** / 0.333 | 0.512 / 0.642 | 2.03 / **4.684** / 6.966 | 1.331 / 1.758 | 2865577215 / 3442509311 / 3105958246 |
| oracle1x r1 | 8.987 / 7.653 / **24.45** / 27.351 | 26.427 / 29.377 | 1.77 / **27.435** / 34.543 | 1.346 / 1.917 | 1234950815 / 533425599 / 3105958246 |
| opt1x r1 | 0.065 / 0.043 / **0.25** / 0.314 | 0.509 / 0.633 | 1.769 / **4.077** / 5.533 | 1.32 / 1.896 | 1234950815 / 533425599 / 3105958246 |

- 2x: route_dijkstra p99 24.76 -> 0.252 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 26.67 -> 0.515 ms = 98.1% reduction
- 1x: route_dijkstra p99 24.63 -> 0.252 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 26.60 -> 0.506 ms = 98.1% reduction

Worst optimized run: route_dijkstra p99 **0.254** ms (gate <= 8) · frame p99 **4.684** ms (gate <= 20) · frame max 6.966 ms, winner-route max 0.645 ms (route-caused frame max gate <= 33.3) · scan excl route p99 **1.331** ms (S1 gate <= 3)

## Clean session A (no other Godot jobs, but the laptop was running ~2.5x slower overall — oracle Dijkstra p99 ~69 ms; 2 interleaved rounds). Reported in full because the S1 scan p99 misses 3 ms here for BOTH oracle and optimized (machine state, not S2)

File: `evidence/timing_ab_clean.json`

| run | route_dijkstra mean / p50 / p99 / max | winner route p99 / max | frame p50 / p99 / max | scan excl route p99 / max | hashes dispatch / clear / final |
|---|---|---|---|---|---|
| oracle2x r0 | 24.941 / 21.08 / **68.89** / 86.729 | 74.874 / 93.379 | 6.159 / **79.536** / 104.549 | 3.957 / 6.111 | 2865577215 / 3442509311 / 3105958246 |
| opt2x r0 | 0.165 / 0.102 / **0.69** / 0.969 | 1.405 / 2.105 | 6.106 / **12.883** / 17.842 | 3.786 / 5.44 | 2865577215 / 3442509311 / 3105958246 |
| oracle1x r0 | 25.088 / 21.65 / **68.834** / 85.394 | 74.47 / 100.342 | 5.298 / **74.041** / 107.109 | 3.711 / 6.561 | 1234950815 / 533425599 / 3105958246 |
| opt1x r0 | 0.165 / 0.105 / **0.682** / 1.13 | 1.375 / 1.916 | 5.319 / **11.714** / 18.257 | 3.826 / 6.83 | 1234950815 / 533425599 / 3105958246 |
| oracle2x r1 | 24.927 / 21.432 / **69.457** / 116.413 | 75.127 / 124.466 | 6.341 / **79.977** / 158.699 | 3.908 / 18.921 | 2865577215 / 3442509311 / 3105958246 |
| opt2x r1 | 0.163 / 0.103 / **0.68** / 3.045 | 1.377 / 3.551 | 5.96 / **12.67** / 17.128 | 3.716 / 6.381 | 2865577215 / 3442509311 / 3105958246 |
| oracle1x r1 | 25.082 / 21.656 / **68.656** / 80.814 | 74.352 / 86.063 | 5.342 / **74.112** / 97.575 | 3.655 / 5.217 | 1234950815 / 533425599 / 3105958246 |
| opt1x r1 | 0.163 / 0.102 / **0.662** / 0.848 | 1.341 / 2.996 | 5.326 / **11.252** / 16.99 | 3.609 / 4.882 | 1234950815 / 533425599 / 3105958246 |

- 2x: route_dijkstra p99 69.17 -> 0.685 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 75.00 -> 1.391 ms = 98.1% reduction
- 1x: route_dijkstra p99 68.75 -> 0.672 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 74.41 -> 1.358 ms = 98.2% reduction

Worst optimized run: route_dijkstra p99 **0.69** ms (gate <= 8) · frame p99 **12.883** ms (gate <= 20) · frame max 18.257 ms, winner-route max 3.551 ms (route-caused frame max gate <= 33.3) · scan excl route p99 **3.826** ms (S1 gate <= 3)

## CONTAMINATED session (two unrelated `m17_canonical_confirmation_v07_r02` Godot campaign jobs, not started by this task, were running; 1 round) — reported, not used for gates

File: `evidence/timing_ab_CONTAMINATED_m17_jobs.json`

| run | route_dijkstra mean / p50 / p99 / max | winner route p99 / max | frame p50 / p99 / max | scan excl route p99 / max | hashes dispatch / clear / final |
|---|---|---|---|---|---|
| oracle2x r0 | 30.087 / 26.598 / **88.026** / 104.701 | 95.641 / 113.099 | 7.618 / **96.061** / 129.387 | 5.574 / 6.277 | 2865577215 / 3442509311 / 3105958246 |
| opt2x r0 | 0.203 / 0.127 / **0.869** / 1.235 | 1.76 / 2.539 | 7.29 / **16.131** / 21.73 | 5.392 / 6.783 | 2865577215 / 3442509311 / 3105958246 |
| oracle1x r0 | 29.416 / 24.976 / **86.236** / 100.888 | 93.326 / 107.361 | 6.038 / **91.006** / 123.243 | 5.444 / 13.981 | 1234950815 / 533425599 / 3105958246 |
| opt1x r0 | 0.193 / 0.121 / **0.897** / 1.216 | 1.736 / 2.577 | 6.115 / **14.425** / 22.452 | 5.456 / 7.656 | 1234950815 / 533425599 / 3105958246 |

- 2x: route_dijkstra p99 88.03 -> 0.869 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 95.64 -> 1.760 ms = 98.2% reduction
- 1x: route_dijkstra p99 86.24 -> 0.897 ms = **99.0% reduction**; whole winner route (compute_route incl. validate) p99 93.33 -> 1.736 ms = 98.1% reduction

Worst optimized run: route_dijkstra p99 **0.897** ms (gate <= 8) · frame p99 **16.131** ms (gate <= 20) · frame max 22.452 ms, winner-route max 2.577 ms (route-caused frame max gate <= 33.3) · scan excl route p99 **5.456** ms (S1 gate <= 3)

## Gate verdict

| Gate | Session B (primary) | Session A (slow machine) |
|---|---|---|
| route_dijkstra p99 <= 8 ms | PASS (0.25) | PASS (0.69) |
| frame p99 <= 20 ms | PASS (4.7) | PASS (12.9) |
| >= 50% same-session p99 route-time reduction | PASS (99.0%) | PASS (99.0%) |
| route-caused frame max <= 33.3 ms | PASS (winner route max 0.65 ms; frame max 7.0 ms) | PASS (winner route max 3.6 ms; frame max 18.3 ms) |
| S1 scan excl route p99 <= 3 ms | PASS (1.33) | MISS 3.6-3.8 ms (opt worst 3.83) for BOTH oracle and optimized — machine slowed ~2.5x (oracle Dijkstra 69 ms vs 25 ms in B); S2 does not touch the selector scan (same-session opt vs oracle scan p99 equal) |

The M25-C003 timing probe (`tests/tools/m25_c003_timing_probe.gd`-equivalent `production uninstrumented` runs inside the standalone `m25_c003_exact_prefilter` suite on the final code) also measured: 2x route_dijkstra p99 0.283 ms, frame p99 5.06 ms, scan p99 1.52 ms; 1x 0.287 / 4.77 / 1.54 ms.
