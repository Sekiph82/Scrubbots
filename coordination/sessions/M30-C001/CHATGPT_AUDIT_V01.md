# M30-C001 V01 — ChatGPT Strict Audit

Date: 2026-09-19
Repository: `Sekiph82/Scrubbots`
Milestone: `M30 — Win/Lose Rules`
Cycle: `M30-C001 V01`
Auditor: ChatGPT

Implementation SHA:
`5e1b82ba2f9e8729e5137a6d4e643e304ae5ddeb`

Claude log SHA:
`d9c7e82864d0ece0025601ac8c53764852be66cb`

Owner authority:
`coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`

Master criteria:
`coordination/sessions/M30-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CHANGES_REQUIRED / NARROW M30 V02 REMEDIATION**

The core M30 architecture is accepted and must not be rewritten.

Accepted V01 behavior:
- real M27 DeadlockClassifier is the LOSE authority;
- DEADLOCK only at quiescence can produce LOST;
- WAITING / STALLED / PROGRESSABLE / UNKNOWN_BOUND are not losses;
- WIN requires ACTIVE=0 plus no live scheduler assignment / agent / claim / reservation / committed work;
- exact-once PLAYING -> WON/LOST terminal latch;
- event/dirty-gated deadlock proof;
- terminal supply-front blocking;
- terminal runtime stop distinct from user pause;
- same deterministic M23 supply reset;
- M26 scheduler reset is the first destructive Retry gate;
- implementation/log commit isolation is correct;
- no TASKS edit by Claude, no M31/Economy/art scope.

Do not reopen these accepted areas.

Three blocking findings remain.

---

## F-M30-V01-001 — cross-engine inconsistency detection is incomplete

### Evidence

`CompletionEvaluator.has_fatal_inconsistency()` currently checks only:

- M26 `scheduler.is_fatal()`;
- `dispatcher.get_active_count() != scheduler.live_assignment_count()`.

It does NOT classify drift involving the other authorities as ERROR.

Example stable evaluation states:

- scheduler=0, dispatcher=0, claim=1;
- scheduler=0, dispatcher=0, reservations=1;
- scheduler=0, dispatcher=0, M24 live_work=1;
- scheduler=1, dispatcher=1, claim/reservation/live_work=0.

These are cross-engine incoherences, not legitimate progress states. Current evaluator returns:

`PLAYING / in_flight_work`

because `is_quiescent()` is false.

That can leave the attempt permanently PLAYING with no real transaction capable of resolving the orphan state.

### Contract violated

Owner decision §2:

> A cross-engine inconsistency or fatal bookkeeping state is not silently reclassified as LOSE. It must fail closed / surface as an error condition for diagnostics.

V01 correctly avoids false LOST, but does not surface these non-dispatcher inconsistencies as ERROR.

### Required correction

At the stable M30 evaluation boundary, validate the live production transaction cardinalities.

For a healthy production M25/M26 in-flight transaction, these authorities must agree:

- scheduler live assignments;
- dispatcher active agents;
- M25 live claims;
- ReservationState live reservations;
- M24 live committed work.

All-zero is quiescent.
Equal positive counts are legitimate in-flight work.
Any cardinality drift is ERROR.

Do not evaluate this during an internal half-step callback. M30 already evaluates at the runtime state-sync tail, after synchronous scheduler/clear work settles.

Add direct tests for each independent mismatch plus a healthy equal-positive in-flight state.

---

## F-M30-V01-002 — Retry has no restore-collaborator preflight and ignores candidate-index rebuild failure

### Evidence

`RetryCoordinator.attempt()` validates only that `scheduler` is non-null, then immediately calls:

`scheduler.reset()`

which is intentionally the first destructive gameplay gate.

After that destructive teardown it blindly invokes the remaining restore collaborators.

Most importantly:

`bundle["candidate_index"].rebuild()`

returns a boolean fail-closed result, but V01 ignores it and continues to:

- reset runtime;
- unblock input;
- resume scheduler;
- reset completion to PLAYING;
- return `true`.

Therefore V01 can report a successful fresh Retry even if the candidate index is not rebuilt/coherent.

The coordinator also does not preflight required bundle collaborators/methods before destructively resetting M26. A missing/dead/malformed restore collaborator can therefore be discovered only after M26 has already torn down the old attempt.

### Contract violated

Owner decision §6 explicitly requires:

- first preflight/prepare everything needed for Retry;
- then invoke M26 teardown;
- never create a half-old / half-new attempt;
- successful Retry must rebuild coherent candidate truth.

Master criteria §H/J require a fully coherent fresh attempt.

### Required correction

Before `scheduler.reset()`:

- preflight every required restore collaborator and required method;
- validate the candidate index is currently bound to the exact production board;
- validate the renderer, if required by the production bundle, is bound to that exact board;
- validate the callback/seams needed for restore;
- do not mutate anything if preflight fails.

After board restoration:
- require `candidate_index.rebuild() == true`;
- verify it remains bound to the exact board;
- never return Retry success if rebuild/coherence verification failed.

Do not weaken M26 reset semantics.

Add tests proving malformed/missing restore dependencies fail BEFORE scheduler.reset is called.

Add a direct rebuild-failure test. A successful Retry must never return true with an unbound/neutralized candidate index.

---

## F-M30-V01-003 — Retry leaves M20 attempt-scoped clear observation state from the previous attempt

### Evidence

Accepted M26 `scheduler.reset()` calls `CompleteClearingLoop.reset()`.

That M20 reset correctly cancels in-flight transaction state but intentionally preserves historical board progress because its original contract is not a full level restart.

Its reset implementation does NOT zero:

- `_cleared_count`;
- `_last_outcome`.

M30 Retry then restores BoardState to all ACTIVE and starts a fresh PLAYING attempt.

Therefore, after a completed 400-cell Hazard attempt followed by Retry:

- BoardState is fresh/all ACTIVE;
- M23/M24 are fresh;
- terminal state is PLAYING;
- but `CompleteClearingLoop.get_cleared_count()` can still report 400;
- `get_last_outcome()` can still report the prior attempt's final outcome.

A replay can therefore accumulate attempt-1 observation state into attempt 2.

Current M30 tests do not assert these values after Retry.

### Contract violated

Owner decision §5 requires a fresh attempt.
Master Retry criteria require one coherent fresh production state and stale-callback/attempt isolation.

### Required correction

Do NOT change the historical semantics of `CompleteClearingLoop.reset()`.

Add a narrow M30-compatible fresh-attempt observation reset seam, for example an explicit method whose only responsibility is to reset attempt-scoped observation state after M26 teardown has safely completed.

A successful Retry must leave:

- `cleared_count == 0`;
- `last_outcome == Outcome.NONE`.

Call it only after the M26 teardown gate succeeds.

Add direct tests:
- partial/complete attempt has cleared_count > 0;
- Retry;
- cleared_count == 0;
- last_outcome == NONE;
- replay count belongs only to the new attempt, not cumulative history.

---

## Commit isolation

Verified:

Implementation:
`5e1b82ba2f9e8729e5137a6d4e643e304ae5ddeb`

Log:
`d9c7e82864d0ece0025601ac8c53764852be66cb`

Implementation -> log is exactly one commit and adds only:

`coordination/sessions/M30-C001/CLAUDE_LOG_V01.md`

The V01 implementation commit does not modify root `TASKS.md`.

---

## Accepted regression evidence

Claude reports the root runner PASS and the dedicated M30 suites PASS.

The two reported standalone M21 corridor/evidence failures are outside the M30 diff and were reproduced on the pre-M30 baseline. They are not M30 regressions and do not block this narrow audit.

No broad M20-M29 reopening is authorized.

---

## V02 scope

V02 is limited to:

1. complete cross-engine inconsistency detection;
2. preflight/verify Retry restoration, especially candidate index coherence;
3. clear M20 attempt-scoped observation state on successful Retry;
4. direct regressions for those three findings.

Everything else from M30 V01 remains accepted and must not be rewritten.

## Verdict string

`CHANGES_REQUIRED / M30-C001 V02 NARROW REMEDIATION REQUIRED`
