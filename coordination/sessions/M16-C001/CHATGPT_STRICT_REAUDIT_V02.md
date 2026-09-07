# M16-C001 — Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Strict-v2 independent inspection found malformed-value and result-coherence gaps
in the RoutingSystem contract/validator.

## F-M16-STRICT-001 — non-finite request coordinates are not rejected

`RouteRequest.for_target()` preserves caller start_position and
`RouteValidator.validate_request()` does not require finite coordinates.

NaN/INF can therefore enter later routing math (floor/distance/sorting).

Required:
- request validation rejects non-finite start/target coordinates before any
  routing/access call;
- direct NaN, +INF, -INF adversarial tests;
- failure must be stable/fail-closed, not a runtime fault.

Affected:
- SB-M16-002
- SB-M16-010

## F-M16-STRICT-002 — non-finite intermediate route points are not structurally rejected

A claimed success route may contain NaN/INF intermediate points. The validator
currently delegates them to the access query.

Required:
- every route point must be finite before segment access queries;
- malformed point test proves the access query is NOT called for that route;
- success fails with INVALID_ROUTE or another stable contract reason.

Affected:
- SB-M16-003
- SB-M16-010

## F-M16-STRICT-003 — success/failure metadata can be internally contradictory

RouteResult fields are mutable by convention. A caller can create a success route
then set `failure_reason = NO_ROUTE`; current success-route validation does not
reject that contradiction.

Required:
- success route validation requires failure_reason == NONE;
- introduce/extend structural validation for failure results so a failure result
  must retain target, have zero points and use a non-NONE failure reason;
- malformed contradictory results fail closed;
- avoid a broad API rewrite unless necessary.

Affected:
- SB-M16-003
- SB-M16-011

## Additional strict dependency check

The access seam contract says segment verdict is boolean. A malformed access
query returning a non-bool value must fail closed rather than rely on truthiness.

## Strict task state

Reopen:
- SB-M16-002
- SB-M16-003
- SB-M16-010
- SB-M16-011

Next:
`coordination/sessions/M16-C001/CHATGPT_PROMPT_V02.md`
