# M15-C001 — Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

This re-audit applies `coordination/AUDIT_POLICY.md` Strict Audit Standard v2
to the previously accepted TargetSelector.

Implementation under review:
- `scripts/gameplay/targeting/target_selector.gd`
- `scripts/gameplay/targeting/color_candidate_index.gd`
- `scripts/gameplay/targeting/reservation_state.gd`
- existing M15 tests/log/audit

Godot is not available in the ChatGPT audit environment. Existing green runtime
results remain E2. The findings below come from independent source/test/adversarial
contract inspection.

## F-M15-STRICT-001 — malformed bound dependencies do not fail closed

Severity: **material contract defect**

`TargetSelector.bind()` currently rejects only null values. Non-null objects
that do not implement the required narrow APIs can be accepted and later cause a
runtime method error during selection.

Strict-v2 requires malformed dependencies to fail closed at the boundary.

Required:
- validate the narrow required API surface at bind time;
- failed bind leaves the selector unbound and unable to use stale prior refs;
- tests must pass non-null malformed doubles and prove no runtime call escapes.

Affected:
- SB-M15-001
- SB-M15-008

## F-M15-STRICT-002 — dependency BoardState coherence is not enforced

Severity: **material stale-state / ownership defect**

TargetSelector binds three independently stateful dependencies:
- BoardState;
- ColorCandidateIndex;
- ReservationState.

Nothing proves the candidate index and reservation layer are bound to the SAME
BoardState instance as TargetSelector.

A mismatched ReservationState can validate/reserve target index N against Board B
while TargetSelector validates N against Board A. Same dimensions/index range do
not make those ownership truths equivalent.

Bind-time checking alone is also insufficient because candidate/reservation
dependencies can be rebound later.

Required:
- add a narrow read-only board-identity seam such as `is_bound_to(board)` to
  ColorCandidateIndex and ReservationState;
- do NOT expose a mutable board reference;
- TargetSelector bind must require coherence;
- every selection call must re-check coherence so post-bind dependency rebind
  fails closed;
- mismatched same-size boards must be tested directly.

Affected:
- SB-M15-001
- SB-M15-007
- SB-M15-008

## F-M15-STRICT-003 — contention retry does not re-check owner assignment

Severity: **material synchronous-contention contract defect**

The original M15 rule says that after a reservation attempt loses, selection may
continue only if the requesting owner still has no reservation.

Current code simply continues after `reserve()` returns false.

An adversarial access-query side effect can assign the SAME owner to another
target between access approval and the selector reserve attempt. The reserve then
fails, but the selector continues querying later candidates despite the owner
already being assigned.

ReservationState still prevents a duplicate reservation, so this is not immediate
dictionary corruption. It is nevertheless a contract violation and can trigger
incorrect later access-query side effects/work.

Required:
- after every failed reserve attempt, re-check
  `get_target_for_owner(owner_id)`;
- if owner is now assigned, stop and return clean no-new-target;
- adversarial test must use the same owner in the side effect, not another owner.

Affected:
- SB-M15-011

## Strict task state

Reopen:
- SB-M15-001
- SB-M15-007
- SB-M15-008
- SB-M15-011

Other M15 tasks remain accepted.

Next:
`coordination/sessions/M15-C001/CHATGPT_PROMPT_V02.md`
