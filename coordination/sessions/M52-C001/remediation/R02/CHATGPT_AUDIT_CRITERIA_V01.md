# SB-M52-C001-R02 — CHATGPT AUDIT CRITERIA

## Verdict rule

PASS only if the physical slot truly becomes reusable when launch count reaches zero after successful dispatch, while the old batch remains safely accountable in flight.

## 1. Real authority release

No UI-only hide.

After final successful departure:
- physical slot is M24 EMPTY;
- `rightmost_empty_index()` may return it;
- a new supply batch can legally occupy it before old agents clear.

## 2. Safe release point

Slot must not retire merely on `commit_work`.

Pre-spawn route/dispatch failure + rollback must leave the original slot/batch intact.

Retirement occurs only after real dispatch/agent establishment is proven.

## 3. Anti-cross-talk

Mandatory:
- Batch A retires;
- Batch B reuses same physical slot;
- A later clear/finalization changes only A draining accounting;
- B counters/state/batch id remain untouched;
- A completion cannot free B's physical slot.

Failure = CHANGES_REQUIRED.

## 4. Draining identity

Live work/claim binding is based on immutable batch identity.

Old physical slot index may be provenance but may not be used as proof that the old batch still occupies the slot.

Exact preflight must distinguish:
- original draining Batch A;
- replacement physical Batch B.

## 5. Transaction law

Across in-flight active + draining batches:

scheduler assignments == dispatcher agents == M25 claims == reservations == M24 live work.

No ghost or orphan identities.

## 6. Rollback / Retry / Tornado

Focused evidence must prove:
- Retry clears active + draining work transaction-safely;
- Tornado selected-color flow handles draining agents without mutating replacement batches;
- reversible rollback/reattach preserves exact identities;
- no stranded launch capacity appears in draining state.

## 7. UI

After final departure but before final target clear:
- slot view = EMPTY;
- no lingering zero-count occupied tile.

## 8. Completion

No early WON from empty physical slots.

WON still requires:
- board cleared;
- all assignments/agents/claims/reservations/live-work drained.

## 9. Wave safety

If a batch retires during a frame-budgeted wave and the physical slot is later refilled, stale queued lane data from the old wave cannot schedule the replacement batch.

Replacement may participate only in a later valid wave.

## 10. Regression

R02 focused suite PASS.
R01 focused suite PASS.
First 10 production runtime PASS.
Relevant historical regression PASS.
Root suite PASS.
No new SCRIPT ERROR/unexplained engine errors.
Diff clean.

## Verdicts

PASS:
`AUDITED_PASS / M52-C001-R02 / OWNER SPOT-CHECK REQUIRED`

Otherwise:
`CHANGES_REQUIRED / M52-C001-R02`
