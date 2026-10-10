extends RefCounted
## CollectionScreen — preload (res://scripts/ui/collection/collection_screen.gd).
##
## M43-C007 (SB-M43-090..101) — the Collection destination and its Collection-owned Cards
## Exchange, all in the approved popup family on the app ModalStack, every value live:
##
##   album        15 canonical sets x 9 cards (135): per set N/9, rarity burden (owned / total per
##                rarity), exact set reward + its claimed state, Master Collection reward + state
##   set detail   9 slots: owned -> canonical art, name, rarity, NEW (not yet viewed) / EXTRAS xN;
##                not owned -> the approved unknown-card silhouette + rarity only (no art leak)
##   card detail  full art, name, rarity, owned count, protected first copy, EXTRAS xN, live SB
##                value per extra, EXCHANGE 1 / EXCHANGE ALL OF THIS CARD
##   exchange     every card with extras + total, EXCHANGE ALL EXTRAS
##
## Truth: CollectionInventory (counts, set/master claims), CollectionCardCatalog (identity),
## CardsExchangeService (protected floor 1, values Common 25 / Rare 75 / Epic 200 / Legendary
## 500 from config). Every exchange is confirmed and committed by ProductionActionFacade
## (atomic removal + SB credit + save); the UI never edits counts or balances. "Viewed" marks
## (meta_ui `card:<id>`) are presentation only. Pack opening entry is NOT here (SB-M43-098).

const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")

const ART := {
	"silhouette": "res://assets/ui/final/collection/states/card_unknown_silhouette.png",
	"set_complete": "res://assets/ui/final/collection/collection_complete_emblem.png",
	"master": "res://assets/ui/final/collection/master_collection_emblem.png",
	"exchange": "res://assets/ui/final/cards_exchange/cards_exchange_header_emblem.png",
	"sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
}
const RARITY_COLOR := {"COMMON": Color(0.47, 0.53, 0.62), "RARE": Color(0.10, 0.45, 0.92),
	"EPIC": Color(0.56, 0.25, 0.86), "LEGENDARY": Color(0.92, 0.62, 0.05)}
const RARITY_SHORT := {"COMMON": "C", "RARE": "R", "EPIC": "E", "LEGENDARY": "L"}
const LIST_H := 1020.0

## ponytail: keeps every card art loaded once viewed (135 small textures max); drop if memory matters.
static var _tex_cache: Dictionary = {}

static func _tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]

static func card_key(card_id: String) -> String:
	return "card:" + card_id

## Cards owned but never viewed in a set detail (presentation "NEW").
static func unseen_cards(economy) -> Array:
	return economy.collection.all_card_ids().filter(func(c): return economy.collection.owned(c) > 0 and not economy.meta_ui.is_seen(card_key(c)))

# ===================================================================== album ==

