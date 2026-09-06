# M16-C001 — RoutingSystem Interface (V01)

Status: **ISSUED — first implementation cycle of milestone M16**

## Milestone transition

M15 TargetSelector is audited complete under the canonical repository audit policy.

This prompt intentionally opens:

**M16 — RoutingSystem Interface**

The owner should start M16 in a **new Claude chat** to keep the implementation context lean.

## Scope

Implement exactly the M16 task set from `tasks.md`:

- SB-M16-001 Define RoutingSystem contract.
- SB-M16-002 Define route input.
- SB-M16-003 Define route output.
- SB-M16-004 Define coordinate space.
- SB-M16-005 Slot origin.
- SB-M16-006 Cell destination.
- SB-M16-007 Keep independent from TargetSelector.
- SB-M16-008 Swappable implementations.
- SB-M16-009 Debug route visualization.
- SB-M16-010 Route validity checks.
- SB-M16-011 Failure behavior: no route is failure, never silent retarget.

Do NOT implement M17 routing prototypes, M18 ScrubbotAgent, M19 Dispatcher, or
M20 vertical slice.

M16 is the **contract/interface milestone**, not the final path algorithm.

## First action

Work in:

`C:\Users\sekip\Desktop\ScrubBots`

Safely synchronize local `main` with `origin/main` while preserving all owner work.

Never use:
- `reset --hard`
- `clean -fd`
- destructive restore/checkout
- force push

Then read, in order:

- `CLAUDE.md`
- `tasks.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/README.md`
- `coordination/SESSION_INDEX.md`
- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- `scripts/gameplay/board/board_state.gd`
- `scripts/gameplay/board/board_renderer.gd`
- `scripts/gameplay/targeting/target_selector.gd`
- `scripts/gameplay/targeting/reservation_state.gd`
- relevant M15 implementation + audit
- this prompt
- `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V01.md`

Apply relevant audit learnings, especially:
- AL-001 explicit preload
- AL-003 performance claim discipline
- AL-004 rectangular/max-size coverage
- AL-005 real validation before task closure
- AL-009 aggregate green totals are insufficient
- AL-011 negative-test specificity
- AL-018 direct observability
- AL-020 no mutable-state leakage
- AL-026 owner-work preservation
- AL-027 ACTIVE/CLEARED
- AL-028 candidate != reachable final target
- AL-033 current C01..C16 palette v2

## Locked architectural boundary

M15 decides **WHAT** target.

M16 defines how a routing implementation will answer **HOW** to travel to an
already-assigned target.

M16 must NEVER:
- choose a target;
- call TargetSelector to pick another target;
- silently retarget;
- reserve another target;
- change reservation ownership;
- clear a cell;
- spawn/move a Scrubbot.

Canonical flow remains:

```text
TargetSelector
    -> already assigned + reserved target_index

RoutingSystem
    -> route for exactly that target, or explicit failure

ScrubbotAgent (M18+)
    -> later consumes the route
```

## Core M16 design decision

Create a **swappable routing contract** plus route data/result types.

Recommended location:

```text
scripts/gameplay/routing/
    route_request.gd
    route_result.gd
    routing_system.gd
    route_validator.gd          # if useful
scripts/debug/
    route_debug_overlay.gd      # or equivalent
scenes/debug/
    routing_interface_debug.tscn # if useful
```

Exact file split may vary if repository conventions justify it, but keep the
responsibilities separable and testable.

## Canonical coordinate space

Use a **resolution-independent board-local cell coordinate space**.

This is NOT screen pixels and NOT global Canvas coordinates.

Definition:

- Board top-left boundary = `Vector2(0, 0)`.
- One logical cell = 1.0 × 1.0 coordinate units.
- Cell `(x,y)` occupies:
  - x range `[x, x+1]`
  - y range `[y, y+1]`
- Cell center = `Vector2(x + 0.5, y + 0.5)`.
- Board rectangle spans:
  - x `[0, board_width]`
  - y `[0, board_height]`.
- Gameplay-background / outside-board free space may use coordinates outside
  that rectangle.
- Slot origins are represented in this SAME board-local coordinate space and
  may therefore lie outside the board rectangle.

This keeps routing independent from phone resolution, BoardRenderer pixel size,
safe areas and UI layout.

Do NOT hard-code 1080×2160 coordinates into route data.

Presentation code can later map board-local route coordinates into pixels using
the current BoardRenderer geometry.

## Route input contract

Create a request/data object equivalent to:

```text
RouteRequest
- start_position: Vector2       # slot origin, board-local cell coordinates
- target_index: int             # already assigned target
- target_position: Vector2      # canonical center of target cell
- board_width: int
- board_height: int
```

The route request must represent exactly one already-assigned target.

Target position must be derivable/validated from BoardState:
- target_index must be valid;
- target cell must be ACTIVE;
- target_position must equal the canonical center of target_index.

