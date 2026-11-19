extends RefCounted
## ProductionActionFacade — preload (res://scripts/economy/production_action_facade.gd).
##
## The ONE canonical production action surface for durable Economy V1 player
## actions (M39 V04, F-M39-V03-005). UI/controllers call these methods; they
## never touch wallet/service internals. Every method:
##   - calls the canonical service/adapter (BoosterService + ProductionBoosterAdapter,
##     SpeedEntitlementService, HeartService, DailyService, GiftMeterService,
##     CollectionInventory, CardsExchangeService, RobotUnlockService);
##   - returns an explicit result {ok: bool, action: String, ...service fields};
##   - on a COMMITTED success only, requests the durable save boundary (if bound)
##     and emits `action_committed(action, result)` — failures never save/emit.
## Boosters need a live gameplay host; economy actions need only EconomyServices.

const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")

signal action_committed(action: String, result: Dictionary)
## M43 master remediation V03 (SB-M43-161/162): a refused action (nothing committed). Presentation
## observers only (MetaFeedback error / warning); never a retry or economy path.
signal action_refused(action: String, result: Dictionary)

var _economy
var _host            # ProductionGameplayHost or null (menus: economy-only actions)
var _save_cb: Callable = Callable()
## SB-M44-032: Callable(feature_id) -> bool, the owner unlock gate (AppState.feature_unlocked).
## Bound by AppState / the gameplay host, so a locked booster is never bought, watched or used
## through ANY caller (Shop, Booster Acquire, Need a Hand), and locked Robots / Events actions
## are refused whatever opened them. Unbound (no AppState) = open.
var feature_gate: Callable = Callable()

func _init(economy, host = null, save_cb: Callable = Callable()) -> void:
	_economy = economy
	_host = host
	_save_cb = save_cb

## Bind the durable-save boundary (M40): called once per committed action.
func bind_save(cb: Callable) -> void:
	_save_cb = cb

func _finish(action: String, r) -> Dictionary:
	var out: Dictionary = r.duplicate() if typeof(r) == TYPE_DICTIONARY else {"ok": bool(r)}
	out["ok"] = bool(out.get("ok", false))
	out["action"] = action
	if out["ok"]:
		if _save_cb.is_valid():
			out["save"] = _save_cb.call()
		action_committed.emit(action, out)
	else:
		action_refused.emit(action, out)
	return out

func _no_host(action: String) -> Dictionary:
	return {"ok": false, "action": action, "reason": "no_gameplay_host"}

func feature_unlocked(feature_id: String) -> bool:
	return not feature_gate.is_valid() or bool(feature_gate.call(feature_id))

## {} when booster `id` is unlocked, else the refused result (nothing touched).
func _locked(action: String, id: String) -> Dictionary:
	return {} if feature_unlocked(id) else _finish(action, {"ok": false, "reason": "locked"})

# ------------------------------------------------------------ boosters ----

func plus_one_slot() -> Dictionary:
	var lk := _locked("plus_one_slot", BoosterInventory.PLUS_ONE_SLOT)
	if not lk.is_empty():
		return lk
	if _host == null:
		return _no_host("plus_one_slot")
	var ok: bool = _host.activate_plus_one_slot()
	var why = _host.get("last_plus_one_refusal")
	return _finish("plus_one_slot", {"ok": ok} if ok or why == null else {"ok": false, "reason": String(why)})

func random() -> Dictionary:
	var lk := _locked("random", BoosterInventory.RANDOM)
	if not lk.is_empty():
		return lk
	if _host == null:
		return _no_host("random")
	var r = _host.get_booster_service().apply_random(_host.get_booster_adapter())
	return _booster_done("random", r)

func selector(batch_id) -> Dictionary:
	var lk := _locked("selector", BoosterInventory.SELECTOR)
	if not lk.is_empty():
		return lk
	if _host == null:
		return _no_host("selector")
	var r = _host.get_booster_service().apply_selector(_host.get_booster_adapter(), batch_id)
	return _booster_done("selector", r)

