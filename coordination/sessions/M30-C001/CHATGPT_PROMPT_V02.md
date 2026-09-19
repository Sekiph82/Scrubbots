# M30-C001 V02 — Narrow Strict Remediation

Repository: `Sekiph82/Scrubbots`
Branch: `main`

Read first:
1. `coordination/sessions/M30-C001/CHATGPT_AUDIT_V01.md`
2. `coordination/sessions/M30-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
3. `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`
4. V01 implementation + `CLAUDE_LOG_V01.md`

V01 core M30 architecture is ACCEPTED.

Do not rewrite WIN/LOSE/terminal architecture.
Fix only the three audit findings in one continuous pass.

## Finding 1 — full cross-engine inconsistency detection

CompletionEvaluator currently only detects scheduler/dispatcher count drift.

At the stable runtime evaluation boundary, healthy live transaction cardinalities must agree across:

- M26 scheduler assignments;
- dispatcher active agents;
- M25 live claims;
- ReservationState reservations;
- M24 committed work.

All zero = quiescent.
All equal positive = legitimate in-flight.
Any mismatch = ERROR, never LOST and never indefinite PLAYING.

Add direct one-axis drift tests plus healthy positive-count test.

## Finding 2 — transaction-safe Retry restore preflight / candidate rebuild verification

Before `scheduler.reset()`:

- validate the entire restore bundle needed after teardown;
- verify required methods;
- verify candidate index is bound to the exact board;
- verify supplied production renderer is bound to the exact board;
- verify optional restore callback is valid.

If preflight fails:
- return false;
- scheduler.reset must NOT be called;
- no state may mutate.

After BoardState restore:
- require `candidate_index.rebuild() == true`;
- verify candidate index remains bound to the exact board;
- verify rebuilt candidate truth reflects the full ACTIVE board.

Never return true on rebuild failure.

Add failure-injection evidence.

Do not weaken M26.

## Finding 3 — reset M20 attempt-scoped observation state

M26/M20 `reset()` intentionally does not reset historical `cleared_count` / `last_outcome`.

Do not change that accepted historical reset contract.

Add a narrow explicit M30 Retry fresh-attempt seam in CompleteClearingLoop, called only after successful M26 teardown, that resets attempt observation state:

- cleared_count -> 0;
- last_outcome -> Outcome.NONE.

Wire the clearing loop into RetryCoordinator's validated restore bundle.

Prove:
- gate failure leaves these values unchanged;
- successful Retry zeros them;
- a replay counts only the new attempt.

## Preserve all V01 accepted behavior

Keep:
- real M27 classifier;
- DEADLOCK-only LOST;
- no WAITING/STALLED/UNKNOWN loss;
- exact-once terminal result;
- event-gated proof;
- terminal input/scheduler stop;
- same deterministic supply on Retry;
- current owner playtest scene behavior.

Do not modify TASKS.md.
Do not implement M31.
Do not implement Economy.
Zero AI image generation.

Run the V02 criteria regression floor.

Push implementation first.

Then create:
`coordination/sessions/M30-C001/CLAUDE_LOG_V02.md`

as a separate final commit.

Return only:
`AWAITING_AUDIT`
final implementation SHA
direct GitHub `CLAUDE_LOG_V02.md` URL.