Do NOT include:
- alternate candidate list;
- color candidate list;
- random target fallback;
- target-selection callback;
- reservation mutation callback.

If adding a board/access dependency to the request would leak too much mutable
state, prefer keeping BoardState/access truth as method arguments to the
RoutingSystem/validator rather than storing them in route data.

## Slot origin

M16 must define the slot origin as a board-local `Vector2`.

It may be outside board bounds.

Do NOT hard-code a final production slot layout in M16.

The caller supplies the slot origin.

Required tests must include:
- origin left of board;
- origin right of board;
- origin above/below board;
- rectangular board.

M16 defines the coordinate contract, not UI placement.

## Cell destination

The destination is the **center of the already-assigned ACTIVE target cell**:

```text
target_position =
Vector2(
    target_x + 0.5,
    target_y + 0.5
)
```

Use BoardState's index/position APIs.

Do not re-derive row-major indexing outside BoardState.

A route that terminates at another target is invalid.

## Route output contract

Create a detached immutable-by-convention result equivalent to:

```text
RouteResult
- success: bool
- target_index: int
- points: PackedVector2Array
- failure_reason: StringName/String
```

Success contract:
- `success == true`
- `target_index` equals the request target
- `points.size() >= 2`
- first point equals request start_position
- last point equals request target_position
- every segment is accepted by authoritative access truth

Failure contract:
- `success == false`
- `points` is empty
- target remains the originally requested target
- failure reason is explicit/stable enough for tests/debugging
- no retarget occurs

Return detached copies so callers cannot mutate internal routing truth.

Do not use exceptions for ordinary “no route” behavior.

## RoutingSystem contract / swappability

Define a narrow base contract/interface equivalent to:

```text
compute_route(request, board, access_query) -> RouteResult
```

M16 does NOT need a production routing algorithm.

A base/default implementation may return a clean `NOT_IMPLEMENTED` /
`NO_ROUTE` failure.

Tests should use small fake routing implementations to prove the interface is
swappable without TargetSelector changes.

Do not introduce a global singleton merely for this interface.

## Access / validity seam

Exact path topology, collision radius and movement language remain M17 design
work.

Therefore route validity must consume an injected authoritative access contract,
not invent topology in M16.

Use a narrow contract equivalent to:

```text
access_query.is_segment_traversable(
    from_position: Vector2,
    to_position: Vector2,
    target_index: int
) -> bool
```

or an equally narrow route-validity query.

This contract represents the locked semantic law:
- non-target ACTIVE cells block;
- CLEARED/background/outside-board free space is open;
- the assigned ACTIVE target may be the endpoint.

M16 must NOT define whether traversal uses 4-neighbor, 8-neighbor, curves,
pixel collision, AStar nodes, navmesh, or another topology.

That belongs to M17.

## Route validation

Create a reusable validation path that checks at minimum:

1. request is structurally valid;
2. board exists;
3. target_index valid;
4. target cell ACTIVE;
5. target_position matches target cell center;
6. result target_index equals request target;
7. success route contains at least 2 points;
8. first point equals exact request slot origin;
9. last point equals exact assigned target center;
10. every route segment is checked through access truth;
11. blocked segment invalidates the route;
12. CLEARED/background/open segment can be accepted when access truth says so;
13. no route never triggers retarget.

Use tolerant Vector2 comparison where floating-point representation requires it,
but do not accept materially wrong endpoints.

## Failure behavior

No route is a first-class failure.

Provide stable failure categories, preferably constants/enums/string names such as:

```text
NONE
INVALID_REQUEST
INVALID_TARGET
TARGET_NOT_ACTIVE
MISSING_ACCESS_QUERY
NO_ROUTE
INVALID_ROUTE
NOT_IMPLEMENTED
```

Exact names may vary.

The critical rule:

```text
route failure for target X
!=
pick target Y
```

RoutingSystem must never call TargetSelector, ColorCandidateIndex candidate
selection, or ReservationState reserve/release to recover from route failure.

The caller decides what happens after failure in a later milestone.

## Debug route visualization

Implement a **generic debug-only route visualization** that can draw any
successful `RouteResult` without knowing the routing algorithm.

It should show at minimum:
- route polyline;
- slot/start marker;
- assigned target/end marker;
- clear failure/no-route text/state when result is failure.

Keep it under debug tooling/scenes.

It must consume RouteResult only.

It must NOT:
- compute a route;
- retarget;
- mutate BoardState;
- become production gameplay UI.

Provide a headless/runtime smoke or direct draw-state test where feasible.

Do not require owner visual approval to close M16 unless a genuinely subjective
design choice is introduced. The visualization is diagnostic only; final
movement language remains M17 owner design gate.

## Required tests

Add direct tests, not proxy-only assertions.

At minimum prove:

