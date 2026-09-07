# M16-C001 — Strict Boundary Hardening V03

Status: **ISSUED**

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M16-C001/CHATGPT_AUDIT_V02.md
- prior M16 V01/V02 prompt/log/audit artifacts
- this prompt + V03 criteria

Fix ONLY F-M16-STRICT-004. Preserve every accepted V02 correction.

## Required boundary behavior

### Request

A non-null malformed object passed as `request` must fail closed before reading:
- start_position
- target_position
- target_index
- board_width
- board_height

Prefer an exact/robust RouteRequest identity check if compatible with Godot 4.7.1, otherwise use a narrow structural guard that cannot itself throw.

Expected:
- validate_request(junk, valid_board) -> INVALID_REQUEST
- validate_route(junk, result, valid_board, access) -> INVALID_REQUEST
- zero access calls

### Board

Before any board method call, require the narrow M16 BoardState API:
- get_width
- get_height
- is_valid_index
- get_cell_state
- get_cell_position

A non-null malformed board must:
- return INVALID_REQUEST;
- make zero access calls;
- never throw.

Do not expose/store the board.

### Failure-result validator

`validate_failure_result(request, result)` must not dereference arbitrary malformed non-null request input.

For malformed non-null request:
- fail closed to INVALID_ROUTE (or a single stable documented structural failure);
- never throw.

Null request may retain its existing documented semantics if intentionally supported.

## Required adversarial tests

At minimum:

1. RefCounted junk request -> validate_request fails closed.
2. RefCounted junk board -> validate_request fails closed.
3. junk request through validate_route -> stable failure + zero access calls.
4. junk board through validate_route -> stable failure + zero access calls.
5. object with only SOME BoardState methods -> fail closed before the first missing-method call.
6. malformed request passed to validate_failure_result -> stable failure, no runtime error.
7. all V02 NaN/INF/result-coherence/non-bool tests remain green.
8. normal real RouteRequest + BoardState path remains green.
9. 59x59 + 53x59 regressions remain green.
10. no M17 pathfinding/movement-language work.

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
`coordination/sessions/M16-C001/CLAUDE_LOG_V03.md`

Commit/push safely.

Return:
`AWAITING_AUDIT`

Then STOP.