static func open_album(stack, app) -> BasePopup:
	var e = app.economy
	var p := BasePopup.new("collection")
	p.set_frame("large")
	p.set_title(UiText.t("COLLECTION_TITLE"))
	var head := BasePopup.body_label("", 28, BasePopup.ROYAL_EDGE)
	head.name = "Summary"
	p.get_content().add_child(head)
	p.add_action("exchange", UiText.t("COLLECTION_OPEN_EXCHANGE"), "primary", false)
	var scroll := ScrollContainer.new()
	scroll.name = "SetList"
	scroll.custom_minimum_size = Vector2(0, LIST_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Sets"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	for row in e.config.collection_config().get("set_rewards", []):
		var n := int(row["set"])
		list.add_child(_set_row(p, e, n, row))
	list.add_child(_master_row(e))
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c): _on_album_action(stack, app, p, id))
	_refresh_album(p, e)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _set_row(p: BasePopup, e, n: int, row: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "Set_%d" % n
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	card.add_child(h)
	var thumb := HomeStyle.art("Thumb")
	thumb.custom_minimum_size = Vector2(74, 92)
	h.add_child(thumb)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := BasePopup.body_label(UiText.t("COLLECTION_SET_ROW", [n, String(row.get("name", ""))]), 26, BasePopup.INK)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	for k in ["Progress", "Burden", "Reward"]:
		var l := BasePopup.body_label("", 21, BasePopup.INK)
		l.name = k
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(l)
	var b := p.add_action("set:%d" % n, UiText.t("COLLECTION_VIEW"), "secondary", false, "", h)
	b.custom_minimum_size = Vector2(150, 80)
	return card

static func _master_row(e) -> Control:
	var card := PanelContainer.new()
	card.name = "MasterRow"
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROYAL, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	card.add_child(h)
	var icon := HomeStyle.art("Icon")
	icon.texture = load(ART["master"])
	icon.custom_minimum_size = Vector2(84, 84)
	h.add_child(icon)
	var l := BasePopup.body_label("", 22, BasePopup.INK)
	l.name = "MasterText"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(l)
	return card

## Album values, all re-read live (also after an exchange / pack grant).
static func _refresh_album(p: BasePopup, e) -> void:
	var col: Dictionary = e.collection.snapshot()
	var claimed: Array = (col.get("set_reward_claimed", []) as Array).map(func(x): return int(x))
	var unique := 0
	for cid in e.collection.all_card_ids():
		if e.collection.owned(cid) > 0:
			unique += 1
	var summary := UiText.t("COLLECTION_SUMMARY", [unique, e.collection.all_card_ids().size(), e.collection.completed_set_count(), 15])
	# M43-C007R (R07-005): honest pity state, only when a configured guarantee is due.
	if e.pack_pity != null and e.pack_pity.guaranteed_next() and not e.collection.first_missing_eligible_card().is_empty():
		summary += "\n" + UiText.t("COLLECTION_PITY_NEXT")
	(p.find_child("Summary", true, false) as Label).text = summary
	for row in e.config.collection_config().get("set_rewards", []):
		var n := int(row["set"])
		var card = p.find_child("Set_%d" % n, true, false)
		var have := 0
		var burden := {}
		for k in range(9):
			var cid := "s%d_c%d" % [n, k]
			var r := String(e.collection.card_rarity(cid))
			var b: Array = burden.get(r, [0, 0])
			b[1] += 1
			if e.collection.owned(cid) > 0:
				have += 1
				b[0] += 1
			burden[r] = b
		var parts: Array = []
		for r in ["COMMON", "RARE", "EPIC", "LEGENDARY"]:
			if burden.has(r):
				parts.append("%s %d/%d" % [RARITY_SHORT[r], burden[r][0], burden[r][1]])
		(card.find_child("Progress", true, false) as Label).text = UiText.t("COLLECTION_PROGRESS", [have, 9])
		(card.find_child("Burden", true, false) as Label).text = " · ".join(parts)
		var rw := UiText.t("COLLECTION_REWARD", [UiText.num(int(row.get("scrub_bucks", 0))), UiText.num(int(row.get("bot_parts", 0)))])
		(card.find_child("Reward", true, false) as Label).text = rw + "  " + UiText.t("COLLECTION_CLAIMED" if claimed.has(n) else "COLLECTION_NOT_CLAIMED")
		var thumb: TextureRect = card.find_child("Thumb", true, false)
		thumb.texture = _tex(ART["set_complete"] if claimed.has(n) else _first_owned_art(e, n))
	var m: Dictionary = e.config.collection_config().get("all_sets_complete", {})
	(p.find_child("MasterText", true, false) as Label).text = UiText.t("COLLECTION_MASTER_ROW", [e.collection.completed_set_count(), 15,
		UiText.num(int(m.get("scrub_bucks", 0))), UiText.num(int(m.get("bot_parts", 0))),
		UiText.t("COLLECTION_CLAIMED" if bool(col.get("master_claimed", false)) else "COLLECTION_NOT_CLAIMED")])

static func _first_owned_art(e, n: int) -> String:
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if e.collection.owned(cid) > 0:
			return String(CollectionCardCatalog.entry(cid)["art"])
	return ART["silhouette"]

## One detail at a time: the album stays latched while a detail is open and re-arms (with
## refreshed live values) when it closes.
static func _on_album_action(stack, app, p: BasePopup, id: String) -> void:
	var back := func():
		if is_instance_valid(p) and p.is_open():
			_refresh_album(p, app.economy)
			p.rearm()
	if id == "exchange":
		if open_exchange(stack, app, back) == null:
			p.rearm()
	elif id.begins_with("set:"):
		if open_set(stack, app, int(id.substr(4)), back) == null:
			p.rearm()

# ================================================================= set detail ==

static func open_set(stack, app, n: int, on_close: Callable = Callable()) -> BasePopup:
	var e = app.economy
	var cfg_row := {}
	for row in e.config.collection_config().get("set_rewards", []):
		if int(row["set"]) == n:
			cfg_row = row
	if cfg_row.is_empty():
		return null
	var p := BasePopup.new("collection_set")
	p.set_frame("large")
	p.set_title(UiText.t("COLLECTION_SET_ROW", [n, String(cfg_row.get("name", ""))]))
	var grid := GridContainer.new()
	grid.name = "Cards"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
	grid.add_theme_constant_override("v_separation", UiTokens.SPACE_SM)
	var center := CenterContainer.new()
	center.add_child(grid)
	p.get_content().add_child(center)
	var newly_seen: Array = []
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		grid.add_child(_tile(p, e, cid))
		if e.collection.owned(cid) > 0 and e.meta_ui.mark_seen(card_key(cid)):
			newly_seen.append(cid)
	p.set_meta("newly_seen", newly_seen)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id.begins_with("card:"):
			if open_card(stack, app, id.substr(5), func(): _refresh_set(p, e)) == null:
				p.rearm())
	p.closed.connect(func(_r):
		if on_close.is_valid():
			on_close.call(), CONNECT_ONE_SHOT)
	if not newly_seen.is_empty():
		app.mark_dirty()   # presentation marks: flushed at the next lifecycle boundary, no save per view
	if not stack.push(p):
		p.free()
		return null
	return p

