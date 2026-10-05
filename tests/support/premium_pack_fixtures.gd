extends RefCounted
## Deterministic COMMITTED Premium pack presentation models (SB-M43-065 tests/evidence/review).
## Built from the canonical card catalog only; no CollectionInventory, no CardPackService.
## Every fixture keeps card 0 Rare-or-better (CardPackService's guaranteed first draw).

const Std = preload("res://tests/support/standard_pack_fixtures.gd")

static func _model(pid: String, cards: Array) -> Dictionary:
	return {"presentation_id": pid, "kind": "premium", "cards": cards}

## Mixed: EPIC NEW (guaranteed), COMMON DUP x2, COMMON NEW, RARE DUP x3, COMMON NEW.
static func mixed(pid: String = "prem_fixture_mixed") -> Dictionary:
	return _model(pid, [Std.card("s4_c6", true, 1), Std.card("s2_c1", false, 2), Std.card("s9_c3", true, 1),
		Std.card("s11_c4", false, 3), Std.card("s14_c0", true, 1)])

## All NEW: LEGENDARY (guaranteed), COMMON, RARE, EPIC, COMMON.
static func all_new(pid: String = "prem_fixture_all_new") -> Dictionary:
	return _model(pid, [Std.card("s15_c6", true, 1), Std.card("s1_c2", true, 1), Std.card("s6_c5", true, 1),
		Std.card("s8_c7", true, 1), Std.card("s12_c0", true, 1)])

## Duplicate-heavy (SB-M43-067): all DUPLICATE with different extras, card 0 still Rare-or-better:
## EPIC x2, COMMON x1, x5, x3, x10.
static func all_duplicate(pid: String = "prem_fixture_all_duplicate") -> Dictionary:
	return _model(pid, [Std.card("s4_c6", false, 3), Std.card("s2_c1", false, 2), Std.card("s9_c3", false, 6),
		Std.card("s11_c4", false, 4), Std.card("s14_c0", false, 11)])

## Repeats: RARE NEW then DUP 2, DUP 3 (guaranteed card repeated), COMMON DUP 4 then DUP 5.
static func repeat(pid: String = "prem_fixture_repeat") -> Dictionary:
	return _model(pid, [Std.card("s5_c4", true, 1), Std.card("s5_c4", false, 2), Std.card("s5_c4", false, 3),
		Std.card("s10_c1", false, 4), Std.card("s10_c1", false, 5)])
