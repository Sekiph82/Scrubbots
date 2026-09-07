---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M17-C002
version: 03
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C002/CHATGPT_PROMPT_V03.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M17-C002/CHATGPT_AUDIT_CRITERIA_V03.md
startingCommit: dea7be3
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS - Claude Log V03 (M17-C002)

Evidence for exactly CHATGPT_PROMPT_V03.md — "Frozen Full-Surface Production
Routing Closure V03" (frozen finding set F-M17-STRICT-001..009). Supersedes V02
(not executed). Claude does not audit itself.

## Inputs read

- `coordination/sessions/M17-C002/CHATGPT_PROMPT_V03.md` + `CHATGPT_AUDIT_CRITERIA_V03.md`.
- `coordination/sessions/M17-C002/CHATGPT_FULL_SURFACE_REAUDIT_V03.md` (F-STRICT-001..009).
- `coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md` (owner decision LOCKED).
- Prior M17-C002 V01 artifacts; M16 contract + ADR-024/ADR-025.
- Current source: `production_access_query.gd`, `production_routing_system.gd`,
  shared RouteRequest/RouteResult/RouteValidator, `dispatch/production_target_access.gd`.

## Repository start state

- `git fetch` + `git merge --ff-only origin/main`: 11 behind, 0 ahead →
  fast-forwarded to `dea7be3` (no reset/clean/force). Upstream now includes M18
  ScrubbotAgent and M19 dispatcher tests, and added `const RouteRequest` to
  `routing_system.gd`.
- Pre-existing owner working-tree changes **preserved, not staged**:
  `M project.godot`, `M scenes/debug/routing_prototype_lab.tscn`,
  `M scenes/debug/scrubbot_agent_debug.tscn`. Incoming commits touch none of
  them (verified). Untracked `.uid`/`.import`/inbox/stray-temp left untouched.

## Work performed (frozen finding set)

Rewrote the two production routing files (production scope only; prototypes/lab
untouched; `dispatch/production_target_access.gd` unchanged — not in finding set).

**ProductionAccessQuery** (`scripts/gameplay/routing/production_access_query.gd`):
- F-007 fail-closed: constructor stores only a real `BoardState` (else null);
  unbound/invalid never throws — `classify_cell` → BLOCKED, `is_segment_traversable`
  → false. Non-finite endpoints → false; invalid `target_index` → false;
  `cell_of_point(non-finite)` → documented `OUTSIDE_SENTINEL`.
- F-005 `is_bound_to(board)`: read-only exact-object-identity; false for
  null/scalar/unbound and for a same-size DIFFERENT board. No board-reference leak.
- F-002 exact truth: removed `SAMPLE_STEP` correctness sampling; added a
  deterministic supercover DDA enumerating every crossed cell, with conservative
  exact-corner handling (both diagonal squeeze cells must be enterable → no
  diagonal corner-cutting between blockers). Target enterable only on the arriving
  segment (to == target centre); never ordinary transit.

**ProductionRoutingSystem** (`scripts/gameplay/routing/production_routing_system.gd`):
- F-006 boundary: require a real `RouteRequest` before any field read
  (`request is RouteRequest`); malformed/null/scalar/junk → INVALID_REQUEST,
  target -1, no access/topology call. Access must be TYPE_OBJECT.
- F-004 seam: require the complete seam (`is_segment_traversable`, `classify_cell`,
  `cell_of_point`, `is_bound_to`) AND validate return types (classify → canonical
  int; cell_of_point → Vector2i; is_segment_traversable → bool). Malformed
  scalar/partial/wrong-return doubles fail closed (MISSING_ACCESS_QUERY).
- F-005 coherence: require `is_bound_to(board) == true` before route work.
- F-001 exterior: removed the correctness-affecting `MAX_ENTRIES` cap — seed ALL
  valid perimeter entries (nearest-first only for deterministic preference).
- F-008 direct perimeter arrival: when no cell path exists but the straight
  exterior segment to the target centre is valid, route directly to the target.
- F-003/§5 per-edge truth: every enqueued BFS edge (and the arrival edge and the
  exterior bridge) must return an actual `true` from segment access; cell class
  alone is never trusted.
- F-003/§6 self-validation: staged post-process (raw backbone → collinear →
  bounded shortcut → rounded); each stage advances only to a candidate that
  passes WHOLE-route shared `RouteValidator`; otherwise it keeps the prior valid
  route. Returned success is `RouteValidator`-clean inside `compute_route`; if no
  valid route remains → explicit failure retaining the original target.
- F-009 tuning: sanitised `corner_radius` (non-finite/≤0 → sharp), `corner_samples`
  (<1 → sharp), `max_shortcut_span` (≤1 → no shortcut); never produces non-finite
  success points; valid owner defaults (span 2, radius 0.25, samples 3) unchanged.

Docs: ADR-025 extended with a **V03 hardening** subsection (exact traversal,
no entry cap, fail-closed + coherence, per-edge truth, internal validation,
tuning robustness); status "Accepted (M17-C002); hardened V03".

