extends RefCounted
## PackReceiptLedger — preload (res://scripts/collection/pack_receipt_ledger.gd).
##
## M43-C005-C008 (SB-M43-066) — the durable record of committed card-pack openings. One
## immutable receipt per caller-supplied transaction id, persisted in the canonical save
## through EconomyServices.snapshot()["pack_receipts"]. Written ONLY by
## PackCommitTransaction.commit(); everything else reads.
##
## Receipt (data only, can never grant by itself):
##   {schema: "scrubbots.pack_receipt.v1", tx_id, presentation_id (== tx_id),
##    kind: "standard" | "premium", status: "committed",
##    cards: [{card_id, art, name, rarity, is_new, copies_after}]  3 or 5 rows, service order}
## Card truth is checked by the shipping StandardPackModel / PremiumPackModel validators (the
## receipt must be exactly what the accepted ceremonies consume).
##
## Snapshot {version: 1, receipts: [receipt, ...]} in commit order. Import is strict and
## all-or-nothing (exactly version + receipts). Legacy saves without the section are handled by
## EconomyServices (key absent -> empty ledger), never by passing an empty section here.

const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const PremiumPackModel = preload("res://scripts/ui/ceremony/premium_pack_model.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const SCHEMA := "scrubbots.pack_receipt.v1"
const VERSION := 1
const STATUS_COMMITTED := "committed"
const KINDS := {"standard": 3, "premium": 5}
const CARD_KEYS := ["card_id", "art", "name", "rarity", "is_new", "copies_after"]

## ponytail: one small receipt per opened pack, kept forever; compact if save size ever matters.
var _receipts: Dictionary = {}   ## tx_id -> normalized receipt
var _order: Array = []           ## tx ids in commit order
var _in_flight := ""             ## transient (never persisted): tx currently being committed

## Public reads never reveal the receipt of the commit in flight: it is recorded before the
## durable save, and nothing may present it until that save has succeeded.
func has(tx_id: String) -> bool:
	return _receipts.has(tx_id) and tx_id != _in_flight

func get_receipt(tx_id: String) -> Dictionary:
	if tx_id == _in_flight:
		return {}
	return (_receipts.get(tx_id, {}) as Dictionary).duplicate(true)

func size() -> int:
	return _order.size()

## Coordinator-only: record a NEW validated receipt. False (nothing changed) when invalid or
## the tx id already exists.
func record(receipt) -> bool:
	var v := validate_receipt(receipt)
	if not v["ok"] or _receipts.has(v["receipt"]["tx_id"]):
		return false
	_receipts[v["receipt"]["tx_id"]] = v["receipt"]
	_order.append(v["receipt"]["tx_id"])
	return true

# ------------------------------------------------------------- reentrancy ----

func is_busy() -> bool:
	return not _in_flight.is_empty()

func begin(tx_id: String) -> void:
	_in_flight = tx_id

func end() -> void:
	_in_flight = ""

# ------------------------------------------------------------- receipt truth ----

## {ok, reason, receipt}: `receipt` is a normalized deep copy (copies_after as int).
static func validate_receipt(r) -> Dictionary:
	if typeof(r) != TYPE_DICTIONARY:
		return _fail("not_a_dictionary")
	if r.get("schema") != SCHEMA:
		return _fail("schema")
	var tx = r.get("tx_id")
	if typeof(tx) != TYPE_STRING or String(tx).is_empty() or String(tx) != String(tx).strip_edges():
		return _fail("tx_id")
	if r.get("presentation_id") != tx:
		return _fail("presentation_id")
	var kind = r.get("kind")
	if typeof(kind) != TYPE_STRING or not KINDS.has(kind):
		return _fail("kind")
	if r.get("status") != STATUS_COMMITTED:
		return _fail("status")
	var cards = r.get("cards")
	if typeof(cards) != TYPE_ARRAY or cards.size() != int(KINDS[kind]):
		return _fail("card_count")
	var norm: Array = []
	for c in cards:
		if typeof(c) != TYPE_DICTIONARY or c.size() != CARD_KEYS.size() or not CARD_KEYS.all(func(k): return c.has(k)):
			return _fail("card_shape")
		var copies = IntDomain.exact_int(c["copies_after"])
		if copies == null or typeof(c["is_new"]) != TYPE_BOOL:
			return _fail("card_state")
		norm.append({"card_id": c["card_id"], "art": c["art"], "name": c["name"], "rarity": c["rarity"],
			"is_new": c["is_new"], "copies_after": int(copies)})
	var m := {"presentation_id": tx, "kind": kind, "cards": norm}
	var check: Dictionary = StandardPackModel.validate(m) if kind == "standard" else PremiumPackModel.validate(m)
	if not check["ok"]:
		return _fail("cards:" + String(check["reason"]))
	return {"ok": true, "reason": "", "receipt": {"schema": SCHEMA, "tx_id": tx, "presentation_id": tx,
		"kind": kind, "status": STATUS_COMMITTED, "cards": norm}}

## The ONLY receipt -> presentation bridge: the model the accepted ceremonies consume
## (StandardPackCeremony.create / PremiumPackCeremony.create_premium). Pure data.
static func presentation_model(receipt: Dictionary) -> Dictionary:
	return {"presentation_id": receipt["presentation_id"], "kind": receipt["kind"], "cards": (receipt["cards"] as Array).duplicate(true)}

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "receipt": {}}

# --------------------------------------------------------------- snapshot ----

func snapshot() -> Dictionary:
	return {"version": VERSION, "receipts": _order.map(func(tx): return (_receipts[tx] as Dictionary).duplicate(true))}

## The canonical empty ledger section (what a pre-C008 save means).
static func empty_snapshot() -> Dictionary:
	return {"version": VERSION, "receipts": []}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or s.size() != 2 or not s.has("version") or not s.has("receipts"):
		return false
	if IntDomain.exact_int(s["version"]) != VERSION:
		return false
	var raw = s.get("receipts", null)
	if typeof(raw) != TYPE_ARRAY:
		return false
	var new_receipts := {}
	var new_order: Array = []
	for r in raw:
		var v := validate_receipt(r)
		if not v["ok"] or new_receipts.has(v["receipt"]["tx_id"]):
			return false
		new_receipts[v["receipt"]["tx_id"]] = v["receipt"]
		new_order.append(v["receipt"]["tx_id"])
	_receipts = new_receipts
	_order = new_order
	return true
