# M16-C001 — ChatGPT Independent Audit V03

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Audited implementation:
- base: `c783af00f3d97366bbfdf4a16fce053b3e67f990`
- head: `9110a1068c77f865aac7eb60cf0978d3d9a37409`
- exact implementation diff: one commit
- prompt: `CHATGPT_PROMPT_V03.md`
- criteria: `CHATGPT_AUDIT_CRITERIA_V03.md`
- Claude log: `CLAUDE_LOG_V03.md`

## Evidence classification

### E1/E2
Claude reports:
- Godot 4.7.1
- 1673 checks
- 0 failures
- ALL PASS
- git diff --check clean

These are implementer results.

### E3
ChatGPT independently inspected:
- exact one-commit diff;
- RouteValidator V03 source;
- PartialBoardDouble;
- V03 test bodies;
- preserved V02 tests;
- no M17 algorithm leakage;
- governance scope.

Godot is not available in the ChatGPT audit environment, so the 1673-check suite was not independently rerun.

## F-M16-STRICT-004 — PARTIALLY CLOSED

The V03 implementation correctly closes the object-shaped cases explicitly requested:
- non-null junk request object fails before field reads;
- non-null junk board object fails before board method use;
- partial board API fails closed;
- validate_route returns before access calls;
- validate_failure_result does not dereference a malformed request object.

Those tests are direct and well-isolated.

## New strict-v2 finding

### F-M16-STRICT-005 — remaining untyped Variant boundaries can still fault before fail-closed handling

Severity: **material contract-boundary defect**

M16 public validator entry points remain untyped. The V03 guards cover object-shaped junk but not every legal Variant input.

Two concrete gaps remain:

1. `_board_has_api(board)` calls `board.has_method(...)` after only checking `board != null`.
   A scalar/non-object Variant such as int/string/Vector2 is not proven safe before `has_method` is invoked.

2. `validate_route()` checks:
   `if result == null or not result.success`
   before proving `result` is a real RouteResult.
   A non-null malformed result object/scalar can therefore be dereferenced at `.success` and fault.

A similar safe-object guard is required before `access_query.has_method(...)`; null is covered, but arbitrary scalar/non-object access_query values are not directly proven fail-closed.

Strict-v2 requires the complete public boundary, not only RefCounted junk doubles, to fail closed.

## Required V04 closure

- Board input:
  - reject non-object Variant before any has_method call, OR prefer exact `board is BoardState` because this validator contract is explicitly BoardState-based;
  - direct scalar board tests: int, string, Vector2.

- Route result:
  - require `result is RouteResult` before any field/method dereference;
  - direct malformed object and scalar result tests;
  - zero access calls for malformed result.

- Access query:
  - reject non-object Variant before has_method;
  - direct int/string/Vector2 access-query tests;
  - stable MISSING_ACCESS_QUERY or another single documented failure reason;
  - zero access calls.

- Preserve all V02/V03 accepted behavior.

## Final verdict

**CHANGES_REQUIRED**

Affected M16 tasks remain open:
- SB-M16-002
- SB-M16-003
- SB-M16-010
- SB-M16-011

M17-C002 V02 remains BLOCKED_BY_M16.

Next:
`coordination/sessions/M16-C001/CHATGPT_PROMPT_V04.md`
