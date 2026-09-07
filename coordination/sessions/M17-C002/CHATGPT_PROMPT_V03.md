# M17-C002 — Frozen Full-Surface Production Routing Closure V03

Status: **ISSUED — FROZEN FINDING SET**

This supersedes CHATGPT_PROMPT_V02.md. Do NOT execute V02.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M17-C001/OWNER_MOVEMENT_DECISION_V01.md
- coordination/sessions/M17-C002/CHATGPT_FULL_SURFACE_REAUDIT_V03.md
- prior M17-C002 V01 artifacts
- this prompt + V03 criteria

Owner decision is LOCKED:
- Organized/curved production movement language;
- deterministic grid-aware backbone;
- Direct debug-only.

Fix the complete frozen production-routing finding set only.
Do not implement M18/M19/M20 features.

## 1. Exact ProductionAccessQuery BoardState ownership

ProductionAccessQuery must recognize only a real BoardState.

Add:
- is_bound_to(board) -> exact object identity, false when invalid/unbound.

Fail-closed public behavior:
- invalid/unbound board never throws;
- classify_cell(...) -> BLOCKED for board-local/unknown truth when invalid;
- is_segment_traversable(...) -> false when invalid;
- invalid target_index -> false for segment traversability;
- cell_of_point(non-finite) -> stable documented outside/sentinel Vector2i;
- non-finite from/to -> false.

Do not expose the board reference.

## 2. Replace sampling with exact grid traversal

Remove SAMPLE_STEP as production correctness truth.

Implement deterministic exact/supercover traversal that enumerates every logical
cell geometrically crossed by a segment.

Rules:
- outside board is OPEN;
- CLEARED is OPEN;
- non-target ACTIVE is BLOCKED;
- assigned ACTIVE target may be entered only on a segment whose final endpoint is
  exactly the target center;
- target is never ordinary transit;
- a segment crossing blocker interior is false;
- exact corner crossing is conservative enough to prevent diagonal corner-cutting
  between blockers.

Direct tests:
- short chord (0.5,0.5)->(20.5,23.5), blocker (7,7) -> false;
- same with (7,7) CLEARED and otherwise open -> true;
- exact diagonal corner between blockers -> false;
- axis-aligned CLEARED corridor -> true;
- outside-board segment -> true;
- outside -> target center final arrival -> true when geometrically clear;
- target pass-through / non-final target use -> false;
- NaN/INF endpoints -> false.

## 3. Complete exterior reachability

Remove MAX_ENTRIES correctness pruning.

Use all valid deterministic perimeter entries or an equivalent complete exterior
virtual-node algorithm.

Required:
- >12 usable entries;
- first 12 deterministic nearest candidates lead only to dead ends;
- later entry is the ONLY route;
- same assigned target succeeds.

Also cover direct perimeter target:
- target ACTIVE on perimeter;
- slot origin directly outside its center;
- every non-target board/perimeter cell blocked;
- routing succeeds directly to that target;
- target remains same;
- target is not opened as transit for unrelated routes.

## 4. Harden ProductionRoutingSystem public boundary and topology seam

Before request.target_index:
- require request is a real RouteRequest.
Malformed/null/scalar/junk request:
- stable failure;
- target -1;
- no topology/access call.

Before access_query.has_method:
- prove TYPE_OBJECT.

Require complete seam:
- is_segment_traversable
- classify_cell
- cell_of_point
- is_bound_to

Require is_bound_to(board) == true before route work.

Validate return values:
- classify_cell -> actual int and one of OPEN/BLOCKED/TARGET;
- cell_of_point -> Vector2i;
- is_segment_traversable -> actual bool.

Malformed:
- scalar access;
- object missing one method;
- partial object;
- full-shape/wrong-return double;
- same-size access bound to different BoardState.

All fail closed with stable failure, no runtime fault.

## 5. Every planning edge obeys access truth

BFS may not infer segment validity from OPEN cell class alone.

For every neighbour edge actually enqueued/used:
- classify target cell semantics correctly;
- call segment access truth;
- require actual bool true.

Add a sensitivity double:
- all cells report OPEN;
- one specific orthogonal edge reports false;
- planner must not use that edge;
- if alternate path exists, use it;
- if no alternate path exists, NO_ROUTE.

## 6. Self-validating post-process with fallback

Maintain route stages:
1. raw validated backbone route;
2. collinear-reduced candidate;
3. bounded-shortcut candidate;
4. rounded candidate.

At every stage:
- preserve last-known-valid route;
- use shared RouteValidator for whole-route validation, not only local segment
  spot checks;
- candidate invalid -> fall back to prior valid route;
- final compute_route success must be RouteValidator-clean INSIDE compute_route;
- if no valid route remains, return explicit failure retaining original target.

Never return success that external RouteValidator would reject.

## 7. Invalid tuning must not poison routing

corner_radius:
- NaN/+INF/-INF/negative must have documented deterministic safe behavior
  (e.g. clamp/fallback to sharp/last-valid route);
- must never generate non-finite success points.

Also prove:
- corner_samples = 0 and negative are safe;
- max_shortcut_span = 0 and negative are safe;
- default conservative owner tuning remains unchanged when valid.

Do not add a new gameplay feature. This is configuration hardening only.

## 8. Regression / scale

Preserve:
- Organized/curved owner-selected language;
- deterministic grid-aware backbone;
- Direct debug-only;
- no retarget;
- no BoardState mutation;
- no ReservationState mutation;
- no target selection;
- opened-after-clear same target;
- blocked interior NO_ROUTE;
- deterministic repeated points;
- 59x59;
- 53x59;
- production code independent from prototypes.

Update ADR-025/current-law docs:
- exact traversal replaces sampling;
- no correctness-affecting entry cap;
- final internal RouteValidator requirement;
- access BoardState coherence.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- any ChatGPT audit/re-audit file
- strict sequence controller

Run:
- godot --version
- full headless suite
- git diff --check

Write:
`coordination/sessions/M17-C002/CLAUDE_LOG_V03.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
