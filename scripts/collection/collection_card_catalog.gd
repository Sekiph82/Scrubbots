extends RefCounted
## CollectionCardCatalog — preload (res://scripts/collection/collection_card_catalog.gd).
##
## M43-C005-C006 (SB-M43-064) — read-only canonical card IDENTITY for presentation:
## CollectionInventory card id ("s<set>_c<k>") -> {set, card, name, rarity, art}. Loaded from
## data/config/collection_card_catalog_v1.json (built from the audited C003 card manifest).
## Content data only: it never owns, counts, adds, opens or grants a card.

const PATH := "res://data/config/collection_card_catalog_v1.json"
const RARITIES := ["COMMON", "RARE", "EPIC", "LEGENDARY"]

static var _cards: Dictionary = {}

## {set, card, name, rarity, art} for `card_id`, or {} when unknown.
static func entry(card_id: String) -> Dictionary:
	return (_all().get(card_id, {}) as Dictionary).duplicate()

static func card_ids() -> Array:
	return _all().keys()

static func _all() -> Dictionary:
	if _cards.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if data is Dictionary:
			_cards = data.get("cards", {})
	return _cards
