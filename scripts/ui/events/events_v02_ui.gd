extends RefCounted
## EventsV02Ui — preload (res://scripts/ui/events/events_v02_ui.gd).
##
## SB-EV02-008/013 — native V02 event surfaces, every value from one EventsV02Service view:
##   - card(v, open): one Events-page card per listed instance, art chosen by event id. Active /
##     claimable: hero art + When pill + family / participants + progress + DETAILS; upcoming:
##     a compact preview row with the 256 px icon only (so at most the 3..5 live heroes are
##     resident; textures are plain load()s released with the popup);
##   - open_details(stack, app, iid): hero, goal, computer-controlled note, live standings /
##     bracket / team / color state, reward steps (CLAIM through ProductionActionFacade), JOIN
##     and HOW IT WORKS (EventTutorial; shown once automatically on the first visit).
## Missing art falls back to an empty TextureRect tagged `art_fallback` (QA visible), never a
## crash. Every entry re-checks the Events unlock (Level 30, feature_unlocks_v1.json).

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiEventCard = preload("res://scripts/ui/components/ui_event_card.gd")
const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

const HERO := "res://assets/ui/final/events/heroes/%s.png"
const ICON := "res://assets/ui/final/events/icons/%s.png"
const PALETTE := "res://data/palettes/scrubbots_palette_v3.json"
const TUTORIAL := "res://scripts/ui/events/event_tutorial.gd"   ## loaded on use (it preloads this file)
const RIVAL_KINDS := ["race", "ranking", "royale", "bracket", "team_milestones", "team_versus"]
const MAX_ROWS := 8   ## standings rows shown (Royale: top rows + You)

## Texture for an event art path; null (fallback) when the file is missing.
static func art_texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

static func _art(node_name: String, path: String, height: int) -> TextureRect:
	var a := HomeStyle.art(node_name)
	a.texture = art_texture(path)
	a.set_meta("art_fallback", a.texture == null)
	a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	a.clip_contents = true
	a.custom_minimum_size = Vector2(0, height)
	return a

static func title(id: String) -> String:
	return UiText.t("EV2_NAME_" + id.to_upper())

## The event's goal sentence with its live instance values (goal, season, colors).
static func goal(v: Dictionary) -> String:
	var key := "EV2_GOAL_" + String(v["id"]).to_upper()
	match String(v["id"]):
		"scrub_sprint", "first_brush_race":
			return UiText.t(key, [UiText.num(int(v["params"].get("goal", 0)))])
		"seasonal_scrub_festival":
			return UiText.t(key, [UiText.t("EV2_SEASON_" + String(v["params"].get("variant", "summer")).to_upper())])
		"color_scrub_rush":
			var names: Array = (v["params"].get("colors", []) as Array).map(func(c): return color_name(String(c)))
			return UiText.t(key, [UiText.num(300), ", ".join(names)])
	return UiText.t(key)

static func participants(v: Dictionary) -> String:
	if v.has("team_size"):
		return UiText.t("EV2_TEAM", [UiText.num(int(v["team_size"]))])
	if v.has("entrants"):
		return UiText.t("EV2_RIVALS", [UiText.num(int(v["entrants"]) - 1)])
	return UiText.t("EV2_SOLO")

## Canonical palette name for a C-id ("C04" -> "Green"); text + swatch, never color alone.
static func color_name(cid: String) -> String:
	var d = JSON.parse_string(FileAccess.get_file_as_string(PALETTE))
	for c in (d.get("colors", []) if typeof(d) == TYPE_DICTIONARY else []):
		if c["id"] == cid:
			return String(c["name"])
	return cid

static func color_value(cid: String) -> Color:
	var d = JSON.parse_string(FileAccess.get_file_as_string(PALETTE))
	for c in (d.get("colors", []) if typeof(d) == TYPE_DICTIONARY else []):
		if c["id"] == cid:
			return Color(String(c["hex"]))
	return Color.GRAY

## One-line live progress for a view (card + details header).
static func progress_text(v: Dictionary) -> String:
	match String(v["kind"]):
		"race":
			var s: Dictionary = v["steps"][0]
			return UiText.t("EV2_PLACE", [UiText.num(int(s["value"]))]) if s["reached"] else UiText.t("EV2_PROGRESS", [UiText.t("HOME_RATIO", [UiText.num(v["progress"]), UiText.num(int(v["params"]["goal"]))])])
		"ranking":
			return UiText.t("EV2_RANK", [UiText.num(int(v["rank"])), UiText.num(int(v["entrants"]))])
		"bracket":
			return UiText.t(("EV2_ROUND_%d" % mini(3, (v["bracket"]["rounds"] as Array).size())) if not (v["bracket"]["rounds"] as Array).is_empty() else "EV2_ROUND_1")
		"team_milestones", "team_versus":
			return UiText.t("EV2_TEAM_TOTAL", [UiText.num(int(v["team_total"]))])
		"quest":
			return UiText.t("EV2_OBJECTIVES", [UiText.num(int(v["objectives"]))])
		"streak":
			return UiText.t("EV2_PROGRESS", [UiText.num(int(v["progress"]))])
	return UiText.t("EV2_PROGRESS", [UiText.num(int(v["progress"]))])