1. RouteRequest construction/validation.
2. Invalid target index rejected.
3. CLEARED target rejected.
4. Canonical target center computed correctly.
5. Rectangular board target center/index correctness.
6. Slot origin can be outside left.
7. Slot origin can be outside right.
8. Slot origin can be above/below.
9. RouteResult success structure.
10. RouteResult failure structure.
11. Returned points are detached from internal/source mutable arrays.
12. RoutingSystem base/default fails cleanly rather than inventing a route.
13. Two fake routing implementations can satisfy the same interface.
14. Swapping implementation requires no TargetSelector modification.
15. Route target remains the already-assigned target.
16. Wrong target_index in result invalidates route.
17. Route ending at wrong cell/point invalidates route.
18. Route starting away from slot origin invalidates route.
19. Missing access query fails closed.
20. Every route segment is directly observed as queried through access truth.
21. One blocked segment invalidates route.
22. Open segments accepted when access truth reports them traversable.
23. Successful final segment may terminate at the assigned ACTIVE target.
24. Non-target ACTIVE blocker semantic represented through access-query test.
25. CLEARED/background/outside open semantic represented through access-query test.
26. No-route result does not call TargetSelector.
27. No-route result does not reserve/release/retarget.
28. No route does not mutate BoardState.
29. Debug visualization accepts valid successful route.
30. Debug visualization represents failure/no-route state cleanly.
31. Debug visualization does not compute/alter route.
32. 59×59 coordinate contract test.
33. rectangular Very Hard-sized coordinate contract test.
34. full Godot 4.7.1 regression suite passes.
35. debug scene/runtime smoke succeeds if a scene is added.

### Observability requirement

Create a small access-query test double that records:
- every segment queried;
- target_index supplied;
- returned verdict.

Tests must assert the actual segment-query sequence (AL-018), not infer route
validation only from a boolean result.

If fake routing systems are used, they must expose enough direct evidence to
show RoutingSystem swappability without calling TargetSelector.

## No M17 algorithm leakage

M16 must not implement:
- AStar2D/AStarGrid2D;
- BFS/DFS pathfinding;
- direct-route selection heuristic as a production strategy;
- curved routing algorithm;
- obstacle avoidance algorithm;
- collision radius model;
- congestion scoring;
- path crossing optimization;
- route distance optimization;
- final animation/movement language.

Small hard-coded/fake route outputs are allowed **only in tests/debug fixtures**
to prove the interface/validator/visualizer.

## Documentation / ADR

Update current-law documentation:

- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`

Record the M16 interface/coordinate-space/failure contract as the next available
ADR because these are durable architecture choices.

Expected next number is ADR-024, but inspect current main and use the actual next
available number.

The ADR must explicitly record:
- board-local cell-coordinate space;
- caller-supplied slot origin;
- target cell center destination;
- success/failure RouteResult;
- injected route-access validity seam;
- no silent retarget;
- swappable routing implementations;
- M17 owns final routing algorithm/movement language.

Do not rewrite historical evidence.

## Locked project rules

Preserve:
- max 59×59 = 3481;
- C01..C16 palette v2;
- C16 Pure Black #000000;
- BG01 #202533 outside logical palette;
- ACTIVE/CLEARED only;
- five slots;
- ReservationState ADR-022;
- TargetSelector ADR-023;
- candidate != reachable final target;
- TargetSelector != RoutingSystem;
- no one-Node-per-cell board architecture.

## Governance ownership

Claude must NOT modify:
- `tasks.md`
- `.hiveai/ACTIVE_CYCLES.md`
- `.hiveai/ARTIFACT_MAP.md`
- `.hiveai/PROGRESS_SNAPSHOT.md`
- `.hiveai/PROJECT_DASHBOARD.md`
- `coordination/SESSION_INDEX.md`
- `coordination/AUDIT_INDEX.md`
- any ChatGPT audit file

ChatGPT owns audit/task/tracker updates.

## Validation

Run at minimum:

```text
godot --version
godot --headless --path . -s res://tests/run_tests.gd
git diff --check
```

If a debug scene is added, also run an explicit headless scene smoke.

Record prompt-mandated material checks individually. Aggregate green test totals
alone are insufficient under AL-009.

Inspect actual `git diff` before commit.

## Coordination output

Write:

`coordination/sessions/M16-C001/CLAUDE_LOG_V01.md`

The log must contain:
- starting origin/main SHA;
- exact changed files;
- ADR number;
- route input/output contracts;
- coordinate-space proof;
- swappability evidence;
- no-retarget evidence;
- access-query direct-observability evidence;
- debug visualization evidence;
- SB-M16-001..011 task-by-task evidence;
- full regression results;
- debug smoke result if applicable;
- M17+ non-scope confirmation;
- owner/local-work preservation evidence;
- governance files untouched confirmation;
- safe commit/push evidence.

Commit and push safely.

Hand back:

`AWAITING_AUDIT`

Then stop.

Do not self-audit.
