# M39-C001 V02 — ChatGPT Full-Surface Re-Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M39-C001 V02 / FINDING_SET_FROZEN**

Implementation: `657c5d9` (+ cleanup `f98ee80`)
Claude log: `coordination/sessions/M39-C001/CLAUDE_LOG_V02.md`

This is a strict-v2 whole-sprint re-audit. Claude's 5336/0 result is E1/E2 implementation evidence, not independent closure.

## Pass A — implementation/state sweep

### F-M39-V02-001 — sixth slot is not actually integrated through presentation/routing origin
`FiveSlotBatchEngine` can grow to six, but:
- `FiveSlotStrip.SLOT_COUNT := 5`;
- it builds exactly five views;
- `bind_snapshots()` truncates/pads to five;
- `SlotOriginProvider.SLOT_COUNT := 5` and rejects slot index 5.

Therefore the sixth authoritative slot cannot render as the sixth slot and a robot dispatched from slot 5 cannot obtain a valid production origin. SB-M39-031/033 are not closed.

### F-M39-V02-002 — M27 solver kernel is still five-slot
`ProofState` carries `capacity`, but `ProofKernel` still:
- reconstructs slots with `range(ProofState.SLOT_COUNT)`;
- reads back with the same fixed five loop;
- computes origins using `ProofState.SLOT_COUNT`;
- constructs a baseline five-slot engine without growing it to state.capacity.

So a six-slot ProofState key may differ while actual solver transitions ignore slot 6. SB-M39-032 is not closed.

### F-M39-V02-003 — Random does not prove the owner-required three consecutive safe selections
`propose_random_reorder()` reverses the remaining supply and calls one current-state `_is_safe()` classifier check. It does not simulate/prove >=3 consecutive legal accepted front choices. This fails SB-M39-035.

### F-M39-V02-004 — Selector eligibility is checked before extraction/placement
`eligible_safe_batches()` calls `_selector_reorder_solvable()`, which only checks a reordered supply with unchanged slots. It does not prove the state after the selected batch is actually extracted and placed into the rightmost EMPTY slot. SB-M39-036/037 remain unsafe.

### F-M39-V02-005 — transaction rollback excludes the failing stage
`BoosterService._run_transaction()` appends a stage only after its `apply()` returns true. If a stage mutates partially and then returns false, that stage's own rollback is never called.

Concrete examples:
- Tornado slot stage may free earlier same-color idle slots, then encounter a non-idle same-color slot and return false. Those freed slots are not restored by the transaction runner.
- Selector stage can load reordered supply, then fail the actual M24 placement; the failing stage rollback is not invoked.

This violates SB-M39-037/040.

### F-M39-V02-006 — Tornado invented a quiescence-only rule that conflicts with owner law
Owner lock requires Tornado to reconcile/cancel the selected color's committed/in-flight assignments, claims, reservations and agents atomically.

V02 instead requires `_inflight()==0` and refuses all active-work Tornado calls. That is a product-rule change, not an implementation of SB-M39-039. No owner decision authorized this restriction.

### F-M39-V02-007 — restart-after-real-gameplay Heart/streak law is not wired
`WinStreakService.on_gameplay_started()` is never called by `ProductionGameplayHost`.
The accepted player activation callback only notifies completion.

On successful Retry, host calls `streak.on_restart()`, but because gameplay-start was never armed, the streak does not reset. Retry also never calls `hearts.consume()`.

Owner law requires restart after real gameplay to consume one Heart and reset Win Streak; pre-action restart consumes neither. SB-M39-020 and runtime wiring are not closed.

### F-M39-V02-008 — +1 Slot cross-engine transaction has an admitted unrefunded failure path
Host first commits the economy/capacity authority, then calls `_slots.grow_to_sixth()`.
If the engine grow fails, the code comments that no refund is exposed and simply returns false.

A "should not happen" synchronous assumption is not atomicity. V03 must make the economy authority + engine capacity one transactional commit/rollback boundary.

### F-M39-V02-009 — Daily uses UTC-style unix-day arithmetic, not local calendar day, and omits required rollback timestamps
`_today() = int(unix_seconds / 86400)` is not the owner-required local calendar date key.

The owner lock also requires at minimum:
- last claimed local-date key;
- claim timestamp;
- highest-seen trusted/system timestamp.

Current snapshot has none of the latter two. SB-M39-041/044 remain incomplete.

### F-M39-V02-010 — Collection import accepts internally inconsistent claimed completion state
`CollectionInventory.import_snapshot()` validates ranges/types, but accepts:
- a claimed set whose 9 cards are not owned;
- `master_claimed=true` while fewer than 15 sets are complete.

