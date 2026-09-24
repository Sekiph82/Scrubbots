extends RefCounted
## CollectionInventory — preload
## (res://scripts/collection/collection_inventory.gd).
##
## 15 sets x 9 cards (SB-M39-045). Owns a card catalog derived from the config
## rarity profiles, per-card owned counts (non-negative), derived set-completion
## state, and idempotent per-set + master completion reward transactions
## (SB-M39-047/047A/047C). The first owned copy of any card is protected;
## CardsExchangeService only touches copies above that.
##
## Reward grants route through RewardGrantService (idempotent). Set/master
## completion transaction ids persist through snapshot so relaunch/sync cannot
## duplicate rewards.

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const SETS := 15
const CARDS_PER_SET := 9
const RARITY_ORDER := ["COMMON", "RARE", "EPIC", "LEGENDARY"]

var _config
var _reward
## card_id -> {set:int, rarity:String}
var _catalog: Dictionary = {}
## set -> Array[card_id] in catalog order
var _set_cards: Dictionary = {}
var _owned: Dictionary = {}                 ## card_id -> count
var _set_reward_claimed: Dictionary = {}    ## set(int) -> true
var _master_claimed := false

func _init(config, reward) -> void:
	_config = config
	_reward = reward
	_build_catalog()

func _build_catalog() -> void:
	var coll = _config.collection_config()
	var set_rewards = coll.get("set_rewards", [])
	for entry in set_rewards:
		var set_no := int(entry.get("set", 0))
		var profile := String(entry.get("rarity_profile", "4C/2R/2E/1L"))
		var cards: Array = []
		var k := 0
		for token in profile.split("/"):
			token = token.strip_edges()
			if token.is_empty():
				continue
			var count := int(token.substr(0, token.length() - 1))
			var code := token.substr(token.length() - 1, 1)
			var rarity := _rarity_from_code(code)
			for _i in range(count):
				var cid := "s%d_c%d" % [set_no, k]
				_catalog[cid] = {"set": set_no, "rarity": rarity}
				cards.append(cid)
				k += 1
		_set_cards[set_no] = cards

func _rarity_from_code(code: String) -> String:
	match code:
		"C": return "COMMON"
		"R": return "RARE"
		"E": return "EPIC"
		"L": return "LEGENDARY"
	return "COMMON"

# --------------------------------------------------------------- queries ----

func all_card_ids() -> Array:
	return _catalog.keys()

func card_rarity(card_id: String) -> String:
	return String(_catalog.get(card_id, {}).get("rarity", ""))

func owned(card_id: String) -> int:
	return int(_owned.get(card_id, 0))

func is_set_complete(set_no: int) -> bool:
	var cards = _set_cards.get(set_no, [])
	if cards.is_empty():
		return false
	for cid in cards:
		if owned(cid) < 1:
			return false
	return true

func completed_set_count() -> int:
	var n := 0
	for s in range(1, SETS + 1):
		if is_set_complete(s):
			n += 1
	return n

# --------------------------------------------------------------- mutation ----

## Add one owned copy of a card, then process any newly-completed set + master
## rewards idempotently. Returns {added, set_completed, master_completed}.
func add_card(card_id: String) -> Dictionary:
	if not _catalog.has(card_id):
		return {"added": false, "reason": "unknown_card"}
	_owned[card_id] = owned(card_id) + 1
	var set_no := int(_catalog[card_id]["set"])
	var result := {"added": true, "card_id": card_id, "set_completed": false, "master_completed": false}
	_process_set_completion(set_no, result)
	_process_master_completion(result)
	return result

## Canonical Collection claim (M39 V04, F-M39-V03-005): (re)process every
## complete-but-unclaimed set reward and the master reward. Normally add_card
## already granted them; this recovers a grant that could not apply at the time.
## Idempotent via the stable tx ids. ok only when something newly committed.
func claim_pending_rewards() -> Dictionary:
	var claimed: Array = []
	var result := {"set_completed": false, "master_completed": false}
	for set_no in range(1, SETS + 1):
		result["set_completed"] = false
		_process_set_completion(set_no, result)
		if result["set_completed"]:
			claimed.append(set_no)
	result["master_completed"] = false
	_process_master_completion(result)
	var any: bool = not claimed.is_empty() or bool(result["master_completed"])
	return {"ok": any, "sets": claimed, "master": result["master_completed"],
		"reason": "" if any else "nothing_to_claim"}

