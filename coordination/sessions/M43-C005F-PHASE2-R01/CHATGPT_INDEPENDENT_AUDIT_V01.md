# M43-C005F-PHASE2-R01 — Earned Pack Production Wiring — INDEPENDENT STRICT AUDIT V01

Date: 2026-10-08
Repository: `Sekiph82/Scrubbots`
Authorized base: `861d6a8a7d4a572ae7a35a9b65a55677a8e071b5`
Implementation/log commit: `26b4a2d5fdb70b93337705a30f5914054291f5a1`
Prompt: `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_EARNED_PACK_RUNTIME_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M43-C005F-PHASE2-R01/M43_C005F_PHASE2_R01_CLAUDE_LOG_V01.md`

## VERDICT

**CHANGES REQUIRED / R02**

The production wiring is real and the original owner-reported defect is substantially fixed, but one durability blocker remains in the acknowledgement path.

Do not mark `SB-M43-C005F-005` CLOSED yet.

## What passes

### 1. Shipping route exists

PASS.

Independent source review confirms the old silent-draw path is removed:

- `EconomyServices._register_handlers()` now enqueues `standard_card_packs` / `premium_card_packs` into `PendingPackQueue`.
- `CardPackService.open_standard()/open_premium()` are no longer called by reward handlers.
- `PackCommitTransaction` remains the canonical draw/receipt authority.
- one production `PackPresenter` is created from `main.gd`.
- it uses the real ModalStack and accepted Standard/Premium ceremony classes.
- it binds the canonical FeedbackAdapter.
- Gift/Daily/facade commits and verified rewarded grants request earned-pack draining.
- gameplay / Results do not get interrupted.

This fixes the core owner-observed problem: earned pack rewards now have a production route to the pack-opening screen rather than being silently written straight into Collection.

### 2. Queue/save schema

PASS.

`PendingPackQueue` is durable, FIFO and strict:
- exact versioned snapshot;
- unique non-empty earned ids;
- supported kind validation;
- old save with absent section -> empty migration;
- malformed present section fails import.

### 3. Draw-once / replay

PASS.

`AppState.open_earned_pack()` routes the pending entry through the existing `PackCommitTransaction`.

The existing transaction provides:
- one canonical RNG/pity/Collection path;
- Standard 3 / Premium 5;
- durable PackReceiptLedger receipt before model return;
- save-failure rollback for the PACK COMMIT itself;
- replay by same tx id without another draw.

### 4. Runtime / modal integration

PASS.

The new PackPresenter is app-level, FIFO and presentation-only.

The ModalStack z-band change is justified by the real stacked-popup composition and remains narrow: each popup receives a depth-relative z band while its internal relative order remains unchanged.

### 5. Scope isolation

PASS.

Compare `861d6a8a..26b4a2d5` is one implementation/log commit. No `TASKS.md`, Remote Content/R2, LF/VOID, gameplay authority, Results feel source, FeedbackAdapter or accepted pack ceremony source changed.

### 6. Builder evidence

Accepted as supporting evidence:
- R01 focused suite 19/19;
- 44 requested regression suites PASS;
- root 5329/5329 PASS;
- headless import/boot clean;
- git diff --check clean;
- real app Gift 10 and Gift 1000 capture sequence committed.

The focused suite covers commit-save rollback, restart before open, restart after pack commit, FIFO, Reduced, plugin failure, duplicate claims and gameplay gating.

## BLOCKER — acknowledgement is not durable-atomic

FAIL.

Current `AppState.acknowledge_earned_pack(id)` does:

1. verify receipt exists;
2. `pending_packs.remove(id)`;
3. return `{"ok": true, "save": request_save()}`.

If `request_save()` fails, the pending entry has already been removed from live economy state and is **not restored**.

Worse, `PackPresenter._on_completed()` only checks the outer `r["ok"]`, so a result shaped like:

`{ok:true, save:{ok:false,...}}`

is treated as a successful acknowledgement.

Then `_on_closed(reason == "complete")` emits `pack_finished` and the app is allowed to advance its presentation sequence.

This violates the explicit R01 contract:

- “A queue entry may be acknowledged/removed only after its shipping ceremony completes successfully, followed by durable save.”
- restart/durability must not depend on a later unrelated save;
- the next pending pack must not advance when acknowledgement of the current pack was not durably persisted.

The existing q05 rollback test covers **save failure during PackCommitTransaction/open**, not **save failure during acknowledge/remove**. Therefore the permanent suite does not currently detect this defect.

## Required R02

R02 must make acknowledgement transactional:

- capture the exact pre-ack economy state;
- remove the queue entry;
- attempt canonical save;
- if save succeeds: acknowledge succeeds;
- if save fails: restore the exact pre-ack economy state and return `ok:false`;
- receipt/cards/RNG/pity remain exactly as already committed;
- the same pending entry remains at the same FIFO position;
- PackPresenter must not report `pack_finished` / advance to the next pack unless durable acknowledgement succeeded.

Use SaveService's existing `set_fault_injector()` for deterministic acknowledgement-save failure tests.

Mandatory new tests:
1. committed pack -> ceremony complete -> inject `temp_write` failure -> queue entry restored, receipt unchanged, Collection unchanged, next pending pack not advanced;
2. clear fault -> retry same committed receipt -> zero redraw -> acknowledgement save succeeds -> entry removed exactly once;
3. multi-pack FIFO -> first ack failure never opens/acks second;
4. app restart after failed ack sees the same receipt/pending pack;
5. all existing R01 + pack/economy/save/modal/feel/root regressions remain PASS.

## Non-blocking observation

The builder correctly reported a separate pre-existing UI copy issue:
`REWARD_guaranteed_new_fallback_sb x500` is shown raw in the Gift 1000 row.

That is not the reason for this audit failure and should be tracked separately from R02.

## FINAL

**M43-C005F-PHASE2-R01 = CHANGES REQUIRED / R02.**

The original shipping wiring is accepted in principle, but F005 cannot close until durable acknowledgement is fixed and re-audited.