func tornado(color) -> Dictionary:
	var lk := _locked("tornado", BoosterInventory.TORNADO)
	if not lk.is_empty():
		return lk
	if _host == null:
		return _no_host("tornado")
	var r = _host.get_booster_service().apply_tornado(_host.get_booster_adapter(), color)
	return _booster_done("tornado", r)

## M43-C004: buy one saved charge (no execution; usable on the next attempt). Needs no
## gameplay host, so terminal-recovery UI can call it.
func buy_booster_charge(id: String) -> Dictionary:
	var lk := _locked("buy_booster_charge", id)
	if not lk.is_empty():
		return lk
	var r: Dictionary = _economy.boosters.buy_charge(id)
	r["booster"] = id   # presentation identity copied from the input (SB-TF-05 reward reveal)
	return _finish("buy_booster_charge", r)

func _booster_done(action: String, r: Dictionary) -> Dictionary:
	if r.get("ok", false):
		_host.on_booster_committed()
	return _finish(action, r)

# ------------------------------------------------------------ 2x / Hearts ----

func buy_current_level_2x(level: int = -1) -> Dictionary:
	var lvl := level
	if lvl < 1 and _host != null:
		lvl = int(_host.progression_level)
	return _finish("buy_current_level_2x", _economy.speed.purchase_current_level(lvl))

func buy_timed_2x(seconds: int) -> Dictionary:
	return _finish("buy_timed_2x", _economy.speed.purchase_timed(seconds))

func buy_heart() -> Dictionary:
	return _finish("buy_heart", _economy.hearts.purchase_plus_one())

func refill_hearts() -> Dictionary:
	return _finish("refill_hearts", _economy.hearts.purchase_full_refill())

# ------------------------------------------------------------ rewarded (M43-C003) ----

## Rewarded products: "heart" | "booster:<id>". The grant itself commits (and saves) in
## RewardedGrantService.resolve() when the provider reports a verified completion.
func rewarded_available(product: String) -> bool:
	return _economy.rewarded.is_available(product)

func start_rewarded(product: String, token: String = "") -> Dictionary:
	if product.begins_with("booster:") and not feature_unlocked(product.substr(8)):
		return {"ok": false, "action": "start_rewarded", "reason": "locked"}
	if not _economy.ads.allowed("rewarded"):
		return {"ok": false, "action": "start_rewarded", "reason": "ads_disallowed"}
	var r: Dictionary = _economy.rewarded.start(product, token)
	r["action"] = "start_rewarded"
	return r

## M43-C015R Rewarded Ads daily track. Slot 1 is a direct committed claim (saved by _finish);
## slots 2..5 start one rewarded video whose verified completion commits + saves inside
## RewardedGrantService.resolve() under daily_rewarded:<local_day>:<slot>.
func claim_rewarded_daily_free() -> Dictionary:
	return _finish("claim_rewarded_daily", _economy.rewarded_daily.claim_free())

func start_rewarded_daily(slot: int, token: String = "") -> Dictionary:
	if not _economy.ads.allowed("rewarded"):
		return {"ok": false, "action": "start_rewarded_daily", "reason": "ads_disallowed"}
	var r: Dictionary = _economy.rewarded_daily.start_ad(slot, token)
	r["action"] = "start_rewarded_daily"
	return r

## SB-TF-05 (owner 2026-11-18): the rewarded x2 on a level win. Offered while the win's reward
## reveal holds, only when the committed receipt is a WON with Scrub Bucks and an ad is ready
## (No Ads keeps rewarded videos). A verified completion grants the receipt's
## wallet_delta.scrub_bucks once more under win_double:<receipt_key> (commit + save inside
## RewardedGrantService.resolve); never twice for one win.
func win_double_available(receipt_key: String, receipt: Dictionary) -> bool:
	return _win_double_sb(receipt) > 0 and _economy.ads.allowed("rewarded") 		and bool(_economy.rewarded.can_start_win_double(receipt_key).get("ok", false))

