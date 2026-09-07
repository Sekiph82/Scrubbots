# M15-C001 — Strict Adversarial Correction / Validation V02

Status: **ISSUED**

Read:
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M15-C001/CHATGPT_STRICT_REAUDIT_V02.md`
- original M15 V01 prompt/log/audit
- this prompt + V02 criteria

Fix ONLY the strict M15 findings. Do not implement routing/dispatcher/vertical
slice work.

## 1. Dependency contract fail-closed

TargetSelector.bind() must reject non-null malformed dependencies before setting
bound state.

Validate only the narrow APIs M15 actually requires.

A failed bind must:
- return false;
- leave selector unbound;
- clear/neutralize prior bound refs so stale dependencies cannot be reused.

Add malformed non-null dependency tests.

## 2. Same-BoardState coherence

Add a narrow read-only identity query to ColorCandidateIndex and ReservationState,
for example:

`is_bound_to(board) -> bool`

Requirements:
- exact object identity, not equal dimensions/content;
- no mutable board reference is exposed;
- false when unbound.

TargetSelector:
- requires candidate index and reservation state to be bound to the SAME board
  passed to TargetSelector.bind();
- re-checks this coherence at every select_and_reserve() call, because a sibling
  dependency may be rebound after selector bind;
- mismatched same-size boards fail closed with no reservation and no candidate
  selection.

Required adversarial tests:
- candidate index on Board A + selector Board B, same dimensions -> bind fails;
- reservation on Board A + selector Board B, same dimensions -> bind fails;
- bind valid on Board A, then rebind candidate index to Board B -> selection
  fails closed;
- bind valid on Board A, then rebind reservation state to Board B -> selection
  fails closed;
- no internal board reference can be mutated through the new identity API.

## 3. Same-owner contention retry

Create a direct contention test where:
- owner X starts selection;
- first candidate is access-approved;
- access-query side effect synchronously reserves another valid target for SAME
  owner X before TargetSelector.reserve(first) executes;
- TargetSelector.reserve(first, X) loses because X now owns another target.

Required result:
- selector detects owner X is now assigned;
- it stops immediately;
- it does not query/attempt later candidates;
- it creates no additional reservation;
- the side-effect reservation remains the only reservation owned by X.

Preserve the existing different-owner contention behavior: when another owner
takes the contested target and X still owns nothing, X may continue to the next
valid candidate.

## Regression

Preserve:
- deterministic ascending selection;
- ACTIVE/color final BoardState checks;
- blocked/unreachable filtering;
- no routing APIs;
- no BoardState mutation;
- no candidate-index mutation;
- reservation uniqueness;
- rectangular and 59×59 coverage.

Run Godot 4.7.1 full headless suite and `git diff --check`.

Governance: do not modify tasks.md, .hiveai/*, SESSION_INDEX, AUDIT_INDEX or any
ChatGPT audit/re-audit file.

Write:
`coordination/sessions/M15-C001/CLAUDE_LOG_V02.md`

Commit/push and return `AWAITING_AUDIT`. Stop.
