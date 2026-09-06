# M16-C001 — Claude Implementation Log V01

Cycle: **M16-C001** — RoutingSystem Interface
Prompt: `coordination/sessions/M16-C001/CHATGPT_PROMPT_V01.md`
Audit criteria: `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
Handoff state at end: **AWAITING_AUDIT**
Engine: Godot **v4.7.1.stable.official.a13da4feb**

M16 is the routing **CONTRACT / interface** milestone. It defines HOW a routing
implementation will answer travel-to-an-already-assigned-target, plus route
data/result types, an injected access seam, route validation, explicit no-route
failure, and a generic debug visualizer. It ships **no** M17 path algorithm.

---

## 1. Starting point / safe sync

- Starting `origin/main` SHA (fast-forwarded to, base for this work):
  `1c6d9c9cb2a02df17690a139ecaf2da4de297200`
- Local `HEAD` before sync: `ba50bc822715865efa5cdeb65c78a15718049be4`
  (behind origin by 18, ahead by 0).
- Sync method: `git fetch origin` then `git merge --ff-only origin/main`
  (fast-forward only — **no** `reset --hard`, `clean -fd`, restore/checkout, or
  force operation was used).
- Verified `origin/main` does not touch `project.godot`, so the pre-existing
  owner modification to `project.godot` and all untracked owner files
  (`*.import`, `*.uid`, `docs/logs/`, `assets/art/references/_owner_inbox/...`)
  survived the fast-forward untouched. See §11.

## 2. Exact changed files

New (M16 implementation):
- `scripts/gameplay/routing/route_request.gd`
- `scripts/gameplay/routing/route_result.gd`
- `scripts/gameplay/routing/routing_system.gd`
- `scripts/gameplay/routing/route_validator.gd`
- `scripts/debug/route_debug_overlay.gd`

New (test doubles / fakes, TEST-only):
- `tests/support/route_access_query_double.gd`
- `tests/support/route_fake_straight.gd`
- `tests/support/route_fake_relay.gd`

Modified:
- `tests/run_tests.gd` — added M16 preloads, registered 7 new test sections,
  and superseded the stale M11-era "no routing implementation" guard (that
  guard asserted `routing_system.gd` did **not** exist; M16 legitimately
  introduces it, so the assertion was flipped to assert the contract file now
  exists, with an explanatory comment — no history erased).
- `docs/05_TECH_DECISIONS.md` — added **ADR-024**.
- `docs/01_GAMEPLAY_SPEC.md` — "Target selection vs. routing" updated to record
  the M16 contract; algorithm/movement language remain `[TO BE DESIGNED]` (M17).
- `docs/02_TECH_ARCHITECTURE.md` — RoutingSystem seam entry updated to the M16
  contract.

Explicitly **not** staged (owner/local work, preserved): `project.godot`,
every `*.uid`, `docs/logs/`, `assets/art/references/_owner_inbox/*`, and the
session scratchpad temp file.

## 3. ADR

**ADR-024 — RoutingSystem interface: board-local route contract with injected
access seam** (`docs/05_TECH_DECISIONS.md`). Records: board-local cell
coordinate space; caller-supplied slot origin (may be outside board); target
cell center destination; success/failure `RouteResult`; injected route-access
validity seam; no silent retarget; swappable routing implementations; M17 owns
the final routing algorithm/movement language. (Next number confirmed by
inspecting main: latest existing was ADR-023.)

## 4. Route input / output contracts

`RouteRequest` (`route_request.gd`, `extends RefCounted`, explicit preload):
- `start_position: Vector2` — slot origin, board-local cell coordinates, **may
  lie outside the board rectangle**.
- `target_index: int` — the one already-assigned target.
- `target_position: Vector2` — canonical center of `target_index`.
- `board_width: int`, `board_height: int`.
- `for_target(board, start, index)` derives center + dimensions from BoardState
  (index math stays in BoardState); returns `null` for an invalid index (fail
  closed). No alternate/candidate list, no fallback, no selection/reservation
  callback. BoardState is a method arg, never stored (AL-020).

`RouteResult` (`route_result.gd`, `extends RefCounted`):
- `success: bool`, `target_index: int`, detached board-local
  `points: PackedVector2Array`, stable `failure_reason: StringName`.
- `success_route()` copies points **in**; `get_points()` returns a detached
  copy **out** — callers cannot mutate routing truth.
- Failure factory keeps the originally requested target and empty points.
- `FailureReason`: `NONE, INVALID_REQUEST, INVALID_TARGET, TARGET_NOT_ACTIVE,
  MISSING_ACCESS_QUERY, NO_ROUTE, INVALID_ROUTE, NOT_IMPLEMENTED`.

## 5. Coordinate-space proof

Board-local cell units, resolution-independent (NOT pixels, never 1080×2160):
board top-left `(0,0)`; one cell = 1.0×1.0 units; cell `(x,y)` center
`(x+0.5, y+0.5)`. Proven by tests:
- `center of (0,0) == (0.5,0.5)`, `center of (5,3) == (5.5,3.5)` (6×4 board);
- adjacent centers differ by exactly `1.0` (one cell == one unit);
- 59×59 far corner center `== (58.5,58.5)`; 53×59 far corner `== (52.5,58.5)`;
- slot origins outside board on all four sides preserved exactly;
- 59×59 route endpoint `< 60.0` in each axis (cell units, not pixels).
Index/position math is only ever taken from `BoardState.get_cell_position`.

## 6. Swappability evidence

`RoutingSystem.compute_route(request, board, access_query) -> RouteResult` is
the swappable base (`extends RefCounted`, not a singleton). Base returns a clean
`NOT_IMPLEMENTED` failure (invents no route). Two TEST fakes satisfy the SAME
contract — `route_fake_straight.gd` (2-point route) and `route_fake_relay.gd`
(3-point route) — both validated green. Tests assert every routing impl exposes
`compute_route` and has **no** `select_and_reserve` / `reserve` method, while a
real `TargetSelector` still owns `select_and_reserve` and has no `compute_route`
— so swapping a routing implementation requires **no TargetSelector source
change**. Two `RoutingSystem.new()` instances are distinct (no global
singleton).

## 7. No-retarget evidence

RoutingSystem holds no handle to TargetSelector / ColorCandidateIndex /
ReservationState — it structurally cannot retarget. Tests confirm:
- a failed `compute_route` keeps the original `target_index` and empty points;
- `compute_route` (base + both fakes) does not mutate BoardState (cell-state
  snapshot equal before/after);
- a live `ReservationState` (bound, target reserved for owner 0) is unchanged
  after `compute_route` — owner 0 still holds exactly its original target.

## 8. Access-query direct-observability evidence (AL-018)

Injected access seam: `access_query.is_segment_traversable(from, to,
target_index) -> bool`. `RouteAccessQueryDouble` records every query
(`from`, `to`, `target_index`, `verdict`) in order. Tests assert the ACTUAL
segment-query sequence, not just the boolean:
- a 2-point route triggers exactly 1 segment query, with `from == slot origin`,
  `to == assigned target center`, and `target_index == request target`;
- a 3-point route triggers exactly 2 segment queries;
- one blocked segment (single or among many) → `INVALID_ROUTE`;
- all-open segments → valid;
- missing access query → `MISSING_ACCESS_QUERY` (fail closed).
Blocker semantics (non-target ACTIVE blocks; CLEARED/background/outside open;
assigned ACTIVE target only as endpoint) are represented via access-query
verdicts — M16 defines no topology (no 4/8-neighbour, curve, pixel collision,
AStar, navmesh).

## 9. Debug visualization evidence

`scripts/debug/route_debug_overlay.gd` (`extends Node2D`) consumes a
`RouteResult` **only**. Pure static `build_draw_model(result)` is directly
testable headlessly:
- success → `{success:true, polyline == route points, start == slot origin,
  end == assigned target center, target_index}`;
- failure → `{success:false, failure_reason surfaced, empty polyline}`;
- null → clean `success:false` (no crash).
Runtime smoke: overlay instantiated under the SceneTree root, fed a successful
and a failure route via `set_route()`, model checked, freed — no `.tscn` was
added, so this runtime-instantiation smoke satisfies the "if a scene is added"
scene-smoke clause. Overlay has no `compute_route` and does not mutate
BoardState. It is debug-only, not production gameplay UI.

## 10. SB-M16-001..011 task-by-task evidence

- **SB-M16-001 Define RoutingSystem contract** — `routing_system.gd`
  `compute_route(request, board, access_query) -> RouteResult`; §6.
- **SB-M16-002 Define route input** — `route_request.gd`; §4.
- **SB-M16-003 Define route output** — `route_result.gd`; §4.
- **SB-M16-004 Define coordinate space** — board-local cell units; ADR-024; §5.
- **SB-M16-005 Slot origin** — caller-supplied `Vector2`, may be outside board;
  left/right/above/below tests; §5.
- **SB-M16-006 Cell destination** — target cell center via BoardState; §4/§5.
- **SB-M16-007 Keep independent from TargetSelector** — §6/§7 (no cross-calls,
  no shared methods).
- **SB-M16-008 Swappable implementations** — base + 2 fakes; §6.
- **SB-M16-009 Debug route visualization** — `route_debug_overlay.gd`; §9.
- **SB-M16-010 Route validity checks** — `route_validator.gd`
  (`validate_request` + `validate_route`); §8 and validator tests.
- **SB-M16-011 Failure behavior: no route is failure, never silent retarget** —
  `FailureReason` constants + §7.

(Per governance, Claude does **not** mark these `[x]` in `tasks.md` — ChatGPT
closes them after audit.)

## 11. Owner / local-work preservation evidence

- `git merge --ff-only` used; no destructive command run.
- `project.godot` remained `M` (owner-modified) throughout and was **not**
  staged.
- All untracked owner artifacts (`*.import`, `*.uid`, `docs/logs/`, owner inbox
  art) remained untracked and untouched; none were added to the commit.
- Only the eight new M16 `.gd` files + `tests/run_tests.gd` + three `docs/`
  files were staged (see §2). No `*.uid` sidecar was committed (repo convention:
  `.uid` files are untracked locally).

## 12. Governance files untouched

Not created or modified by Claude this cycle: `tasks.md`,
`.hiveai/ACTIVE_CYCLES.md`, `.hiveai/ARTIFACT_MAP.md`,
`.hiveai/PROGRESS_SNAPSHOT.md`, `.hiveai/PROJECT_DASHBOARD.md`,
`coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, and any
`CHATGPT_AUDIT_VNN.md`. No self-audit performed.

## 13. Validation results

Commands run:
- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` → full regression
  suite: **Total checks: 1266, Failures: 0, RESULT: ALL PASS**, zero
  `SCRIPT ERROR` / `Parse Error` lines. This includes all pre-existing suites
  plus the 7 new M16 sections:
  `_run_route_request_tests`, `_run_route_result_tests`,
  `_run_route_validator_tests`, `_run_routing_system_swappability_tests`,
  `_run_routing_no_retarget_tests`, `_run_route_debug_overlay_tests`,
  `_run_route_coordinate_scale_tests`.
- `git diff --check` → clean (only benign LF→CRLF line-ending warnings on
  `project.godot` and `tests/run_tests.gd`; no whitespace errors).
- `git diff` inspected before commit.

Material checks recorded individually above (§5–§9), not inferred from the
aggregate green total alone (AL-009). Every M16 test is a direct assertion on
the contract/validator/observability, not a proxy.

Coverage confirmed for prompt-required cases: slot origin left/right/above/
below, rectangular boards (6×4, 5×5, 8×6, 7×7, 6×6, 53×59), 59×59 coordinate
contract, Very Hard rectangular 53×59, detachment (copy-in and copy-out),
blocked/open segments, wrong target/start/end rejection, missing access query,
base NOT_IMPLEMENTED, two swappable fakes, debug success + failure state.

## 14. M17+ non-scope confirmation

No AStar/AStarGrid2D, BFS/DFS, production direct/curved/grid routing strategy,
collision radius, congestion/path-crossing, route-distance optimization,
Scrubbot movement, Dispatcher, or final movement language was implemented. The
base RoutingSystem returns `NOT_IMPLEMENTED`; only TEST fakes emit small
hard-coded routes to exercise the interface/validator/visualizer.

## 15. Commit / push

See the commit that carries this cycle's implementation (feat(M16-C001 V01)).
Push performed to `origin/main` with a non-destructive `git push` (no force).
Handoff: **AWAITING_AUDIT**. Claude stops here and does not self-audit.
