# M24-C001 V01 — ChatGPT Strict Audit

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Auditor: ChatGPT
Implementation SHA: `789c207133ff6134fe6158cb3c468daf30ff1344`
Evidence log commit: `10ba7f01399c25dbc257267dfce1ed07abc8e809`
Verdict: **CHANGES_REQUIRED**

## Executive result

M24 V01 is well-scoped and implements the intended Five-Slot Batch Engine architecture: exactly five initially EMPTY slots, rightmost-empty automatic placement, M23 transactional front selection, independent same-color batch identities, counter accounting, WAITING/ACTIVE lifecycle, completion/freeing, detached queries, pause/reset, BLUE 8/14/12 evidence, five-full rejection/refill, and preservation of M23/M22/M21/M20 production systems.

The implementation cannot close M24 yet because the transaction/re-entrancy boundary is incomplete. `select_front_batch()` protects only nested calls to itself with `_busy`; other public M24 mutators, especially `reset()`, can still execute synchronously while the engine is inside the external M23 collaborator call. `reset()` additionally writes `_busy = false`, which can reopen the placement transaction before the outer call has finished. This violates the explicit master criteria §13 transaction serialization requirement and can break rightmost-empty/atomicity truth.

A second evidence gap remains: the master criteria explicitly require a failed/stale M23 commit path to be driven directly and prove exact M24 prestate preservation. V01 tests cover full rejection, null/foreign supply, exhausted supply, and nested `select_front_batch`, but do not directly drive the `supply_commit_failed` branch.

M25 must not start until V02 closes these boundaries.

## Verified PASS areas

- Start SHA `79e3754e4146b9805a03e7070a4787ab84307ea0` -> implementation SHA is exactly one focused implementation commit.
- Implementation diff is narrow: two new M24 production scripts plus M24 tests/evidence only; root `TASKS.md` is absent.
- Historical `slot_system.gd` / `slot_state.gd` remain unchanged.
- No M25 target arbitration, M26 dispatch/routing/spawn, or M27 solvability/deadlock implementation was introduced.
- Exactly five M24 slots are fixed and initially EMPTY.
- Rightmost-empty ordinary placement works and occupied slots do not compact.
- Full-five rejection occurs before ordinary M23 interaction and preserves ordinary M23/M24 state.
- Same-color batches remain distinct; canonical `BLUE 8`, `BLUE 14`, `BLUE 12` evidence is present.
- Counter invariant `0 <= committed <= remaining_to_clear <= initial_count` and capacity calculation are implemented on the normal path.
- Opaque live-work accounting rejects duplicate/unknown/double identities on the tested normal path.
- Completion returns only the completed slot to EMPTY; neighbors remain in place.
- WAITING/ACTIVE ordinary transitions preserve counters.
- Detached snapshots, pause/resume ordinary behavior, reset ordinary behavior, and pre-reset work-id invalidation are directly exercised.
- Five-full -> reject -> complete -> refill evidence is present.
- Reported root suite is `5072` checks / `0` failures and historical M23/M22/M21/M20 evidence is green.

## F-M24-V01-STRICT-001 — Incomplete cross-engine mutation serialization

**Severity: BLOCKING**

`FiveSlotBatchEngine.select_front_batch()` sets `_busy = true` before entering the M23 collaborator and rejects a nested `select_front_batch()` call. However the rest of the public mutation surface does not honor that transaction guard:

- `commit_work()` can mutate counters/ledger while `_busy`;
- `resolve_clear()` can mutate counters, free a slot and delete ledger entries while `_busy`;
- `rollback_work()` can mutate counters/ledger while `_busy`;
- `set_claimable_work_available()` can mutate lifecycle while `_busy`;
- `pause()` / `resume()` can mutate pause state while `_busy`;
- most critically, `reset()` can replace all slots, clear work, reset sequence, and explicitly set `_busy = false` while the outer placement transaction is still executing.

The M24 master criteria §13 require any nested placement/commit/reset occurring during another placement to fail closed or be deterministically deferred. V01 protects only nested placement.

### Concrete failure class

A real `BatchSupplyEngine` subclass/test seam can synchronously call back into M24 from `begin_front_selection()`:

