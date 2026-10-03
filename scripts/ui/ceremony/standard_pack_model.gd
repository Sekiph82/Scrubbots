extends RefCounted
## StandardPackModel — preload (res://scripts/ui/ceremony/standard_pack_model.gd).
##
## M43-C005-C006 (SB-M43-064) — validator for the PRESENTATION input of one Standard Card
## Pack opening. The model describes a pack that is ALREADY committed (SB-M43-066 will build
## it from the authoritative transaction); nothing here opens, draws, adds or peeks:
##
##   {presentation_id: String,                       stable one-shot key (never empty)
##    cards: [ {card_id, art, name, rarity,            canonical identity (catalog-checked)
##              is_new: bool,                          NEW at the committed transaction
##              copies_after: int} x 3 ]}              owned count after commit
##
## Fails closed: any count/identity/rarity/NEW-duplicate inconsistency -> {ok:false, reason}.

const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")

const CARD_COUNT := 3

## {ok, reason, model}. `model` is a normalized deep copy (only on ok).
static func validate(model) -> Dictionary:
	if not (model is Dictionary):
		return _fail("not_a_dictionary")
	var pid = model.get("presentation_id", "")
	if not (pid is String) or String(pid).strip_edges().is_empty():
		return _fail("presentation_id_empty")
	var cards = model.get("cards")
	if not (cards is Array) or cards.size() != CARD_COUNT:
		return _fail("card_count")
	var out: Array = []
	var last_copies: Dictionary = {}   ## card_id -> copies_after of its previous row
	for i in range(CARD_COUNT):
		var c = cards[i]
		if not (c is Dictionary):
			return _fail("card_%d_not_a_dictionary" % i)
		var cid := String(c.get("card_id", ""))
		var canon := CollectionCardCatalog.entry(cid)
		if canon.is_empty():
			return _fail("card_%d_unknown_id" % i)
		if String(c.get("art", "")) != String(canon["art"]) or not ResourceLoader.exists(String(canon["art"])):
			return _fail("card_%d_art" % i)
		if String(c.get("name", "")) != String(canon["name"]):
			return _fail("card_%d_name" % i)
		var rarity := String(c.get("rarity", ""))
		if not rarity in CollectionCardCatalog.RARITIES or rarity != String(canon["rarity"]):
			return _fail("card_%d_rarity" % i)
		var is_new = c.get("is_new")
		var copies = c.get("copies_after")
		if not (is_new is bool) or not (copies is int):
			return _fail("card_%d_state" % i)
		# NEW = first copy ever (exactly 1 after commit); DUPLICATE = >= 2 after commit. A card
		# repeated inside the pack must count up by one per row and only its first row may be NEW.
		if (is_new and copies != 1) or (not is_new and copies < 2):
			return _fail("card_%d_copies" % i)
		if last_copies.has(cid) and (is_new or copies != int(last_copies[cid]) + 1):
			return _fail("card_%d_repeat_order" % i)
		last_copies[cid] = copies
		out.append({"card_id": cid, "art": String(canon["art"]), "name": String(canon["name"]),
			"rarity": rarity, "is_new": is_new, "copies_after": copies})
	return {"ok": true, "reason": "", "model": {"presentation_id": String(pid), "cards": out}}

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "model": {}}
