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

## 2. Manual speed control and entitlement gate

The bottom-right gameplay control is the speed control.

The gameplay-speed authority still supports exactly:

`1x <-> 2x`

However, **production manual activation of 2x is no longer always free**. It is gated by the owner-locked Economy & Rewards V1 decision:

`coordination/OWNER_ECONOMY_REWARDS_V01.md`

A production manual 2x request is allowed only when at least one of these is true:

- the current progression level has a paid current-level 2x entitlement (200 SB);
- a paid timed 2x entitlement is currently unexpired (15m/300 SB, 30m/500 SB, 60m/750 SB);
- the runtime is entering the free authoritative M23-supply-exhausted endgame 2x path.

The control must visibly reflect current speed state and, when manual 2x is not entitled, route the request to the economy/entitlement purchase flow rather than silently enabling 2x.

Until the M39 economy services exist, M29 may keep a direct toggle seam for headless/debug verification of temporal behavior, but a shipping production UI must not expose free manual 2x.

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

Automatic activation does not permanently lock 2x. The player may always return to 1x afterward. Returning from that free automatic 2x to 2x manually again before/after the automatic condition is no longer free unless a valid paid entitlement exists; the automatic M23-exhausted trigger itself may reassert free 2x only according to the authoritative runtime rule.

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

A new level/session and a full gameplay reset restore the temporal state to `1x`.

A current-level paid entitlement is tied to its level ID and survives retries/restarts of that same level until successful completion. Timed entitlements are wall-clock expiry timestamps and continue counting in menus, pause, background and while the app is closed.

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


## 9. Economy V1 supersession note

On 2026-09-18, `coordination/OWNER_ECONOMY_REWARDS_V01.md` superseded the earlier assumption that the bottom-right manual 1x/2x toggle is always free.

The speed authority remains responsible only for temporal factor. Payment, entitlement ownership and expiry belong to the economy/speed-entitlement layer. Automatic M23-supply-exhausted 2x remains free.
