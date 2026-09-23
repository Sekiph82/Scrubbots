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

const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")

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
