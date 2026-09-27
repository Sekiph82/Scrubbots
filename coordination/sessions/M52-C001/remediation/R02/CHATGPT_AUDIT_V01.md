# M52-C001-R02 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-09-27
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited HEAD: `9485472e6cba3a7c7b59fe496d97bcb2263bd37c`
Implementation commit: `59336f1c93bfac4021ff5d007625379193e04f4d`

## Verdict

**AUDITED_PASS / M52-C001-R02 / OWNER SPOT-CHECK REQUIRED**

R02 passes the code/evidence/regression gate.

The only remaining M52 owner gate is a short interactive confirmation that:
1. a slot visually becomes EMPTY as soon as its last waiting Scrubby has successfully departed;
2. the newly empty physical slot can be reused immediately while the old Scrubby is still travelling;
3. the old Scrubby's later clear does not disturb the replacement batch.

No full Levels 2–10 replay is required again because the owner already passed R01 across the pack and R02 re-ran the full First 10 production runtime/regression evidence.

## 1. Authoritative physical-slot release — PASS

This is not a UI-only hide.

M24 `FiveSlotBatchEngine` now separates:
- physical `_slots`;
- immutable live-work identities;
- `_draining[batch_id]` accounting for batches whose launch capacity is exhausted but whose dispatched work is still in flight.

`confirm_departed(work_id)` is called only after M26 has successfully created the exact real dispatcher agent.

A physical batch retires only when:
- its launch capacity is zero;
- it has committed work;
- all live work identities for that batch have confirmed departure;
- the exact batch still occupies the physical slot.

The same `SlotBatchState` accounting object is moved to the draining ledger and the physical slot is replaced with EMPTY.

Therefore `rightmost_empty_index()` sees real reusable capacity immediately.

## 2. Safe release point — PASS

R02 does not free a slot at raw M25 `commit_work`.

Production order remains:

M25 exact-slot claim/reservation + M24 commit
→ route validation
→ `dispatch_preclaimed`
→ real ScrubbotAgent exists
→ M24 `confirm_departed`
→ optional physical-slot retirement.

If route/spawn fails, M25 rolls the claim back and the original physical batch remains in its slot.

The focused R02 suite explicitly tests the capacity-zero pre-spawn condition and proves the slot remains occupied until a real dispatch exists.

## 3. Immutable batch ownership / anti-cross-talk — PASS

`_live_work` records:
- provenance slot;
- immutable batch_id;
- departed flag.

After retirement, `_owner_state(rec)` resolves work to:
1. the physical slot only if that slot still contains the exact same batch_id; otherwise
2. the draining ledger entry with the exact batch_id.

A replacement batch in the same physical slot therefore cannot satisfy the old work identity.

Mandatory acceptance fixture passes:

- Batch A x1 dispatches and retires.
- Before A clears, the physical slot is EMPTY and A still owns one assignment/agent/claim/reservation/work.
- Batch B immediately enters the same physical slot.
- A later clears/finalizes against A's draining accounting only.
- B snapshot/counters/state/batch id remain unchanged.
- A completion does not free B's slot.

The multi-agent x3 version and five-slots-at-once version also pass.

## 4. Player-visible zero-tile timing — PASS IN AUTOMATION

The production state-sync path observes the M24 retirement in the same runtime tick.

Focused UI evidence proves:
- final Scrubby is in flight;
- board ACTIVE is still unchanged;
- physical M24 slot is EMPTY;
- `BatchSlotView` already renders EMPTY.

No stale visible `0 ACTIVE/WAITING` tile remains during the old agent's travel interval.

Owner interactive confirmation remains the final visual-feel gate.

## 5. Stale-wave safety — PASS

R01's production waves are frame-budgeted and lane entries are now pinned as:
`{slot, batch_id}`.

If an old batch retires and the physical slot is reused before a previously queued lane is serviced, `step_lane()` re-proves:
- slot occupied;
- exact same pinned batch_id;
- positive capacity;
- non-WAITING state.

A replacement batch cannot consume the old lane.

New placement wakes only its own newly placed lane through `queue_lane(slot)`; it does not retroactively join an already-fixed cadence wave.

## 6. Completion / no early WON — PASS

M30 quiescence now additionally requires:
`draining_count() == 0`.

Thus all visible physical slots may be EMPTY while dispatched Scrubbys are still travelling, but completion remains PLAYING until:
- scheduler assignments;
- dispatcher agents;
- M25 claims;
- reservations;
- M24 live work;
- draining batches

have all drained, and the board is fully cleared.

R02 tests explicitly prove no early WON.

## 7. Retry / reset — PASS

Retry with:
- a draining old batch;
- replacement physical batches;
- live assignments/agents/claims

