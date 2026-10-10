extends RefCounted
## RobotsScreen — preload (res://scripts/ui/robots/robots_screen.gd).
##
## M43-C008 (SB-M43-102..111) — the ROBOTS BottomNav destination: the canonical 10-robot roster
## (OWNER_ROBOT_ROSTER_V01 order) in the approved popup family, every value live.
##   - per robot: portrait, name, role, canonical 20% meta perk (meta only — never puzzle power),
##     ACTIVE / UNLOCKED / LOCKED, NEW until first seen here after its unlock;
##   - Bot Parts N / 250 toward the next robot, with the overflow that carries over;
##   - EQUIP (unlocked) -> ProductionActionFacade.equip_robot; UNLOCK (only the next robot in
##     canonical order, only with enough Bot Parts) -> unlock_next_robot -> the shared ceremony
##     presenter shows the owner-accepted Robot Unlock ceremony on top;
##   - locked detail: preview art under the lock, required Bot Parts, perk; Bot Parts are earned
##     by playing and cannot be bought (no SB / money path exists).
## Robot selection is presentation/meta only: nothing here reaches BoardState, targeting,
## routing, solver or batch legality. "Seen" marks are presentation (dirty flag, no save per view).

const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

const ART := {
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"lock": "res://assets/ui/final/robots/robot_lock_emblem.png",
}
const LIST_H := 1060.0

static func seen_key(id: String) -> String:
	return "robot_seen:" + id

## Unlocked robots (after the initial one) not yet seen on the Robots screen.
static func unseen_robots(economy) -> Array:
	return RobotRoster.ids().filter(func(id): return economy.robots.is_unlocked(id) and id != String(RobotRoster.load_roster()["initial_robot_id"]) and not economy.meta_ui.is_seen(seen_key(id)))

static func open(stack, app, ceremonies = null) -> BasePopup:
	var e = app.economy
	var p := BasePopup.new("robots")
	p.set_frame("large")
	p.set_title(UiText.t("ROBOTS_TITLE"))
	var parts := HBoxContainer.new()
	parts.name = "PartsRow"
	parts.alignment = BoxContainer.ALIGNMENT_CENTER
	parts.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(parts)
	var bi := HomeStyle.art("BotPartsIcon")
	bi.texture = load(ART["bot_parts"])
	bi.custom_minimum_size = Vector2(56, 56)
	parts.add_child(bi)
	var pl := BasePopup.body_label("", 26, BasePopup.INK)
	pl.name = "Parts"
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.add_child(pl)
	var scroll := ScrollContainer.new()
	scroll.name = "RobotList"
	scroll.custom_minimum_size = Vector2(0, LIST_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Robots"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	var new_ids := unseen_robots(e)
	p.set_meta("new_on_open", new_ids)
	for r in RobotRoster.load_roster()["robots"]:
		list.add_child(_row(p, e, r, new_ids.has(String(r["id"]))))
	for id in new_ids:
		e.meta_ui.mark_seen(seen_key(id))
	if not new_ids.is_empty():
		app.mark_dirty()
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c): _on_action(stack, app, ceremonies, p, id))
	refresh(p, e)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _row(p: BasePopup, e, r: Dictionary, is_new: bool) -> Control:
	var id := String(r["id"])
	var card := PanelContainer.new()
	card.name = "Robot_" + id
	card.set_meta("robot_id", id)
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	card.add_child(h)
	var portrait := HomeStyle.art("Portrait")
	portrait.texture = load(RobotRoster.asset(id, "portrait"))
	portrait.custom_minimum_size = Vector2(120, 120)
	h.add_child(portrait)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	v.add_child(top)
	var name_l := BasePopup.body_label("%d · %s" % [int(r["order"]), String(r["name"]).to_upper()], 28, BasePopup.ROYAL_EDGE)
	name_l.name = "Name"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(name_l)
	var state := _chip("", Color(0.2, 0.66, 0.14), 18)
	state.name = "State"
	top.add_child(state)
	var newb := _chip(UiText.t("PACK_CARD_NEW"), Color(0.95, 0.55, 0.05), 18)
	newb.name = "NewBadge"
	newb.visible = is_new
	top.add_child(newb)
	var perk := BasePopup.body_label("%s: %s" % [String(r["perk_name"]), String(r["perk_text"])], 20, BasePopup.INK)
	perk.name = "Perk"
	perk.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(perk)
	var note := BasePopup.body_label("", 19, BasePopup.INK)
	note.name = "Note"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(note)
	var b := p.add_action("robot:" + id, "", "secondary", false, "", h)
	b.custom_minimum_size = Vector2(210, 80)
	return card

static func _chip(text: String, bg: Color, fs: int) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, bg.darkened(0.35), 3, 16, 0), 10, 2))
	var l := Label.new()
	l.name = "Text"
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", bg.darkened(0.5))
	c.add_child(l)
	return c

## Live row state + the one action per row: EQUIP / ACTIVE / UNLOCK / DETAILS.
static func row_state(e, id: String) -> Dictionary:
	var next := RobotRoster.next_locked(e.robots)
	var prog: Dictionary = e.robots.next_robot_progress()
	if e.robots.is_unlocked(id):
		var active: bool = e.robots.active_robot() == id
		return {"state": "active" if active else "unlocked", "action": "" if active else "equip"}
	if id == next:
		return {"state": "next", "action": "unlock", "can_unlock": bool(prog["can_unlock"])}
	return {"state": "locked", "action": "details"}

