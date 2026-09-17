# M25 Work Package 04 — BLUE Opening and Race Evidence

Covers primarily: `SB-M25-028..030` plus direct duplicate-color arbitration evidence.

## Objective

Prove the owner-requested duplicate-color behavior with the canonical three-blue fixture and dynamic target opening.

## Fixture construction

Use the real accepted M23 -> M24 path to place three distinct same-color batches:

- `BLUE 8`
- `BLUE 14`
- `BLUE 12`

Record exact slot indexes and placement sequences. Do not inject occupied slot internals directly.

## A. Oldest-batch-first claims

With multiple currently targetable blue pixels:

- repeated claim requests must choose `BLUE 8` while it has M24 dispatch capacity;
- every accepted claim must reserve a distinct target;
- ReservationState count, M25 live-claim count and BLUE 8 committed count must agree;
- BLUE 14 and BLUE 12 remain uncommitted while BLUE 8 still has capacity.

Then exhaust BLUE 8's dispatch capacity with live claims without clearing them. Additional blue claims must spill to BLUE 14, never BLUE 12 first.

Do not decrement remaining merely to create these claims.

## B. Rapid / competing requests

Exercise rapid sequential/re-entrant/simultaneous-style claim attempts under main-thread synchronous semantics.

Prove:

- no two claims receive the same target;
- no duplicate ReservationState owner/target pair;
- no claim is recorded without matching M24 committed work;
- deterministic result for identical replay/call order.

## C. No pre-ownership of inaccessible target

Create a board state where a blue target exists but is production-unreachable/blocked.

Before opening:

- claim attempt returns no claim;
- target is unreserved;
- M25 ledger does not contain target;
- no M24 committed increment occurs;
- oldest relevant blue batch becomes/remains WAITING.

Then perform an authoritative BoardState clear/opening that changes production reachability under accepted routing semantics.

After opening/reconsideration:

- the target becomes production-targetable;
- it is claimed only now;
- it goes to the oldest same-color batch that still has capacity;
- batch resumes ACTIVE;
- no newer blue batch steals it.

Use the accepted Railroad V1 + post-rail orthogonal-turn targetability where suitable; do not invent a simplified accessibility model.

## D. TargetSelector order

On a fixture with several targetable blue candidates, prove the claimed target is exactly the existing TargetSelector bottom-most then left-most winner. M25 must not alter target priority while performing batch arbitration.

## Evidence outputs

Add one or more dedicated headless evidence scripts with readable traces:

- placement sequence;
- claim ID;
- reservation owner ID;
- batch/slot;
- target index/coord;
- pre-opening no-claim state;
- post-opening exact owner batch.
