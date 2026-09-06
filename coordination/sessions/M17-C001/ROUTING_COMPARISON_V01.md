# M17-C001 — Routing Prototype Comparison (V01)

Status: **NEUTRAL COMPARISON — no winner declared. OWNER_DESIGN_GATE OPEN.**

This document reports neutral, reproducible observations for three EXPERIMENTAL
routing prototypes built behind the locked M16 `compute_route` contract. It does
**not** select a production routing algorithm or movement language. The final
movement language is an owner decision (M17 prompt "Owner design gate").

All numbers below were produced headlessly with Godot 4.7.1 using the same
deterministic scenarios and the shared `RouteMetrics` utilities. CPU is
route-computation microseconds only — **no FPS/GPU claim**. Every successful
route in these runs passed the shared M16 `RouteValidator`.

## Prototypes

- **Direct** — single straight segment `[start, target]`; succeeds only if that
  one segment is accepted by access truth. Never bends, never retargets.
- **Grid-aware** — deterministic BFS on the board-local 4-neighbour cell-centre
  lattice; non-target ACTIVE blocks, CLEARED opens, target enterable only as the
  final endpoint; exterior slot origins enter via a nearest-first, capped,
  validated perimeter bridge.
- **Organized/curved** — post-process of the grid path: collinear reduction →
  validated greedy shortcut → validated quadratic-bezier corner rounding, with
  fallback to the last valid section (never accepts an invalid segment).

## Metric definitions (exact)

- **distance** — sum of consecutive segment lengths, board-local cell units.
- **crossings** — count of PROPER interior segment intersections between
  distinct routes. Shared start/end endpoints do NOT count; collinear overlap is
  NOT counted here (it is congestion). Self-crossings are out of scope.
- **congestion** — routes quantised into cells (0.25 sampling):
  `max_overlap` = max distinct routes sharing one cell; `total_repeated` = sum of
  `max(0, users-1)` over cells (extra corridor sharing beyond the first user).
- **cpu_mean_us** — mean microseconds per `compute_route` call over 3 samples.
- **determ** — identical points on repeat for identical state/request/config.

## Semantic-regression evidence

| Scenario | Observation |
|---|---|
| S2 blocker | Direct → NO_ROUTE (straight blocked); Grid/Organized detour and validate. |
| S3 enclosed | All three → NO_ROUTE, target identity retained, no retarget. |
| S4 opened-after-clear | Grid before=NO_ROUTE; after clearing prerequisite cells the SAME target routes and validates. |

## Comparison tables

Format: `success | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ`

### S1 Open/simple — 12×9, 3 routes
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 3 | 0 | 20.1 | 6.71 | 0 | 1 | 0 | 108.9 | true |
| Grid | 3 | 0 | 22.8 | 7.61 | 0 | 1 | 0 | 819.6 | true |
| Organized | 3 | 0 | 20.1 | 6.71 | 0 | 1 | 0 | 900.6 | true |

### S2 Blocker/detour — 14×11, 1 route
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 0 | 1 | 0.0 | 0.00 | 0 | 0 | 0 | 251.7 | true |
| Grid | 1 | 0 | 19.7 | 19.72 | 0 | 1 | 0 | 1187.0 | true |
| Organized | 1 | 0 | 19.5 | 19.52 | 0 | 1 | 0 | 1392.0 | true |

### S3 Enclosed — 11×11, 1 route (expect NO_ROUTE)
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 0 | 1 | 0.0 | 0.00 | 0 | 0 | 0 | 89.3 | true |
| Grid | 0 | 1 | 0.0 | 0.00 | 0 | 0 | 0 | 1127.0 | true |
| Organized | 0 | 1 | 0.0 | 0.00 | 0 | 0 | 0 | 922.0 | true |

### S5 Crossing pressure — 30×30
5 routes:
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 4 | 1 | 72.6 | 18.16 | 0 | 2 | 2 | 305.7 | true |
| Grid | 5 | 0 | 108.5 | 21.70 | 0 | 2 | 13 | 1940.7 | true |
| Organized | 5 | 0 | 97.2 | 19.44 | 1 | 2 | 5 | 2404.1 | true |

10 routes:
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 7 | 3 | 111.0 | 15.85 | 2 | 2 | 11 | 231.4 | true |
| Grid | 10 | 0 | 209.3 | 20.93 | 0 | 2 | 41 | 1884.9 | true |
| Organized | 10 | 0 | 182.6 | 18.26 | 6 | 2 | 27 | 2542.9 | true |

