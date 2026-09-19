# M30-C001 V01 - MASTER STRICT AUDIT CRITERIA

Milestone: `M30 - Win/Lose Rules`
Tasks: `SB-M30-001..008`
Owner authority: `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`

All sections are blocking unless explicitly marked non-blocking.

## A. Governance

- root TASKS unchanged by Claude;
- no M31/economy/result-art scope creep;
- zero AI image generation;
- implementation commit(s) precede separate log commit;
- accepted M23-M29 authority boundaries preserved.

## B. WIN truth

WON can latch only when:
- BoardState ACTIVE = 0;
- M26 live assignments = 0;
- dispatcher active agents = 0;
- M25 live claims = 0;
- reservations = 0;
- M24 live committed work = 0;
- no pending clear transaction remains.

Direct negative test:
- board approaches zero but a legitimate final transaction is still in flight -> no early WON.

Direct positive test:
- final authenticated clear/finalize settles all authorities -> WON.

## C. LOSE truth

LOST can latch only from real M27 `DeadlockClassifier.DEADLOCK` at quiescence.

Prove:
- WAITING != LOST;
- STALLED != LOST;
- PROGRESSABLE != LOST;
- UNKNOWN_BOUND != LOST;
- in-flight assignment != LOST;
- proven DEADLOCK + no in-flight progress -> LOST.

Do not duplicate M27 proof logic.

## D. Exact-once terminal result

For each attempt:
- terminal result begins PLAYING;
- WON or LOST latches at most once;
- exactly one terminal event emits;
- later callbacks/frames cannot emit duplicate terminal event;
- terminal result cannot flip WON<->LOST.

Retry creates a new attempt with a fresh exact-once latch.

## E. Post-terminal blocking

After WON/LOST and before Retry:
- supply-front input rejects deterministically;
- M23 does not advance;
- M24 does not mutate;
- scheduler accepts no new assignment;
- no new Scrubbot spawns;
- pause/focus callbacks do not accidentally clear terminal state.

## F. In-flight handling

Terminal result must not destroy legitimate work to reach a result.

WIN/LOSE only after the accepted quiescent conditions.

No ghost agents, claims, reservations or committed work may survive a successful terminal settle/retry boundary.

## G. Event-driven evaluation

Deadlock proof must not run unconditionally each render frame.

Prove a dirty/event-driven gate or equivalent bounded evaluation policy.

Repeated idle frames with no state change must not repeatedly invoke full M27 proof.

## H. Transaction-safe Retry

Before destructive M23/M24/board reset:
- M26 reset/teardown must succeed.

Failure/deferred test:
- force scheduler reset failure/defer;
- Retry reports failure;
- M23 snapshot unchanged;
- M24 snapshot unchanged;
- BoardState unchanged;
- speed/terminal state not falsely reset;
- no partial new attempt.

Successful Retry:
- exact initial board restored;
- exact initial M23 full snapshot restored;
- five slots empty;
- committed work 0;
- claims 0;
- reservations 0;
- assignments 0;
- live agents 0;
- speed 1x;
- speed UI 1x;
- pause/system suspension clear;
- result PLAYING;
- input enabled.

## I. Same puzzle on Retry

Capture the exact M23 initial full/debug snapshot before first play.

After Retry compare:
- column count;
- batch IDs;
- colors;
- counts;
- order;
- seed/config metadata where represented.

Must be equivalent.

No new random candidate.

## J. Board and presentation reset

After partial clearing then Retry:
- all source cells ACTIVE;
- candidate index rebuilt/coherent;
- renderer shows full original artwork again;
- no stale transparent cleared pixels;
- five-slot UI EMPTY;
- supply front/preview UI matches initial attempt.

## K. Stale callback/generation safety

After successful Retry:
- pre-retry agent/callback/owner/work identity cannot mutate the new attempt;
- stale arrival cannot clear a new board cell;
- stale terminal callback cannot emit a second old result;
- no recycled identity collision that violates accepted M25/M26 contracts.

## L. Manual production playtest

Owner-testable real scene must demonstrate:
- solved Hazard Bot -> WON exactly once;
- one proven deadlock case -> LOST exactly once;
- terminal blocks further front placement;
- Retry restores same board/supply;
- Retry starts 1x;
- fresh attempt is playable.

A minimal debug result UI is sufficient.

## M. Regression floor

At minimum:
- full root suite;
- dedicated M30 WIN tests;
- dedicated M30 DEADLOCK/STALLED/UNKNOWN tests;
- exact-once terminal tests;
- terminal input/scheduler blocking tests;
- retry success tests;
- retry reset-failure atomicity tests;
- same-supply retry equivalence;
- board/renderer reset tests;
- stale callback tests;
- M29 real-time graphical/process smoke;
- M29 slot sync/count evidence;
- M29 exact slot origin;
- M28 layout;
- M27 Hazard/59/generation/deadlock classifier;
- M26 Hazard/scale/reset;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 Railroad/connector;
- M20 lifecycle;
- `git diff --check`.

## N. Closure

PASS only when the production stack has deterministic exact-once WON/LOST truth and a transaction-safe same-puzzle Retry loop.

M30 closure does not require final branded result-screen art or Economy rewards.