1. M24 computes `target = rightmost_empty_index()` and sets `_busy = true`.
2. M24 calls external `supply.begin_front_selection(column)`.
3. The supply callback calls `m24.reset()`.
4. Current `reset()` empties all slots, clears work/sequence and sets `_busy = false` while the outer placement remains on the stack.
5. The callback may now even re-enter `select_front_batch()` because the lock was reopened.
6. The outer call resumes with its stale pre-reset `target` and may continue toward M23 commit/placement.

Even without a second nested placement, after reset the original precomputed target may no longer be the rightmost EMPTY slot. The reset request also did not leave the engine in its promised reset state once the outer placement resumes. This is exactly the split-brain/state-drift class §13 was written to prevent.

A similar stale-target problem can be produced if a synchronous callback resolves/completes another slot while the outer placement is waiting inside M23, changing the set of empty slots after `target` was computed.

### Required correction

Make M24 mutation serialization global, not limited to nested `select_front_batch()`.

Acceptable designs include:

- a single transaction/mutation guard honored by every public state-mutating method; nested mutations fail closed without changing state; or
- a generation/deferred-operation design that proves the outer placement cannot consume M23 supply and then apply stale M24 state.

For reset specifically, do **not** clear the active transaction guard from inside a nested reset call. A reset requested during placement must either fail closed with explicit evidence or be deferred/serialized in a way that cannot leave M23 consumed while M24 is reset/empty.

Direct adversarial tests must invoke reset and at least one accounting/lifecycle mutation synchronously from the M23 callback while placement is in progress and prove:

- nested mutation does not change slots/counters/sequence/work ledger;
- nested reset does not reopen `_busy`;
- a nested `select_front_batch()` after the reset attempt is still rejected;
- outer placement either completes from an unchanged prestate or aborts cleanly according to the chosen policy;
- rightmost-empty truth is not stale;
- no M23/M24 split-brain or extra supply advance occurs.

## F-M24-V01-STRICT-002 — Missing direct failed/stale M23 commit evidence

**Severity: REQUIRED EVIDENCE GAP**

Master criteria §12 explicitly require:

> failed M23 commit or stale supply transaction leaves M24 exact-prestate.

V01 production has a `supply_commit_failed` branch, but the supplied adversarial double only re-enters `select_front_batch()` during `begin_front_selection()` and then returns null. The dedicated handoff evidence likewise covers ordinary accepted placement, exhausted/full/foreign supply and nested select, but it does not force M23 `commit(tx)` to return false after a valid begin.

### Required correction

Add a narrow adversarial M23 seam/test double that:

1. returns a valid authentic M23 transaction from `begin_front_selection()`;
2. makes the corresponding M23 commit fail (for example by deterministically making the transaction stale without mutating M24, or by a narrowly controlled test seam);
3. proves `select_front_batch()` returns `supply_commit_failed`;
4. proves the entire M24 state is byte/logically identical to its pre-call state: all five slots, counters, lifecycle, placement sequence and live-work ledger;
5. proves no ghost slot/batch was inserted and no second M24 mutation occurred.

If the chosen stale-transaction construction legitimately changes M23 because another M23 consumer advanced that column, report that separately; the required M24 proof is exact prestate preservation and no false placement.

## Non-blocking observation — SlotBatchState state mutator

`SlotBatchState.set_state(new_state)` accepts an arbitrary String and performs no lifecycle validation. Because the FiveSlotBatchEngine does not expose its owned SlotBatchState instances, this does not currently provide an ordinary API path to corrupt engine-owned state. V02 should nevertheless prefer narrowing this seam (for example an internal-style validated transition method) while touching lifecycle serialization, or add direct proof that engine-owned states can only be `EMPTY|ACTIVE|WAITING`. Do not turn this observation into an M25 policy rewrite.

## V02 scope

V02 is a narrow transaction-hardening/evidence cycle. Preserve all V01 behavior that already passes.

Required V02 themes:

1. global M24 mutation serialization while an M23 placement transaction is active;
2. reset-during-placement safety, with no guard reopening;
3. accounting/lifecycle mutation-during-placement safety;
4. direct M23 commit-failure/stale-transaction evidence;
5. preserve all 30-task ordinary-path evidence and full historical regressions;
6. no M25/M26/M27 implementation.

## Closure state

- `SB-M24-001..SB-M24-030`: **remain open pending V02 strict closure**.
- M24-C001 V01: **CHANGES_REQUIRED**.
- Next cycle: **M24-C001 V02**.
- M25: **must not start**.
