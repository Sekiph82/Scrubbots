# M43-C005F-PHASE2-R02 — Durable Pack Acknowledgement — INDEPENDENT STRICT RE-AUDIT V01

Date: 2026-10-08
Repository: `Sekiph82/Scrubbots`
Authorized base: `25a5094d5435c1d903bc1b3f43515d7f57162cf9`
Implementation/log commit: `9f0fdf50`
Prompt: `coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_REMEDIATION_PROMPT_V01.md`
Criteria: `coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_AUDIT_CRITERIA_V01.md`
Builder log: `coordination/sessions/M43-C005F-PHASE2-R02/M43_C005F_PHASE2_R02_CLAUDE_LOG_V01.md`

## VERDICT

**PASS / AWAITING OWNER RUNTIME ACCEPTANCE**

No further technical remediation is required for R02.

`SB-M43-C005F-005` is technically accepted, but remains open until the owner confirms the real game now shows the Standard/Premium pack-opening flow correctly.

## 1. Scope / governance

PASS.

Independent compare `25a5094d..9f0fdf50` contains exactly one commit and five changed files:

- `scripts/app/app_state.gd`
- `scripts/app/main.gd`
- `scripts/ui/ceremony/pack_presenter.gd`
- `tests/m43_c005f_phase2_r01_earned_pack_runtime.gd`
- R02 builder log

No TASKS, Remote Content/R2, LF/VOID, GameFeelFlow/Spark adapter, pack ceremony source, Results source, reward handlers, PendingPackQueue, CardPackService, PackCommitTransaction or economy configuration changed.

## 2. Transactional acknowledgement

PASS.

Current `AppState.acknowledge_earned_pack(id)` now:

1. rejects blocked / uncommitted / non-pending ids;
2. captures exact `economy.snapshot()`;
3. removes the pending queue entry;
4. executes the canonical `request_save()`;
5. returns `ok:true` only on successful durable save;
6. on save failure, re-imports the exact pre-ack economy snapshot and returns outer `ok:false`, reason `ack_save_failed`, the save result and `restored`.

This closes the R01 blocker.

The restored snapshot includes:
- PendingPackQueue order;
- PackReceiptLedger;
- Collection;
- pack RNG;
- pity;
- wallet and the rest of EconomyServices.

No redraw occurs during rollback.

## 3. Presenter completion semantics

PASS.

`PackPresenter` now records the durable ack result and:

- emits `pack_finished` only when acknowledgement returned `ok:true`;
- emits `pack_ack_failed` on ack failure;
- does not advance FIFO after failed ack;
- guards the failed front id in presentation-local memory to prevent an immediate reopen loop;
- leaves the durable queue/receipt authoritative;
- permits later retry after a future Home re-entry or restart.

The guard is not persisted and does not become a new authority.

A replay after guard release/restart uses the already committed receipt, so cards/RNG/pity do not change.

## 4. Fault-injection coverage

PASS.

The focused suite was expanded from 19 to **22/22 PASS**, with three direct R02 cases using `SaveService.set_fault_injector(... temp_write ...)`.

### h01
Direct AppState acknowledgement failure:
- outer `ok:false`;
- `ack_save_failed`;
- `restored:true`;
- same pending id at FIFO front;
- full economy snapshot identical after rollback;
- retry returns `replay:true`;
- later ack removes exactly once.

### h02
Real app + two queued packs:
- failed ack emits `pack_ack_failed`;
- emits no `pack_finished`;
- pack 2 does not start;
- pack 1 does not immediately reopen;
- guard holds FIFO;
- after fault clear + guard release, same pack 1 reopens as replay;
- no draw/pity change;
- successful ack then advances to pack 2.

### h03
Restart after failed acknowledgement:
- last good save retains pending entry + committed receipt;
- same five Premium cards reopen;
- `replay:true`;
- no reroll;
- successful completion acknowledges durably.

These cases directly cover the blocker from the R01 independent audit.

## 5. R01 production path remains intact

PASS.

R02 does not alter:
- earned-pack enqueue semantics;
- Gift / Daily / Rewarded triggers;
- queue schema;
- pack commit authority;
- Standard 3 / Premium 5 truth;
- Premium Rare+ guarantee;
- pity;
- F005 feel binding;
- F003/F004 Results owner-approved behavior;
- ModalStack z-band fix.

The R01 q*/g* production scenarios remain in the same 22-case suite and pass.

## 6. Regression evidence

Builder evidence reports:

- R01+R02 focused: **22/22 PASS**
- Phase 1 feel: 23/23 PASS
- Phase 2 feel: 22/22 PASS
- legacy C005F: 10/10 PASS
- Results suites: PASS
- pack commit/card state/Premium/owner-review suites: PASS
- M39 relevant: PASS
- M40 save suites: PASS
- M41: PASS
- Home/navigation/modal/acquisition/Need-a-Hand/terminal/R15/M55: PASS
- root `tests/run_tests.gd`: ALL PASS
- headless import/boot: exit 0
- `git diff --check`: clean

### Non-blocking test-flake finding

`m43_c005_c006_standard_pack_presentation` v07 failed once during the loaded full-battery run, then passed **3/3 consecutive reruns**.

Independent source inspection confirms:
- R02 does not modify `standard_pack_ceremony.gd` or this test;
- v07 is a frame-sampled presentation assertion that requires observing each card while `0 < route < 1`;
- its failure mode can therefore be sensitive to frame scheduling under heavy concurrent/system load;
- the deterministic routing assertions and all pack transaction/runtime tests pass.

This is recorded as existing test-hygiene debt, not an R02 product blocker. It must not be misreported as “the first battery was literally zero-failure”.

## 7. Owner gate

**OPEN.**

The owner must now verify the actual shipping build, not a harness:

1. claim a Standard card-pack reward;
2. confirm the Standard pack screen appears automatically;
3. open/reveal the 3 cards;
4. confirm completion returns to the previous Home popup and Collection contains those cards;
5. claim a Premium reward and verify the 5-card ceremony likewise appears.

F005 can be marked fully CLOSED after this owner runtime acceptance.

## 8. Separate observations

Two unrelated items remain outside this R02 verdict:

- Gift 1000 currently exposes raw copy `REWARD_guaranteed_new_fallback_sb x500`; localization/copy cleanup should be handled separately.
- C006 v07 mid-route frame sampling is flaky under load and should eventually be hardened as test hygiene, without changing the accepted pack behavior.

## FINAL

**M43-C005F-PHASE2-R02 = PASS / AWAITING OWNER RUNTIME ACCEPTANCE.**

No R03 remediation is issued.