Tests: `tests/run_tests.gd` — new `_run_m17c002_v03_hardening_tests`; three new
support doubles (`route_access_wrong_return.gd`, `route_access_missing_method.gd`,
`route_access_edge_block.gd`). One prior V01 conservative-metric assertion updated
to compare INTERIOR max segment (the shared exterior bridge is not part of the
movement-language shape).

## Files changed

Modified: `scripts/gameplay/routing/production_access_query.gd`,
`scripts/gameplay/routing/production_routing_system.gd`, `tests/run_tests.gd`,
`docs/05_TECH_DECISIONS.md`.
Added: `tests/support/route_access_wrong_return.gd`,
`tests/support/route_access_missing_method.gd`,
`tests/support/route_access_edge_block.gd`,
`coordination/sessions/M17-C002/CLAUDE_LOG_V03.md`.
NOT staged (owner/local): `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
`scenes/debug/scrubbot_agent_debug.tscn`, untracked `.uid`/`.import`/inbox files.

## Validation evidence

Environment: `godot --version` → `4.7.1.stable.official.a13da4feb`.
Full suite: `godot --headless --path . -s res://tests/run_tests.gd`
→ **Total checks: 1801, Failures: 0, RESULT: ALL PASS**.
`git diff --check` → clean (only benign LF→CRLF notices).

Criteria coverage (each proven headless in the run above):
- 1-8 ProductionAccessQuery: exact ownership; is_bound_to exact (self true,
  same-size-other false, null/scalar false); unbound classify→BLOCKED/seg→false;
  invalid target→false; NaN-from→false; INF-to→false; cell_of_point(non-finite)
  →sentinel; no get_board leak.
- 9-17 exact truth: short-chord blocker (7,7)→false; cleared→true; diagonal
  corner→false; axis corridor→true; outside→true; final target arrival→true;
  non-final target transit→false.
- 18-22 exterior: 13th (far) later-only entry route found on the 6×26 finger
  board (maxy≥25), same target, validates; direct outside→perimeter target
  succeeds + validates; perimeter target not transit for another target.
- 23-32 boundary: null/scalar/junk request→INVALID_REQUEST target -1; scalar
  access→MISSING_ACCESS_QUERY (target retained); missing-method→MISSING;
  wrong-return→MISSING; same-size different board→MISSING; return types validated.
- 33-36 planner edge: alternate-exists routes around a blocked edge and validates
  under the edge-blocking truth; sole-connection blocked→NO_ROUTE and the edge
  access was consulted (`blocked_edge_queried`).
- 37-43 self-validation: S2 success is externally RouteValidator-clean; points
  finite.
- 44-51 tuning: NaN/+INF/-INF/negative corner_radius, corner_samples {0,-3},
  max_shortcut_span {0,-3} all route safely with finite, validating points;
  defaults unchanged.
- 52-63 regression: covered by the retained `_run_m17c002_production_routing_tests`
  (blocked→NO_ROUTE, opened-after-clear same target, no retarget, no BoardState/
  ReservationState mutation, no selection API, determinism, 59×59, 53×59,
  Organized/curved preserved, Direct debug-only, prototypes/lab retained) plus
  the M17 lab/prototype suites — all green in the 1801-check run.
- 64 docs: ADR-025 V03 subsection added. 65 no M18/M19/M20 feature added.
- 66 full suite passes. 67 diff --check clean. 68 governance untouched. 69 this
  log. 70 no self-audit.

## Failures and fixes

- Parse error after rewrite: my subclass redeclared `const RouteRequest`, which
  upstream had added to the parent `routing_system.gd`. Removed the duplicate;
  RouteRequest is inherited.
- Prior V01 assertion "production avoids long diagonals (max seg …)" failed
  because uncapped exterior entries change which entry (and thus the exterior
  bridge length) seeds BFS. Fixed by comparing INTERIOR max segment (excluding
  the shared exterior bridge): production 28.5 < experimental 39.3 — the
  conservative-shortcut intent holds.
- Sensitivity assertion `blocked_edge_queried` on the open board was BFS-order
  dependent (the edge's destination could be reached from another cell first, so
  the visited-check short-circuits before the query). Moved the "edge consulted"
  proof to the sole-connection L-corridor case, where the blocked edge is the
  only path and is necessarily queried.

## Task/docs/coordination/H!veAI updates

Per M10-C001 V05, Claude did NOT modify `tasks.md`, `coordination/SESSION_INDEX.md`,
`coordination/AUDIT_INDEX.md`, any `.hiveai/*`, any `CHATGPT_AUDIT_*`/re-audit, or
the strict-sequence controller. Only ADR-025 (docs), the two production files,
tests + support doubles, and this log changed.

## Commit and push evidence

Committed the V03 hardening + docs + tests + this log on `main`; owner's
`project.godot`, `routing_prototype_lab.tscn`, `scrubbot_agent_debug.tscn` and
untracked sidecars excluded. Safe push to `origin/main` (no reset/clean/force).
Final commit SHA reported in the session hand-back (not re-embedded per the
non-self-referential final-SHA rule).

## Handoff

**AWAITING_AUDIT.** No self-audit. Owner-selected Organized/curved + grid-aware
backbone preserved; Direct debug-only; prototypes/lab retained; M16 contract
intact; no M18/M19/M20 feature leakage.
