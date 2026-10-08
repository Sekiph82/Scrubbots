# M43-C005F-PHASE2-R02 — Durable Pack Acknowledgement — CLAUDE REMEDIATION PROMPT V01

Repository: `Sekiph82/Scrubbots`
Owner-local: `C:/Users/sekip/Desktop/ScrubBots`
Engine: Godot 4.7.2
Date: 2026-10-08

## Scope

Target only the one blocker from:
`coordination/sessions/M43-C005F-PHASE2-R01/CHATGPT_INDEPENDENT_AUDIT_V01.md`

R01 implementation `26b4a2d5` is otherwise retained.

Do not redesign the queue/presenter/reward architecture.

## Defect

Current `AppState.acknowledge_earned_pack(id)` removes the pending queue entry before `request_save()`, and returns outer `ok:true` even when that save fails.

`PackPresenter` then treats the acknowledgement as successful and may emit `pack_finished` / continue.

This violates durable acknowledgement.

## Required fix

### A. Atomic acknowledgement

Make `acknowledge_earned_pack(id)` transactional.

Required behavior:

1. reject blocked / no committed receipt / no pending entry as today;
2. capture the exact pre-ack economy snapshot;
3. remove the pending entry;
4. call the canonical save boundary;
5. if save succeeds:
   - return `ok:true`;
   - pending entry stays removed.
6. if save fails:
   - restore the exact pre-ack economy snapshot;
   - verify/return whether restore succeeded;
   - return `ok:false` with a specific durable-ack/save-failure reason;
   - same pending id/kind must be back at the same FIFO position;
   - committed receipt remains identical;
   - Collection/RNG/pity remain identical to the already committed pack.

Do not redraw the pack during rollback/retry.

Use the existing EconomyServices snapshot/import transaction style rather than inventing a second state authority.

### B. Presenter completion semantics

`PackPresenter` must only emit successful completion/advance when durable acknowledgement returned `ok:true`.

If ack fails:
- record a truthful error;
- do not report `pack_finished`;
- do not advance to the next pending pack;
- never delete/alter the committed receipt;
- the same pack must remain recoverable/replayable.

It is acceptable for a later safe drain/restart to present the same committed receipt again. It must never reroll.

Avoid an uncontrolled immediate reopen loop under persistent disk/save failure. If current modal/home callbacks would cause such a loop, add the smallest presentation-local transient guard needed. Do not persist a new authority flag.

### C. Deterministic fault tests

Use `SaveService.set_fault_injector()`.

Add focused tests for:

1. pending Standard pack committed;
2. inject ack save failure at `temp_write`;
3. complete the shipping ceremony;
4. assert:
   - acknowledgement is failure;
   - queue entry is restored at front;
   - receipt bytes/model unchanged;
   - Collection counts unchanged;
   - RNG/pity unchanged;
   - second pending pack does not start;
   - no successful `pack_finished` signal for the failed ack.
5. clear fault;
6. drain/reopen the same id;
7. assert `replay=true`, zero new draw / zero pity advance;
8. complete again;
9. durable ack succeeds, queue removes exactly once;
10. FIFO then advances.

Also cover restart after failed acknowledgement:
- load from last good save;
- same committed receipt + pending entry is present;
- same cards reopen;
- no reroll.

### D. Preserve R01

Must remain unchanged:
- silent-draw path stays removed;
- pending queue schema;
- Gift/Daily/Rewarded production triggers;
- Standard/Premium 3/5 truth;
- Premium guarantee;
- pity;
- F005 feel;
- Results F003/F004 owner-accepted behavior;
- ModalStack z fix;
- no R2/LF/VOID changes;
- no TASKS.md edit.

## Required regression

At minimum:
- updated R01 focused suite;
- pack C006/C007/C008/C009;
- Phase1 + Phase2 feel;
- R15;
- M39 relevant;
- M40 save suites;
- M41;
- M55;
- popup/modal;
- Gift/Daily/Home;
- root tests/run_tests.gd;
- headless import/boot;
- git diff --check.

## Log

Write:
`coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_CLAUDE_LOG_V01.md`

End:
`AWAITING_GPT_M43_C005F_PHASE2_R02_REAUDIT`