static func refresh(p: BasePopup, e) -> void:
	var prog: Dictionary = e.robots.next_robot_progress()
	var next := RobotRoster.next_locked(e.robots)
	var parts := int(prog["parts"])
	var cost := int(prog["cost"])
	var text := UiText.t("ROBOTS_ALL_UNLOCKED", [UiText.num(parts)]) if next.is_empty() else UiText.t("ROBOTS_PARTS", [UiText.num(parts), UiText.num(cost), String(RobotRoster.entry(next)["name"])])
	if not next.is_empty() and parts >= cost:
		text += "\n" + UiText.t("ROBOTS_OVERFLOW", [UiText.num(parts - cost)])
	(p.find_child("Parts", true, false) as Label).text = text
	for card in p.find_children("Robot_*", "PanelContainer", true, false):
		var id := String(card.get_meta("robot_id"))
		var st := row_state(e, id)
		var chip: PanelContainer = card.find_child("State", true, false)
		var chip_text: Label = chip.get_node("Text")
		var note: Label = card.find_child("Note", true, false)
		var b: Button = p.get_action_button("robot:" + id)
		match String(st["state"]):
			"active":
				chip_text.text = UiText.t("ROBOTS_ACTIVE")
				note.text = UiText.t("ROBOTS_NOTE_ACTIVE")
				b.text = UiText.t("ROBOTS_ACTIVE")
				p.set_action_blocked("robot:" + id, true)
			"unlocked":
				chip_text.text = UiText.t("ROBOTS_UNLOCKED")
				note.text = ""
				b.text = UiText.t("ROBOTS_EQUIP")
				p.set_action_blocked("robot:" + id, false)
			"next":
				chip_text.text = UiText.t("ROBOTS_LOCKED")
				note.text = UiText.t("ROBOTS_NOTE_NEXT", [UiText.num(cost)])
				b.text = UiText.t("ROBOTS_UNLOCK", [UiText.num(cost)])
				p.set_action_blocked("robot:" + id, not bool(st["can_unlock"]))
			_:
				chip_text.text = UiText.t("ROBOTS_LOCKED")
				note.text = UiText.t("ROBOTS_NOTE_LOCKED")
				b.text = UiText.t("COLLECTION_DETAILS")
				p.set_action_blocked("robot:" + id, false)

static func _on_action(stack, app, ceremonies, p: BasePopup, id: String) -> void:
	if not id.begins_with("robot:"):
		return
	var rid := id.substr(6)
	var e = app.economy
	var st := row_state(e, rid)
	match String(st["action"]):
		"equip":
			app.actions.equip_robot(rid)
		"unlock":
			var r: Dictionary = app.actions.unlock_next_robot()
			if bool(r.get("ok", false)) and ceremonies != null:
				e.meta_ui.mark_seen(seen_key(String(r.get("robot_id", ""))))
				# Re-read the roster once the ceremony (EQUIP / KEEP) is done.
				ceremonies.idle.connect(func(_s):
					if is_instance_valid(p) and p.is_open():
						refresh(p, e), CONNECT_ONE_SHOT)
				ceremonies.drain("robots")
		"details":
			if open_detail(stack, app, rid, func(): if is_instance_valid(p): p.rearm()) != null:
				return
	refresh(p, e)
	p.rearm_soon()

## Locked robot detail: preview art under the lock emblem, required Bot Parts, perk, and the
## fact that Bot Parts are only earned (never bought). Informational: no action.
static func open_detail(stack, app, id: String, on_close: Callable = Callable()) -> BasePopup:
	var e = app.economy
	var r := RobotRoster.entry(id)
	if r.is_empty() or e.robots.is_unlocked(id):
		return null
	var p := BasePopup.new("robot_detail")
	p.set_frame("large")
	p.set_title(String(r["name"]).to_upper())
	var box := CenterContainer.new()
	box.name = "Preview"
	p.get_content().add_child(box)
	var art := HomeStyle.art("PreviewArt")
	art.texture = load(RobotRoster.asset(id, "master"))
	art.custom_minimum_size = Vector2(330, 396)
	art.modulate = Color(0.55, 0.6, 0.7, 1.0)
	box.add_child(art)
	var lock := HomeStyle.art("Lock")
	lock.texture = load(ART["lock"])
	lock.custom_minimum_size = Vector2(150, 150)
	box.add_child(lock)
	p.add_body_line(String(r["role"]), "Role", BasePopup.INK, 26)
	p.add_body_line("%s: %s" % [String(r["perk_name"]), String(r["perk_text"])], "Perk", BasePopup.ROYAL_EDGE, 26)
	var need := int(e.robots.unlock_cost()) * (RobotRoster.ids().find(id) - RobotRoster.ids().find(RobotRoster.next_locked(e.robots)) + 1)
	p.add_body_line(UiText.t("ROBOTS_DETAIL_NEED", [UiText.num(need), UiText.num(e.wallet.bot_parts())]), "Required", BasePopup.INK, 26)
	p.add_body_line(UiText.t("ROBOTS_DETAIL_EARNED"), "EarnedOnly", BasePopup.INK, 22)
	p.add_body_line(UiText.t("ROBOTS_PERK_META"), "MetaOnly", BasePopup.INK, 20)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	p.closed.connect(func(_r):
		if on_close.is_valid():
			on_close.call(), CONNECT_ONE_SHOT)
	if not stack.push(p):
		p.free()
		return null
	return p