static func when_text(v: Dictionary) -> String:
	match String(v["phase"]):
		"upcoming":
			return UiText.t("EVENT_STARTS_IN", [UiText.time_left(int(v["starts_in"]))])
		"active":
			return UiText.t("EVENT_ENDS_IN", [UiText.time_left(int(v["ends_in"]))])
	return UiText.t("EV2_CLAIM_ENDS", [UiText.time_left(int(v["claim_ends_in"]))])

# ------------------------------------------------------------------ card ----

## `open` (aid, parent) -> Button supplies the DETAILS button (popup keeps the action gating).
static func card(v: Dictionary, open: Callable) -> PanelContainer:
	var upcoming: bool = v["phase"] == "upcoming"
	var c := PanelContainer.new()
	c.name = "EventV2_" + String(v["id"])
	c.set_meta("phase", v["phase"])
	c.set_meta("iid", v["iid"])
	var bg := UiEventCard.LOCK_GREY.lightened(0.2) if upcoming else BasePopup.ROYAL
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, UiEventCard.LOCK_GREY if upcoming else BasePopup.ROYAL_EDGE, 4, 26, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	c.add_child(box)
	if upcoming:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
		box.add_child(row)
		var icon := _art("EventIcon", ICON % v["id"], 96)
		icon.custom_minimum_size = Vector2(96, 96)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(col)
		col.add_child(_label("Title", title(v["id"]), 30, HomeStyle.TEXT))
		col.add_child(_label("When", when_text(v), 24, HomeStyle.TEXT))
		return c
	var t := _label("Title", title(v["id"]).to_upper(), 38, HomeStyle.SUBTITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var hero := _art("EventHero", HERO % v["id"], 260)
	box.add_child(hero)
	var over := HBoxContainer.new()
	over.set_anchors_preset(Control.PRESET_TOP_WIDE)
	over.offset_left = UiTokens.SPACE_SM
	over.offset_top = UiTokens.SPACE_SM
	over.offset_right = -UiTokens.SPACE_SM
	over.alignment = BoxContainer.ALIGNMENT_END
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(over)
	over.add_child(UiEventCard._pill("WhenPill", "When", when_text(v), "common/icons/icon_clock.png"))
	box.add_child(_label("Info", "%s · %s" % [UiText.t("EV2_FAMILY_" + String(v["family"]).to_upper()), participants(v)], 24, HomeStyle.TEXT))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	box.add_child(h)
	var p := _label("Progress", progress_text(v) if v["joined"] else UiText.t("EV2_NOT_JOINED"), 26, HomeStyle.TEXT)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(p)
	if int(v["claimable"]) > 0:
		h.add_child(_badge(int(v["claimable"])))
	var b: Button = open.call("ev2:" + String(v["iid"]), h)
	b.text = UiText.t("EV2_DETAILS")
	return c

static func _badge(n: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "Claimable"
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(HomeStyle.BADGE, HomeStyle.BADGE.darkened(0.3), 3, 30, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	pill.add_child(HomeStyle.label(UiText.num(n), 26))
	return pill

static func _label(n: String, text: String, size: int, color: Color) -> Label:
	var l := HomeStyle.label(text, size, color, 6)
	l.name = n
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func _ink(n: String, text: String, size: int) -> Label:
	var l := BasePopup.body_label(text, size, BasePopup.INK)
	l.name = n
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l

# --------------------------------------------------------------- details ----

## Details popup for one instance; null while Events are locked or the instance is unknown.
static func open_details(stack, app, iid: String) -> BasePopup:
	if not app.feature_unlocked("events") or app.economy.events_v02.view(iid).is_empty():
		return null
	var p := BasePopup.new("event_details")
	p.set_frame("large")
	p.set_meta("iid", iid)
	var scroll := ScrollContainer.new()
	scroll.name = "DetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 1180
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "DetailList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	scroll.add_child(list)
	TouchScroll.enable(scroll)
	p.add_action("join", UiText.t("EV2_JOIN"), "primary", false)
	p.add_action("how", UiText.t("EV2_HOW"), "secondary", false, "foot")
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true, "foot")
	p.action_selected.connect(func(id, _c):
		if id == "join":
			app.actions.join_event(iid)
		elif id.begins_with("rw:"):
			app.actions.claim_event_reward(iid, id.substr(3))
		elif id == "how":
			load(TUTORIAL).open(stack, app, iid)
		else:
			return
		refresh_details(p, app)
		p.rearm_soon())
	refresh_details(p, app)
	if not stack.push(p):
		p.free()
		return null
	var ev = app.economy.events_v02
	var id := String(ev.view(iid)["id"])
	if not ev.tutorial_seen(id):   # first visit: the walkthrough opens once on top
		load(TUTORIAL).open(stack, app, iid)
	return p

static func refresh_details(p: BasePopup, app) -> void:
	var v: Dictionary = app.economy.events_v02.view(String(p.get_meta("iid")))
	p.set_title(title(v["id"]).to_upper())
	var list: VBoxContainer = p.find_child("DetailList", true, false)
	var stash: Control = p.find_child("RewardStash", true, false)
	if stash == null:
		stash = Control.new()
		stash.name = "RewardStash"
		stash.visible = false
		p.get_content().add_child(stash)
	for c in list.get_children():
		for b in c.find_children("*", "Button", true, false):
			b.reparent(stash)
		list.remove_child(c)
		c.queue_free()
	for b in stash.get_children():
		p.set_action_blocked(b.get_meta("aid"), true)
	var hero := _art("EventHero", HERO % v["id"], 300)
	hero.add_child(_when_overlay(v))
	list.add_child(hero)
	var head := _section("Head")
	head.get_child(0).add_child(_ink("Goal", goal(v), 28))
	head.get_child(0).add_child(_ink("Info", "%s · %s" % [UiText.t("EV2_FAMILY_" + String(v["family"]).to_upper()), participants(v)], 24))
	head.get_child(0).add_child(_ink("Joined", UiText.t("EV2_JOINED") if v["joined"] else UiText.t("EV2_NOT_JOINED"), 24))
	list.add_child(head)
	if RIVAL_KINDS.has(v["kind"]):
		var note := _section("CpuNote")
		note.get_child(0).add_child(_ink("Text", UiText.t("EV2_CPU_NOTE"), 22))
		list.add_child(note)
	var state := _state_section(v, app.economy.events_v02)
	if state != null:
		list.add_child(state)
	var rewards := _section("Rewards")
	if not v["claims_enabled"]:
		rewards.get_child(0).add_child(_ink("Preview", UiText.t("EV2_PREVIEW"), 22))
	for s in v["steps"]:
		rewards.get_child(0).add_child(_reward_row(p, stash, v, s, app))
	list.add_child(rewards)
	p.set_action_visible("join", v["phase"] == "active" and not v["joined"])
	p.set_action_blocked("join", app.is_blocked)

static func _when_overlay(v: Dictionary) -> Control:
	var over := HBoxContainer.new()
	over.set_anchors_preset(Control.PRESET_TOP_WIDE)
	over.offset_left = UiTokens.SPACE_SM
	over.offset_top = UiTokens.SPACE_SM
	over.offset_right = -UiTokens.SPACE_SM
	over.alignment = BoxContainer.ALIGNMENT_END
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_child(UiEventCard._pill("WhenPill", "When", when_text(v), "common/icons/icon_clock.png"))
	return over

static func _section(n: String) -> PanelContainer:
	var s := PanelContainer.new()
	s.name = n
	s.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	s.add_child(v)
	return s

## Live event state: standings (CPU-badged), Royale stages, bracket rounds, team totals, colors.
static func _state_section(v: Dictionary, ev) -> PanelContainer:
	var s := _section("Live")
	var box: VBoxContainer = s.get_child(0)
	box.add_child(_ink("Progress", progress_text(v), 28))
	match String(v["kind"]):
		"race", "ranking", "royale":
			if v["kind"] == "royale":
				for i in range((v["stage_counts"] as Array).size()):
					box.add_child(_ink("Stage_%d" % (i + 1), UiText.t("EV2_STAGE", [UiText.num(i + 1), UiText.num(int(v["stage_counts"][i]))]), 22))
			var rec: Dictionary = ev._record(v["iid"])
			var rows: Array = v["standings"]
			var you := rows.find(rows.filter(func(r): return r["player"])[0])
			for i in range(rows.size()):
				if i < MAX_ROWS or i == you:
					box.add_child(_standing(i + 1, rows[i], ev, rec))
		"bracket":
			var b: Dictionary = v["bracket"]
			var rec: Dictionary = ev._record(v["iid"])
			for r in range((b["rounds"] as Array).size()):
				box.add_child(_ink("Round_%d" % (r + 1), UiText.t("EV2_ROUND_%d" % (r + 1)), 24))
				for m in b["rounds"][r]:
					box.add_child(_ink("Match", UiText.t("EV2_MATCH", [_who(m[0], ev, rec), UiText.num(m[2]), UiText.num(m[3]), _who(m[1], ev, rec)]), 22))
		"team_milestones", "team_versus":
			box.add_child(_ink("Part", UiText.t("EV2_YOUR_PART", [UiText.num(int(v["progress"])), UiText.num(int(v["min_player_contribution"]))]), 22))
			if v["kind"] == "team_versus":
				box.add_child(_ink("Opponent", UiText.t("EV2_OPP_TOTAL", [UiText.num(int(v["opponent_total"]))]), 22))
		"colors":
			for c in v["params"]["colors"]:
				var row := HBoxContainer.new()
				row.name = "Color_" + String(c)
				var sw := ColorRect.new()
				sw.color = color_value(String(c))
				sw.custom_minimum_size = Vector2(36, 36)
				row.add_child(sw)
				row.add_child(_ink("Text", UiText.t("EV2_COLOR_ROW", [color_name(String(c)), UiText.num(int(v["colors"].get(c, 0))), UiText.num(300)]), 22))
				box.add_child(row)
	return s

static func _who(idx: int, ev, rec: Dictionary) -> String:
	return UiText.t("EV2_YOU") if idx == 0 else "%s (%s)" % [ev.entrant(rec, idx)["name"], UiText.t("EV2_CPU")]

static func _standing(place: int, r: Dictionary, ev, rec: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "You" if r["player"] else "Rival_%d" % int(r["idx"])
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	var pl := _ink("Place", "%s." % UiText.num(place), 22)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pl.custom_minimum_size.x = 64
	h.add_child(pl)
	var pic := HomeStyle.art("Avatar")
	pic.custom_minimum_size = Vector2(44, 44)
	var robot := "scrubby" if r["player"] else String(ev.entrant(rec, int(r["idx"]))["robot"])
	pic.texture = art_texture(RobotRoster.asset(robot, "portrait"))
	h.add_child(pic)
	var name := _ink("Name", UiText.t("EV2_YOU") if r["player"] else "%s · %s" % [ev.entrant(rec, int(r["idx"]))["name"], UiText.t("EV2_CPU")], 22)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var sc := _ink("Score", UiText.num(int(r["score"])), 22)
	sc.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(sc)
	return h

static func step_label(v: Dictionary, s: Dictionary) -> String:
	match String(s["rid"]):
		"place":
			return UiText.t("EV2_ROW_PLACE")
		"rank":
			return UiText.t("EV2_ROW_RANK")
		"result":
			return UiText.t("EV2_ROW_RESULT")
		"win":
			return UiText.t("EV2_ROW_WIN")
	return UiText.t("EV2_ROW_TARGET", [UiText.num(int(s["value"]))])

static func _reward_row(p: BasePopup, stash: Control, v: Dictionary, s: Dictionary, app) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "Step_" + String(s["rid"])
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	var icon := HomeStyle.art("Icon")
	icon.texture = load(UiEventCard.F + "rewards/%s.png" % UiEventCard.reward_icon(s["reward"]))
	icon.custom_minimum_size = Vector2(64, 64)
	h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	col.add_child(_ink("Text", step_label(v, s), 24))
	col.add_child(_ink("Reward", UiText.reward_text(s["reward"]), 20))
	if s["claimed"]:
		h.add_child(_ink("State", UiText.t("ACH_DONE"), 22))
	elif s["claimable"] and v["claims_enabled"]:
		var aid := "rw:" + String(s["rid"])
		var b: Button = p.get_action_button(aid)
		if b == null:
			b = p.add_action(aid, "", "secondary", false, "", h)
		else:
			b.reparent(h)
		b.set_meta("aid", aid)
		b.text = UiText.t("POPUP_CLAIM")
		b.custom_minimum_size = Vector2(190, UiTokens.TOUCH_MIN)
		p.set_action_blocked(aid, app.is_blocked)
	else:
		var lock := HomeStyle.art("Locked")
		lock.texture = load(UiEventCard.F + ("common/icons/icon_check.png" if s["reached"] else "common/icons/icon_lock.png"))
		lock.custom_minimum_size = Vector2(48, 48)
		h.add_child(lock)
	return h
