# OWNER SLOT RELEASE ON DISPATCH EXHAUSTION V01

Date: 2026-09-27
Authority: OWNER
Status: OWNER-LOCKED
Repository: Sekiph82/Scrubbots

## 1. Player-facing rule

A physical execution slot represents **Scrubbys still waiting to leave that slot**, not Scrubbys already travelling toward reserved pixels.

Therefore, when a batch has no more Scrubbys waiting to launch:

`displayed / launch capacity = remaining_to_clear - committed = 0`

and every committed unit has successfully established a real dispatched agent, the physical slot must immediately become **EMPTY**.

It must NOT remain visually or functionally occupied until the last in-flight Scrubby clears its target.

## 2. Immediate reuse

The physical slot released by this rule is immediately eligible for the next normal supply placement.

Example:

1. Batch A occupies physical Slot 4.
2. Batch A's final waiting Scrubby successfully dispatches.
3. Batch A visible count reaches 0.
4. Slot 4 becomes EMPTY in the same authoritative runtime transition.
5. The player may place Batch B into Slot 4 while Batch A still has one or more Scrubbys travelling.
6. Batch A arrivals must finalize Batch A only and must never mutate Batch B.

This exact reuse-before-arrival scenario is mandatory test coverage.

## 3. Do not fake this in UI

Hiding a zero tile is insufficient.

The gameplay authority itself must release the physical slot so:
- `rightmost_empty_index()` sees it as empty;
- new supply selection may legally use it;
- occupied/full checks reflect the new availability.

## 4. Batch accounting must outlive physical slot occupancy

An already-dispatched batch may continue to own:
- M25 claims;
- ReservationState entries;
- M24 committed work identities;
- M26 assignments;
- dispatcher agents;
- remaining authenticated clears

after its physical slot has been released/reused.

Therefore M24 must separate:
- **physical slot occupancy / launch capacity**, from
- **retired/draining batch accounting for in-flight work**.

A live work identity is bound to the immutable batch identity, not to whichever batch later occupies that physical slot.

## 5. Safe release point

Do NOT release merely when `commit_work()` makes capacity zero, because claim/route/spawn can still fail and roll back.

Release is authorized only after the final zero-capacity work unit has successfully established its real production dispatch/agent.

Recommended seam:
- M24 commit establishes committed accounting;
- M26 successfully dispatches the preclaimed agent;
- M26/M24 then confirm that work as departed;
- if the batch now has zero launch capacity and all committed work is departure-established, detach the batch from the physical slot into a draining-batch ledger and mark the physical slot EMPTY.

The transition must be atomic/fail-closed.

## 6. Draining batch invariants

A draining batch:
- retains immutable batch_id/color/initial count/accounting;
- is not visible as an occupied physical slot;
- cannot receive new normal dispatches;
- may continue to resolve its existing exact work identities;
- is removed from the draining ledger only when all its in-flight work is finalized and its remaining-to-clear reaches zero;
- must never collide with a new batch using the same physical slot.

Physical slot index may remain as provenance only. It is no longer proof of live batch ownership after detachment.

## 7. Resolve / rollback

`resolve_clear(work_id)` must locate the exact batch identity even if that batch is draining and its old physical slot now contains another batch.

A stale/old work arrival must never:
- decrement the replacement batch;
- empty the replacement batch;
- change its displayed count;
- change its lifecycle.

Rollback/reset/Tornado paths must also remain transaction-safe with draining batches.

If a post-dispatch rollback temporarily restores launch capacity inside a draining batch, that capacity must not silently become schedulable through a replacement physical batch. The owning transaction must either restore the exact draining state, purge it, or reset it atomically.

## 8. Completion / cardinality

Existing no-ghost transaction law remains:

scheduler assignments == dispatcher agents == M25 claims == reservations == M24 live work.

Physical occupied-slot count is no longer required to equal the number of batches with in-flight work.

WON still requires:
- board fully cleared;
- all in-flight transaction authorities quiescent.

Freeing the final visible slot early must never cause an early WON.

## 9. Solver / proof

The proof model may remain quiescent/conservative if it still soundly proves accepted content.

However, any documentation claiming that physical slot occupancy persists until authenticated clear must be updated.

Runtime tests must prove that early physical reuse cannot create:
- false SOLVED;
- false LOST;
- cross-batch clear accounting;
- duplicated capacity.

## 10. UI timing

The same runtime/state sync that observes the final successful departure must render the physical slot EMPTY without waiting for that Scrubby's target clear.

A one-frame internal bookkeeping transition is acceptable only if the player does not see a stale zero-count occupied tile lingering through the in-flight travel interval.

## 11. Protected rules

Unchanged:
- front-only FIFO supply;
- rightmost-empty placement;
- 5 baseline / 6 boosted physical slots;
- parallel per-slot dispatch;
- unique reservation/target identity;
- authenticated clear;
- remaining-to-clear decrements only on successful clear;
- visible count before release = remaining - committed;
- 1x/2x behavior;
- Level 1–10 owner supply plans.
