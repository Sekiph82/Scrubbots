extends "res://scripts/ui/ceremony/standard_pack_ceremony.gd"
## PremiumPackCeremony — preload (res://scripts/ui/ceremony/premium_pack_ceremony.gd).
##
## M43-C005-C007 (SB-M43-065) — the shipping Premium Card Pack opening. Same owner-accepted
## interaction grammar, state machine, cadence, card views, destinations and routing as the
## Standard ceremony (it IS that ceremony, specialised):
##
##   Premium Pack alone -> TAP 1 -> Premium frames 01..09 (0.40 s / 0.22 s x7 / 0.30 s) ->
##   the 5 committed cards rise from frame 09's five card backs (card i from back i) -> pack
##   gone -> 5-card hold, centred 3 + 2 in
##   draw order (0,1,2 / 3,4) -> Collection upper-left, Cards Exchange upper-right -> TAP 2 ->
##   each card in order: NEW -> Collection, DUPLICATE -> Cards Exchange -> complete once.
##
## Differences from Standard: the owner-approved Premium frame family, the PREMIUM PACK title,
## a PremiumPackModel (exactly 5 cards, card 0 = the service's Rare-or-better draw, never
## reordered) and the 3 + 2 hold layout. PRESENTATION ONLY, like Standard: no pack opening,
## RNG, grant, Collection / Cards Exchange mutation, save or navigation.

const PremiumPackModel = preload("res://scripts/ui/ceremony/premium_pack_model.gd")
const PREMIUM_SELF_PATH := "res://scripts/ui/ceremony/premium_pack_ceremony.gd"
## Owner-approved Premium opening (M43-C005-C002 FINAL OWNER ACCEPTANCE), byte-identical.
const PREMIUM_FRAME_DIR := "res://assets/ui/final/rewards/pack_opening/premium/"
const ROW_GAP := 28.0
const ROWS := [[0, 1, 2], [3, 4]]   ## draw order, row-major
## Frame 09's five card backs (C002 PACK_ASSET_MANIFEST_V01 card_overlays: centre x, top y + half
## card height 133, in 1024x1536 frame space), left to right. Card i rises from back i.
const BACKS := [Vector2(278, 415), Vector2(395, 409), Vector2(512, 403), Vector2(629, 409), Vector2(746, 415)]
const FRAME_SIZE := Vector2(1024, 1536)

## {ok, reason, popup}: a ceremony only for a valid committed Premium model; otherwise fail closed.
static func create_premium(model, reduced := false) -> Dictionary:
	var v := PremiumPackModel.validate(model)
	if not v["ok"]:
		return {"ok": false, "reason": v["reason"], "popup": null}
	var script: GDScript = load(PREMIUM_SELF_PATH)
	return {"ok": true, "reason": "", "popup": script.new(v["model"], reduced)}

func _init(model: Dictionary = {}, reduced := false) -> void:
	super(model, reduced)
	popup_id = "premium_pack"
	name = "Popup_premium_pack"
	set_title(UiText.t("PACK_PREMIUM_TITLE"))
	_title_l.text = UiText.t("PACK_PREMIUM_TITLE")

func _frame_paths() -> Array:
	return PACK_FRAMES.map(func(f): return PREMIUM_FRAME_DIR + f)

## Standard geometry (title, hint, stage, destinations, card width), then the five card slots
## as a centred 3 + 2 block between the destinations and the hint.
func _layout() -> void:
	super()
	var sz := _layer.size
	if sz.x <= 0.0 or sz.y <= 0.0 or _cards.size() != 5:
		return
	var cw := minf(CARD_MAX_W, (sz.x - 2.0 * EDGE - 2.0 * CARD_GAP) / 3.0)
	var card_h := cw * 1.5 + CardView.LABEL_H
	var top := (sz.y - (2.0 * card_h + ROW_GAP)) * 0.5
	for r in range(ROWS.size()):
		var row: Array = ROWS[r]
		var row_w := row.size() * cw + (row.size() - 1) * CARD_GAP
		for j in range(row.size()):
			var i: int = row[j]
			var slot := Vector2((sz.x - row_w) * 0.5 + cw * 0.5 + j * (cw + CARD_GAP), top + r * (card_h + ROW_GAP) + cw * 0.75)
			var origin: Vector2 = _stage.position + _stage.size * (BACKS[i] / FRAME_SIZE)
			_cards[i].set_path(origin, slot, _dest[destination_of(_model["cards"][i])].position + DEST_BOX * 0.5)