This violates V02 criterion 9's explicit inconsistent claimed-set/master-state requirement and weakens SB-M39-045/047C.

## Pass B — evidence/test/policy sweep
Key false-positive risks found:
- `m39_v02_capacity.gd` proves capacity field/key distinction, but never drives the real ProofKernel at six slots.
- `m39_v02_integration.gd` tests Tornado only on a fresh quiescent host, so it cannot expose the owner-required in-flight reconciliation gap.
- Tornado fault injection occurs before each stage's mutation; it does not inject failure *after partial mutation inside a stage*, so the failing-stage rollback defect stays invisible.
- Random/Selector integration tests do not observe the required three-step/post-placement solver property.
- no V02 test drives Restart after a real gameplay action and checks both Heart + streak exact postconditions.
- no V02 UI/layout test can show a sixth slot because the production strip itself is still fixed at five.
- Daily tests advance whole 86400-second periods and therefore cannot distinguish local-midnight semantics from UTC-day semantics.

## Sprint coverage ledger

| Task | Status | Audit note |
|---|---|---|
| SB-M39-001 | **DEFECT/GAP** | F-M39-V02-011 EconomyConfig validation incomplete |
| SB-M39-002 | **DEFECT/GAP** | F-M39-V02-013 wallet accepts arbitrary removed-currency resource IDs |
| SB-M39-003 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-004 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-005 | **DEFECT/GAP** | F-M39-V02-014 first-clear reward precedes progression acceptance |
| SB-M39-006 | **DEFECT/GAP** | F-M39-V02-014 Bot Part first-clear reward shares wrong transaction ordering |
| SB-M39-007 | **DEFECT/GAP** | F-M39-V02-012 RewardGrant applied-tx import noncanonical |
| SB-M39-008 | **DEFECT/GAP** | F-M39-V02-012 Gift Meter import/queue noncanonical |
| SB-M39-009 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-010 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-011 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-012 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-013 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-014 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-015 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-016 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-017 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-018 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-019 | **DEFECT/GAP** | F-M39-V02-016 Heart anchor domain noncanonical |
| SB-M39-020 | **DEFECT/GAP** | F-M39-V02-007 restart-after-gameplay Heart/streak law not wired |
| SB-M39-021 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-022 | **DEFECT/GAP** | F-M39-V02-016 2x entitlement sentinel domain noncanonical |
| SB-M39-023 | **DEFECT/GAP** | F-M39-V02-016 current-level entitlement state domain requires hardening |
| SB-M39-024 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-025 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-026 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-027 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-028 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-029 | **DEFECT/GAP** | F-M39-V02-012 unknown fifth booster snapshot key ignored |
| SB-M39-030 | **DEFECT/GAP** | F-M39-V02-008 +1 Slot economy/engine commit not atomic |
| SB-M39-031 | **DEFECT/GAP** | F-M39-V02-001 sixth slot not integrated through presentation/origin |
| SB-M39-032 | **DEFECT/GAP** | F-M39-V02-002 ProofKernel still fixed-five |
| SB-M39-033 | **DEFECT/GAP** | F-M39-V02-001 production sixth-slot presentation absent; device gate follows code fix |
| SB-M39-034 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-035 | **DEFECT/GAP** | F-M39-V02-003 no 3-consecutive safe-selection proof |
| SB-M39-036 | **DEFECT/GAP** | F-M39-V02-004 selector safety checked before actual placement |
| SB-M39-037 | **DEFECT/GAP** | F-M39-V02-004/005 selector partial failure rollback unsafe |
| SB-M39-038 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-039 | **DEFECT/GAP** | F-M39-V02-006 Tornado owner in-flight law replaced by quiescence-only rule |
| SB-M39-040 | **DEFECT/GAP** | F-M39-V02-005 failing-stage rollback missing |
| SB-M39-041 | **DEFECT/GAP** | F-M39-V02-009/015 local-day/task-day semantics incomplete |
| SB-M39-042 | **DEFECT/GAP** | F-M39-V02-015 login state mutates before unchecked reward grant |
| SB-M39-043 | **DEFECT/GAP** | F-M39-V02-015 prior-day task completion can leak into next-day claim |
| SB-M39-044 | **DEFECT/GAP** | F-M39-V02-009/015 required local date + timestamps/rollback state absent |
| SB-M39-045 | **DEFECT/GAP** | F-M39-V02-010 collection claimed-state coherence missing |
| SB-M39-046 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-047 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-047A | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-047B | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-047C | **DEFECT/GAP** | F-M39-V02-010 persisted completion-grant state not coherency-validated |
| SB-M39-048 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-049 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-050 | PROVEN / no new material gap | V01/V02 source + direct evidence reviewed; rerun regression if touched by V03 dependencies. |
| SB-M39-051 | **DEFECT/GAP** | F-M39-V02-013 removed currency can exist through wallet runtime API |
| SB-M39-052 | **DEFECT/GAP** | full matrix misses frozen findings |

