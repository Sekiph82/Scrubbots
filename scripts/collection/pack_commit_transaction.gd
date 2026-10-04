extends RefCounted
## PackCommitTransaction — preload (res://scripts/collection/pack_commit_transaction.gd).
##
## M43-C005-C008 (SB-M43-066) — THE canonical card-pack commit authority for presented pack
## openings. Callers (production: AppState.commit_pack) supply a stable transaction id:
##
##   commit(economy, "standard" | "premium", tx_id, save) ->
##     {ok, replay, receipt, model}  |  {ok:false, reason [, stage, restored]}
##
## New tx id: validate -> snapshot the FULL EconomyServices state (wallet, RewardGrant applied
## ids, Collection, set/master claims, pack RNG, receipt ledger, ...) -> draw + apply ONCE via
## CardPackService (Collection set/master rewards included) -> receipt from the real before /
## after counts, in service draw order -> ledger record -> durable save. Only after the save
## succeeds is the receipt / presentation model returned. Any failure re-imports the snapshot
## (FirstClearTransaction philosophy): nothing partial survives and no model is released.
##
## Committed tx id: the stored receipt + model are returned; nothing is drawn, applied, saved
## or advanced. Same id with the other kind -> "kind_collision", zero mutation. While a commit
## is in flight every nested commit is refused ("in_flight"), so one id can never draw twice.
##
## `fault` is a test-only seam: fault(stage) -> true forces failure at "after_draw",
## "after_ledger" or "save" (the save stage fails before writing).

const PackReceiptLedger = preload("res://scripts/collection/pack_receipt_ledger.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")

static func commit(economy, kind: String, tx_id, save: Callable, fault: Callable = Callable()) -> Dictionary:
	if typeof(tx_id) != TYPE_STRING or String(tx_id).is_empty() or String(tx_id) != String(tx_id).strip_edges():
		return {"ok": false, "reason": "tx_id"}
	if not PackReceiptLedger.KINDS.has(kind):
		return {"ok": false, "reason": "kind"}
	var ledger = economy.pack_receipts
	# Checked FIRST: a nested call (e.g. from inside the save callback) must neither draw again
	# nor see a receipt that is recorded but not yet durably saved.
	if ledger.is_busy():
		return {"ok": false, "reason": "in_flight"}
	if ledger.has(tx_id):
		var stored: Dictionary = ledger.get_receipt(tx_id)
		if stored["kind"] != kind:
			return {"ok": false, "reason": "kind_collision"}
		return {"ok": true, "replay": true, "receipt": stored, "model": PackReceiptLedger.presentation_model(stored)}
	if not save.is_valid():
		return {"ok": false, "reason": "no_save"}
	ledger.begin(tx_id)
	var pre: Dictionary = economy.snapshot()
	var drawn: Array = economy.packs.open_standard() if kind == "standard" else economy.packs.open_premium()
	var failed := ""
	var receipt := {}
	if _hit(fault, "after_draw"):
		failed = "after_draw"
	if failed == "":
		receipt = _receipt(economy, kind, tx_id, pre["collection"]["owned"], drawn)
		if receipt.is_empty():
			failed = "receipt"
	if failed == "":
		if not ledger.record(receipt):
			failed = "ledger"
		elif _hit(fault, "after_ledger"):
			failed = "after_ledger"
	if failed == "":
		if _hit(fault, "save"):
			failed = "save"
		else:
			var r = save.call()
			if typeof(r) != TYPE_DICTIONARY or not bool(r.get("ok", false)):
				failed = "save"
	if failed != "":
		var restored: bool = economy.import_snapshot(pre)
		ledger.end()
		return {"ok": false, "reason": "rolled_back", "stage": failed, "restored": restored}
	ledger.end()
	var stored_new: Dictionary = ledger.get_receipt(tx_id)
	return {"ok": true, "replay": false, "receipt": stored_new, "model": PackReceiptLedger.presentation_model(stored_new)}

## Committed receipt for `tx_id` ({} when none). Read-only.
static func receipt(economy, tx_id: String) -> Dictionary:
	return economy.pack_receipts.get_receipt(tx_id)

## Presentation model for a committed `tx_id` ({} when none). Read-only; never draws.
static func presentation_model(economy, tx_id: String) -> Dictionary:
	var r: Dictionary = economy.pack_receipts.get_receipt(tx_id)
	return {} if r.is_empty() else PackReceiptLedger.presentation_model(r)

## Rows in service draw order. Counts run from the pre-commit owned count, one copy per row,
## so a card repeated inside the pack reads NEW (only if it was unowned) then DUPLICATE x2, x3...
## Cross-checked against the live post-apply counts; any mismatch fails the commit.
static func _receipt(economy, kind: String, tx_id: String, before: Dictionary, drawn: Array) -> Dictionary:
	if drawn.size() != int(PackReceiptLedger.KINDS[kind]):
		return {}
	var running := {}
	var cards: Array = []
	for cid in drawn:
		var n := int(running.get(cid, int(before.get(cid, 0)))) + 1
		running[cid] = n
		var e: Dictionary = CollectionCardCatalog.entry(cid)
		cards.append({"card_id": cid, "art": e.get("art", ""), "name": e.get("name", ""),
			"rarity": economy.collection.card_rarity(cid), "is_new": n == 1, "copies_after": n})
	for cid in running:
		if economy.collection.owned(cid) != int(running[cid]):
			return {}
	var v := PackReceiptLedger.validate_receipt({"schema": PackReceiptLedger.SCHEMA, "tx_id": tx_id, "presentation_id": tx_id,
		"kind": kind, "status": PackReceiptLedger.STATUS_COMMITTED, "cards": cards})
	return v["receipt"] if v["ok"] else {}

static func _hit(fault: Callable, stage: String) -> bool:
	return fault.is_valid() and bool(fault.call(stage))
