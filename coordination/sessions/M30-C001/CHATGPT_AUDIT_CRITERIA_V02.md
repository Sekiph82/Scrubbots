# M30-C001 V02 — Strict Remediation Criteria

Cycle: `M30-C001 V02`

Authority:
- `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`
- `coordination/sessions/M30-C001/CHATGPT_AUDIT_V01.md`

V01 core terminal architecture is accepted. Only the three V01 audit findings are in scope.

## 1. Complete cross-engine consistency guard

At the stable completion-evaluation boundary, read:

- scheduler live assignment count;
- dispatcher active agent count;
- M25 live claim count;
- reservation count;
- M24 live committed-work count.

Healthy states:

- all zero = quiescent;
- all equal positive N = legitimate in-flight N transactions.

Any cardinality mismatch = `ERROR`.

Direct tests must independently drift:
- scheduler;
- dispatcher;
- claim;
- reservation;
- M24 committed work.

Also test equal positive counts remain PLAYING/in-flight, not ERROR.

Do not classify any mismatch as LOST.

## 2. Retry preflight before M26 teardown

Before calling `scheduler.reset()`, validate every restore dependency needed after the gate.

At minimum prove:
- required object exists;
- required method surface exists;
- candidate index is bound to the exact board;
- production renderer is coherent/bound to the exact board when supplied;
- restore callback, when supplied, is valid.

Malformed/missing restore bundle must:
- return false;
- call scheduler.reset zero times;
- mutate nothing.

## 3. Candidate rebuild is a required postcondition

After a successful M26 reset and BoardState restoration:

- `candidate_index.rebuild()` must return true;
- candidate index must still be bound to the exact BoardState;
- candidate counts must reflect the fully ACTIVE board.

Retry must never return true when candidate rebuild/coherence verification failed.

Add a rebuild-failure evidence path.

Do not weaken or bypass M13 fail-closed semantics.

## 4. M20 fresh-attempt observation reset

Preserve historical `CompleteClearingLoop.reset()` behavior.

Add a separate/narrow fresh-attempt seam for M30 Retry.

After successful Retry:
- `get_cleared_count() == 0`;
- `get_last_outcome() == Outcome.NONE`.

It must execute only after the M26 teardown gate succeeds.

On Retry gate failure:
- M20 attempt observation state must remain unchanged.

## 5. Retry end-to-end fresh attempt

After a real partially/fully played Hazard attempt and successful Retry verify:

- full board ACTIVE;
- exact same initial M23 debug snapshot;
- five slots EMPTY;
- M24 committed 0;
- M25 claims 0;
- reservations 0;
- scheduler assignments 0;
- dispatcher agents 0;
- M20 cleared_count 0;
- M20 last_outcome NONE;
- candidate index bound/coherent and repopulated for the full ACTIVE board;
- speed 1x;
- runtime/input terminal stop false;
- completion PLAYING;
- visible renderer full artwork;
- supply/slot UI fresh.

Replay must produce a current-attempt clear count, not previous+current cumulative count.

## 6. Preserve accepted V01 behavior

Do not rewrite:
- M27 DEADLOCK authority;
- WIN conditions;
- dirty/event gate;
- exact-once terminal latch;
- terminal input block;
- terminal scheduler/runtime stop;
- same-puzzle supply reset;
- M23-M29 accepted gameplay.

No M31.
No Economy.
No visual generation.
Root TASKS read-only for Claude.

## 7. Regression floor

Run:
- all dedicated M30 V01 tests;
- new V02 remediation tests;
- M29 real-time movement;
- M29 slot sync/count;
- M29 exact origins;
- M27 classifier/solver;
- M26 reset/integration;
- M25;
- M24;
- M23;
- M22 Railroad;
- M20 clearing lifecycle;
- root test runner;
- `git diff --check`.

Pre-existing unrelated M21 standalone failures may be documented but must not be modified in this remediation.

## 8. Handoff

Implementation commit(s) first.

Then separate:
`coordination/sessions/M30-C001/CLAUDE_LOG_V02.md`

Return only:
`AWAITING_AUDIT`
final implementation SHA
direct GitHub log URL.