returns to:
- zero assignments;
- zero agents;
- zero claims;
- zero reservations;
- zero live work;
- zero draining entries;
- five empty baseline slots;
- full reset board.

No ghost identities remain.

## 8. Tornado transactional integrity — PASS

Tornado now explicitly includes draining batches of the selected color.

Transaction order is coherent:
- selected-color live assignments are detached/rolled back first;
- selected-color physical slots are purged;
- selected-color draining records are purged;
- board/supply/finalize stages continue;
- rollback restores draining records before exact claims are reattached.

Focused tests inject faults at multiple Tornado stages and compare the exact pre-state:
- physical slots;
- draining ledger;
- five transaction cardinalities;
- board.

All tested fault paths restore exactly; committed Tornado leaves unrelated colors untouched.

## 9. R01 parallel dispatch / 2x / performance — PASS

R02 preserves the accepted R01 behavior:
- five same-color x30 physical lanes still produce the parallel-lane behavior;
- batches are not retired while waiting capacity remains;
- 2x purchase/toggle behavior remains intact;
- +1 Slot still supports six lanes and Retry restores five.

R02 additionally corrects placement waking: a newly placed batch queues only its own prompt lane rather than forcing every slot into an immediate extra wave.

This prevents frequent early slot reuse from bypassing the intended 1x/2x cadence for unrelated existing slots.

Level 2 headless evidence after R02:
- terminal WON at 1x and 2x;
- worst measured frame ~18.6 ms;
- 0 frames >33 ms;
- 1x simulated completion ~283 s;
- 2x simulated completion ~152.85 s.

The performance evidence is headless desktop evidence; owner already accepted the R01 stutter feel interactively.

## 10. Historical harness changes — ACCEPTED / NOT A PRODUCTION BYPASS

R02 changes the game rule: a physical slot may be reused while its previous batch still drains.

The old Hazard Bot m29 and m33 harnesses immediately filled every newly-empty slot using a fixed order that had only been proven under completion-time slot reuse.

Under R02 that exact greedy timing can legitimately fill all five slots with batches whose target colors are still enclosed, and M27 correctly proves LOST.

The updated harnesses wait for draining work to quiesce before applying their historical fixed order.

This does not hide a First-10 production failure because:
- R02 explicitly permits immediate player reuse and the focused suite tests it directly;
- M27 correctly classifies unsafe greedy choices as genuine deadlocks rather than false engine failures;
- the owner has already manually played Levels 2–10 successfully under the new runtime;
- `tests/m52_owner_supply_plans.gd` still executes all nine production plans to WON;
- R02's anti-cross-talk/stale-lane tests exercise the new immediate-reuse behavior directly.

Therefore the harness updates are accepted as adaptation to the new gameplay rule, not a workaround masking slot lifecycle corruption.

## 11. Solver / proof consistency — PASS WITH DOCUMENTED SCOPE

ProofKernel remains a quiescent decision model and does not model mid-travel player placement.

At its decision boundaries, wave clears are applied before the next placement, so its slot state matches a conservative runtime state.

Early runtime slot release adds optional earlier player choices; it does not fabricate a solver action that runtime cannot perform.

The project also retains the stronger production admission requirement that the owner plan must execute through the real production runtime.

Levels 2–10 re-solve/replay with the same R01 trace hashes and the production owner-plan runtime reaches WON 9/9.

## 12. First 10 / regression — PASS

Committed final-state evidence records:

- R02 focused suite: 65 checks, PASS.
- R01 focused suite: 79 checks, PASS.
- M52 owner supply-plan suite: 255 checks, PASS; 9/9 production runtimes WON.
- Full M23–M52 sweep: 76 suites, all exit 0, no FAIL, no SCRIPT ERROR.
- Root suite: 5323 checks, ALL PASS.
- Known engine ERROR output: same 9 lines/hash as baseline.
- Level 1 unchanged.
- Production catalog/order 1–10 unchanged.
- Frontier 11 remains CONTENT_MISSING.
- `project.godot` incidental headless rewrite was restored and not committed.
- Root `TASKS.md` was not changed by Claude implementation.

## 13. Owner spot-check

Use:
`coordination/sessions/M52-C001/remediation/R02/OWNER_SPOT_CHECK_V01.md`.

If the owner reports PASS:
1. ChatGPT records final M52-C001 owner acceptance;
2. closes SB-M52-C001-O01/O02/O03 and SB-M52-R01-017 / SB-M52-R02-016;
3. updates root `TASKS.md`;
4. advances the locked First 10 block to M53 per-level QA.

If the slot still visually lingers at zero or cannot be reused before the old Scrubby clears, R02 returns to remediation.
