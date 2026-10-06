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

signal action_committed(action: String, result: Dictionary)
## M43 master remediation V03 (SB-M43-161/162): a refused action (nothing committed). Presentation
## observers only (MetaFeedback error / warning); never a retry or economy path.
signal action_refused(action: String, result: Dictionary)

var _economy
var _host            # ProductionGameplayHost or null (menus: economy-only actions)
var _save_cb: Callable = Callable()

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

# ------------------------------------------------------------ boosters ----

func plus_one_slot() -> Dictionary:
	if _host == null:
		return _no_host("plus_one_slot")
	return _finish("plus_one_slot", {"ok": _host.activate_plus_one_slot()})

func random() -> Dictionary:
	if _host == null:
		return _no_host("random")
	var r = _host.get_booster_service().apply_random(_host.get_booster_adapter())
	return _booster_done("random", r)

func selector(batch_id) -> Dictionary:
	if _host == null:
		return _no_host("selector")
	var r = _host.get_booster_service().apply_selector(_host.get_booster_adapter(), batch_id)
	return _booster_done("selector", r)

func tornado(color) -> Dictionary:
	if _host == null:
		return _no_host("tornado")
	var r = _host.get_booster_service().apply_tornado(_host.get_booster_adapter(), color)
	return _booster_done("tornado", r)

## M43-C004: buy one saved charge (no execution; usable on the next attempt). Needs no
## gameplay host, so terminal-recovery UI can call it.
func buy_booster_charge(id: String) -> Dictionary:
	return _finish("buy_booster_charge", _economy.boosters.buy_charge(id))

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
	var r: Dictionary = _economy.rewarded.start(product, token)
	r["action"] = "start_rewarded"
	return r

## M43-C015R Rewarded Ads daily track. Slot 1 is a direct committed claim (saved by _finish);
## slots 2..5 start one rewarded video whose verified completion commits + saves inside
## RewardedGrantService.resolve() under daily_rewarded:<local_day>:<slot>.
func claim_rewarded_daily_free() -> Dictionary:
	return _finish("claim_rewarded_daily", _economy.rewarded_daily.claim_free())

func start_rewarded_daily(slot: int, token: String = "") -> Dictionary:
	var r: Dictionary = _economy.rewarded_daily.start_ad(slot, token)
	r["action"] = "start_rewarded_daily"
	return r

# ------------------------------------------------------------ claims ----

func claim_daily_login() -> Dictionary:
	return _finish("claim_daily_login", _economy.daily.claim_login())

func claim_daily_task(task_index: int) -> Dictionary:
	return _finish("claim_daily_task", _economy.daily.claim_task(task_index))

func claim_daily_all_tasks() -> Dictionary:
	return _finish("claim_daily_all_tasks", _economy.daily.claim_all_tasks_bonus())

func claim_gift(occurrence_id: String) -> Dictionary:
	return _finish("claim_gift", _economy.gift.claim(occurrence_id, _economy.reward, _economy.config))

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
	return _finish("unlock_robot", _economy.robots.unlock(robot_id))

## M43 master (SB-M43-102/104): unlock the NEXT robot of the canonical roster order (owner
## roster §4) for exactly the configured Bot Parts. {ok, reason, robot_id, remaining_parts}.
func unlock_next_robot() -> Dictionary:
	var id: String = RobotRoster.next_locked(_economy.robots)
	if id.is_empty():
		return _finish("unlock_robot", {"ok": false, "reason": "all_unlocked"})
	var r: Dictionary = _economy.robots.unlock(id)
	r["robot_id"] = id
	return _finish("unlock_robot", r)

## M43-C010 / C010R: event milestone / First-Try claims (EventService, RewardGrantService tx).
func claim_event_milestone(event_id: String, index: int) -> Dictionary:
	return _finish("claim_event_milestone", _economy.events.claim_weekly(event_id, index, _economy.reward))

func join_first_try() -> Dictionary:
	return _finish("join_first_try", _economy.events.join_first_try())

func claim_first_try() -> Dictionary:
	return _finish("claim_first_try", _economy.events.claim_first_try(_economy.reward))

## M43-C012R: Comeback Catch-Up step claim (only when an owner reward sequence is configured).
func claim_catchup(step: int) -> Dictionary:
	return _finish("claim_catchup", _economy.returns.claim_catchup(step, _economy.reward))

## M43 master (SB-M43-071/106): equip an unlocked robot (persisted selection, spends nothing).
func equip_robot(robot_id: String) -> Dictionary:
	return _finish("equip_robot", _economy.robots.set_active(robot_id))
