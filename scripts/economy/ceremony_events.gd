extends RefCounted
## CeremonyEvents — preload (res://scripts/economy/ceremony_events.gd).
##
## M43 master (SB-M43-068 onward) — READ-ONLY derivation of the already-committed events
## that deserve a meta ceremony, straight from authoritative service state:
##
##   gift:<occurrence id>  a queued Gift Meter milestone occurrence (GiftMeterService queue)
##   set:<n>               Collection set n reward claimed (CollectionInventory)
##   master                Master Collection reward claimed (CollectionInventory)
##   robot:<id>            a robot unlocked after the initial robot (RobotUnlockService)
##
## Each event carries the committed facts a ceremony needs (no recomputation of grants:
## set / master rewards come from the same config the grant used, read-only). Order is
## deterministic: Gift milestones (queue order), sets ascending, Master, robots.
## Nothing here grants, claims, saves or mutates; pending = events() minus MetaUiState.seen.

static func events(economy) -> Array:
	var out: Array = []
	for occ in economy.gift.gift_bar_queue():
		out.append({"key": "gift:" + String(occ["id"]), "kind": "gift_milestone", "occurrence_id": String(occ["id"]),
			"milestone": int(occ["milestone"]), "cycle": int(occ["cycle"]), "claimed": bool(occ.get("claimed", false)),
			"cycle_max": int(economy.config.gift_meter_cycle_max()),
			"rewards": (economy.config.gift_meter_milestone(int(occ["milestone"])) as Dictionary).duplicate(true)})
	var col: Dictionary = economy.collection.snapshot()
	var claimed: Array = (col.get("set_reward_claimed", []) as Array).map(func(n): return int(n))
	claimed.sort()
	var cfg: Dictionary = economy.config.collection_config()
	for n in claimed:
		var e := _set_entry(cfg, n)
		out.append({"key": "set:%d" % n, "kind": "set_complete", "set": n, "name": String(e.get("name", "")),
			"rewards": {"scrub_bucks": int(e.get("scrub_bucks", 0)), "bot_parts": int(e.get("bot_parts", 0))}})
	if bool(col.get("master_claimed", false)):
		var m: Dictionary = cfg.get("all_sets_complete", {})
		out.append({"key": "master", "kind": "master_complete", "sets": int(m.get("required_completed_sets", 0)),
			"rewards": {"scrub_bucks": int(m.get("scrub_bucks", 0)), "bot_parts": int(m.get("bot_parts", 0))}})
	var rs: Dictionary = economy.robots.snapshot()
	for rid in rs.get("unlocked", []):
		if String(rid) != String(rs.get("initial_robot", "")):
			out.append({"key": "robot:" + String(rid), "kind": "robot_unlock", "robot_id": String(rid),
				"parts_left": economy.wallet.bot_parts(), "active_robot": String(rs.get("active", ""))})
	return out

static func keys(economy) -> Array:
	return events(economy).map(func(e): return String(e["key"]))

## Events not yet acknowledged in `meta` (a MetaUiState), in event order.
static func pending(economy, meta) -> Array:
	return events(economy).filter(func(e): return not meta.is_seen(String(e["key"])))

static func _set_entry(cfg: Dictionary, n: int) -> Dictionary:
	for e in cfg.get("set_rewards", []):
		if int(e.get("set", 0)) == n:
			return e
	return {}
