# SB-M52-C001-R02 — DISPATCH-EXHAUSTED SLOT RELEASE

Status: READY FOR CLAUDE
Date: 2026-09-27
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/sessions/M52-C001/remediation/R01/OWNER_REPLAY_RESULT_V01.md`
4. `coordination/OWNER_SLOT_RELEASE_ON_DISPATCH_EXHAUSTION_V01.md`
5. `coordination/OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01.md`
6. M24/M25/M26/M27/M30 code + tests
7. M39 Tornado / Retry / booster transaction code
8. R01 implementation and audit evidence

Do NOT edit root `TASKS.md`.

## Mission

Fix the final owner gameplay blocker:

**When a batch's last waiting Scrubby has successfully dispatched and its launch/display count reaches 0, immediately free the physical slot. Do not wait for the final in-flight Scrubby to clean its pixel.**

The freed physical slot must be immediately reusable even while the retired batch still has live claims/agents.

Do not implement this as a UI-only hide.

## A. Required architecture

Refactor M24 minimally but correctly so physical slot occupancy is separated from in-flight batch accounting.

Introduce a batch-identity-based draining/retired accounting path for a batch whose launch capacity is exhausted but whose work is still in flight.

A safe production sequence is:

1. M25 claim -> M24 `commit_work`.
2. route validates.
3. real agent dispatch succeeds.
4. M26 confirms that exact work identity as departed.
5. if that batch now has `remaining - committed == 0` and every live committed unit for that batch is departure-established:
   - detach batch accounting from the physical slot;
   - retain it in a draining ledger keyed by immutable batch_id;
   - set the physical slot EMPTY immediately.
6. UI/state sync shows EMPTY in that same runtime transition.
7. later authenticated arrivals resolve against the draining batch identity.
8. when draining remaining=0 and committed=0, remove the draining record.

Do not free at raw `commit_work()` time before route/spawn success.

## B. Exact anti-cross-talk acceptance fixture

Mandatory test:

- Physical Slot N holds Batch A x1.
- Dispatch A's only Scrubby successfully.
- BEFORE A clears:
  - Slot N is EMPTY;
  - A still has one live assignment/claim/reservation/work;
  - board ACTIVE count unchanged.
- Immediately place Batch B into the same physical Slot N.
- Confirm B has its own batch id/color/counters.
- Let A arrive and clear.
- Assert:
  - A finalizes only A;
  - B remaining/committed/display/state are unchanged;
  - B remains in Slot N;
  - no claim/reservation/work identity aliases B.

Repeat with a multi-agent draining Batch A, not only x1.

## C. M24 identity rules

Update `_live_work` so an exact work identity resolves by immutable batch identity even after the physical slot is reused.

`is_work_bound_to` and M25 preflights must accept the exact original live batch whether:
- still physically occupying its slot; or
- present in the draining ledger.

They must reject a replacement batch occupying the old physical slot.

Never infer batch ownership from slot index alone after retirement.

## D. Rollback / reset / Tornado

Audit every caller of:
- `rollback_work`
- M25 `rollback_claim`
- M25 reset
- M26 reset/retry
- Tornado selected-color cancellation / restoration
- any booster action touching occupied slots or live assignments

Required:
- Retry tears down active + draining batches with zero ghosts.
- Tornado remains atomic with draining same-color agents.
- transactional undo can restore exact retired work identities without touching a replacement physical batch.
- no stranded schedulable capacity may be created in a draining batch.
- +1 Slot still returns to five on Retry.

Add focused tests.

## E. Scheduler integration

After `dispatch_preclaimed` succeeds and BEFORE publishing final UI state, confirm departure in M24.

If that confirmation triggers retirement:
- clear any obsolete per-slot WAITING marker for the retired batch;
- pending wave lanes referring to the retired batch must not accidentally act on the new replacement batch;
- wave generation/batch-id checks must prevent stale lane reuse.

A slot refilled during later input may participate only in a future cadence wave, not retroactively in the old wave.

## F. UI

When retirement happens:
- slot snapshot must report EMPTY;
- the slot view must become EMPTY on the same runtime/state-sync cycle;
- the player must not see `0 ACTIVE/WAITING` sitting there while old agents travel.

## G. Completion / solver

Update comments/tests/documentation that currently say a batch/slot becomes EMPTY only at `remaining==0 && committed==0`.

Completion still waits for all live work/agents and board clear.

Review M27 quiescent proof assumptions. If no kernel behavioral change is needed, document why early runtime reuse is conservatively represented and cannot produce a false admission.

Re-run Levels 1–10 proof/replay/runtime.

## H. Focused tests

Create `tests/m52_r02_early_slot_release.gd` or equivalent covering at minimum:

- x1 batch: last successful departure -> slot EMPTY before clear;
- UI shows EMPTY before clear;
- immediate replacement batch in same physical slot;
- old arrival cannot mutate replacement batch;
- old clear cannot free replacement slot;
- multiple old in-flight agents resolve safely after reuse;
- five slots can each retire/reuse while older agents remain in flight;
- same-color old/new batch identities remain independent;
- pending old wave lane cannot dispatch from replacement batch;
- rollback before successful spawn does NOT release slot;
- Retry with draining batches = clean reset;
- Tornado with draining selected-color batches = coherent/atomic;
- pause/focus with draining agents;
- transaction cardinalities remain equal;
- no early WON;
- +1 Slot behavior remains correct;
- R01 five-BLUE parallel rule still passes;
- 2x rule still passes;
- Levels 2–10 owner plans still production-WON;
- Level 1 unchanged;
- frontier 11 CONTENT_MISSING.

## I. Regression

Run:
- new R02 suite;
- R01 focused suite;
- M23–M42 relevant suites;
- M52 owner-plan suite;
- root `tests/run_tests.gd`;
- `git diff --check`.

No new SCRIPT ERROR or unexplained engine errors.

## J. Deliverables

Commit + push to main.

Write:
`coordination/sessions/M52-C001/remediation/R02/CLAUDE_LOG_V01.md`

Include:
- before/after slot lifecycle evidence;
- anti-cross-talk reuse evidence;
- draining ledger architecture;
- rollback/Retry/Tornado evidence;
- solver consistency note;
- First 10 results;
- regression totals;
- final SHA/status.

Finish with:

`AWAITING_CHATGPT_AUDIT / M52-C001-R02 EARLY SLOT RELEASE`

Do not edit TASKS.md.
