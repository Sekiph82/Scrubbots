extends RefCounted
## FeaturedCards — preload (res://scripts/collection/featured_cards.gd).
##
## SB-M44-026 (OWNER_META_PROGRESSION_DESIGN_V01, model B) — reader of the Featured Card
## schedule data/config/featured_cards_v1.json and the ONLY authority for its milestone card
## guarantees. A featured card is a highlight only; packs stay random (CardPackService).
##
## Guarantees: on the FIRST clear of a guarantee level (FirstClearTransaction) one card is granted
## through RewardGrantService under tx "featured_card:L<level>:<card id>" (resource
## "featured_card", handler in EconomyServices), so a duplicate WON, relaunch or snapshot import
## never grants twice. A `card` row grants that card; a `set` row grants the first card of the set
## not owned yet in schedule order, or its `fallback_card` as an ordinary duplicate when the whole
## set is owned.

const PATH := "res://data/config/featured_cards_v1.json"
const TX_PREFIX := "featured_card:"
const RESOURCE := "featured_card"

static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			_data = d
	return _data

## [{level, card}] ascending by level (all 135 cards).
static func schedule() -> Array:
	return data().get("schedule", [])

## The tx id already applied for the guarantee at `level`, or "".
static func applied_tx(reward, level: int) -> String:
	var prefix := "%sL%d:" % [TX_PREFIX, level]
	for tx in reward.applied_ids():
		if String(tx).begins_with(prefix):
			return String(tx)
	return ""

## Grant the guarantee for a first clear of `level` (no-op when none is configured or it was
## already granted). Returns {applied, card}.
static func grant_milestone(economy, level: int) -> Dictionary:
	for g in data().get("guarantees", []):
		if int(g["level"]) != level:
			continue
		if not applied_tx(economy.reward, level).is_empty():
			return {"applied": false, "card": ""}
		var cid := String(g.get("card", ""))
		if g.has("set"):
			cid = String(g["fallback_card"])
			for e in schedule():
				var c := String(e["card"])
				if economy.collection.card_set(c) == int(g["set"]) and economy.collection.owned(c) == 0:
					cid = c
					break
		var ok: bool = economy.reward.grant("%sL%d:%s" % [TX_PREFIX, level, cid], {RESOURCE: 1})
		return {"applied": ok, "card": cid if ok else ""}
	return {"applied": false, "card": ""}

## [{level, card}] of every guarantee already granted, ascending by level (from the reward ledger).
static func milestone_cards(reward) -> Array:
	var out: Array = []
	for tx in reward.applied_ids():
		var t := String(tx)
		if t.begins_with(TX_PREFIX):
			out.append({"level": int(t.get_slice(":", 1).substr(1)), "card": t.get_slice(":", 2)})
	out.sort_custom(func(a, b): return a["level"] < b["level"])
	return out
