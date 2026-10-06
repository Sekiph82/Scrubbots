extends RefCounted
## RewardedDailyService — preload (res://scripts/economy/rewarded_daily_service.gd).
##
## M43-C015R (SB-M43-R15-001) — the Rewarded Ads daily track: five config-driven rewards per
## LOCAL calendar day (data/config/rewarded_daily_v1.json, seeded 1:1 from the Daily D1..D5
## bundles). A distinct track: it never reads or writes the Daily login streak / cycle, Daily
## Scrub Orders, the Gift Meter, Hearts, boosters or 2x rules.
##   - slot 1: no ad; claim_free() grants the bundle exactly once per local day;
##   - slots 2..5: start_ad() hands the bundle to the canonical RewardedGrantService, which
##     grants ONLY on a verified completed video (no second callback -> reward path here).
## Every grant uses the deterministic economy id "daily_rewarded:<local_day>:<slot>" on the
## canonical RewardGrantService, whose applied-tx set is persisted atomically by the M40 save.
## Claimed state AND the rollback high-water day are derived from that ledger, so there is no
## new save section and no migration: an old save simply has no such ids (fresh track).
## Rollback: a local day earlier than the highest day ever granted refuses every slot, so a
## clock / local-day rollback can never reopen or farm a prior day. A new forward local day
## offers all five slots again.
## Config fails closed: anything but exactly slots 1..5 (1 free, 2..5 ad) with known positive
## reward resources disables the whole track.

const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const PATH := "res://data/config/rewarded_daily_v1.json"
const SCHEMA := "scrubbots.rewarded_daily.v1"
const SLOTS := 5
const RESOURCES := ["scrub_bucks", "standard_card_packs", "premium_card_packs", "random_booster_charges", "selected_booster_charges"]

var _reward
var _rewarded
var _today: Callable
var _bundles: Dictionary = {}   ## slot -> reward bundle; empty = track disabled (bad config)

func _init(reward, rewarded, local_day: Callable, path: String = PATH) -> void:
	_reward = reward
	_rewarded = rewarded
	_today = local_day
	_bundles = load_bundles(path)

## {slot: bundle} for a valid config, else {} (fail closed).
static func load_bundles(path: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or IntDomain.exact_int(d.get("version")) != 1 or typeof(d.get("slots")) != TYPE_ARRAY:
		return {}
	var out := {}
	for e in d["slots"]:
		if typeof(e) != TYPE_DICTIONARY or typeof(e.get("reward")) != TYPE_DICTIONARY or typeof(e.get("requires_ad")) != TYPE_BOOL:
			return {}
		var slot = IntDomain.exact_int(e.get("slot"))
		if slot == null or slot < 1 or slot > SLOTS or out.has(slot) or bool(e["requires_ad"]) != (slot != 1):
			return {}
		var bundle := {}
		for k in e["reward"]:
			var n = IntDomain.exact_int(e["reward"][k])
			if not RESOURCES.has(String(k)) or n == null or n <= 0:
				return {}
			bundle[String(k)] = n
		if bundle.is_empty():
			return {}
		out[slot] = bundle
	return out if out.size() == SLOTS else {}

func is_configured() -> bool:
	return _bundles.size() == SLOTS

func today() -> int:
	return int(_today.call())

func reward_for(slot: int) -> Dictionary:
	return (_bundles.get(slot, {}) as Dictionary).duplicate(true)

static func tx_id(day: int, slot: int) -> String:
	return RewardedGrantService.daily_tx(day, slot)

func is_claimed(slot: int, day: int = -2147483648) -> bool:
	return _reward.already_applied(tx_id(today() if day == -2147483648 else day, slot))

## Highest local day with any rewarded-daily grant (-1 = none), from the canonical ledger.
func high_water_day() -> int:
	var hi := -1
	for id in _reward.applied_ids():
		var s := String(id)
		if s.begins_with(RewardedGrantService.DAILY_TX_PREFIX):
			var parts := s.substr(RewardedGrantService.DAILY_TX_PREFIX.length()).split(":")
			if parts.size() == 2 and parts[0].is_valid_int():
				hi = maxi(hi, int(parts[0]))
	return hi

func rollback_locked() -> bool:
	return today() < high_water_day()

## Presentation state of `slot` for today:
## claimed | ready_free | ready_ad | pending | ad_unavailable | locked_rollback | unavailable
func slot_state(slot: int) -> String:
	if not is_configured() or slot < 1 or slot > SLOTS:
		return "unavailable"
	if is_claimed(slot):
		return "claimed"
	if rollback_locked():
		return "locked_rollback"
	if slot == 1:
		return "ready_free"
	var c: Dictionary = _rewarded.can_start_daily(today(), slot)
	if bool(c["ok"]):
		return "ready_ad"
	return "pending" if String(c["reason"]) == "pending" else "ad_unavailable"

func states() -> Array:
	var out: Array = []
	for slot in range(1, SLOTS + 1):
		out.append(slot_state(slot))
	return out

## Slot 1: direct exactly-once grant for today (no ad request).
func claim_free() -> Dictionary:
	var st := slot_state(1)
	if st != "ready_free":
		return {"ok": false, "reason": {"claimed": "already_claimed", "locked_rollback": "clock_rollback"}.get(st, "unavailable")}
	var day := today()
	if not _reward.grant(tx_id(day, 1), reward_for(1)):
		return {"ok": false, "reason": "already_claimed" if _reward.already_applied(tx_id(day, 1)) else "grant_failed"}
	return {"ok": true, "slot": 1, "day": day, "tx": tx_id(day, 1), "reward": reward_for(1)}

## Slots 2..5: one verified rewarded video; the grant happens in RewardedGrantService.resolve().
func start_ad(slot: int, token: String = "") -> Dictionary:
	if slot < 2 or slot > SLOTS:
		return {"ok": false, "reason": "unknown_product"}
	if not is_configured():
		return {"ok": false, "reason": "unavailable"}
	if is_claimed(slot):
		return {"ok": false, "reason": "already_claimed"}
	if rollback_locked():
		return {"ok": false, "reason": "clock_rollback"}
	return _rewarded.start_daily_slot(today(), slot, reward_for(slot), token)
