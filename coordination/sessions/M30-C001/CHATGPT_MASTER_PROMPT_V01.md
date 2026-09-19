# M30-C001 V01 - MASTER IMPLEMENTATION PROMPT

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: `M30 - Win/Lose Rules`
Execution mode: **ONE CONTINUOUS FULL-MILESTONE PASS**
Tasks: `SB-M30-001..008`

Read first:

1. `coordination/OWNER_WIN_LOSE_RETRY_DECISION_V01.md`
2. `coordination/sessions/M29-C001/CHATGPT_AUDIT_V03.md`
3. `coordination/OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01.md`
4. `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
5. accepted M23-M29 final audits
6. `coordination/sessions/M30-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
7. all linked M30 work packages
8. root `TASKS.md` as read-only tracker truth

## Objective

Add the first authoritative terminal gameplay loop to the accepted M29 production stack:

`PLAYING -> WON or LOST -> Retry -> fresh PLAYING attempt`

M30 must make Win/Lose/Retry mechanically real and owner-testable without inventing final branded result-screen art or Economy rewards.

## Owner-locked WIN

WON may latch only when:

- BoardState ACTIVE pixel count is zero;
- M26 live assignment count is zero;
- dispatcher live Scrubbot count is zero;
- M25 live claim count is zero;
- ReservationState reservation count is zero;
- M24 live committed-work count is zero;
- no pending authenticated-clear transaction remains.

Do not fire early on the last robot's departure from a slot. WIN occurs only after the final authenticated clear and cross-engine finalization have settled.

## Owner-locked LOSE

LOSE may latch only when:

1. gameplay is quiescent with no live in-flight progress transaction; and
2. the accepted M27 `DeadlockClassifier` returns exactly `DEADLOCK`.

Never lose on:
- WAITING;
- STALLED;
- PROGRESSABLE;
- UNKNOWN_BOUND;
- supply fullness alone;
- slot fullness alone;
- temporary no-target state;
- a live in-flight Scrubbot.

Cross-engine inconsistency/fatal bookkeeping is not a normal LOSE. Fail closed and surface a diagnostic state/error.

## Completion architecture

Create a narrow gameplay-domain completion authority, preferably split into:

- a read-only `CompletionEvaluator` that determines current nonterminal/terminal truth from accepted engine state;
- a production `CompletionController` that owns attempt terminal state, dirty/event-driven evaluation, exact-once terminal latch and one terminal signal.

Recommended terminal states:
- `PLAYING`
- `WON`
- `LOST`

Do not put win/lose policy in UI widgets.

Do not replace M27 deadlock semantics.

## Evaluation cadence

Do not run M27 solver/deadlock proof blindly every render frame.

Use dirty/event-driven evaluation after meaningful state changes such as:

- successful M23 -> M24 placement;
- authenticated clear/finalization;
- scheduler quiescence/no-assignment boundary;
- relevant wake/state change;
- supply exhaustion.

Cheap WIN checks may run more frequently.

M27 classification should only be invoked when no existing live in-flight transaction already guarantees possible progress.

## Exact-once terminal latch

Once WON or LOST is latched:

- emit exactly one terminal result event for the attempt;
- block new supply-front activations;
- stop new M26 scheduler assignments;
- do not emit another terminal result;
- do not mutate terminal result until Retry begins a new attempt.

Terminal blocking must be a distinct state, not disguised as user pause.

No legitimate in-flight robot may be discarded merely to make a result screen appear. The owner rules already require terminal evaluation at quiescence.

## Production input/runtime integration

Add narrow terminal gating to the accepted M29 controllers.

Input:
- `ProductionInputController` must reject new front activations after terminal latch with a deterministic terminal error;
- no M23 consumption and no M24 mutation on such rejection.

Runtime:
- terminal latch stops scheduler cadence;
- because terminal state is quiescent, no normal in-flight travel should remain;
- terminal stop is separate from user pause and system suspension;
- Retry clears terminal stop and resumes a fresh attempt at 1x.

Preserve all M29 mouse/touch, focus, pause and speed semantics.

## Transaction-safe Retry

Harden the provisional M29 `ProductionGameplayHost.reset_session()` before it becomes a real Retry path.