func start_win_double(receipt_key: String, receipt: Dictionary, token: String = "") -> Dictionary:
	if not _economy.ads.allowed("rewarded"):
		return {"ok": false, "action": "start_win_double", "reason": "ads_disallowed"}
	if _win_double_sb(receipt) <= 0:
		return {"ok": false, "action": "start_win_double", "reason": "unknown_product"}
	var r: Dictionary = _economy.rewarded.start_win_double(receipt_key, _win_double_sb(receipt), token)
	r["action"] = "start_win_double"
	return r

## UI safety timeout: close a pending rewarded request as a non-grant (a late callback is a duplicate).
func abandon_rewarded(token: String) -> Dictionary:
	return _economy.rewarded.abandon(token)

static func _win_double_sb(receipt: Dictionary) -> int:
	if String(receipt.get("status", "")) != "WON":
		return 0
	return int((receipt.get("wallet_delta", {}) as Dictionary).get("scrub_bucks", 0))

# ------------------------------------------------------------ claims ----

## M44 (owner V03, first Home DAILY / TASKS 100 SB claims): the two first-Home claims commit
## DURABLY. If the bound save boundary reports failure, the exact pre-claim economy snapshot is
## re-imported (no grant-first-save-later: wallet, ledger tx, Daily state and badge return to
## the prior durable truth) and the claim is refused, so a retry is the same single claim.
## SB-M44-023: Daily / Daily Scrub Orders claims follow the data-driven `daily` / `tasks` gate.
func claim_daily_login() -> Dictionary:
	if not feature_unlocked("daily"):
		return _locked("claim_daily_login", "daily")
	return _finish_durable("claim_daily_login", func(): return _economy.daily.claim_login())

## M43-C005F-PHASE3: results carry presentation-only identity copied from the input (the task
## index / Gift occurrence id); the grant itself is unchanged.
func claim_daily_task(task_index: int) -> Dictionary:
	if not feature_unlocked("tasks"):
		return _locked("claim_daily_task", "tasks")
	return _finish_durable("claim_daily_task", func():
		var r: Dictionary = _economy.daily.claim_task(task_index)
		r["task_index"] = task_index
		return r)

## Commit `op` (a canonical claim) and its save as one unit (see claim_daily_login). A save
## callback that returns no result (unbound harness) counts as committed, exactly like _finish.
func _finish_durable(action: String, op: Callable) -> Dictionary:
	var pre: Dictionary = _economy.snapshot()
	var r: Dictionary = op.call()
	if not bool(r.get("ok", false)) or not _save_cb.is_valid():
		return _finish(action, r)
	var s = _save_cb.call()
	if typeof(s) == TYPE_DICTIONARY and not bool(s.get("ok", true)):
		var restored: bool = _economy.import_snapshot(pre)
		var out := {"ok": false, "action": action, "reason": "save_failed", "save": s, "restored": restored}
		if r.has("task_index"):
			out["task_index"] = r["task_index"]
		action_refused.emit(action, out)
		return out
	var done: Dictionary = r.duplicate()
	done["ok"] = true
	done["action"] = action
	done["save"] = s
	action_committed.emit(action, done)
	return done

## SB-POLISH-007: claim one completed achievement's reward (tx achievement:<id>, durable like
## the Daily task claims). `app` supplies the read-only progression stats.
func claim_achievement(app, id: String) -> Dictionary:
	return _finish_durable("claim_achievement", func(): return Achievements.claim(app, id))

func claim_daily_all_tasks() -> Dictionary:
	if not feature_unlocked("tasks"):
		return _locked("claim_daily_all_tasks", "tasks")
	return _finish("claim_daily_all_tasks", _economy.daily.claim_all_tasks_bonus())

func claim_gift(occurrence_id: String) -> Dictionary:
	var r: Dictionary = _economy.gift.claim(occurrence_id, _economy.reward, _economy.config)
	r["occurrence_id"] = occurrence_id
	return _finish("claim_gift", r)

