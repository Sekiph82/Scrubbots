# OWNER GAMEPLAY SPEED RULE V01

Date: 2026-09-18
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: Production gameplay speed behavior

## 1. Supported gameplay speeds

Production gameplay V1 supports exactly:

- `1x` normal speed
- `2x` accelerated speed

No 3x or higher speed is part of this rule.

A new level/session starts at `1x`.

## 2. Manual speed control

The bottom-right gameplay control is the speed control.

It toggles:

`1x <-> 2x`

The control must visibly reflect the current speed state.

This is a gameplay-time control, not Settings.

## 3. Automatic 2x endgame acceleration

The game automatically switches to `2x` immediately after the FINAL remaining M23 supply batch has been successfully transferred into M24 through the normal transactional handoff.

Canonical trigger:

- every M23 FIFO supply column has zero remaining batches;
- this includes all formerly hidden future batches, not merely the three visible preview rows;
- the final front-selection transaction has been accepted and committed downstream;
- therefore no further player supply selection remains.

This condition is called **M23 supply exhausted**.

The trigger is NOT:
- all five M24 slots occupied at the same time;
- the three visible preview rows merely appearing empty while hidden batches remain;
- a click/request that later fails because M24 cannot accept the batch.

If the final transfer is rejected, M23 is not exhausted and automatic 2x must not activate.

If gameplay is already at 2x, the automatic trigger is an idempotent no-op.

Automatic activation does not permanently lock 2x. The player may use the speed control to return to 1x afterward.

## 4. What 2x means

2x changes temporal playback/execution speed only. It must not change gameplay truth or decision policy.

The implementation must preserve exactly:
- M23 FIFO/front-only order;
- M24 rightmost-empty placement and quota accounting;
- M25 same-color arbitration / claims / reservations;
- TargetSelector ordering;
- routing geometry and chosen route;
- M26 no-ghost transaction law;
- authenticated clear semantics;
- M27 solvability/deadlock meaning.

2x may accelerate time-based production behavior such as:
- M26 dispatch cadence;
- ScrubbotAgent travel;
- cleaning/arrival/disappearance animation timing;
- later gameplay visual effects whose timing is explicitly tied to gameplay speed.

2x must not create a one-frame uncontrolled batch burst, skip reservations, double-clear pixels, alter quota totals, or reorder deterministic target decisions.

UI navigation clocks, monetization timers and unrelated application timing must not implicitly become 2x merely because gameplay is accelerated. Prefer an explicit gameplay-speed authority over a blind global time-scale change.

## 5. Pause

Pause overrides gameplay speed. While paused, no new time-based gameplay progress occurs.

After resume, the previous gameplay speed (1x or 2x) is restored.

## 6. Reset / new level

A new level/session and a full gameplay reset restore speed to `1x`.

Stale callbacks from a previous 2x session must not change a newly reset session.

## 7. Presentation / milestone ownership

M28 owns:
- bottom-right speed-control placement;
- responsive sizing;
- safe-area containment;
- visual 1x/2x state presentation.

M28 does not need to activate gameplay timing.

M29 is the first production input milestone and must wire the manual speed-control interaction.

The automatic `M23 supply exhausted -> 2x` transition must be integrated with the production gameplay controller/runtime when speed behavior is activated; it must consume authoritative M23 exhaustion state rather than infer exhaustion from UI visuals.

## 8. Precedence

This decision extends and supersedes the previously-deferred functional semantics in:

`coordination/OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01.md`

It also supersedes any older gameplay-screen wording that treats the bottom-right control as Settings.