static func _tile(p: BasePopup, e, cid: String) -> Control:
	var cat := CollectionCardCatalog.entry(cid)
	var owned: int = e.collection.owned(cid)
	var tile := VBoxContainer.new()
	tile.name = "Tile_" + cid
	tile.set_meta("card_id", cid)
	tile.add_theme_constant_override("separation", 2)
	var face := Control.new()
	face.name = "Face"
	face.custom_minimum_size = Vector2(210, 300)
	tile.add_child(face)
	var art := HomeStyle.art("CardArt")
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = _tex(String(cat["art"]) if owned > 0 else ART["silhouette"])
	face.add_child(art)
	var state := _chip("", Color(0.2, 0.66, 0.14), 20)
	state.name = "State"
	state.set_anchors_preset(Control.PRESET_CENTER_TOP)
	state.grow_horizontal = Control.GROW_DIRECTION_BOTH
	face.add_child(state)
	var name_l := BasePopup.body_label(String(cat["name"]) if owned > 0 else UiText.t("COLLECTION_NOT_FOUND"), 20, BasePopup.INK)
	name_l.name = "Name"
	tile.add_child(name_l)
	var r := String(cat["rarity"])
	var rc := _chip(UiText.t("RARITY_" + r), RARITY_COLOR[r], 18)
	rc.name = "Rarity"
	rc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_child(rc)
	var cnt := BasePopup.body_label("", 20, BasePopup.INK)
	cnt.name = "Count"
	tile.add_child(cnt)
	if owned > 0:
		var b := p.add_action("card:" + cid, UiText.t("COLLECTION_DETAILS"), "secondary", false, "", tile)
		b.custom_minimum_size = Vector2(0, 64)
	_fill_tile(tile, e, cid)
	return tile

## Tile state: NEW (owned, not viewed before this visit), EXTRAS xN (copies above the protected
## first), count; unowned shows nothing but its rarity.
static func _fill_tile(tile: Control, e, cid: String) -> void:
	var owned: int = e.collection.owned(cid)
	var state: PanelContainer = tile.find_child("State", true, false)
	var label: Label = state.get_node("Text")
	var was_new: bool = owned > 0 and not e.meta_ui.is_seen(card_key(cid))
	state.visible = owned > 0 and (was_new or owned > 1)
	label.text = UiText.t("PACK_CARD_NEW") if was_new else UiText.t("PACK_CARD_EXTRAS", [owned - 1])
	(tile.find_child("Count", true, false) as Label).text = UiText.t("COLLECTION_OWNED", [owned]) if owned > 0 else ""