Critical rule:

- the accepted M26 scheduler teardown/reset is the first destructive gameplay teardown gate;
- if `scheduler.reset()` fails, is deferred, or remains pending, Retry fails closed;
- on such failure, do NOT reset M23, M24, BoardState, speed or terminal result as if Retry succeeded.

On successful teardown, restore one coherent fresh attempt:

- same level;
- same generation seed;
- same M23 column count;
- same preview depth;
- exact same initial M23 batch IDs/colors/counts/order;
- BoardState restored to all source cells ACTIVE;
- ColorCandidateIndex rebuilt against the restored board;
- five authoritative slots EMPTY;
- zero committed work;
- zero M25 claims;
- zero reservations;
- zero scheduler assignments;
- zero live ScrubbotAgents;
- renderer refreshed to original full artwork;
- supply UI restored to original front/preview state;
- five-slot UI EMPTY;
- speed authority = 1x;
- speed UI = 1x;
- user/system pause cleared;
- terminal state = PLAYING;
- input unblocked.

A successful retry must not generate a different puzzle candidate.

Compare initial M23 full/debug snapshot before the first move with the full/debug snapshot after Retry. They must be equivalent.

If an in-place reset is used, add the minimum safe BoardState/reset/rebuild seams required. If rebuilding the coherent production bundle is safer, that is acceptable, but stale pre-retry callbacks must be unable to mutate the new attempt.

## Retry failure injection

Add direct evidence for the M29 V03 hardening note:

Force the M26 reset gate to fail/defer and prove:

- Retry returns failure;
- supply does not reset;
- M24 slots do not reset;
- board does not reset;
- terminal result does not pretend a new attempt started;
- no half-old/half-new state appears.

Do not weaken M26 to make this test easier.

## M27 integration

Use the real `DeadlockClassifier` and real runtime state.

The evaluator must distinguish at least:

- COMPLETED / valid quiescent completion -> WON;
- PROGRESSABLE -> PLAYING;
- STALLED -> PLAYING;
- UNKNOWN_BOUND -> PLAYING / unresolved, never LOST;
- DEADLOCK at quiescence -> LOST.

Do not duplicate solver logic inside M30.

## Owner-testable M30 scene

Extend the real production Hazard Bot playtest path or add a dedicated M30 debug/manual scene that uses:

- real M28 screen;
- real M23-M29 production stack;
- real M30 completion authority;
- same deterministic Hazard Bot supply.

A minimal native/debug result display is acceptable.

Owner must be able to verify:

1. complete the known solved sequence and see WON exactly once;
2. trigger a proven deadlock fixture/path and see LOST exactly once;
3. press Retry and see the same board and same initial supply sequence restored;
4. Retry starts at 1x;
5. no new placement is accepted after WON/LOST before Retry.

Do not implement final branded results art.

## Economy boundary

M30 must NOT:
- award Scrub Bucks;
- consume Hearts;
- update Win Streak;
- grant Bot Parts;
- implement ads/IAP;
- implement M39 economy entitlements.

Expose stable terminal truth/events only. Later systems consume them.

## Work packages

Execute continuously without approval stops:

1. `M30_WORK_PACKAGE_01_COMPLETION_AUTHORITY_AND_TERMINAL_LATCH.md`
2. `M30_WORK_PACKAGE_02_PRODUCTION_WIN_LOSE_INTEGRATION.md`
3. `M30_WORK_PACKAGE_03_TRANSACTION_SAFE_RETRY.md`
4. `M30_WORK_PACKAGE_04_MANUAL_PLAYTEST_AND_CLOSURE.md`

## Scope prohibitions

- root `TASKS.md` is read-only for Claude;
- no M31 effects;
- no final result-screen art;
- no Economy rewards;
- no new solver;
- no rewrite of M23-M29 accepted authority;
- zero AI image generation.

## Handoff

Push implementation commit(s) first.

Then create:

`coordination/sessions/M30-C001/CLAUDE_LOG_V01.md`

as a separate final commit.

The log must map every `SB-M30-001..008` requirement to code/tests/manual evidence.

Return only:

`AWAITING_AUDIT`

final implementation SHA

direct GitHub `CLAUDE_LOG_V01.md` URL
