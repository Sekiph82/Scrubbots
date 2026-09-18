# M29-C001 V01 — MASTER STRICT AUDIT CRITERIA

Milestone: `M29 — Mobile Touch / Production Input Integration`
Tasks: `SB-M29-001..009`
All sections are blocking.

## A. Governance
- root TASKS unchanged by Claude;
- M30+ not implemented;
- no image generation;
- implementation commit(s) precede separate log commit;
- accepted M23–M28 authority boundaries preserved.

## B. Production input authority
Only supply row 0/front can activate production placement.

Direct proof:
- front row activates correct column;
- preview row 2 cannot activate;
- preview row 3 cannot activate;
- exhausted column cannot activate;
- five batch slots are still not Buttons/destination controls;
- controller accepts only authoritative M23 column count 3/4/5.

## C. Exact transaction
One activation calls real M24 transactional placement against real M23.

Success:
- exactly one originating column advances;
- exact front batch enters M24 rightmost EMPTY slot;
- other columns unchanged;
- snapshots refresh;
- M26 wake notified.

Failure/full slots:
- zero supply consumption;
- zero slot mutation;
- no scheduler wake/spawn caused by the rejected selection;
- no automatic 2x caused by rejection.

## D. Mouse/touch deduplication
Prove one physical touch plus any synthesized mouse event yields at most one placement.

Desktop mouse must independently work.

## E. Cancel/focus
- touch down then cancel => zero activation;
- touch down then focus loss => zero activation;
- stale release after focus return => zero activation;
- no stuck visual/pressed state.

## F. Rapid tap / reentry
Adversarial rapid repeated activation while one transaction is active:
- no double commit;
- no duplicate batch skip;
- no M24 overfill;
- no corrupted transaction token;
- UI refresh remains consistent.

## G. Multi-touch
Simultaneous touches on one or multiple columns must preserve all invariants.
It is acceptable to serialize/reject secondary concurrent touches; it is not acceptable to consume a front twice or partially mutate columns.

## H. Pause/background
User pause and system suspension are distinct reasons.

While either pause reason is active:
- no new activation;
- no scheduler cadence;
- in-flight agents do not advance.

Resume:
- no stale tap;
- no duplicate scheduler work;
- previous 1x/2x preserved;
- system return does not override explicit user pause.

## I. Automatic production cadence
- M26 `step()` is driven automatically;
- one cadence event invokes at most one scheduler step;
- no production `run_until_idle()` burst;
- scheduler WAITING/wake behavior remains intact;
- placement wakes scheduler.

## J. 1x / 2x manual speed
- new session starts 1x;
- bottom-right button toggles 1x -> 2x -> 1x;
- visual state follows authority;
- 2x cadence interval is exactly half 1x;
- future agents use 2x travel speed;
- already-moving agents update to 2x immediately;
- returning to 1x updates current/future agents consistently.

No blind global Engine.time_scale.

## K. Automatic M23-exhausted -> 2x
Direct evidence must distinguish:
1. visible three rows empty while hidden supply exists => NO auto-2x;
2. all five slots full and attempted final selection rejected => NO auto-2x;
3. successful final front transfer leaves every authoritative M23 column empty => auto-2x;
4. already 2x => idempotent;
5. after auto-2x, manual toggle back to 1x works;
6. full reset/new session => 1x.

Trigger must read real `BatchSupplyEngine.is_exhausted()` after successful M24 placement.

## L. Gameplay truth invariant under speed
Replay equivalent deterministic fixture at 1x and 2x and prove:
- same cleared targets/order where deterministic authority requires it;
- same quota totals;
- same supply consumption;
- same final board;
- speed changes temporal duration only.

## M. Manual Hazard Bot playtest
A committed debug/manual scene must instantiate the real production path:
- M28 GameplayScreen;
- real Hazard Bot LevelData/BoardState;
- real M23 supply;
- real M24/M25/M26;
- real routing/ReservationState/dispatcher/agents;
- real M20 authenticated clear;
- real input/runtime controller.

It must be runnable in graphical Godot with desktop mouse.

Log must contain exact manual steps.

## N. Regression floor
At minimum:
- full root suite;
- dedicated M29 input tests;
- dedicated speed/auto-2x tests;
- dedicated graphical/headless-compatible runtime smoke as applicable;
- M28 viewport smoke;
- M27 Hazard/59/generation;
- M26 Hazard/scale;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 Railroad/connector;
- M20 lifecycle;
- M19 dispatcher;
- M18 agent;
- `git diff --check`.

## O. Closure
PASS only when the owner can run the documented M29 Hazard Bot playtest scene and use real mouse/touch supply-front input through the production engine chain, with functional 1x/2x and automatic M23-exhausted -> 2x behavior.