static func _refresh_set(p: BasePopup, e) -> void:
	if p == null or not is_instance_valid(p):
		return
	for tile in p.find_children("Tile_*", "VBoxContainer", true, false):
		_fill_tile(tile, e, String(tile.get_meta("card_id")))
	p.rearm()

static func _chip(text: String, bg: Color, fs: int) -> PanelContainer:
	var c := PanelContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, bg.darkened(0.35), 3, 18, 0), 10, 2))
	var l := Label.new()
	l.name = "Text"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", bg.darkened(0.5))
	c.add_child(l)
	return c

# ================================================================ card detail ==

static func open_card(stack, app, cid: String, on_close: Callable = Callable()) -> BasePopup:
	var e = app.economy
	if e.collection.owned(cid) <= 0:
		return null
	var cat := CollectionCardCatalog.entry(cid)
	var p := BasePopup.new("collection_card")
	p.set_frame("large")
	p.set_title(String(cat["name"]).to_upper())
	p.context = {"card_id": cid}
	var box := CenterContainer.new()
	p.get_content().add_child(box)
	var art := HomeStyle.art("CardArt")
	art.texture = load(String(cat["art"]))
	art.custom_minimum_size = Vector2(380, 540)
	box.add_child(art)
	var rc := _chip(UiText.t("RARITY_" + String(cat["rarity"])), RARITY_COLOR[String(cat["rarity"])], 24)
	rc.name = "Rarity"
	rc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.get_content().add_child(rc)
	for k in ["Owned", "Protected", "Extras", "Value"]:
		p.add_body_line("", k, BasePopup.INK, 26)
	p.add_action("ex_one", "", "primary", false)
	p.add_action("ex_all", "", "secondary", false)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	p.action_selected.connect(func(id, ctx): _on_card_action(stack, app, p, id, ctx))
	p.closed.connect(func(_r):
		if on_close.is_valid():
			on_close.call(), CONNECT_ONE_SHOT)
	_refresh_card(p, e)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _refresh_card(p: BasePopup, e) -> void:
	var cid := String(p.context["card_id"])
	var owned: int = e.collection.owned(cid)
	var extras: int = e.exchange.exchangeable(cid)
	var value: int = e.exchange.card_value(cid)
	(p.find_child("Owned", true, false) as Label).text = UiText.t("COLLECTION_OWNED", [owned])
	(p.find_child("Protected", true, false) as Label).text = UiText.t("COLLECTION_PROTECTED")
	(p.find_child("Extras", true, false) as Label).text = UiText.t("PACK_CARD_EXTRAS", [extras]) if extras > 0 else UiText.t("COLLECTION_NO_EXTRAS")
	(p.find_child("Value", true, false) as Label).text = UiText.t("COLLECTION_VALUE", [UiText.num(value)])
	p.get_action_button("ex_one").text = UiText.t("COLLECTION_EXCHANGE_ONE", [UiText.num(value)])
	p.get_action_button("ex_all").text = UiText.t("COLLECTION_EXCHANGE_CARD_ALL", [extras, UiText.num(value * extras)])
	p.set_action_blocked("ex_one", extras < 1)
	p.set_action_blocked("ex_all", extras < 1)

static func _on_card_action(stack, app, p: BasePopup, id: String, ctx: Dictionary) -> void:
	if id != "ex_one" and id != "ex_all":
		return
	var e = app.economy
	var cid := String(ctx["card_id"])
	var n: int = 1 if id == "ex_one" else e.exchange.exchangeable(cid)
	if n < 1:
		p.rearm()
		return
	_confirm(stack, UiText.t("COLLECTION_CONFIRM_CARD", [n, String(CollectionCardCatalog.entry(cid)["name"]), UiText.num(n * e.exchange.card_value(cid))]),
		func(): return app.actions.exchange_card(cid, n),
		func():
			if is_instance_valid(p) and p.is_open():
				_refresh_card(p, e)
				p.rearm_soon())

