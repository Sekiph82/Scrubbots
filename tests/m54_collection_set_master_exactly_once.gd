extends SceneTree
## M54-C001 — SB-M54-016A: every set-specific 9/9 reward + all-15 Master
## Collection (+2500 SB / +20 Bot Parts) granted exactly once.
## Expected values are read straight from the raw config JSON, not through
## EconomyConfig, so a config-loader defect cannot make this suite agree with itself.
## Run: godot --headless --path . -s res://tests/m54_collection_set_master_exactly_once.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")

const CONFIG_PATH := "res://data/config/economy_rewards_v1.json"

var _fail := 0
var _sets := {}   # set_no -> [sb, bp] from raw JSON
var _master := [0, 0]

func _initialize() -> void:
	_raw_config()
	_each_set_in_isolation()
	_master_fires_once_on_fifteenth(range(1, 16), "ascending")
	var rev := range(1, 16)
	rev.reverse()
	_master_fires_once_on_fifteenth(rev, "descending")
	_regrant_attempts()
	print("M54 COLLECTION SET/MASTER EXACTLY-ONCE: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _raw_config() -> void:
	print("[raw config]")
	var coll: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))["collection"]
	for e in coll["set_rewards"]:
		_sets[int(e["set"])] = [int(e["scrub_bucks"]), int(e["bot_parts"])]
	_master = [int(coll["all_sets_complete"]["scrub_bucks"]), int(coll["all_sets_complete"]["bot_parts"])]
	var keys := _sets.keys()
	keys.sort()
	_ok(keys == range(1, 16), "config lists exactly sets 1..15")
	var sb := 0
	var bp := 0
	for s in _sets:
		sb += _sets[s][0]
		bp += _sets[s][1]
	_ok(sb == int(coll["all_individual_set_rewards_total"]["scrub_bucks"]) and bp == int(coll["all_individual_set_rewards_total"]["bot_parts"]),
		"per-set rewards sum to documented total (%d SB / %d BP)" % [sb, bp])
	_ok(_master == [2500, 20], "master bonus is owner-locked +2500 SB / +20 BP (got %s)" % str(_master))
	_ok(int(coll["all_sets_complete"]["required_completed_sets"]) == 15, "master requires all 15 sets")

func _mk() -> Array:
	var w = EconomyWallet.new(0)
	var r = RewardGrantService.new(w)
	var inv = CollectionInventory.new(EconomyConfig.new(), r)
	return [w, inv]

func _set_cards(inv, set_no: int) -> Array:
	var out := []
	for cid in inv.all_card_ids():
		if cid.begins_with("s%d_" % set_no):
			out.append(cid)
	return out

## Adds every card of the set; asserts the set completes only on the 9th card.
func _complete(inv, set_no: int) -> Dictionary:
	var cards := _set_cards(inv, set_no)
	_ok(cards.size() == 9, "set %d has 9 cards" % set_no)
	var last := {}
	for i in cards.size():
		last = inv.add_card(cards[i])
		if i < cards.size() - 1 and inv.is_set_complete(set_no):
			_ok(false, "set %d complete before 9/9 (at %d/9)" % [set_no, i + 1])
	_ok(inv.is_set_complete(set_no), "set %d complete at 9/9" % set_no)
	return last

func _bal(w) -> Array:
	return [w.scrub_bucks(), w.bot_parts()]

func _each_set_in_isolation() -> void:
	print("[each set alone: exact set reward, no master]")
	for s in range(1, 16):
		var m := _mk()
		var w = m[0]
		var inv = m[1]
		var r := _complete(inv, s)
		_ok(_bal(w) == _sets[s], "set %d alone grants exactly %s (got %s)" % [s, str(_sets[s]), str(_bal(w))])
		_ok(bool(r["set_completed"]) and not bool(r["master_completed"]), "set %d alone: set_completed, no master" % s)

func _master_fires_once_on_fifteenth(order: Array, label: String) -> void:
	print("[all 15 %s: per-set deltas + master once]" % label)
	var m := _mk()
	var w = m[0]
	var inv = m[1]
	for n in order.size():
		var s: int = order[n]
		var before := _bal(w)
		var r := _complete(inv, s)
		var delta := [w.scrub_bucks() - before[0], w.bot_parts() - before[1]]
		if n < order.size() - 1:
			_ok(delta == _sets[s] and not bool(r["master_completed"]), "%s #%d set %d delta exactly %s, no master (got %s)" % [label, n + 1, s, str(_sets[s]), str(delta)])
		else:
			var want := [_sets[s][0] + _master[0], _sets[s][1] + _master[1]]
			_ok(delta == want and bool(r["master_completed"]), "%s 15th set %d delta = set + master %s (got %s)" % [label, s, str(want), str(delta)])
	_ok(_bal(w) == [15850, 167], "%s final totals 15850 SB / 167 BP (got %s)" % [label, str(_bal(w))])

func _regrant_attempts() -> void:
	print("[no re-grant: duplicates, pending-claim, remove+re-add]")
	var m := _mk()
	var w = m[0]
	var inv = m[1]
	for s in range(1, 16):
		_complete(inv, s)
	var full := _bal(w)
	_ok(full == [15850, 167], "baseline full collection")
	for s in range(1, 16):
		inv.add_card(_set_cards(inv, s)[0])
	_ok(_bal(w) == full, "duplicate card in every set: nothing re-granted")
	var p: Dictionary = inv.claim_pending_rewards()
	_ok(not bool(p["ok"]) and _bal(w) == full, "claim_pending_rewards after full grant: nothing (ok=%s)" % str(p["ok"]))
	# Drop set 7 below 9/9 and rebuild it: neither set 7 nor master may pay again.
	var cid: String = _set_cards(inv, 7)[0]
	var removed: bool = inv.remove_copies(cid, inv.owned(cid), 0)
	_ok(removed and not inv.is_set_complete(7), "set 7 made incomplete (removed=%s)" % str(removed))
	var r: Dictionary = inv.add_card(cid)
	_ok(inv.is_set_complete(7), "set 7 complete again")
	_ok(_bal(w) == full and not bool(r["master_completed"]), "re-completed set 7: no set/master re-grant (got %s)" % str(_bal(w)))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