25 routes:
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 15 | 10 | 274.1 | 18.28 | 14 | 5 | 55 | 263.7 | true |
| Grid | 25 | 0 | 609.5 | 24.38 | 0 | 6 | 266 | 2242.2 | true |
| Organized | 25 | 0 | 538.0 | 21.52 | 59 | 5 | 182 | 2740.1 | true |

### S6 Stress density — 40×40, 50 routes
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 19 | 31 | 333.0 | 17.53 | 15 | 5 | 86 | 227.4 | true |
| Grid | 50 | 0 | 1587.4 | 31.75 | 0 | 11 | 967 | 10432.9 | true |
| Organized | 50 | 0 | 1447.0 | 28.94 | 233 | 10 | 742 | 12665.4 | true |

### S7 59×59 (production max), 25 routes
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 20 | 5 | 746.5 | 37.33 | 30 | 5 | 116 | 1606.1 | true |
| Grid | 25 | 0 | 1185.2 | 47.41 | 0 | 6 | 499 | 20457.8 | true |
| Organized | 25 | 0 | 982.5 | 39.30 | 58 | 5 | 204 | 22796.5 | true |

### S8 Rectangular Very Hard — 53×59, 25 routes
| strategy | succ | no_route | dist_total | dist_mean | crossings | max_overlap | total_repeated | cpu_mean_us | determ |
|---|---|---|---|---|---|---|---|---|---|
| Direct | 21 | 4 | 726.7 | 34.60 | 32 | 5 | 127 | 1538.0 | true |
| Grid | 25 | 0 | 1110.2 | 44.41 | 0 | 6 | 478 | 18688.5 | true |
| Organized | 25 | 0 | 913.6 | 36.54 | 57 | 5 | 197 | 20489.9 | true |

## Neutral observations (NOT a ranking)

- **Direct** minimises distance and route computation cost and has the fewest
  corridor-sharing cells, but fails whenever its straight segment crosses any
  non-target ACTIVE cell — including another route's target cell — so its
  success rate drops sharply as density rises.
- **Grid-aware** solves every reachable target in these scenarios and shows 0
  *proper* crossings (its axis-aligned cell-centre segments meet, when they do,
  at shared lattice points rather than transversally), but it produces the
  longest paths and the highest corridor congestion, and the highest CPU cost.
- **Organized/curved** keeps grid's full success rate with shorter paths than
  grid and lower congestion than grid, at the cost of more *proper* geometric
  crossings (its shortcut/curve segments are no longer axis-aligned) and the
  highest CPU cost of the three.
- The grid "0 crossings vs high congestion" versus organized "more crossings vs
  lower congestion" contrast is exactly the kind of trade-off the owner should
  judge visually — the numbers do not settle it.

## Known limitations (experimental)

- Access truth is a **sampled** segment check (0.1 cell step): exact for
  axis-aligned grid segments, approximate for organized diagonal/curved segments.
- The exterior bridge is a straight, nearest-first, capped perimeter model
  (`MAX_ENTRIES=12`); it is an experimental representation of outside-board free
  space, not a canonical exterior navigation model.
- CPU figures include the exterior bridge scan and vary with machine load; treat
  them as relative comparison only, never as production/mobile performance.
- "Crossings = 0" for grid is a property of axis-aligned geometry, not a claim
  that grid routes never visually overlap (see congestion).

## Original SCRUBBOTS visual-direction comparison (SB-M17-010)

**BLOCKED_BY_MISSING_OWNER_REFERENCE.** `docs/01_GAMEPLAY_SPEC.md` explicitly
marks route shape and movement language `[TO BE DESIGNED]` (M15/M16/M17); no
authoritative owner reference documenting the original movement direction exists
in the repo/local project. Static owner visual references exist in
`assets/art/references/_owner_inbox/` (e.g. `Game Screens/`, `Playing Motors/`)
but are unclassified intake images, not a documented movement-language
direction, and are not treated as authoritative movement evidence. No generic
external-game ("Colony Flow-like") assumption is substituted.

## Owner review checklist

1. Open `scenes/debug/routing_prototype_lab.tscn` in Godot 4.7.1.
2. Switch **Strategy** across Direct / Grid-aware / Organized on the same
   scenario; watch route shape, crossings and overlap in the overlay.
3. Step through **Scenario** S1..S8 and **Bots** 1/5/10/25/100.
4. Toggle **Curved rounding** (organized) to see the curvature effect.
5. On **S4**, toggle **Apply S4 clear** to see a previously enclosed target
   become routable to the SAME target.
6. Read the metric panel (right) for distance / crossings / congestion / CPU /
   determinism and success/no-route counts.
7. Decide the final movement language — this document declares no winner.
