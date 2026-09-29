# M25-C004 — EXACT-EQUIVALENT RAILROAD / DIJKSTRA ACCELERATION — IMPLEMENTATION PROMPT V01

Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M25-035`
Status: READY FOR CLAUDE

Blocking parent:
`SB-M29-010 — Gameplay Tempo Retune`

Prior accepted work:
- M25-C002 investigation: `coordination/sessions/M25-C002/CHATGPT_AUDIT_V01.md`
- M25-C003 S0+S1 audit: `coordination/sessions/M25-C003/CHATGPT_AUDIT_V01.md`

Current production baseline to preserve:
`aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`

Do not edit root `TASKS.md`.

## Why this cycle exists

M25-C003 removed the WHAT-side scan hotspot:

- 2x selector scan p99: 5.62 -> ~1.78 ms;
- 1x selector scan p99: 5.90 -> ~1.82 ms;
- target winner / reservation / dispatch / clear truth remained identical.

The remaining real-layout 59x59 hotspot is now the single winning Railroad route calculation:

- Dijkstra p99 ~27.7 ms at 2x;
- Dijkstra p99 ~33.1 ms at 1x;
- frame max ~51.8 ms / ~74.0 ms.

At 60 FPS the frame budget is ~16.7 ms.

This cycle optimizes HOW only.

## Non-negotiable owner rule

The optimized production route must be **point-for-point identical** to the current production Railroad route for the same:

- request;
- board state;
- origin;
- target;
- access authority;
- routing tuning.

"Equivalent length", "same target", "visually similar", or "also RouteValidator-clean" is NOT sufficient.

For every differential case, optimized vs frozen baseline must match:

1. success/failure;
2. failure reason;
3. target index;
4. point count;
5. every route point in the same order and same coordinates.

The railway-first rule and deterministic tie-break are immutable.

## Scope

Primary production file:

`scripts/gameplay/routing/production_routing_system.gd`

Supporting test-only baseline/oracle files are expected.

Small read-only helpers may be added elsewhere only if necessary and audited.

Do NOT change:
- TargetSelector;
- ProductionTargetAccess S1 semantics;
- claims/reservations;
- scheduler/lane budget;
- gameplay speed/cadence;
- economy;
- level data;
- BoardRenderer/UI;
- route owner rules.

## Freeze a pre-S2 oracle BEFORE optimization

Create a TEST-ONLY frozen baseline Railroad implementation copied from commit:

`aadc57253d45dcd6b71ca8cc1b00b7a7684e0574`

Recommended location:

`tests/support/m25_c004_railroad_baseline.gd`

or an equivalent test-only path.

Requirements:

- clearly mark the source commit SHA;
- do not load it in shipping runtime;
- preserve the current Railroad algorithm/tie-break exactly;
- use it only for differential proof;
- do not "update" the oracle to make the new implementation pass.

The oracle must include enough of the old route path to compare actual RouteResult outputs, not merely route cost.

## Current route contract that MUST remain exact

Production default:

`INTERIOR_STEP_COST = 1000.0`

Canonical railway-first ordering:

1. minimize number of interior board steps;
2. then connector + rail + ingress cost;
3. then side priority:
   `BOTTOM -> LEFT -> RIGHT -> TOP`;
4. then same-side perimeter sequence;
5. then deterministic interior expansion behavior;
6. final returned points remain validator-clean and use the same collinear collapse.

The current Dijkstra also has a strict heap ordering:

`(cost, side, seq, cell)`

Do not change observable tie outcomes.

### Equal-weight / analysis mode

`ProductionRoutingSystem.interior_step_cost` may be set to:

`TOTAL_TRAVEL_COST = 1.0`

by difficulty/analysis tooling.

S2 must preserve this mode exactly.

A production-only optimized fast path is allowed only when its preconditions are exact and explicit.

If the optimization relies on railway-first dominance at 1000.0, then:

- use it only for that exact mode / exact canonical access;
- fall back to the frozen/current generic Dijkstra semantics for `interior_step_cost != INTERIOR_STEP_COST`;
- noncanonical access doubles/subclasses must retain the generic validated path unless exact equivalence is proven.

## Preferred optimization order

Use the lowest-risk exact-equivalent improvements first.

### Stage A — exact micro-optimization of the existing Dijkstra

Candidates include:

- take one detached `BoardState.get_cell_states_copy()` for canonical production access instead of calling `board.get_cell_state()` in the inner neighbour loop;
- replace `for d in NEIGHBORS` / per-neighbour Vector2i work with explicit integer neighbour checks;
- avoid constructing cell-centre Vector2 values inside the canonical fast inner loop when segment checks are already proven unnecessary;
- replace source Dictionaries with packed/parallel arrays or small typed records;
- replace `src_rp: Dictionary` with a fixed per-cell packed ingress-point representation;
- pre-size heap arrays when a safe bound is known;
- reduce repeated Variant/Dictionary lookup in the hot loop;
- keep the same relax conditions and heap ordering.

These are strongly preferred because they can preserve the exact algorithm while reducing GDScript overhead.

### Stage B — stronger algorithmic acceleration only if needed

If Stage A cannot meet the performance target, an exact specialized production fast path is allowed, but only if:

- it is gated to exact safe preconditions;
- generic/equal-weight/noncanonical paths retain the baseline algorithm;
- the frozen oracle proves point-for-point identity over a broad state space.

Examples may include an exact bucket/layer formulation, reverse-distance pre-pass, or other specialized method.

Do not use a heuristic/approximate shortcut.

Do not accept a different shortest path among ties.

## Correctness differential matrix — BLOCKING

Build a dedicated S2 focused suite.

Compare optimized vs frozen baseline on at least:

### 1. Production levels

- levels 1..10;
- multiple board revisions per level;
- all valid slot origins/capacities available in the laid-out host;
- representative targets that are actually selected during play.

### 2. Synthetic boards

Include:
- 20x20;
- 32x32;
- 38x38;
- rectangular boards;
- 59x59 six-stripe;
- open board;
- narrow corridors;
- sealed pockets;
- corner targets;
- top/bottom/left/right perimeter targets;
- deep interior targets;
- multiple equal-cost/tie situations;
- boards with large CLEARED connected areas;
- late-game sparse ACTIVE states.

### 3. Origins

Include:
- all five baseline production slots;
- sixth slot;
- below-board starts;
- left/right/top outside starts where supported by current route contract;
- inside-board debug origin to prove the generic fallback is unchanged.

### 4. Routing modes

Compare:
- `interior_step_cost = INTERIOR_STEP_COST`;
- `interior_step_cost = TOTAL_TRAVEL_COST`;
- canonical ProductionAccessQuery;
- representative noncanonical/adversarial access doubles where existing suites cover them.

### Required equality

For every case:

`optimized RouteResult == frozen baseline RouteResult`

at observable route level:
- same success;
- same failure reason;
- same target;
- same points.

Record total differential case count and zero-diff result.

A handful of examples is insufficient. Target at least **10,000 route comparisons**, preferably much more through deterministic generated states.

## Real-host truth proof

On the fully laid-out 59x59 six-stripe host:

- run baseline oracle mode and optimized production mode against equivalent detached/replayed states;
- prove identical winning route points for every actual dispatch;
- identical target/color dispatch sequence;
- identical clear sequence;
- identical final board;
- 3481/3481 clears;
- WON;
- zero duplicate claim/dispatch/clear;
- zero residue.

M25-C003 target prefilter remains enabled in production mode.

## Work-count instrumentation

Add debug/test-only counters sufficient to explain the speedup, such as:

- heap pushes;
- heap pops;
- stale pops;
- neighbour checks;
- relaxations;
- board-state reads / bulk snapshot count;
- source count;
- max heap size.

Do not ship noisy logging.

If the algorithm remains Dijkstra, show that the performance gain comes from lower per-pop/per-neighbour overhead and/or fewer safe operations, not changed route semantics.

If the algorithm changes, provide an exact work-bound explanation.

## Performance gate — BLOCKING

Measure in a clean same-machine session, using the corrected laid-out 59x59 full-level harness from M25-C003.

Compare:

1. frozen/pre-S2 baseline;
2. optimized production.

At both new 1x and new 2x.

### Hard target

For the full 59x59 laid-out run:

- `route_dijkstra` p99 <= **8 ms**;
- full frame p99 <= **20 ms** at 60 FPS;
- no frame max caused by route computation above **33.3 ms** unless a separately identified non-routing subsystem is responsible.

If machine load contaminates results:
- detect it;
- rerun clean;
- report both contaminated and clean measurements.

Do not hide a miss.

### Relative target

Also require at least **50% reduction** in same-session p99 route time vs frozen baseline.

If exact point-for-point correctness passes but performance target fails, return a FAIL/BLOCKED handoff with measurements; do not weaken the criteria.

## Preserve S1 gains

M25-C003 must not regress:

- selector scan excluding route p99 target remains <=3 ms;
- compute_route <=1/lane on laid-out 59x59;
- failed route probes = 0;
- exact target winner remains unchanged.

## Regression gate

Run at minimum:

- new M25-C004 S2 focused differential suite;
- M15/M19 strict;
- M22 railroad/responsive suites;
- M25/M26;
- M27 solve/scale;
- M28 railway-first remediation;
- M29 exact-slot-origin;
- M29-C002 corrected tempo suite;
- M30;
- M36/M53 difficulty analyzers, especially equal-weight mode;
- M39;
- M52;
- M55 long session;
- root suite;
- `git diff --check`.

Historical m21_v08/v09 baseline may remain only with exact known signatures.

## No semantic drift

FAIL if S2 changes any of:

- TargetSelector winner;
- route target;
- route point sequence;
- railway-first exit;
- connector geometry;
- side/seq tie-break;
- equal-weight analyzer routes;
- claims/reservations;
- clear order under normalized deterministic replay;
- 1x/2x speed/cadence;
- one-lane-per-frame scheduler rule.

## Documentation

Update current production routing comments if implementation structure changes.

Do not rewrite historical evidence.

Create new S2 evidence under:

`coordination/sessions/M25-C004/evidence/`

## Required outputs

Create:

- `coordination/sessions/M25-C004/CLAUDE_LOG_V01.md`
- `coordination/sessions/M25-C004/IMPLEMENTATION_MATRIX_V01.md`
- differential report;
- before/after performance report;
- work-count report.

Commit/push to `main`.

Return:
1. final SHA;
2. optimization architecture;
3. fast-path preconditions/fallbacks;
4. differential comparison count and result;
5. before/after p99/max timings;
6. 59x59 full-level truth result;
7. regression summary;
8. whether all performance targets passed.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M25-C004 EXACT-EQUIVALENT RAILROAD ACCELERATION V01`
