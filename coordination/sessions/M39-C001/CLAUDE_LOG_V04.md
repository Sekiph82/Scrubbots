# M39-C001 V04 — Claude Targeted Final Economy Remediation Log

V03 audit: `coordination/sessions/M39-C001/CHATGPT_AUDIT_V03.md`
(`CHANGES_REQUIRED / F-M39-V03-001..005`)
V04 prompt: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V04.md`
V04 criteria: `coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
Batch master: `coordination/sessions/M39-M40-BATCH/CHATGPT_MASTER_PROMPT_V04.md`

Scope: only F-M39-V03-001..005. Accepted V03 repairs preserved. Root `TASKS.md`
untouched. No audit verdict created; closure is ChatGPT's.

## Finding-by-finding closure

| Finding | Status | Fix | Direct test |
|---------|--------|-----|-------------|
| F-M39-V03-001 Tornado selected-color in-flight | IMPLEMENTED | Smallest targeted seam, no global reset. M26 `AutoDispatchScheduler`: `color_assignment_owners`, read-only `preflight_color_cancel` (scheduler assignment -> M25 claim tuple (owner/target/slot/color) -> ReservationState pair both directions -> M24 `is_work_bound_to` exact slot+batch -> M19 dispatcher owns the same agent and it has NOT arrived), reversible `detach_assignment` (M25 `rollback_claim`) / `reattach_assignment` (new M25 `restore_claim`, exact companion: re-reserve, re-commit work id, re-insert ledger), irreversible `finalize_detached` (new M19 `ScrubbotDispatcher.cancel_owner(owner, agent)`, no reservation touch, no generation bump). New M24 `purge_uncommitted_slot`/`restore_purged_slot` (detached SlotBatchState object reinstated exactly). Adapter `tornado_stages`: guard -> claims -> board -> slots -> supply -> finalize (agent cancel last, re-proved all-or-nothing). Latent V03 bugs fixed: `_color_inflight_count` read `"color_id"` but scheduler key is `"color"` (guard was always 0); supply-stage rollback reassigned a captured local (GDScript lambdas capture by value) so supply rollback was a no-op; live boosters used `load_columns`, which also overwrote the Retry baseline `_initial` — new M23 `replace_live_columns` preserves it. | `tests/m39_v04_tornado_inflight.gd` |
| F-M39-V03-002 production local calendar | IMPLEMENTED | New `scripts/economy/local_calendar.gd`: civil-date ordinal (Hinnant days_from_civil; 0 = 1970-01-01 so persisted day keys stay compatible), `system_provider()` = OS local date (`Time.get_date_dict_from_system(false)`, OS applies TZ/DST), `offset_provider(clock, offset)` test seam. `DailyService`: no UTC fallback — no injected clock -> system provider; injected test clock -> offset 0. `EconomyServices(..., local_day)` and `AppState(save_path, clock, local_day)` seams; AppState explicitly injects `LocalCalendar.system_provider()`. Also: task-day sync forward-only (rollback no longer rewrites/wipes task progress, task/all-task claims refuse under rollback); login no longer wipes tasks completed earlier the same day. | `tests/m39_v04_integration.gd::_phase_b_calendar` |
| F-M39-V03-003 +1 Slot exact rollback | IMPLEMENTED | Host `activate_plus_one_slot` = one reversible transition; on any failure: strip back to prior capacity, new M24 `rollback_grow_to_sixth()` (only EMPTY, uncommitted sixth slot), refund, capacity authority back to (5, unused). Never returns false with M24 at six. Latent bug fixed: `BoosterService.apply_plus_one_slot` result dropped `price`, so an SB-paid refund credited 0 SB. Test-only `set_plus_one_fault_injector("engine"|"strip")`; `FiveSlotStrip.get_capacity()`. | `tests/m39_v04_integration.gd::_phase_c_plus_one` |
| F-M39-V03-004 atomic first-clear | IMPLEMENTED | New `scripts/economy/first_clear_transaction.gd` `FirstClearTransaction.commit(progression, economy, level, fault)`: snapshots LevelProgressionService + full EconomyServices (wallet, Bot Parts, RewardGrant applied tx set, streak, Gift Meter, 2x entitlement, ...); record_win (stale/future/replay -> zero mutation, nothing else runs) -> first-clear -> streak/Gift -> entitlement; any failure re-imports both snapshots. Host WON path calls it (`last_first_clear_result`, test-only `set_first_clear_fault_injector`). | `tests/m39_v04_integration.gd::_phase_d_first_clear`, `::_phase_d_host_terminal` |
| F-M39-V03-005 canonical action surface | IMPLEMENTED | New `scripts/economy/production_action_facade.gd`: `plus_one_slot`, `random`, `selector`, `tornado`, `buy_current_level_2x`, `buy_timed_2x`, `buy_heart`, `refill_hearts`, `claim_daily_login/task/all_tasks`, `claim_gift`, `claim_collection_rewards` (new `CollectionInventory.claim_pending_rewards`), `exchange_card`, `exchange_all_extras` (fresh tx id skips persisted applied ids — previously a relaunch reset the counter and exchanges were refused as "duplicate"), `unlock_robot`. Explicit `{ok, action, ...}`; ONLY committed success calls the bound save and emits `action_committed(action, result)`. Host builds it bound to `request_save` (`get_actions()`); boosters then run host `on_booster_committed()` (candidate-index rebuild, renderer refresh, UI snapshots, completion dirty). Economy-only facade (no host) refuses gameplay boosters explicitly (`no_gameplay_host`) — M40 binds it app-wide. | `tests/m39_v04_integration.gd::_phase_e_facade` |