## Interaction sweep
The findings interact:
- fixed-five ProofKernel invalidates Random/Selector safety claims whenever capacity=6;
- fixed-five presentation/origin means a sixth-slot batch can exist in canonical M24 truth while M26 routing cannot originate it;
- failing-stage rollback makes both Selector and Tornado partial-mutation paths unsafe;
- quiescence-only Tornado avoids the very active-work transaction the owner specifically required;
- missing gameplay-start wiring means Retry economics are wrong even if terminal WON/LOST economics are correct.

### F-M39-V02-011 — EconomyConfig is not actually fail-closed on malformed/out-of-range owner tuning
`EconomyConfig._load()` validates only schema_version by `int()`, required section presence, and removed_systems array shape.

It does not validate the owner-locked values/types/ranges inside currency, first-clear, streak, Gift Meter, Hearts, 2x, boosters, Daily, Collection or exchange tables. Fractional/string/negative values can be silently coerced later by typed accessors.

Even `schema_version: 2.9` can satisfy `int(schema_version) == 2`.

This violates SB-M39-001.

### F-M39-V02-012 — canonical economy snapshot import remains permissive in Reward/Gift/Booster state
Sibling sweep found:
- `RewardGrantService.import_snapshot()` string-coerces arbitrary applied transaction entries and does not reject duplicate/non-string/empty IDs;
- `GiftMeterService.import_snapshot()` accepts arbitrary queue element shapes, arbitrary applied IDs and inconsistent total/cycle/queue truth. A malformed queue element can later reach `occ.get(...)` in claim/read paths;
- `BoosterInventory.import_snapshot()` reads the four known keys but silently ignores an injected fifth/unknown booster key.

These violate exact canonical save/import requirements and the "exactly four boosters" law.

### F-M39-V02-013 — removed currencies can still be created through EconomyWallet runtime API
`EconomyWallet.credit/debit/get_balance` accept arbitrary resource strings.
A production caller can therefore create runtime balances such as `"stars"` even though snapshots omit them.

SB-M39-051 requires Stars/Event Points/profile-XP economic state to not exist in production runtime/save APIs. Wallet mutation must reject unknown resource IDs.

### F-M39-V02-014 — first-clear economy is applied before progression authority accepts the win
On WON, `ProductionGameplayHost._drive_economy_terminal()` currently performs:
1. first-clear grant;
2. streak grant;
3. `progression.record_win()`.

The return value from progression is ignored.

After M37 V03 correctly rejects stale/future non-frontier wins, this ordering could still grant economy before the canonical progression authority rejects the completion.

A first-clear progression transaction must gate economic rewards on the authoritative current-frontier transition, with no reward/progression partial success.

### F-M39-V02-015 — Daily task state is not bound to a local day and login claim is not atomic with reward grant
`_tasks_done` is reset only when `claim_login()` runs. Crossing into a new day without first claiming login can leave yesterday's completed tasks claimable under today's transaction IDs.

Also `claim_login()` mutates streak/day state before calling `RewardGrantService.grant()` and ignores the grant result. A reward failure can advance Daily state without delivering the reward.

This compounds F-M39-V02-009 and affects SB-M39-041..044.

### F-M39-V02-016 — Heart/2x imported sentinel/timestamp domains are not fully canonical
`HeartService.import_snapshot()` accepts a negative regen anchor.
`SpeedEntitlementService.import_snapshot()` accepts arbitrary negative `entitled_level` values rather than only the sentinel -1 or a valid positive level.

These are noncanonical persisted states and must fail closed.

## Audit-spec correction discovered during the sweep
The earlier M40 criterion that said "reject invalid robot IDs" is too broad for the current owner law because the exact post-Scrubby robot roster is explicitly a later owner tuning decision. Claude cannot validate against a roster that does not yet exist.

For M39/M40 V03:
- empty/malformed robot IDs must fail;
- Scrubby must remain canonical initial unlocked robot;
- duplicate/invalid-shape entries must fail;
- a closed-world unknown-ID roster check is **NOT required until an owner-approved robot ID catalog exists**.

This is an auditor specification correction, not a Claude defect.

## Final frozen finding set
**F-M39-V02-001..016**

SB-M39-033 remains a later DEVICE/OWNER gate only *after* the sixth-slot production presentation/origin code exists.

Verdict string:
`CHANGES_REQUIRED / M39-C001 V02 / F-M39-V02-001..016`
