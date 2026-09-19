# OWNER WIN / LOSE / RETRY DECISION V01

Date: 2026-09-19
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: M30 — Win/Lose Rules

## 1. WIN condition

The level is WON only when the board is fully cleared **and the gameplay transaction pipeline is quiescent**.

Canonical WIN requirements:

- `BoardState.count_cells_by_state(ACTIVE) == 0`;
- no live M26 assignment remains;
- no live ScrubbotAgent remains in flight;
- no live M25 claim remains;
- no live ReservationState ownership remains for gameplay work;
- no live M24 committed work remains;
- no pending authenticated-clear transaction remains.

The result must not fire early while the last Scrubbot is still travelling or while any claim/commit/clear transaction is unresolved.

A normal final authenticated clear should naturally produce this quiescent state and then latch WIN.

## 2. LOSE condition

The level is LOST only when the accepted M27 runtime classifier proves:

`status == DeadlockClassifier.DEADLOCK`

and there is no live in-flight/progress transaction that can still alter the board.

Therefore:

- WAITING alone is NOT a loss;
- STALLED is NOT a loss;
- PROGRESSABLE is NOT a loss;
- UNKNOWN_BOUND is NOT a loss;
- an occupied slot with temporarily unreachable work is NOT a loss;
- a live M26 assignment / in-flight Scrubbot prevents loss;
- a legal future supply-front placement that can unlock progress prevents loss.

Only a proven M27 DEADLOCK at a quiescent gameplay boundary may latch LOSE.

A cross-engine inconsistency or fatal bookkeeping state is not silently reclassified as LOSE. It must fail closed / surface as an error condition for diagnostics.

## 3. Terminal latch

M30 owns one terminal result authority with at least:

- PLAYING;
- WON;
- LOST.

WON/LOST is latched exactly once per attempt.

After terminal latch:

- player supply-front input is blocked;
- no new M26 scheduler assignment may be accepted;
- no duplicate terminal event may be emitted;
- no second reward/result transaction may be generated.

Because WIN and LOSE are evaluated only at a quiescent terminal boundary, no legitimate in-flight Scrubbot is discarded merely to show a result.

Terminal state remains stable until Retry/Restart begins a new attempt.

## 4. Completion evaluation timing

Do not run the expensive M27 deadlock proof blindly every render frame.

Evaluation should be event/dirty driven at meaningful gameplay boundaries, for example:

- successful supply-front placement;
- authenticated clear/finalization;
- scheduler transition to no immediate assignment / quiescence;
- relevant wake/state change;
- supply exhaustion.

Cheap WIN checks may run more frequently if desired.

DEADLOCK proof is evaluated only when there is no in-flight work that already guarantees future progress.

## 5. Retry / Restart semantics

Retry starts the **same level from the beginning with the same initial batch/supply sequence**.

The retry attempt must restore:

- original board: all source pixels ACTIVE;
- same level identity;
- same M23 column count;
- same preview depth;
- same generation seed/config;
- exact same initial M23 batch IDs/colors/counts/order;
- empty authoritative batch slots;
- zero M24 committed work;
- zero M25 claims;
- zero reservations;
- zero scheduler assignments;
- zero live ScrubbotAgents;
- cleared transient WAITING/ACTIVE slot lifecycle because slots are empty;
- runtime unpaused;
- gameplay speed = 1x;
- speed UI = 1x;
- fresh PLAYING terminal state.

Retry must not generate a new/random puzzle candidate.

The initial supply snapshot before first play and the supply snapshot after retry must be exactly equivalent.

## 6. Transaction-safe retry

M29 V03 introduced a provisional `ProductionGameplayHost.reset_session()` helper that currently ignores the return value of `AutoDispatchScheduler.reset()`.

M30 MUST harden this before exposing Retry.

Canonical rule:

- first preflight/prepare everything needed for a retry;
- invoke the accepted M26 teardown/reset path;
- if scheduler teardown fails, is deferred, or remains pending, Retry MUST fail closed;
- on such failure, do NOT reset M23 supply, M24 slots, BoardState, speed, or terminal result as if retry succeeded;
- never create a half-old / half-new attempt;
- stale pre-retry callbacks/agents must never mutate the new attempt.

A successful retry may rebuild the coherent production gameplay bundle if that is safer than mutating every existing engine in place, but it must preserve the exact same level/supply candidate and presentation contract.

## 7. Economy boundary

M30 does not award currency, consume Hearts, update Win Streak, or implement real-money behavior.

It may emit one stable terminal result event for later progression/economy systems to consume.

Existing Economy V1 rules remain separate authorities.

## 8. Result presentation boundary

M30 owns terminal gameplay truth and a functional owner-testable result/retry seam.

Final branded Win/Lose result-screen art is not required to close M30 unless already separately approved.

A minimal native/debug result label/button is acceptable for the M30 manual playtest as long as it uses the real production completion authority.

## 9. Canonical examples

### WIN

Last Scrubbot arrives -> authenticated clear -> final ACTIVE pixel becomes CLEARED -> M25/M24 finalize -> no live assignment/claim/reservation/commit/agent -> latch WON exactly once.

### Not LOSE

Red/Yellow/Brown batches are WAITING, but future Blue/Black clearing or legal future supply placement can open progress -> M27 returns STALLED/PROGRESSABLE -> keep PLAYING.

### LOSE

No in-flight work, no immediate claimable target, and M27 proves no legal future placement/action sequence can ever produce progress -> DEADLOCK -> latch LOST exactly once.

### RETRY

Player retries after terminal result -> safe teardown succeeds -> same level and exact same initial supply sequence restored -> five slots empty -> board fully ACTIVE -> speed 1x -> PLAYING.