## Test evidence (fault/adversarial highlights)

- Tornado: selected color with 3 live in-flight assignments + an unrelated color
  in flight. Faults at `tornado_guard` (before cancel), `tornado_cancel_one`
  (after first cancel), `tornado_claims` (after claim/work rollback),
  `tornado_board`, `tornado_slots`, `tornado_supply`, `tornado_finalize` — each:
  no charge, no SB loss, exact snapshot of board cells, M24 slots + live work,
  M23 supply, M25 claims, reservations, M26 assignments, agents alive/owned,
  dispatcher count. Success: 1 charge, generations unchanged (no global reset),
  zero selected-color assignment/claim/cell/slot/supply, agents freed, unrelated
  assignment/reservation/agent intact, then the attempt drains to terminal with
  0 reservations. Reservation drift and arrived agent fail closed.
- Local day: UTC-5 same local day across UTC midnight refused; local midnight
  crossing claims; UTC+9 local cross inside one UTC day; year/month/leap
  consecutive; 2000 leap / 2100 non-leap; rollback + high-water fail-closed;
  refused claims zero mutation; relaunch preserves ts/high-water; AppState and
  default EconomyServices return the OS local-date ordinal.
- +1 Slot: engine/strip fault x charge/SB payment -> exact 5-slot restoration of
  economy snapshot, capacity authority, M24 slots, strip, slot-5 origin.
- First clear: fault after each of 4 stages -> exact progression + economy
  snapshots; clean retry commits exactly once; host WON with streak fault leaves
  progression/streak unchanged.
- Facade: all 16 actions return explicit results; all four boosters commit;
  save count == signal count == committed count; failures neither save nor emit.

## Regression (all exit 0)

M23 v01/v02/v03, M24 (5 suites), M25 (6 suites), M26 hazard-bot + scale-59,
M27 generation-retry / hazard-bot-solve / scale-59, M28, M29 (7 suites), M30
completion / manual-playtest / transaction-safe-retry, M37 v01/v02/v03, M38
win-streak / v02-strict, M39 a/b/c/d/e, M39 V02 atomicity/capacity/integration,
M39 V03 full-surface/integration, M39 V04 integration + tornado-inflight, M40
save / v02-safety / v03-canonical. Root suite `tests/run_tests.gd`: 5336 checks, 0 failures.

Notes, not failures: `m30_transaction_safe_retry` prints 26 `ok: FAIL-CLOSED[...]`
labels (passing assertions). `m38_v02_strict` (files untouched by this cycle)
prints PASS but its `_reward_failure_no_mutation` sub-check aborts with a
pre-existing typed-argument SCRIPT ERROR (`_FakeReward` not accepted by
`WinStreakService.new`); flagged as a separate follow-up, not changed here.

`git diff --check` clean. `project.godot` [audio] headless strip restored before commit.

## Remaining gates

- SB-M39-033: DEVICE/OWNER_REQUIRED — real handset sixth-slot safe-area/touch/readability.

Handoff: `AWAITING_AUDIT / M39-C001 V04 / DEVICE_GATE_REMAINS`
