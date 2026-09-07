# M16-C001 — ChatGPT Independent Audit V02

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Audited implementation:
- base: `61608ff010fd2b8c7b9ea42c2690ea3d88483bca`
- head: `d12f558360255be7fc41fe3d758425aff12811f8`
- exact implementation diff: one commit
- active prompt: `CHATGPT_PROMPT_V02.md`
- criteria: `CHATGPT_AUDIT_CRITERIA_V02.md`
- Claude log: `CLAUDE_LOG_V02.md`

## Evidence classification

### E1/E2
Claude reports:
- Godot 4.7.1
- 1662 checks
- 0 failures
- ALL PASS
- git diff --check clean

These remain implementer evidence.

### E3
ChatGPT independently inspected:
- exact base/head compare and changed-file scope;
- `route_validator.gd`;
- non-bool access double;
- direct V02 adversarial test bodies;
- no M17 algorithm leakage;
- governance scope.

Godot is not available in the ChatGPT audit environment, so the suite was not independently rerun.

## V02 finding closure

### F-M16-STRICT-001 — CLOSED
Non-finite start/target coordinates are structurally rejected before route/access work. NaN and +/-INF are directly tested.

### F-M16-STRICT-002 — CLOSED
Every route point is checked for finiteness before access queries. NaN/INF middle points are directly tested with zero access calls.

### F-M16-STRICT-003 — CLOSED
Success/failure metadata coherence is now validated. Canonical failure structure has a dedicated validator.

### Non-bool access verdict — CLOSED
Integer/string/null access verdicts fail closed rather than using truthiness.

## New strict-v2 finding

### F-M16-STRICT-004 — malformed non-null request/board dependencies can still raise runtime errors

Severity: **material contract-boundary defect**

The V02 numeric guards assume both `request` and `board` expose the expected M16 fields/methods.

Examples:
- a non-null malformed request reaches `request.start_position`;
- a non-null malformed board reaches `board.get_width()` / `get_height()` / `is_valid_index()` / `get_cell_state()`.

Under current code those are runtime method/property faults, not stable fail-closed `INVALID_REQUEST` outcomes.

This is now explicitly covered by canonical audit learning AL-040: non-null is not enough for a duck-typed/stateful dependency boundary.

Required:
- validate request shape/type before reading request fields;
- validate the narrow BoardState method surface before any board method call;
- malformed non-null request -> stable INVALID_REQUEST, no runtime fault;
- malformed non-null board -> stable INVALID_REQUEST, no runtime fault;
- `validate_route()` must inherit the same fail-closed behavior;
- `validate_failure_result()` must not dereference an arbitrary malformed non-null request.

Direct adversarial tests must use non-null junk objects, not null.

## Final verdict

**CHANGES_REQUIRED**

The V02 corrections are accepted and must be preserved, but M16 cannot strict-close yet.

Affected tasks remain open:
- SB-M16-002
- SB-M16-003
- SB-M16-010
- SB-M16-011

Next:
`coordination/sessions/M16-C001/CHATGPT_PROMPT_V03.md`

M17-C002 V02 remains BLOCKED_BY_M16.