func _process_set_completion(set_no: int, result: Dictionary) -> void:
	if _set_reward_claimed.has(set_no):
		return
	if not is_set_complete(set_no):
		return
	var reward := _set_reward_for(set_no)
	var tx := "collection_set:%d" % set_no
	if _reward.grant(tx, reward) or _reward.already_applied(tx):
		_set_reward_claimed[set_no] = true
		result["set_completed"] = true

func _process_master_completion(result: Dictionary) -> void:
	if _master_claimed:
		return
	if completed_set_count() < SETS:
		return
	var coll = _config.collection_config()
	var master = coll.get("all_sets_complete", {})
	var reward := {
		EconomyWallet.SCRUB_BUCKS: int(master.get("scrub_bucks", 0)),
		EconomyWallet.BOT_PARTS: int(master.get("bot_parts", 0)),
	}
	var tx := "collection_master"
	if _reward.grant(tx, reward) or _reward.already_applied(tx):
		_master_claimed = true
		result["master_completed"] = true

func _set_reward_for(set_no: int) -> Dictionary:
	var coll = _config.collection_config()
	for entry in coll.get("set_rewards", []):
		if int(entry.get("set", 0)) == set_no:
			return {
				EconomyWallet.SCRUB_BUCKS: int(entry.get("scrub_bucks", 0)),
				EconomyWallet.BOT_PARTS: int(entry.get("bot_parts", 0)),
			}
	return {}

## Add `count` copies back (used by CardsExchangeService rollback). Does not
## re-trigger set/master reward processing (those are already claimed if the set
## was complete; a rollback of an exchange never crosses a new completion).
func add_copies(card_id: String, count: int) -> void:
	if not _catalog.has(card_id) or count <= 0:
		return
	_owned[card_id] = owned(card_id) + count

## Remove `count` copies of a card (used by CardsExchangeService). Never drops
## below `protected_min` (default 1). Returns true on success. Atomic.
func remove_copies(card_id: String, count: int, protected_min: int = 1) -> bool:
	if count <= 0:
		return false
	if owned(card_id) - count < protected_min:
		return false
	_owned[card_id] = owned(card_id) - count
	return true

## SB-M39-013: choose an eligible missing card from an unlocked incomplete set.
## Returns "" if none (caller applies the 500 SB fallback).
func first_missing_eligible_card() -> String:
	for s in range(1, SETS + 1):
		if is_set_complete(s):
			continue
		for cid in _set_cards.get(s, []):
			if owned(cid) < 1:
				return cid
	return ""

# --------------------------------------------------------------- snapshot ----

func snapshot() -> Dictionary:
	return {
		"owned": _owned.duplicate(),
		"set_reward_claimed": _set_reward_claimed.keys(),
		"master_claimed": _master_claimed,
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var owned_raw = s.get("owned", {})
	if typeof(owned_raw) != TYPE_DICTIONARY:
		return false
	# Canonical validation (F-M39-009): reject unknown card ids and fractional/
	# negative counts. Nothing is stored unless the whole snapshot is canonical.
	var new_owned: Dictionary = {}
	for cid in owned_raw.keys():
		var key := String(cid)
		if not _catalog.has(key):
			return false   # unknown card id => noncanonical, fail closed
		var v = IntDomain.nonneg_int(owned_raw[cid])
		if v == null:
			return false
		new_owned[key] = v
	# Set-reward-claimed ids must be exact ints in 1..SETS.
	var claimed_raw = s.get("set_reward_claimed", [])
	if typeof(claimed_raw) != TYPE_ARRAY:
		return false
	var new_claimed: Dictionary = {}
	for s_no in claimed_raw:
		var si = IntDomain.exact_int(s_no)
		if si == null or si < 1 or si > SETS:
			return false
		new_claimed[si] = true
	var master = s.get("master_claimed", false)
	if typeof(master) != TYPE_BOOL:
		return false
	# Claimed-set coherence (M39 V03, F-M39-V02-010): a claimed set MUST be
	# actually 9/9 owned in the same snapshot; master_claimed MUST imply all 15
	# sets complete. Otherwise the persisted state is internally inconsistent
	# and fails closed.
	for set_no in new_claimed.keys():
		var complete := true
		for cid in _set_cards.get(set_no, []):
			if int(new_owned.get(cid, 0)) < 1:
				complete = false
				break
		if not complete:
			return false
	if master:
		var all_complete := true
		for si in range(1, SETS + 1):
			if not new_claimed.has(si):
				all_complete = false
				break
		if not all_complete:
			return false
	# All-or-nothing apply.
	_owned = new_owned
	_set_reward_claimed = new_claimed
	_master_claimed = master
	return true