# =================================================================== exchange ==

static func open_exchange(stack, app, on_close: Callable = Callable()) -> BasePopup:
	var p := BasePopup.new("cards_exchange")
	p.set_frame("large")
	p.set_title(UiText.t("CARDS_TITLE"))
	var em := CenterContainer.new()
	var icon := HomeStyle.art("Emblem")
	icon.texture = load(ART["exchange"])
	icon.custom_minimum_size = Vector2(150, 150)
	em.add_child(icon)
	p.get_content().add_child(em)
	var scroll := ScrollContainer.new()
	scroll.name = "ExtraList"
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Extras"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	p.add_body_line("", "Total", BasePopup.ROYAL_EDGE, 28)
	p.add_action("ex_all_extras", "", "primary", false)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id == "ex_all_extras":
			var total := _exchange_total(app.economy)
			if total <= 0:
				p.rearm()
				return
			_confirm(stack, UiText.t("COLLECTION_CONFIRM_ALL", [UiText.num(total)]),
				func(): return app.actions.exchange_all_extras(),
				func():
					if is_instance_valid(p) and p.is_open():
						_refresh_exchange(p, app.economy)
						p.rearm_soon()))
	p.closed.connect(func(_r):
		if on_close.is_valid():
			on_close.call(), CONNECT_ONE_SHOT)
	_refresh_exchange(p, app.economy)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _exchange_total(e) -> int:
	var total := 0
	for cid in e.collection.all_card_ids():
		total += e.exchange.exchangeable(cid) * e.exchange.card_value(cid)
	return total

static func _refresh_exchange(p: BasePopup, e) -> void:
	var list: VBoxContainer = p.find_child("Extras", true, false)
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	for cid in e.collection.all_card_ids():
		var n: int = e.exchange.exchangeable(cid)
		if n <= 0:
			continue
		var cat := CollectionCardCatalog.entry(cid)
		var l := BasePopup.body_label(UiText.t("COLLECTION_EXCHANGE_ROW", [String(cat["name"]), UiText.t("RARITY_" + String(cat["rarity"])), n, UiText.num(n * e.exchange.card_value(cid))]), 22, BasePopup.INK)
		l.name = "Row_" + cid
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(l)
	var total := _exchange_total(e)
	if total <= 0:
		var l := BasePopup.body_label(UiText.t("CARDS_EMPTY"), 24, BasePopup.INK)
		l.name = "Empty"
		list.add_child(l)
	(p.find_child("Total", true, false) as Label).text = UiText.t("COLLECTION_EXCHANGE_TOTAL", [UiText.num(total)])
	p.get_action_button("ex_all_extras").text = UiText.t("COLLECTION_EXCHANGE_ALL", [UiText.num(total)])
	p.set_action_blocked("ex_all_extras", total <= 0)

# ==================================================================== shared ==

## Confirm -> commit through the facade -> committed feedback -> `after`. Never mutates itself.
static func _confirm(stack, body: String, commit: Callable, after: Callable) -> void:
	var c = Popups.confirm({"id": "collection_confirm", "title": UiText.t("COLLECTION_CONFIRM_TITLE"), "body": body,
		"confirm_text": UiText.t("COLLECTION_CONFIRM_YES")})
	var done := [false]
	c.action_selected.connect(func(a, _ctx):
		if a == "confirm":
			var r: Dictionary = commit.call()
			var fb = Popups.feedback({"ok": bool(r.get("ok", false)), "reason": String(r.get("reason", "failed")),
				"text": UiText.t("COLLECTION_EXCHANGED", [UiText.num(int(r.get("sb", 0)))]) if bool(r.get("ok", false)) else ""})
			if not stack.push(fb):
				fb.free()
			done[0] = true
			after.call())
	c.closed.connect(func(_r):
		if not done[0]:
			after.call())
	if not stack.push(c):
		c.free()
		after.call()
