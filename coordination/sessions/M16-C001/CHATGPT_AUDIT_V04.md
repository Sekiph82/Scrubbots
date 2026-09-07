# M16-C001 — ChatGPT Full Attack-Surface Audit V04

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This audit deliberately changes methodology from the earlier delta-only passes.

Per the owner-requested stricter method, ChatGPT performed a subsystem-level closure sweep across:
- RouteRequest
- RouteResult
- RouteValidator
- RoutingSystem base contract
- M16 test doubles/tests
- immediate M17 production consumer
- M19 dispatcher consumer

The goal was to freeze the complete M16 finding set before issuing another correction prompt.

Audited implementation:
- V04 base: `543c474b0d77eb742da8a518d491d099a2a58510`
- V04 head: `5323538a2af09b2fbbd420fa9a0800b7d228b24a`
- Claude log: `CLAUDE_LOG_V04.md`

## Evidence

Claude reports Godot 4.7.1:
- 1694 checks
- 0 failures
- ALL PASS
- git diff --check clean

This is E1/E2 implementer evidence.

ChatGPT independently inspected the exact V04 diff and the full current M16 subsystem plus immediate M17/M19 consumers. Godot is unavailable in the ChatGPT audit environment, so the suite was not independently rerun.

## V04 requested finding

### F-M16-STRICT-005 — CLOSED

V04 correctly hardens scalar/non-object Variant handling for:
- validator board input;
- validator result input;
- validator access-query input.

The new scalar int/String/Vector2 tests are direct and appropriately fail closed.

## Full attack-surface sweep

### RouteValidator — accepted areas

Accepted:
- RouteRequest type guard;
- scalar/object board shape guards;
- finite request coordinates;
- canonical target/dimension checks;
- RouteResult type guard;
- success/failure metadata coherence;
- finite route points;
- bool-only access verdict;
- no-retarget validation;
- detached points;
- zero-access-call observability on malformed input.

### F-M16-STRICT-006 — BoardState API-shape guard does not prove return-value contract

Severity: **material boundary defect**

V04 chose the alternative duck-typed board guard rather than exact `board is BoardState`.

The V04 prompt explicitly allowed that alternative only if it validated the required API surface **and return types strongly enough that RouteRequest.center_of_index() cannot fault**.

Current `_board_has_api()` only checks method existence:
- get_width
- get_height
- is_valid_index
- get_cell_state
- get_cell_position

An object can expose all five names but return incompatible values. Validation then proceeds into typed assignments/comparisons or `RouteRequest.center_of_index()`, where an invalid return can fault rather than produce stable INVALID_REQUEST.

Required:
- prefer exact `board is BoardState` at the M16 validator/factory boundary, OR fully validate every required return type before use;
- direct adversarial full-shape/wrong-return double.

### F-M16-STRICT-007 — RouteRequest public factories are still unsafe on malformed board input

Severity: **material public-contract defect**

`RouteRequest.center_of_index(board,index)` checks only null and then immediately calls `board.get_cell_position(index)`.

`RouteRequest.for_target(board,start,target)` checks only null and then immediately calls `board.is_valid_index(target)`.

Therefore non-null scalar, malformed object, or full-shape/wrong-return board values can fault at the RouteRequest public API even though RouteValidator itself is now hardened.

The M16 contract cannot be considered fail-closed while its canonical request factory remains an unsafe entry point.

Required:
- harden both public RouteRequest functions at the board boundary;
- exact BoardState identity is preferred because these functions are explicitly BoardState-based;
- malformed board -> sentinel/null according to existing documented function semantics, never runtime error;
- direct scalar, junk-object and wrong-return tests.

Additional canonicalization:
- `for_target()` should reject non-finite start_position instead of constructing a request that is known-invalid at creation time. A canonical factory should not emit a structurally invalid request.

### F-M16-STRICT-008 — RoutingSystem base contract dereferences arbitrary non-null request

Severity: **material public-contract defect**

Base `RoutingSystem.compute_route(request,...)` currently does:

`request.target_index if request != null else -1`

A scalar or malformed non-null request can therefore fault before the base class returns its documented clean NOT_IMPLEMENTED failure.

Required:
- only read target_index from a real RouteRequest;
- malformed request -> stable failure with target -1;
- real RouteRequest -> NOT_IMPLEMENTED retaining its target;
- direct null/object/scalar tests.

## RouteResult full sweep

No new required correction found.

Its factories are intentionally lightweight value constructors and the shared validator is the trust boundary for success/failure coherence. Detached point copy-in/copy-out remains correct. Public mutability is already treated as untrusted by RouteValidator.

## Immediate consumer sweep

### M17 ProductionRoutingSystem

Known M17 strict findings remain:
- capped exterior entries;
- sampled segment access;
- missing self-validation/final route validation;
- incomplete topology seam;
- BoardState coherence.

Those remain M17-C002 V02 scope and are **not duplicated as new M16 findings**.

### M19 ScrubbotDispatcher

M19 consumes RouteRequest/RouteResult and has its own untyped collaborator/result assumptions. M19 is already IMPLEMENTED_BUT_AUDIT_BLOCKED and must receive its own strict full-surface audit after corrected M11-M17 dependencies. Those are not used to keep M16 open beyond the M16-owned API defects above.

## Frozen M16 finding set

The M16 correction set is now frozen to:
- F-M16-STRICT-006
- F-M16-STRICT-007
- F-M16-STRICT-008

ChatGPT MUST NOT issue another M16 correction prompt after V05 without first documenting a genuinely new runtime fact that could not reasonably have been observed in this full-surface sweep.

## Final verdict

**CHANGES_REQUIRED / FINDING_SET_FROZEN**

Keep open:
- SB-M16-002
- SB-M16-003
- SB-M16-010
- SB-M16-011

Next:
`coordination/sessions/M16-C001/CHATGPT_PROMPT_V05.md`

M17 remains blocked.