func claim_collection_rewards() -> Dictionary:
	return _finish("claim_collection_rewards", _economy.collection.claim_pending_rewards())

# ------------------------------------------------------------ exchange / unlock ----

## Fresh exchange tx id. The exchange counter is session-local while applied tx
## ids persist, so after a relaunch skip ids already in the applied set (else a
## legitimate exchange would be refused as "duplicate").
func _fresh_exchange_tx() -> String:
	var tx: String = _economy.exchange.next_tx_id()
	while _economy.reward.already_applied(tx):
		tx = _economy.exchange.next_tx_id()
	return tx

func exchange_card(card_id: String, count: int) -> Dictionary:
	return _finish("exchange_card", _economy.exchange.exchange_card(card_id, count, _fresh_exchange_tx()))

func exchange_all_extras() -> Dictionary:
	return _finish("exchange_all_extras", _economy.exchange.exchange_all_extras(_fresh_exchange_tx()))

func unlock_robot(robot_id: String) -> Dictionary:
	if not feature_unlocked("robots"):
		return _locked("unlock_robot", "robots")
	var r: Dictionary = _economy.robots.unlock(robot_id)
	r["robot_id"] = robot_id
	return _finish("unlock_robot", r)

## M43 master (SB-M43-102/104): unlock the NEXT robot of the canonical roster order (owner
## roster §4) for exactly the configured Bot Parts. {ok, reason, robot_id, remaining_parts}.
func unlock_next_robot() -> Dictionary:
	if not feature_unlocked("robots"):
		return _locked("unlock_robot", "robots")
	var id: String = RobotRoster.next_locked(_economy.robots)
	if id.is_empty():
		return _finish("unlock_robot", {"ok": false, "reason": "all_unlocked"})
	var r: Dictionary = _economy.robots.unlock(id)
	r["robot_id"] = id
	return _finish("unlock_robot", r)

## M43-C010 / C010R: event milestone / First-Try claims (EventService, RewardGrantService tx).
func claim_event_milestone(event_id: String, index: int) -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("claim_event_milestone", "events")
	var r: Dictionary = _economy.events.claim_weekly(event_id, index, _economy.reward)
	r["milestone"] = index   # presentation / analytics identity copied from the input
	return _finish("claim_event_milestone", r)

func join_first_try() -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("join_first_try", "events")
	return _finish("join_first_try", _economy.events.join_first_try())

func claim_first_try() -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("claim_first_try", "events")
	return _finish("claim_first_try", _economy.events.claim_first_try(_economy.reward))

## SB-EV02-004/007: V02 event join / reward claim / tutorial seen, all behind the Events
## unlock. A claim is saved before it is acknowledged (a failed save rolls it back).
func join_event(iid: String) -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("join_event", "events")
	return _finish("join_event", _economy.events_v02.join(iid, true))

func claim_event_reward(iid: String, rid: String) -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("claim_event_reward", "events")
	return _finish_durable("claim_event_reward", func(): return _economy.events_v02.claim(iid, rid, _economy.reward, true))

func mark_event_tutorial_seen(event_id: String) -> Dictionary:
	if not feature_unlocked("events"):
		return _locked("mark_event_tutorial_seen", "events")
	_economy.events_v02.mark_tutorial_seen(event_id)
	return _finish("mark_event_tutorial_seen", {"ok": true})

## M43-C012R: Comeback Catch-Up step claim (only when an owner reward sequence is configured).
func claim_catchup(step: int) -> Dictionary:
	return _finish("claim_catchup", _economy.returns.claim_catchup(step, _economy.reward))

## M43 master (SB-M43-071/106): equip an unlocked robot (persisted selection, spends nothing).
func equip_robot(robot_id: String) -> Dictionary:
	if not feature_unlocked("robots"):
		return _locked("equip_robot", "robots")
	return _finish("equip_robot", _economy.robots.set_active(robot_id))
