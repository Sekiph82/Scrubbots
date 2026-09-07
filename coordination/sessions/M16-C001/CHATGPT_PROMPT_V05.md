# M16-C001 — Frozen Full-Surface Closure V05

Status: **ISSUED — FROZEN FINDING SET**

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M16-C001/CHATGPT_AUDIT_V04.md
- all prior M16 V01-V04 artifacts
- this prompt + V05 criteria

This prompt closes the frozen M16 subsystem-level finding set:
- F-M16-STRICT-006
- F-M16-STRICT-007
- F-M16-STRICT-008

Do not implement M17/M19 work.

## 1. Use exact BoardState identity at M16-owned BoardState boundaries

Preferred and expected solution:
- RouteValidator accepts only a real BoardState at its board boundary.
- RouteRequest.center_of_index() accepts only a real BoardState.
- RouteRequest.for_target() accepts only a real BoardState.

Use the preloaded BoardState script identity check compatible with Godot 4.7.1.

This removes duck-typed return-type ambiguity and closes F-M16-STRICT-006.

Direct tests:
- null
- int
- String
- Vector2
- RefCounted junk
- partial-board double
- full-shape/wrong-return board double

All malformed boards must fail closed without any missing-method/type runtime fault.

Expected semantics:
- RouteValidator.validate_request(...) -> INVALID_REQUEST
- RouteRequest.center_of_index(...) -> Vector2(-INF,-INF)
- RouteRequest.for_target(...) -> null

## 2. Canonical RouteRequest factory

`RouteRequest.for_target()` must not construct a request already known to be structurally invalid.

Reject:
- non-BoardState board;
- invalid target index;
- non-finite start_position.

Preserve:
- valid outside-board finite slot origins;
- canonical target center from BoardState;
- width/height copied from BoardState;
- no BoardState reference stored.

Direct tests:
- NaN start -> null
- +INF start -> null
- -INF start -> null
- valid outside-left/right/above/below start still succeeds
- rectangular board still succeeds

## 3. Base RoutingSystem arbitrary request boundary

Base `RoutingSystem.compute_route()` must fail cleanly for arbitrary request Variants.

Expected:
- null -> NOT_IMPLEMENTED (or INVALID_REQUEST if you document and update tests consistently) with target -1
- int/String/Vector2/RefCounted junk -> stable failure, target -1
- real RouteRequest -> NOT_IMPLEMENTED retaining request.target_index

Do not read target_index unless request is a real RouteRequest.

Add direct tests for all classes above.

## 4. Full M16 regression matrix

Run and preserve all earlier strict cases:
- request/result/board/access null
- malformed RefCounted
- partial API object
- scalar int/String/Vector2
- full-shape wrong-return board
- NaN/+INF/-INF request values
- NaN/INF intermediate route points
- success+failure contradiction
- canonical failure structure
- non-bool access verdict
- wrong target/start/end
- too-few points
- blocked/open segments
- no-retarget
- detached points
- left/right/above/below slot origins
- swappable RoutingSystem base/fakes
- 59x59
- 53x59
- no BoardState/ReservationState mutation
- no M17 pathfinding

## 5. Scope/governance

Do not modify:
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
`coordination/sessions/M16-C001/CLAUDE_LOG_V05.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
