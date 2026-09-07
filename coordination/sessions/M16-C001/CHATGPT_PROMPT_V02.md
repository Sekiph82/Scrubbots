# M16-C001 — Strict Adversarial Correction / Validation V02

Status: **ISSUED**

Read the strict-v2 policy, M16 V01 artifacts and:
`coordination/sessions/M16-C001/CHATGPT_STRICT_REAUDIT_V02.md`.

Fix ONLY M16 contract/validator defects. Do not implement pathfinding or alter the
owner-selected M17 movement language here.

## Finite request values

Add a small reusable finite-Vector2 check compatible with Godot 4.7.1.

RouteValidator.validate_request() must reject:
- start.x/y NaN;
- start.x/y +INF/-INF;
- non-finite target_position.

Reject before any access/routing geometry call.

## Finite route points

validate_route() must inspect every route point before querying access truth.

If any point is non-finite:
- return INVALID_ROUTE;
- call access query zero times for that malformed route.

Test NaN and INF in middle points, not only malformed endpoints.

## RouteResult coherence

For claimed success:
- success == true;
- failure_reason == NONE;
- target identity/endpoints/points/access contract remain as before.

Add a narrow failure-result structural validator or equivalent reusable function
that proves a canonical failure:
- success == false;
- original requested target retained;
- points empty;
- failure_reason != NONE.

Directly reject/tests for:
- success + NO_ROUTE;
- failure + NONE;
- failure with route points;
- failure with wrong target.

Do not make RouteResult mutable internals more widely exposed.

## Access verdict type

Every segment access verdict must be an actual bool.

A query object with the required method but returning int/string/null must make
route validation fail closed without treating truthy values as approval.

## Regression

Preserve:
- detached RouteResult point copy-in/copy-out;
- no retarget;
- no BoardState/ReservationState mutation;
- board-local coordinates;
- left/right/above/below origins;
- swappable RoutingSystem contract;
- 59×59 + 53×59;
- no M17 algorithm in M16.

Run full Godot 4.7.1 suite + `git diff --check`.

Governance untouched.

Write `coordination/sessions/M16-C001/CLAUDE_LOG_V02.md`, commit/push,
return `AWAITING_AUDIT`, stop.
