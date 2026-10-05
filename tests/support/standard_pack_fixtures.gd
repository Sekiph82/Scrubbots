extends RefCounted
## Deterministic COMMITTED Standard pack presentation models (SB-M43-064 tests/evidence).
## Built from the canonical card catalog only; no CollectionInventory, no CardPackService.

const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")

static func card(card_id: String, is_new: bool, copies_after: int) -> Dictionary:
	var e := CollectionCardCatalog.entry(card_id)
	return {"card_id": card_id, "art": e.get("art", ""), "name": e.get("name", ""), "rarity": e.get("rarity", ""),
		"is_new": is_new, "copies_after": copies_after}

## Mixed: COMMON NEW, RARE DUPLICATE (x2), LEGENDARY NEW.
static func mixed(pid: String = "std_fixture_mixed") -> Dictionary:
	return {"presentation_id": pid, "cards": [card("s3_c1", true, 1), card("s7_c4", false, 2), card("s15_c8", true, 1)]}

## Same card twice inside one pack: NEW then DUPLICATE x2, plus an EPIC duplicate x5.
static func repeat(pid: String = "std_fixture_repeat") -> Dictionary:
	return {"presentation_id": pid, "cards": [card("s2_c0", true, 1), card("s2_c0", false, 2), card("s9_c6", false, 5)]}

## Same card three times inside one pack (SB-M43-067): FIRST COPY, EXTRAS x1, EXTRAS x2.
static func triple(pid: String = "std_fixture_triple") -> Dictionary:
	return {"presentation_id": pid, "cards": [card("s8_c3", true, 1), card("s8_c3", false, 2), card("s8_c3", false, 3)]}

## All DUPLICATE, different extras (SB-M43-067): EXTRAS x1, x3, x8.
static func all_duplicate(pid: String = "std_fixture_all_duplicate") -> Dictionary:
	return {"presentation_id": pid, "cards": [card("s3_c1", false, 2), card("s7_c4", false, 4), card("s12_c8", false, 9)]}

## All NEW: COMMON, RARE, EPIC — every card routes to Collection (owner review harness).
static func all_new(pid: String = "std_fixture_all_new") -> Dictionary:
	return {"presentation_id": pid, "cards": [card("s1_c0", true, 1), card("s5_c5", true, 1), card("s11_c7", true, 1)]}
