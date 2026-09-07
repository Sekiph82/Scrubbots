# M16-C001 — Claude Implementation Log V05

Cycle: **M16-C001** — RoutingSystem frozen full-surface closure
Prompt: `coordination/sessions/M16-C001/CHATGPT_PROMPT_V05.md`
Audit criteria: `coordination/sessions/M16-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
Audit driving this work: `coordination/sessions/M16-C001/CHATGPT_AUDIT_V04.md`
Handoff state at end: **AWAITING_AUDIT**
Engine: Godot **v4.7.1.stable.official.a13da4feb**

Scope: close the FROZEN M16 finding set — **F-M16-STRICT-006/007/008** — by using
exact BoardState identity at every M16-owned board boundary, canonicalizing the
RouteRequest factory, and hardening the base RoutingSystem request boundary. All
V02/V03/V04 corrections preserved. No M17/M19 work.

---

## 1. Starting point / safe sync

- Local `HEAD` before sync: `5323538` (M16 V04), behind `origin/main` by 10,
  ahead by 0.
- Sync: `git fetch origin main` then `git merge --ff-only origin/main` (no
  `reset --hard`, `clean -fd`, restore/checkout, or force).
- Base `origin/main` SHA after fast-forward (base for this work):
  `e58402b23eb6e5e832d99acab41312bbc104ae56`.
- The 10 upstream commits touch only `.hiveai/*` and `coordination/*` (incl. the
  M16 V04 audit + V05 prompt/criteria/AUDIT_POLICY); disjoint from owner-modified
  files. Owner modifications (`project.godot`, both `scenes/debug/*.tscn`) and all
  untracked owner files (incl. `assets/brand/akilta-wordmark.svg.import`)
  survived untouched. See §7.

## 2. Exact changed files

Modified:
- `scripts/gameplay/routing/route_validator.gd`
- `scripts/gameplay/routing/route_request.gd`
- `scripts/gameplay/routing/routing_system.gd`
- `tests/run_tests.gd`

New (TEST-only adversarial double):
- `tests/support/wrong_return_board_double.gd`

New (this evidence log):
- `coordination/sessions/M16-C001/CLAUDE_LOG_V05.md`

Not staged (owner/local work, preserved): `project.godot`, both
`scenes/debug/*.tscn`, `assets/brand/akilta-wordmark.svg.import`, every `*.uid`,
`docs/logs/`, owner inbox art, scratchpad.

## 3. F-M16-STRICT-006 — exact BoardState identity at M16 board boundaries

Replaced the V04 duck-typed `_board_has_api()` (TYPE_OBJECT + `has_method`
surface) with exact `board is BoardState` identity at all three M16-owned board
boundaries:
- `RouteValidator.validate_request()` — `if not (board is BoardState): return
  INVALID_REQUEST` (the `_board_has_api` helper is removed as dead code);
- `RouteRequest.center_of_index()`;
- `RouteRequest.for_target()`.

`x is BoardState` (preloaded script identity, Godot 4.7.1) is false for null,
scalar Variants (int/String/Vector2), RefCounted junk, partial-API objects, AND a
full-shape/wrong-return double — and never throws. This removes duck-typed
return-type ambiguity: a board object exposing all five method NAMES but returning
wrong-typed values is rejected BEFORE any method call, so its bad returns can
never poison typed comparisons or `center_of_index()`.

Verified every real caller of these three functions passes a genuine BoardState
(`BoardState.from_level_data(...)` in tests; `_board`/`board` in
`production_target_access`, `scrubbot_dispatcher`, `production_routing_system`,
prototypes) so the stricter identity check causes no regression. The RefCounted
`board_state_scan_spy` is never routed to any M16 board boundary.

## 4. F-M16-STRICT-007 — canonical RouteRequest factory

`RouteRequest.for_target()` now fails closed to `null` for:
- non-BoardState board (identity, §3);
- non-finite `start_position` (NaN / ±INF) — `is_finite(x)` per axis;
- invalid target index.

So the canonical factory never emits a request that is already structurally
invalid at creation time. Preserved: valid finite outside-board slot origins
(left/right/above/below), canonical target center via BoardState, width/height
copied from BoardState, and no stored BoardState reference (RouteRequest exposes
no `board` member — asserted).

`RouteRequest.center_of_index()` returns the documented `Vector2(-INF,-INF)`
sentinel for any malformed board (no runtime fault).

## 5. F-M16-STRICT-008 — base RoutingSystem arbitrary request boundary

Base `RoutingSystem.compute_route()` now reads `target_index` ONLY from a real
RouteRequest: `var idx := request.target_index if (request is RouteRequest) else
-1`. A `RouteRequest` preload was added. An arbitrary request Variant
(null / int / String / Vector2 / RefCounted junk) yields a stable
`NOT_IMPLEMENTED` failure with target `-1` and no runtime fault; a real
RouteRequest still returns `NOT_IMPLEMENTED` retaining its `target_index`. No
target selection / retarget / mutation was added.

## 6. Adversarial tests

- `_run_route_request_tests`: `center_of_index` → `(-INF,-INF)` and `for_target`
  → `null` for board = null / int / String / Vector2 / RefCounted junk /
  `PartialBoardDouble` / `WrongReturnBoardDouble`; `for_target` NaN/+INF/-INF
  start → `null`; valid left/right/above/below + rectangular still succeed
  (existing); request stores no BoardState ref.
- `_run_route_validator_tests`: `validate_request` / `validate_route` reject board
  = int / String / Vector2 / RefCounted / partial / wrong-return, each with zero
  access calls.
- `_run_routing_system_swappability_tests`: base `compute_route` for request =
  null / int / String / Vector2 / RefCounted junk → `NOT_IMPLEMENTED`, target
  `-1`, no fault; real request retains target.

New TEST double: `tests/support/wrong_return_board_double.gd` (full method shape,
wrong return types, not a BoardState).

## 7. Preserved regression matrix (all green)

request/result/board/access null; malformed RefCounted; partial-API object;
scalar int/String/Vector2; full-shape wrong-return board; NaN/±INF request
values; NaN/INF intermediate route points (+ zero access calls); success/failure
contradiction; canonical failure structure; non-bool access verdict; normal
true/false access; wrong target/start/end; too-few points; blocked/open
multi-segment; no-retarget; detached points; left/right/above/below slot origins;
swappable RoutingSystem base + two fakes; 59×59; 53×59; no BoardState/
ReservationState mutation; no M17 pathfinding (base still `NOT_IMPLEMENTED`).

## 8. Validation results

- `godot --version` → `4.7.1.stable.official.a13da4feb`.
- `godot --headless --path . -s res://tests/run_tests.gd` →
  **Total checks: 1737, Failures: 0, RESULT: ALL PASS**. No `SCRIPT ERROR` /
  `Parse Error`. (Only `ERROR:` lines are pre-existing intentional negative-path
  importer tests loading deliberately corrupt/nonexistent images — unrelated.)
- `git diff --check` → clean (exit 0; only benign LF→CRLF warnings; no whitespace
  errors).
- `git diff` inspected before commit.

Material boundary checks asserted individually (§6), not inferred from the
aggregate green total (AL-009).

## 9. Governance / owner-preservation

Not created or modified this cycle: `tasks.md`, `.hiveai/*`,
`coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, the strict
sequence controller, and any `CHATGPT_AUDIT*` file. No self-audit, no verdict.
Frozen tasks (SB-M16-002/003/010/011) left for ChatGPT to final-close after audit.

Owner preservation: `git merge --ff-only`, no destructive command;
`project.godot`, both `scenes/debug/*.tscn`, and the untracked
`assets/brand/akilta-wordmark.svg.import` stayed unstaged; all untracked owner
artifacts untouched. Only the four modified routing/test files, the one new TEST
double, and this log were staged.

## 10. Commit / push

See the commit carrying this cycle's V05 closure (`fix(M16-C001 V05) ...`). Push
to `origin/main` non-destructive (`git push`, no force). Handoff:
**AWAITING_AUDIT**. Claude stops here and does not self-audit.
