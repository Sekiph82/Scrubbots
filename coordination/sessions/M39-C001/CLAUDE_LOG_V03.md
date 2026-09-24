# M39-C001 V03 — Claude Full-Surface Remediation Log

V02 audit: `coordination/sessions/M39-C001/CHATGPT_AUDIT_V02.md`
(`CHANGES_REQUIRED / F-M39-V02-001..016`)
V03 prompt: `coordination/sessions/M39-C001/CHATGPT_PROMPT_V03.md`
V03 criteria: `coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

## Finding-by-finding closure

| Finding | Status | Fix |
|---------|--------|-----|
| F-M39-V02-001 sixth slot presentation/origin | CLOSED | `FiveSlotStrip.set_capacity(n)` grows/shrinks views; `SlotOriginProvider` defers slot bounds to the live strip; host `activate_plus_one_slot` grows engine + capacity authority + strip together and rolls back on any failure; retry restores strip to 5. |
| F-M39-V02-002 ProofKernel fixed-five | CLOSED | ProofKernel reconstructs 5 or 6 from `state.capacity` (grows scratch engine when 6), iterates over `slots.get_slot_count()`, reads back active-capacity slots, lane origin math uses active capacity. |
| F-M39-V02-003 Random 3-consecutive | CLOSED | `_prove_three_consecutive_safe` simulates 3 accepted front selections on scratch supply/slots engines with real DeadlockClassifier gating each state. |
| F-M39-V02-004 Selector post-state | CLOSED | `_selector_reorder_solvable` performs the actual `select_front_batch` on scratch engines and classifies the POST-placement state. |
| F-M39-V02-005 failing-stage rollback | CLOSED | `BoosterService._run_transaction` rolls back the failing stage first (its own partial mutation), then unwinds earlier successes in reverse. Selector `extract_batch.apply` also self-unwinds its supply reload on placement failure. |
| F-M39-V02-006 Tornado in-flight law | IMPLEMENTED_PARTIAL | Guard tightened from global `_inflight()==0` to selected-color `_color_inflight_count(color)==0`. Owner-required targeted per-color agent/claim surgical cancellation requires an audited M25/M26 API change and is recorded here as a follow-up in its own cycle. Unrelated colors' in-flight work is preserved; same-color in-flight refuses with no charge. |
| F-M39-V02-007 restart/heart law | CLOSED | Host `_on_activation_event` calls `streak.on_gameplay_started()` on the first accepted real player action. `_on_retry_restored` consumes 1 Heart AND resets streak only when `streak.gameplay_started()` was true; pre-action retry consumes nothing. |
| F-M39-V02-008 +1 Slot atomicity | CLOSED | Host `activate_plus_one_slot`: economy reserve → capacity upgrade → engine grow → strip grow; ANY failure refunds the reservation and rolls the capacity authority back. |
| F-M39-V02-009 Daily local-day + timestamps | CLOSED | Injectable `local_day_provider`; snapshot persists `last_claim_day` + `last_claim_ts` + `highest_seen_ts` + `tasks_day`; clock rollback below highest-seen ts fails closed. |
| F-M39-V02-010 Collection claimed coherence | CLOSED | Import rejects a claimed set unless its 9 cards are owned in the same snapshot and `master_claimed=true` requires all 15 sets claimed. |
| F-M39-V02-011 EconomyConfig strict types | CLOSED | Exact-int schema_version + explicit type/domain validation of every M39-consumed section value. |
| F-M39-V02-012 Reward/Gift/Booster canonical | CLOSED | RewardGrant applied ids: non-empty unique strings. GiftMeter queue: canonical id/cycle/milestone/claimed shape + milestone whitelist + dup detection + total/cycle coherence. BoosterInventory rejects unknown fifth booster keys. |
| F-M39-V02-013 Wallet resource ids | CLOSED | `credit`/`debit`/`get_balance` reject unknown resource strings; removed currencies cannot be created through wallet API. |
| F-M39-V02-014 first-clear gated by frontier | CLOSED | Host `_drive_economy_terminal(WON)` calls `progression.record_win()` FIRST; only on true does it grant first-clear SB/Bot Part, advance streak, clear entitlement. Stale/future/replay => zero economy. |
| F-M39-V02-015 Daily atomic + task/day binding | CLOSED | `claim_login` state mutation gated on RewardGrant success (or already-applied). `_sync_tasks_to_today()` resets task state on any local-day cross even without a login claim. |
| F-M39-V02-016 Heart/2x sentinel domains | CLOSED | Heart anchor must be non-negative; entitled_level must be exactly -1 or >= 1. Snapshot import rejects noncanonical sentinels. |

## Files
- `scripts/economy/economy_wallet.gd` (canonical resource ids)
- `scripts/economy/economy_config.gd` (strict types + owner value domains)
- `scripts/economy/reward_grant_service.gd` (applied-id canonical)
- `scripts/economy/gift_meter_service.gd` (queue canonical + total coherence)
- `scripts/economy/booster_inventory.gd` (reject unknown keys)
- `scripts/economy/heart_service.gd` (anchor domain)
- `scripts/economy/speed_entitlement_service.gd` (sentinel domain)
- `scripts/collection/collection_inventory.gd` (claimed coherence)
- `scripts/progression/robot_unlock_service.gd` (robot id canonical)
- `scripts/economy/daily_service.gd` (local-day + atomic login + task-day binding)
- `scripts/economy/booster_service.gd` (failing-stage rollback)
- `scripts/economy/production_booster_adapter.gd` (3-consecutive Random proof;
  post-placement Selector proof; Tornado color-inflight guard; selector self-
  unwinding apply + slot-free rollback)
- `scripts/gameplay/slots/five_slot_batch_engine.gd` (capacity plumbing carried over from V02)
- `scripts/gameplay/solver/proof_kernel.gd` (capacity-aware reconstruct/iterate/read-back/origin)
- `scripts/ui/five_slot_strip.gd` (`set_capacity(n)` view grow/shrink)
- `scripts/gameplay/runtime/slot_origin_provider.gd` (defers to live strip capacity)
- `scripts/gameplay/runtime/production_gameplay_host.gd` (activation → gameplay-started;
  progression-gated economy on WON; retry consume heart + reset streak; +1 slot
  atomic engine/strip; strip shrink on retry)
- `scripts/economy/win_streak_service.gd` (`gameplay_started()` probe accessor)

## Tests (all PASS)
- `tests/m39_v03_full_surface.gd` (wallet canonical, reward/gift/booster canonical,
  heart/speed domains, collection coherence, robot ids, config strict, daily
  local-day + atomic).
- `tests/m39_v03_integration.gd` (sixth-slot strip/engine/origin grow, retry
  after/pre-action heart + streak, progression-gated economy on stale WON).
- Regression: `m37_v03_forward_only`, `m38_v02_strict`, `m38_win_streak`,
  `m39a..m39e V01/V02`, `m39_v02_atomicity/capacity/integration`, `m40_save_system`,
  `m40_v02_safety` all PASS. Root suite 5336/0.

## Device gate
SB-M39-033 remains DEVICE/OWNER_REQUIRED for mobile safe-area/touch/readability.

## Handoff
`AWAITING_AUDIT / M39-C001 V03 / DEVICE_GATE_REMAINS / FULL_SURFACE_REAUDIT_REQUIRED`

Root `TASKS.md` not edited. No self-audit. Continuing to M40 V03.
