extends RefCounted
## CardPackService — preload
## (res://scripts/collection/card_pack_service.gd).
##
## Standard pack = 3 eligible draws; Premium pack = 5 eligible draws with at
## least one Rare-or-better (SB-M39-046). Duplicates allowed. Drawn cards are
## added to CollectionInventory (which may complete sets).
##
## RNG is INJECTED (a RandomNumberGenerator) so tests are deterministic; the
## production default seeds from the OS, never a globally-fixed test seed.
## M43-C005-C008: the generator state is part of the canonical save (snapshot/import), so a
## failed pack commit restores it exactly and a reload continues the same sequence.
##
## LOW-LEVEL AUTHORITY: open_standard()/open_premium() draw AND apply at once and keep no
## receipt. Their only callers are the M39 `standard_card_packs` / `premium_card_packs`
## reward handlers (grant-and-resolve). Anything that PRESENTS a pack opening must go through
## PackCommitTransaction.commit() (res://scripts/collection/pack_commit_transaction.gd),
## which owns the durable receipt; presentation never calls these directly.

const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")
const U32 := 0xFFFFFFFF

const STANDARD_DRAWS := 3
const PREMIUM_DRAWS := 5

var _inventory: CollectionInventory
var _rng: RandomNumberGenerator
var _card_ids: Array
var _rare_or_better: Array

func _init(inventory: CollectionInventory, rng: RandomNumberGenerator = null) -> void:
	_inventory = inventory
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()
	_card_ids = inventory.all_card_ids()
	_rare_or_better = []
	for cid in _card_ids:
		if inventory.card_rarity(cid) != "COMMON":
			_rare_or_better.append(cid)

func _draw_any() -> String:
	return _card_ids[_rng.randi_range(0, _card_ids.size() - 1)]

func _draw_rare_or_better() -> String:
	return _rare_or_better[_rng.randi_range(0, _rare_or_better.size() - 1)]

## Open a standard pack: 3 eligible draws, duplicates allowed. Returns the drawn
## card ids.
func open_standard() -> Array:
	var drawn: Array = []
	for _i in range(STANDARD_DRAWS):
		var cid := _draw_any()
		drawn.append(cid)
		_inventory.add_card(cid)
	return drawn

## Open a premium pack: 5 eligible draws with >=1 Rare-or-better guaranteed.
func open_premium() -> Array:
	var drawn: Array = []
	# Guarantee slot first.
	var guaranteed := _draw_rare_or_better()
	drawn.append(guaranteed)
	_inventory.add_card(guaranteed)
	for _i in range(PREMIUM_DRAWS - 1):
		var cid := _draw_any()
		drawn.append(cid)
		_inventory.add_card(cid)
	return drawn

## Grant a single guaranteed-new eligible card (used by Gift Meter 1000
## milestone). Returns the card id granted, or "" if none was eligible (caller
## applies the 500 SB fallback).
func grant_guaranteed_new() -> String:
	var cid := _inventory.first_missing_eligible_card()
	if cid.is_empty():
		return ""
	_inventory.add_card(cid)
	return cid

# --------------------------------------------------------------- snapshot ----

## RNG continuation, as two exact 32-bit halves (the JSON save cannot carry a 64-bit int).
func snapshot() -> Dictionary:
	var st: int = _rng.state
	return {"rng": {"hi": (st >> 32) & U32, "lo": st & U32}}

## Strict, all-or-nothing: the section must be exactly {rng: {hi, lo}}. Legacy saves without
## the section are handled by EconomyServices (key absent -> this is never called).
func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or s.size() != 1 or not s.has("rng"):
		return false
	var r = s["rng"]
	if typeof(r) != TYPE_DICTIONARY or r.size() != 2:
		return false
	var hi = IntDomain.exact_int(r.get("hi", null))
	var lo = IntDomain.exact_int(r.get("lo", null))
	if hi == null or lo == null or hi < 0 or hi > U32 or lo < 0 or lo > U32:
		return false
	_rng.state = (int(hi) << 32) | int(lo)
	return true
