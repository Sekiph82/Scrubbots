# M16-C001 — Complete Public Boundary Closure V04

Status: **ISSUED**

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M16-C001/CHATGPT_AUDIT_V03.md
- prior M16 V01/V02/V03 artifacts
- this prompt + V04 criteria

Fix ONLY F-M16-STRICT-005. Preserve every accepted V02/V03 correction.

## Goal

All public RouteValidator inputs must fail closed for arbitrary GDScript Variant values.
Do not stop at null or RefCounted junk-object coverage.

## 1. Board boundary

Before any `has_method` or BoardState method call, reject non-object/scalar board values.

Preferred solution:
- use exact `board is BoardState` if that preserves the intended M16 contract and current real callers/tests.

Acceptable alternative:
- safely prove TYPE_OBJECT before any has_method call, then validate the required API surface and return types strongly enough that `RouteRequest.center_of_index()` cannot fault.

Direct tests:
- board = 7
- board = "board"
- board = Vector2.ZERO
- partial RefCounted board
All must return INVALID_REQUEST with no runtime error.

## 2. RouteResult boundary in validate_route

Before reading `.success`, `.failure_reason`, `.target_index` or calling `get_points()`, require a real RouteResult.

Direct tests:
- result = RefCounted.new()
- result = 7
- result = "route"
- result = Vector2.ZERO

Expected:
- INVALID_ROUTE
- zero access-query calls
- no runtime error

Preserve validate_failure_result's V03 result guard.

## 3. Access-query boundary

Before calling `has_method`, prove access_query is an object.

Direct tests:
- access_query = 7
- access_query = "access"
- access_query = Vector2.ZERO
- RefCounted object with no is_segment_traversable method

Expected:
- stable MISSING_ACCESS_QUERY (preferred) or one single documented fail-closed reason
- no runtime error
- no segment call

Keep the existing non-bool verdict tests after a valid query object is accepted.

## 4. Regression

Preserve:
- malformed request object V03 behavior;
- malformed/partial board object V03 behavior;
- malformed request through validate_failure_result;
- NaN/+INF/-INF request checks;
- NaN/INF intermediate route points + zero calls;
- success/failure metadata coherence;
- non-bool verdict rejection;
- normal true/false access behavior;
- detached RouteResult points;
- no retarget;
- board-local coordinates;
- swappable RoutingSystem contract;
- 59x59 + 53x59;
- no M17 algorithm or movement-language change.

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
`coordination/sessions/M16-C001/CLAUDE_LOG_V04.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
