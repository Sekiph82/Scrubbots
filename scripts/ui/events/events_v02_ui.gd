extends RefCounted
## EventsV02Ui — preload (res://scripts/ui/events/events_v02_ui.gd).
##
## SB-EV02-008/013, SB-TF-12 — native V02 event surfaces, every value from one EventsV02Service view:
##   - card(v, open): one Events-page card per listed instance (owner master events_ui_master.png):
##     accent card with gold rim, the event icon, native title + goal + progress meter and the
##     event's own scene on the right. Upcoming: a compact row with the icon only, so at most the
##     3..5 live scenes are resident (plain load()s, released with the popup);
##   - open_details(stack, app, iid): the full-screen event screen, drawn natively over the event's
##     scene: title ribbon, timer pill, goal banner, Hero (host robot + key prop), the REAL level
##     Board, Team, Standings (rivals / colors), Map (props), Progress track, Rewards (CLAIM through
##     ProductionActionFacade) and the green JOIN area. Each coach-mark target of
##     data/config/events_v02_tutorials.json is one section tagged meta "coach" (EventTutorial);
##     the walkthrough opens once on the first visit and again from the (i) button;
##   - SB-TF-07: WATCH AD · +1 while ProductionActionFacade.event_ad_available(iid) (joined, active,
##     not quest / colors, once per event per local day, an ad ready); the verified grant and its
##     save happen in RewardedGrantService, this screen only starts it and refreshes on `resolved`.
## Only the scene, the icon, the key props, robots and reward icons are raster art; ribbons, pills,
## panels, track nodes, buttons and every text are native. Missing art falls back to an empty
## TextureRect tagged `art_fallback` (QA visible), never a crash. Every entry re-checks the Events
## unlock (Level 30, feature_unlocks_v1.json).

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiEventCard = preload("res://scripts/ui/components/ui_event_card.gd")
const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")

const HERO := "res://assets/ui/final/events/heroes/%s.png"
const ICON := "res://assets/ui/final/events/icons/%s.png"
const SCENE := "res://assets/ui/final/events/scenes/%s.webp"
const PROP := "res://assets/ui/final/events/props/%s_%s.webp"
const KIT := "res://assets/ui/final/events/kit/%s.webp"   ## logo, laurel, checkered flags, sparkle lines, star
const TUTORIALS := "res://data/config/events_v02_tutorials.json"
const PALETTE := "res://data/palettes/scrubbots_palette_v3.json"
const TUTORIAL := "res://scripts/ui/events/event_tutorial.gd"   ## loaded on use (it preloads this file)
## A real campaign level (Level 4, catalog entry level_004_orange_cat) shown as the Board.
const LEVEL := "res://data/levels/level_004_orange_cat.json"
const RIVAL_KINDS := ["race", "ranking", "royale", "bracket", "team_milestones", "team_versus"]
const STANDING_KINDS := ["race", "ranking", "royale", "bracket", "colors"]
const TEAM_KINDS := ["team_milestones", "team_versus"]
const MAX_ROWS := 5   ## standings rows shown (top rows + You)
const RACE_KINDS := ["race", "royale"]   ## checkered flags beside the title
const AD_TIMEOUT_S := 60.0   ## SB-TF-05 pattern: an unanswered event ad is abandoned (no grant)
const GOLD := Color(1.0, 0.788, 0.243)
const GOLD_DARK := Color(0.690, 0.400, 0.039)
const CREAM := Color(1.0, 0.965, 0.878)
const BG01 := Color("#202533")   ## gameplay background seen through CLEARED cells
const WIDTH := 1000.0   ## content column of the 1080-wide canvas

static var _tut: Dictionary = {}

## Per-event presentation data (steps, accent, props) from events_v02_tutorials.json.
static func data(id: String) -> Dictionary:
	if _tut.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(TUTORIALS))
		_tut = d["events"] if typeof(d) == TYPE_DICTIONARY else {}
	return _tut.get(id, {})

static func accent(id: String) -> Color:
	return Color(String(data(id).get("accent", "#1b5dc9")))

## Panel fill sampled from the event's reference storyboards.
static func panel_color(id: String) -> Color:
	return Color(String(data(id).get("panel", data(id).get("accent", "#1b5dc9"))))

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

## Localized canonical palette name for a C-id ("C04" -> "Green" / "Yeşil"); text + swatch, never color alone.
static func color_name(cid: String) -> String:
	return UiText.t("EV2_COLOR_" + cid) if UiText.EN.has("EV2_COLOR_" + cid) else cid

static func color_value(cid: String) -> Color:
	var d = JSON.parse_string(FileAccess.get_file_as_string(PALETTE))
	for c in (d.get("colors", []) if typeof(d) == TYPE_DICTIONARY else []):
		if c["id"] == cid:
			return Color(String(c["hex"]))
	return Color.GRAY

## One-line live progress for a view (card + details).
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

## The event's canonical host robot (roster order, rotating through the ten robots).
static func host_robot(v: Dictionary, ev) -> String:
	return EventsV02.ROBOTS[maxi(0, ev.event_ids().find(v["id"])) % EventsV02.ROBOTS.size()]

## What one qualifying win adds to this event (Board caption).
static func gain_text(v: Dictionary) -> String:
	match String(v["metric"]):
		"first_attempt_new_level_win":
			return UiText.t("EV2_GAIN_FIRST_TRY", [UiText.num(1)])
		"cleaned_active_pixels", "cleaned_active_pixels_on_new_levels", "virtual_team_cleaned_active_pixels":
			return UiText.t("EV2_GAIN_PIXELS", [UiText.num(level_pixels())])
		"win_without_booster_usage":
			return UiText.t("EV2_GAIN_NO_BOOSTER", [UiText.num(1)])
		"consecutive_qualifying_wins":
			return UiText.t("EV2_GAIN_STREAK", [UiText.num(1)])
		"virtual_team_qualifying_level_wins", "virtual_team_cleaning_points", "virtual_team_sequential_clears":
			return UiText.t("EV2_GAIN_TEAM", [UiText.num(1)])
		"first_clear_new_level_cleanup_score":
			return UiText.t("EV2_GAIN_SCORE", [UiText.num(175)])
		"qualified_cross_event_objectives":
			return UiText.t("EV2_GAIN_OBJECTIVE", [UiText.num(1)])
		"cleaned_pixels_by_color":
			return UiText.t("EV2_GAIN_COLOR", [UiText.num(level_pixels() / 3)])
	return UiText.t("EV2_GAIN_LEVEL", [UiText.num(1)])

## Artwork (non-VOID) cells of the shown level = the pixels one win of it cleans.
static func level_pixels() -> int:
	var r = LevelLoader.load_from_path(LEVEL)
	return r.level_data.get_artwork_cell_count() if r.is_ok() else 0

static func score(v: Dictionary) -> int:
	match String(v["kind"]):
		"team_milestones", "team_versus":
			return int(v["team_total"])
		"streak":
			return int(v["best"])
	return int(v["progress"])

## Values of the event's own target track (e.g. 3 > 7 > 12 > 20); a race: 1..goal.
static func track_values(v: Dictionary) -> Array:
	var out: Array = (v["steps"] as Array).filter(func(x): return String(x["rid"]).begins_with("m")).map(func(x): return int(x["value"]))
	if out.is_empty() and v["kind"] == "race":   # one rail node per level of the race
		out = range(1, int(v["params"]["goal"]) + 1)
	return out

# ------------------------------------------------------------------ card ----

## `open` (aid, parent) -> Button supplies the DETAILS button (popup keeps the action gating).
static func card(v: Dictionary, open: Callable) -> PanelContainer:
	var id := String(v["id"])
	var upcoming: bool = v["phase"] == "upcoming"
	var c := PanelContainer.new()
	c.name = "EventV2_" + id
	c.set_meta("phase", v["phase"])
	c.set_meta("iid", v["iid"])
	var a := UiEventCard.LOCK_GREY if upcoming else accent(id)
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(a, GOLD, 6, 34, 8, 4), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	if not upcoming:   # the event's own scene on the right half, behind the text
		var layer := HBoxContainer.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layer.add_child(gap)
		var scene := _art("EventScene", SCENE % id, 0)
		scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scene.modulate = Color(1, 1, 1, 0.8)
		layer.add_child(scene)
		c.add_child(layer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	c.add_child(row)
	var icon := _art("EventIcon", ICON % id, 0)
	icon.custom_minimum_size = Vector2(96, 96) if upcoming else Vector2(150, 150)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	row.add_child(col)
	if upcoming:
		col.add_child(_label("Title", title(id), 30, HomeStyle.TEXT))
		col.add_child(_label("When", when_text(v), 24, HomeStyle.TEXT))
		return c
	col.add_child(_label("Title", title(id), 40, HomeStyle.SUBTITLE))
	var pill := PanelContainer.new()
	pill.name = "GoalPill"
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, GOLD_DARK, 2, 22, 0), UiTokens.SPACE_MD, UiTokens.SPACE_XS))
	pill.add_child(_ink("Goal", goal(v), 20))
	col.add_child(pill)
	col.add_child(_label("Info", "%s · %s" % [UiText.t("EV2_FAMILY_" + String(v["family"]).to_upper()), participants(v)], 20, HomeStyle.TEXT))
	col.add_child(_meter(v))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	col.add_child(h)
	var p := _label("Progress", progress_text(v) if v["joined"] else UiText.t("EV2_NOT_JOINED"), 22, HomeStyle.TEXT)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(p)
	if int(v["claimable"]) > 0:
		h.add_child(_badge(int(v["claimable"])))
	col.add_child(_when_pill(v))
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

## Green progress meter toward the next target of the event's track.
static func _meter(v: Dictionary) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "Meter"
	bar.show_percentage = false
	var next := 1
	for t in track_values(v):
		next = t
		if t > score(v) and v["kind"] != "race":   # a race fills toward its goal
			break
	bar.max_value = maxi(1, maxi(next, score(v)))
	bar.value = score(v)
	HomeStyle.style_meter(bar, HomeStyle.GREEN, 30)
	return bar

## Cream timer pill with the clock icon (native body, existing clock icon).
static func _when_pill(v: Dictionary, px := 24) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "TimerPill"
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, GOLD_DARK, 4, 30, 6, 2), UiTokens.SPACE_MD, 4))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	pill.add_child(h)
	var clock := HomeStyle.art("Clock")
	clock.texture = load(UiEventCard.F + "common/icons/icon_clock.png")
	clock.custom_minimum_size = Vector2(px * 1.7, px * 1.7)
	h.add_child(clock)
	var l := _ink("When", when_text(v), px)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return pill

# --------------------------------------------------------------- details ----

## Full-screen details for one instance; null while Events are locked or the instance is unknown.
## `auto_tutorial`: the walkthrough opens on top on the event's first visit.
static func open_details(stack, app, iid: String, auto_tutorial := true) -> BasePopup:
	if not app.feature_unlocked("events") or app.economy.events_v02.view(iid).is_empty():
		return null
	var id := String(app.economy.events_v02.view(iid)["id"])
	var p := BasePopup.new("event_details")
	p.set_meta("iid", iid)
	p.set_title(title(id))
	(p.find_child("Center", true, false) as Control).visible = false   # native full screen instead of the frame
	var bg := _art("EventBackground", SCENE % id, 0)   # the event's scene behind everything
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(bg)
	p.move_child(bg, 1)
	var shade := ColorRect.new()   # keeps the panels readable over a bright scene
	shade.name = "Shade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(accent(id).darkened(0.7), 0.25)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(shade)
	p.move_child(shade, 2)
	var screen := VBoxContainer.new()
	screen.name = "EventScreen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 0)
	(p.get_safe_root().get_node("MarginContainer/Content") as Control).add_child(screen)
	var top := HBoxContainer.new()
	top.name = "TopBar"
	screen.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.name = "DetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var list := VBoxContainer.new()
	list.name = "DetailList"
	list.custom_minimum_size.x = WIDTH
	list.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	center.add_child(list)
	TouchScroll.enable(scroll)
	_round_button(p.add_action("how", "i", "secondary", false, "", top), Color(0.106, 0.365, 0.788), UiText.t("EV2_HOW"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	_round_button(p.add_action("close", "X", "secondary", true, "", top), Color(0.85, 0.16, 0.18), UiText.t("POPUP_CLOSE"))
	# SB-TF-13: the green area is pinned under the scroll and the screen ends above the banner
	# (HomeStyle.banner_reserve), so JOIN / WATCH AD are never under the ad.
	var start := VBoxContainer.new()
	start.name = "StartArea"
	start.set_meta("coach", "start_button")
	start.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	start.custom_minimum_size.x = WIDTH
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_child(start)
	var ad_gap := Control.new()
	ad_gap.name = "BannerGap"
	ad_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(ad_gap)
	style_go(p.add_action("join", UiText.t("EV2_JOIN"), "primary", false, "", start))
	p.add_action("ad", UiText.t("EV2_WATCH_AD"), "secondary", false, "", start)
	var joined := _label("Joined", "", 30, HomeStyle.TEXT)
	joined.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start.add_child(joined)
	p.action_selected.connect(func(aid, _c):
		if aid == "join":
			app.actions.join_event(iid)
		elif aid.begins_with("rw:"):
			app.actions.claim_event_reward(iid, aid.substr(3))
		elif aid == "how":
			open_info(stack, app, iid)
		elif aid == "ad":
			if _watch_ad(p, app, iid):
				return   # refreshed + re-armed when the verified result arrives
		else:
			return
		refresh_details(p, app)
		p.rearm_soon())
	refresh_details(p, app)
	if not stack.push(p):
		p.free()
		return null
	_fit_banner_gap(p, app)
	var poll := Timer.new()   # SB-TF-13: WATCH AD appears in place once the next video has loaded
	poll.name = "AdPoll"
	poll.wait_time = 1.0
	poll.autostart = true
	poll.timeout.connect(func():
		if p.is_open() and not p.is_busy() and String(p.get_meta("ad_token", "")).is_empty():
			p.set_action_visible("ad", app.actions.event_ad_available(iid)))
	p.add_child(poll)
	var on_resolved := func(token: String, _product: String, _r: Dictionary):
		if is_instance_valid(p) and token == String(p.get_meta("ad_token", "")):
			p.set_meta("ad_token", "")
			refresh_details(p, app)
			p.rearm_soon()
	app.economy.rewarded.resolved.connect(on_resolved)
	p.tree_exited.connect(func():
		if app.economy.rewarded.resolved.is_connected(on_resolved):
			app.economy.rewarded.resolved.disconnect(on_resolved))
	if auto_tutorial and not app.economy.events_v02.tutorial_seen(id):   # first visit: the walkthrough opens once on top
		load(TUTORIAL).open(stack, app, iid)
	return p

## (i): the event's full rules (long text kept off the main screen) + HOW IT WORKS (replays the tutorial).
static func open_info(stack, app, iid: String) -> BasePopup:
	var v: Dictionary = app.economy.events_v02.view(iid)
	if not app.feature_unlocked("events") or v.is_empty():
		return null
	var p := BasePopup.new("event_info")
	p.set_frame("large")
	p.set_title(UiText.t("EV2_RULES"))
	var lines := [goal(v), "%s · %s" % [UiText.t("EV2_FAMILY_" + String(v["family"]).to_upper()), participants(v)], gain_text(v)]
	if TEAM_KINDS.has(v["kind"]):
		lines.append(UiText.t("EV2_YOUR_PART", [UiText.num(int(v["progress"])), UiText.num(int(v["min_player_contribution"]))]))
	if v["kind"] == "team_versus":
		lines.append(UiText.t("EV2_OPP_TOTAL", [UiText.num(int(v["opponent_total"]))]))
	if RIVAL_KINDS.has(v["kind"]):
		lines.append(UiText.t("EV2_CPU_NOTE"))
	for i in range(lines.size()):
		var l := _ink("Rule_%d" % i, String(lines[i]), 28)
		p.get_content().add_child(l)
	p.add_action("tutorial", UiText.t("EV2_HOW"), "primary", true)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(aid, _c):
		if aid == "tutorial":
			load(TUTORIAL).open(stack, app, iid))
	if not stack.push(p):
		p.free()
		return null
	return p

## Round (i) / X button: native circle with a gold rim.
static func _round_button(b: Button, body: Color, a11y: String) -> void:
	b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN + 8, UiTokens.TOUCH_MIN + 8)
	b.accessibility_name = a11y
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, HomeStyle.box(body if st != "pressed" else body.darkened(0.2), GOLD, 5, 60, 6, 2))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_outline_color", HomeStyle.OUTLINE)
	b.add_theme_constant_override("outline_size", 8)
	b.add_theme_font_size_override("font_size", 44)

## Start the event ad; true = a video is playing (the popup waits for `resolved`, abandoned after
## AD_TIMEOUT_S). A refusal or a synchronous result refreshes at once.
static func _watch_ad(p: BasePopup, app, iid: String) -> bool:
	var r: Dictionary = app.actions.start_event_ad(iid)
	app.analytics.track("ad_request", {"product": "event_progress", "ok": bool(r.get("ok", false)), "reason": String(r.get("reason", "ok"))})
	if not bool(r.get("ok", false)) or not app.economy.rewarded.result_for(String(r["token"])).is_empty():
		return false
	var token := String(r["token"])
	p.set_meta("ad_token", token)
	if p.is_inside_tree():
		p.get_tree().create_timer(AD_TIMEOUT_S).timeout.connect(func():
			if app.economy.rewarded.is_pending(token):
				app.actions.abandon_rewarded(token))
	return true

## Coach-mark targets this event's screen shows: the core sections + what its steps / kind need.
static func sections(v: Dictionary) -> Array:
	var need := {}
	for s in data(String(v["id"])).get("steps", []):
		need[String(s["target"])] = true
	var out := ["hero", "timer", "board", "team"]
	if STANDING_KINDS.has(v["kind"]) or need.has("ranking"):
		out.append("ranking")
	if need.has("map") or v["kind"] == "quest":
		out.append("map")
	out.append_array(["progress", "rewards", "start_button"])
	return out

## The Control tagged with coach target `key` on a details popup (null when absent).
static func target(p: Control, key: String) -> Control:
	for c in p.find_children("*", "Control", true, false):
		if String(c.get_meta("coach", "")) == key:
			return c
	return null

## Bottom gap = the banner reservation plus a little air (the screen's safe bottom is already kept).
static func _fit_banner_gap(p: BasePopup, app) -> void:
	var gap: Control = p.find_child("BannerGap", true, false)
	if gap != null and p.is_inside_tree():
		var r := HomeStyle.banner_reserve(app, p.get_viewport_rect().size.x)
		gap.custom_minimum_size.y = r + UiTokens.SPACE_LG if r > 0.0 else UiTokens.SPACE_SM

static func refresh_details(p: BasePopup, app) -> void:
	var ev = app.economy.events_v02
	var v: Dictionary = ev.view(String(p.get_meta("iid")))
	var id := String(v["id"])
	var list: VBoxContainer = p.find_child("DetailList", true, false)
	var start: Control = p.find_child("StartArea", true, false)
	var stash: Control = p.find_child("RewardStash", true, false)
	if stash == null:
		stash = Control.new()
		stash.name = "RewardStash"
		stash.visible = false
		p.get_content().add_child(stash)
	for c in list.get_children():
		if c == start:
			continue
		for b in c.find_children("Action_rw*", "Button", true, false):
			b.reparent(stash)
		list.remove_child(c)
		c.queue_free()
	for b in stash.get_children():
		p.set_action_blocked(b.get_meta("aid"), true)
	var a := accent(id)
	var pc := panel_color(id)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	list.add_child(head)
	var logo := _art("Logo", KIT % "logo", 130)   # the ScrubBots logo over the title, as in the storyboards
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(logo)
	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	head.add_child(title_row)
	var race: bool = RACE_KINDS.has(v["kind"])
	if race:
		title_row.add_child(_kit("FlagLeft", "flag_left", 96))
	var rib := Ribbon.make(title(id), a)
	rib.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(rib)
	if race:
		title_row.add_child(_kit("FlagRight", "flag_right", 96))
	var pill := _when_pill(v, 34)
	pill.set_meta("coach", "timer")
	head.add_child(_flanked("When", pill, "sparkle_left", "sparkle_right", 64))
	var banner := Glossy.make("GoalBanner", CREAM, GOLD, 34)
	var g := _ink("Goal", goal(v), 30)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(g)
	head.add_child(banner)
	var keys := sections(v)
	var stage := HBoxContainer.new()
	stage.name = "Stage"
	stage.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	list.add_child(stage)
	stage.add_child(_board(v, pc))
	stage.add_child(_hero(v, ev))
	list.add_child(_team(v, pc))
	if keys.has("ranking"):
		list.add_child(_ranking(v, ev, pc))
	if keys.has("map"):
		list.add_child(_map(v, pc))
	list.add_child(_progress(v, pc, app))
	list.add_child(_rewards(p, stash, v, pc, app))
	_fit_banner_gap(p, app)
	p.set_action_visible("join", v["phase"] == "active" and not v["joined"])
	p.set_action_blocked("join", app.is_blocked)
	p.set_action_visible("ad", app.actions.event_ad_available(String(v["iid"])))
	p.set_action_blocked("ad", app.is_blocked)
	var joined: Label = start.find_child("Joined", true, false)
	joined.text = UiText.t("EV2_JOINED") if v["joined"] else (UiText.t("EV2_PREVIEW") if v["phase"] != "active" else "")
	joined.visible = not joined.text.is_empty()

## Section panel: glossy body in the event's panel colour, bright gold rim, and a glossy header
## tab between two laurels with its native title.
static func _panel(n: String, coach: String, header: String, a: Color) -> PanelContainer:
	var s := Glossy.make(n, a, GOLD, 34)
	s.set_meta("coach", coach)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	s.add_child(box)
	if not header.is_empty():
		var tab := Glossy.make("Header", a.darkened(0.25), GOLD, 30)
		var l := HomeStyle.label(header, 34, HomeStyle.TEXT, 10)
		l.name = "HeaderText"
		tab.add_child(l)
		box.add_child(_flanked("HeaderRow", tab, "laurel", "laurel", 56))
	return s

## Shared kit piece (lossy WebP, a few KB) as a fixed-height TextureRect.
static func _kit(n: String, piece: String, h: int) -> TextureRect:
	var t := _art(n, KIT % piece, h)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h, h)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

## `c` centred between two kit pieces (the right one mirrored when both are the same piece).
static func _flanked(n: String, c: Control, left: String, right: String, h: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = n
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	row.add_child(_kit("KitLeft", left, h))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(c)
	var r := _kit("KitRight", right, h)
	r.flip_h = left == right
	row.add_child(r)
	return row

## Big glossy green button (native): white bold label, gloss band and a play arrow.
static func style_go(b: Button) -> void:
	var bodies := {"normal": Color("#4cc415"), "hover": Color("#5ad21f"), "pressed": Color("#3fa810"), "disabled": HomeStyle.GREEN_DISABLED}
	for st in bodies:
		b.add_theme_stylebox_override(st, HomeStyle.pad(HomeStyle.box(bodies[st], Color("#1f6b07"), 6, 60, 10, 8), 90, 12))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color("#1f5d07"))
	b.add_theme_constant_override("outline_size", 14)
	b.add_theme_font_size_override("font_size", 58)
	b.custom_minimum_size = Vector2(620, 132)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var g := GoShine.new()
	g.name = "Shine"
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(g)

## Host robot (approved roster art) with the event's key prop.
static func _hero(v: Dictionary, ev) -> Control:
	var id := String(v["id"])
	var h := Control.new()
	h.name = "Hero"
	h.set_meta("coach", "hero")
	h.custom_minimum_size = Vector2(0, 520)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var robot_id := host_robot(v, ev)
	var robot := _art("Robot", RobotRoster.asset(robot_id, "home_pose"), 0)
	robot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	robot.set_meta("robot", robot_id)
	robot.set_anchors_preset(Control.PRESET_FULL_RECT)
	robot.offset_bottom = -10
	h.add_child(robot)
	var props: Array = data(id).get("props", [])
	var prop := _art("Prop", PROP % [id, props[0]] if not props.is_empty() else ICON % id, 0)
	prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prop.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	prop.offset_top = -160
	prop.offset_left = -160
	h.add_child(prop)
	return h

## The REAL level board in a gold frame + what one win adds.
static func _board(v: Dictionary, a: Color) -> PanelContainer:
	var s := _panel("BoardPanel", "board", "", a)
	s.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var box: VBoxContainer = s.get_node("Box")
	box.add_child(board_view(430.0))
	var gain := HomeStyle.label(gain_text(v), 30, HomeStyle.SUBTITLE, 8)
	gain.name = "Gain"
	gain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gain.custom_minimum_size.x = 430
	box.add_child(gain)
	return s

## The real level, its whole artwork ACTIVE (SB-TF-13: the old half-cleaned preview left the top
## rows BG01 and read as a cut-off image), centred, nearest-neighbour, aspect kept.
static func board_view(side: float) -> Control:   ## BG01 panel holding the "Board" renderer
	var r = LevelLoader.load_from_path(LEVEL)
	if not r.is_ok():
		var none := Control.new()
		none.name = "Board"
		return none
	var board = BoardState.from_level_data(r.level_data)
	var view = BoardRenderer.new()
	view.name = "Board"
	view.configure(board, r.level_data.palette, Vector2(side, side))
	var back := PanelContainer.new()   # BG01 behind the board, as in gameplay
	back.name = "BoardBack"
	back.add_theme_stylebox_override("panel", HomeStyle.box(BG01, BG01, 0, 8, 0))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_child(view)
	return back

## Participants: you, team / rivals, the team totals (computer-controlled, labelled).
static func _team(v: Dictionary, a: Color) -> PanelContainer:
	var team: bool = TEAM_KINDS.has(v["kind"])
	var s := _panel("Team", "team", UiText.t("EV2_SEC_TEAM") if team else participants(v), a)
	var box: VBoxContainer = s.get_node("Box")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	box.add_child(h)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(rows)
	rows.add_child(_row("You", UiText.t("EV2_YOU"), UiText.num(int(v["progress"])) if v["joined"] else UiText.t("EV2_NOT_JOINED")))
	if team:
		rows.add_child(_row("Members", UiText.t("EV2_TEAMMATES"), UiText.num(int(v["team_total"]))))
	else:
		rows.add_child(_row("Family", UiText.t("EV2_FAMILY_" + String(v["family"]).to_upper()), ""))
	if v.has("team_size") or v.has("entrants"):   # size badge: team members / entrants
		var badge := PanelContainer.new()
		badge.name = "SizeBadge"
		badge.custom_minimum_size = Vector2(180, 0)
		badge.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(a.darkened(0.3), GOLD, 5, 26, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
		var bl := _info("Size", UiText.t("EV2_SIZE_BADGE", [UiText.num(int(v.get("team_size", v.get("entrants", 1))))]))
		bl.add_theme_font_size_override("font_size", 28)
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(bl)
		h.add_child(badge)
	if v["kind"] == "team_versus":
		rows.add_child(_row("Opponent", UiText.t("EV2_OPPONENT"), UiText.num(int(v["opponent_total"]))))
	if RIVAL_KINDS.has(v["kind"]):   # one short line; the full note is in the (i) rules
		box.add_child(_info("CpuNote", UiText.t("EV2_CPU_SHORT")))
	return s

## Cream row: name left, value right.
static func _row(n: String, left: String, right: String) -> PanelContainer:
	var r := PanelContainer.new()
	r.name = n
	r.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, GOLD_DARK, 2, 22, 0), UiTokens.SPACE_MD, 6))
	var h := HBoxContainer.new()
	r.add_child(h)
	var l := _ink("Name", left, 30)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var x := _ink("Score", right, 30)
	x.autowrap_mode = TextServer.AUTOWRAP_OFF
	x.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(x)
	return r

static func _info(n: String, text: String) -> Label:
	var l := _label(n, text, 26, HomeStyle.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Live standings (CPU-badged), Royale stages, bracket rounds, colors.
static func _ranking(v: Dictionary, ev, a: Color) -> PanelContainer:
	var s := _panel("Live", "ranking", UiText.t("EV2_SEC_RANKING"), a)
	var box: VBoxContainer = s.get_node("Box")
	box.add_child(_info("Progress", progress_text(v)))
	match String(v["kind"]):
		"race", "ranking", "royale":
			if v["kind"] == "royale":   # the stages as a row of boxes
				box.add_child(_chips("Stages", range((v["stage_counts"] as Array).size()).map(func(i): return UiText.t("EV2_STAGE", [UiText.num(i + 1), UiText.num(int(v["stage_counts"][i]))])), a))
			var rec: Dictionary = ev._record(v["iid"])
			var rows: Array = v["standings"]
			var you := rows.find(rows.filter(func(r): return r["player"])[0])
			for i in range(rows.size()):
				if i < MAX_ROWS or i == you:
					box.add_child(_standing(i + 1, rows[i], ev, rec))
		"bracket":
			var b: Dictionary = v["bracket"]
			var rec: Dictionary = ev._record(v["iid"])
			box.add_child(_chips("Rounds", [UiText.t("EV2_ROUND_1"), UiText.t("EV2_ROUND_2"), UiText.t("EV2_ROUND_3")], a))
			for r in range((b["rounds"] as Array).size()):
				box.add_child(_info("Round_%d" % (r + 1), UiText.t("EV2_ROUND_%d" % (r + 1))))
				for m in b["rounds"][r]:
					box.add_child(_info("Match", UiText.t("EV2_MATCH", [_who(m[0], ev, rec), UiText.num(m[2]), UiText.num(m[3]), _who(m[1], ev, rec)])))
		"colors":
			for c in v["params"]["colors"]:
				var row := HBoxContainer.new()
				row.name = "Color_" + String(c)
				row.add_theme_constant_override("separation", UiTokens.SPACE_SM)
				var sw := ColorRect.new()
				sw.color = color_value(String(c))
				sw.custom_minimum_size = Vector2(40, 40)
				row.add_child(sw)
				var l := _label("Text", UiText.t("EV2_COLOR_ROW", [color_name(String(c)), UiText.num(int(v["colors"].get(c, 0))), UiText.num(300)]), 24, HomeStyle.TEXT)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(l)
				box.add_child(row)
	return s

## A row of accent boxes (Royale stages / bracket rounds), sized to share the width.
static func _chips(n: String, texts: Array, a: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = n
	row.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	for i in range(texts.size()):
		var c := PanelContainer.new()
		c.name = "Chip_%d" % (i + 1)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(a.lightened(0.15), GOLD, 3, 18, 4, 2), UiTokens.SPACE_XS, UiTokens.SPACE_XS))
		var l := _info("Text", String(texts[i]))
		l.add_theme_font_size_override("font_size", 20)
		c.add_child(l)
		row.add_child(c)
	return row

static func _who(idx: int, ev, rec: Dictionary) -> String:
	return UiText.t("EV2_YOU") if idx == 0 else "%s (%s)" % [ev.entrant(rec, idx)["name"], UiText.t("EV2_CPU")]

static func _standing(place: int, r: Dictionary, ev, rec: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = "You" if r["player"] else "Rival_%d" % int(r["idx"])
	row.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(GOLD if r["player"] else CREAM, GOLD_DARK, 2, 20, 0), UiTokens.SPACE_SM, 2))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	row.add_child(h)
	var pl := _ink("Place", "%s." % UiText.num(place), 22)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pl.custom_minimum_size.x = 56
	h.add_child(pl)
	var pic := HomeStyle.art("Avatar")
	pic.custom_minimum_size = Vector2(40, 40)
	var robot := "scrubby" if r["player"] else String(ev.entrant(rec, int(r["idx"]))["robot"])
	pic.texture = art_texture(RobotRoster.asset(robot, "portrait"))
	h.add_child(pic)
	var name := _ink("Name", UiText.t("EV2_YOU") if r["player"] else "%s · %s" % [ev.entrant(rec, int(r["idx"]))["name"], UiText.t("EV2_CPU")], 22)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var sc := _ink("Score", UiText.num(int(r["score"])), 22)
	sc.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(sc)
	return row

## The event's map: its key props in a row (+ quest objectives).
static func _map(v: Dictionary, a: Color) -> PanelContainer:
	var id := String(v["id"])
	var s := _panel("Map", "map", UiText.t("EV2_SEC_MAP"), a)
	var box: VBoxContainer = s.get_node("Box")
	var row := HBoxContainer.new()
	row.name = "Props"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	box.add_child(row)
	for n in data(id).get("props", []):
		var p := _art("Prop_" + String(n), PROP % [id, n], 0)
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.custom_minimum_size = Vector2(200, 180)
		row.add_child(p)
	if v["kind"] == "quest":
		box.add_child(_info("Objectives", UiText.t("EV2_OBJECTIVES", [UiText.num(int(v["objectives"]))])))
	return s

## Target track: rail + done / current / open nodes (native) with each target value, and the meter.
static func _progress(v: Dictionary, a: Color, app) -> PanelContainer:
	var s := _panel("Progress", "progress", UiText.t("EV2_SEC_PROGRESS"), a)
	var box: VBoxContainer = s.get_node("Box")
	var vals := track_values(v)
	if not vals.is_empty():
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
		box.add_child(h)
		var t := Track.make(vals, score(v))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		var goal_icon := HomeStyle.art("GoalReward")   # the last step's real reward at the end of the rail
		goal_icon.texture = load(UiEventCard.F + "rewards/%s.png" % UiEventCard.reward_icon((v["steps"] as Array).back()["reward"]))
		goal_icon.custom_minimum_size = Vector2(120, 110)
		h.add_child(goal_icon)
	var bar := _meter(v)
	var to := bar.value
	var reduced: bool = app.effects != null and app.effects.is_reduced()
	bar.set_meta("animated", not reduced)
	if not reduced:   # Reduced Effects: the meter shows its value at once
		bar.value = 0.0
		bar.ready.connect(func(): bar.create_tween().tween_property(bar, "value", to, 0.6))
	box.add_child(bar)
	box.add_child(_info("Value", progress_text(v)))
	return s

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

static func _rewards(p: BasePopup, stash: Control, v: Dictionary, a: Color, app) -> PanelContainer:
	var s := _panel("Rewards", "rewards", UiText.t("EV2_SEC_REWARDS"), a)
	var box: VBoxContainer = s.get_node("Box")
	if not v["claims_enabled"]:
		box.add_child(_info("Preview", UiText.t("EV2_PREVIEW")))
	var flow := HFlowContainer.new()
	flow.name = "RewardRow"
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
	flow.add_theme_constant_override("v_separation", UiTokens.SPACE_SM)
	box.add_child(flow)
	for st in v["steps"]:
		flow.add_child(_reward_chip(p, stash, v, st, app))
	return s

## One reward step: real reward icon, its target, the reward, and CLAIM / done / locked.
static func _reward_chip(p: BasePopup, stash: Control, v: Dictionary, s: Dictionary, app) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "Step_" + String(s["rid"])
	chip.custom_minimum_size = Vector2(230, 0)
	chip.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, GOLD, 5, 26, 6, 2), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	chip.add_child(col)
	var icon := HomeStyle.art("Icon")
	icon.texture = load(UiEventCard.F + "rewards/%s.png" % UiEventCard.reward_icon(s["reward"]))
	icon.custom_minimum_size = Vector2(0, 110)
	col.add_child(icon)
	var t := _ink("Text", step_label(v, s), 24)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var r := _ink("Reward", UiText.reward_text(s["reward"]), 18)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(r)
	if s["claimed"]:
		var d := _ink("State", UiText.t("ACH_DONE"), 22)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(d)
	elif s["claimable"] and v["claims_enabled"]:
		var aid := "rw:" + String(s["rid"])
		var b: Button = p.get_action_button(aid)
		if b == null:
			b = p.add_action(aid, "", "secondary", false, "", col)
		else:
			b.reparent(col)
		b.set_meta("aid", aid)
		b.text = UiText.t("POPUP_CLAIM")
		b.custom_minimum_size = Vector2(190, UiTokens.TOUCH_MIN)
		p.set_action_blocked(aid, app.is_blocked)
	else:
		var lock := HomeStyle.art("Locked")
		lock.texture = load(UiEventCard.F + ("common/icons/icon_check.png" if s["reached"] else "common/icons/icon_lock.png"))
		lock.custom_minimum_size = Vector2(0, 44)
		col.add_child(lock)
	return chip

## Title ribbon drawn natively like the storyboards: a glossy band with a bright gold rim, and
## curled ends (tails behind the band, folded under it) with notched tips.
class Ribbon extends Container:
	var accent := Color.BLUE

	static func make(text: String, a: Color) -> Control:
		var r := Ribbon.new()
		r.name = "TitleRibbon"
		r.accent = a
		r.custom_minimum_size = Vector2(0, 200)
		var l := HomeStyle.label(text, 84, HomeStyle.SUBTITLE, 20)
		l.name = "Title"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", a.darkened(0.7))
		l.add_theme_constant_override("shadow_offset_y", 6)
		HomeStyle.fit_on_resize(l, 84)
		r.add_child(l)
		return r

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			for c in get_children():
				fit_child_in_rect(c, Rect2(Vector2(100, 8), size - Vector2(200, 56)))

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var band := Rect2(60, 0, w - 120, h - 44)
		for side in [-1.0, 1.0]:
			var x0: float = 0.0 if side < 0 else w   # outer tip
			var x1: float = 150.0 if side < 0 else w - 150.0   # inner end, under the band
			var xb: float = band.position.x if side < 0 else band.end.x
			var tail := PackedVector2Array([Vector2(x1, 44), Vector2(x0, 44), Vector2(x0 - side * 44.0, (h + 44) / 2.0), Vector2(x0, h), Vector2(x1, h)])
			draw_colored_polygon(tail, accent.darkened(0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(x1, 44), Vector2(x0, 44), Vector2(x0, 64), Vector2(x1, 64)]), Color(1, 1, 1, 0.14))
			var rim := tail.duplicate()
			rim.append(tail[0])
			draw_polyline(rim, GOLD, 5.0, true)
			var fold := PackedVector2Array([Vector2(xb, h - 44), Vector2(x1, h - 44), Vector2(x1, h)])   # the curl under the band
			draw_colored_polygon(fold, accent.darkened(0.65))
		draw_style_box(HomeStyle.box(accent, GOLD, 8, 34, 12), band)
		var hi := StyleBoxFlat.new()   # gloss on the upper half
		hi.bg_color = Color(1, 1, 1, 0.22)
		hi.set_corner_radius_all(26)
		draw_style_box(hi, Rect2(band.position + Vector2(12, 10), Vector2(band.size.x - 24, band.size.y * 0.42)))
		var low := StyleBoxFlat.new()   # deeper lower edge
		low.bg_color = Color(0, 0, 0, 0.16)
		low.set_corner_radius_all(26)
		draw_style_box(low, Rect2(band.position + Vector2(10, band.size.y * 0.66), Vector2(band.size.x - 20, band.size.y * 0.3)))

## Glossy panel: fill + bright rim from the stylebox, then a light top band and a darker lower band
## drawn over the fill (under the children), like the storyboards' candy panels.
class Glossy extends PanelContainer:
	var radius := 30

	static func make(n: String, fill: Color, rim: Color, r: int) -> Glossy:
		var g := Glossy.new()
		g.name = n
		g.radius = r
		var sb := HomeStyle.pad(HomeStyle.box(fill, rim, 6, r, 10, 2), UiTokens.SPACE_MD, UiTokens.SPACE_SM)
		g.add_theme_stylebox_override("panel", sb)
		return g

	func _draw() -> void:
		var hi := StyleBoxFlat.new()
		hi.bg_color = Color(1, 1, 1, 0.2)
		hi.set_corner_radius_all(maxi(4, radius - 8))
		draw_style_box(hi, Rect2(Vector2(8, 8), Vector2(size.x - 16, minf(size.y * 0.4, 90.0))))
		var lo := StyleBoxFlat.new()
		lo.bg_color = Color(0, 0, 0, 0.14)
		lo.set_corner_radius_all(maxi(4, radius - 8))
		var lh := minf(size.y * 0.3, 80.0)
		draw_style_box(lo, Rect2(Vector2(8, size.y - lh - 8), Vector2(size.x - 16, lh)))

## Gloss band + white play arrow over a green button (drawn, no texture).
class GoShine extends Control:
	func _draw() -> void:
		var hi := StyleBoxFlat.new()
		hi.bg_color = Color(1, 1, 1, 0.28)
		hi.set_corner_radius_all(40)
		draw_style_box(hi, Rect2(Vector2(18, 12), Vector2(size.x - 36, size.y * 0.36)))
		var c := Vector2(size.x - 70.0, size.y / 2.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -24), c + Vector2(22, 0), c + Vector2(-16, 24)]), Color.WHITE)

## Target track: a rail with one node per target (done = green check, current = gold, open = cream).
class Track extends VBoxContainer:
	var done := 0

	static func make(values: Array, now: int) -> Track:
		var t := Track.new()
		t.name = "Track"
		var row := HBoxContainer.new()
		row.name = "Nodes"
		t.add_child(row)
		var current := -1
		for i in range(values.size()):
			if int(values[i]) <= now:
				t.done += 1
			elif current < 0:
				current = i
		for i in range(values.size()):
			var n := VBoxContainer.new()
			n.name = "Node_%d" % i
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var dot := Dot.new()
			dot.state = "done" if i < t.done else ("current" if i == current else "open")
			dot.custom_minimum_size = Vector2(64, 64) if values.size() <= 8 else Vector2(44, 44)
			dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			n.set_meta("state", dot.state)
			if dot.state == "current":   # the storyboards' gold star marks where you are
				var star := HomeStyle.art("Star")
				star.texture = load(KIT % "star")
				star.set_anchors_preset(Control.PRESET_FULL_RECT)
				dot.add_child(star)
			n.add_child(dot)
			var l := HomeStyle.label(UiText.num(int(values[i])), 24 if values.size() <= 8 else 18, Color.WHITE, 6)
			l.name = "Value"
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n.add_child(l)
			row.add_child(n)
		row.sort_children.connect(t.queue_redraw)
		return t

	func _draw() -> void:
		var row: HBoxContainer = get_node("Nodes")
		var first: Control = row.get_child(0)
		var last: Control = row.get_child(row.get_child_count() - 1)
		var y := row.position.y + (first.get_child(0) as Control).size.y / 2.0
		var x0 := row.position.x + first.position.x + first.size.x / 2.0
		draw_line(Vector2(x0, y), Vector2(row.position.x + last.position.x + last.size.x / 2.0, y), CREAM, 16.0, true)
		if done > 0:
			var d: Control = row.get_child(done - 1)
			draw_line(Vector2(x0, y), Vector2(row.position.x + d.position.x + d.size.x / 2.0, y), HomeStyle.GREEN, 16.0, true)

class Dot extends Control:
	var state := "open"

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 2.0
		match state:
			"done":
				draw_circle(c, r, GOLD)
				draw_circle(c, r - 6.0, HomeStyle.GREEN)
				draw_polyline(PackedVector2Array([c + Vector2(-13, 0), c + Vector2(-3, 10), c + Vector2(14, -10)]), Color.WHITE, 6.0, true)
			"current":
				draw_circle(c, r, GOLD_DARK)
				draw_circle(c, r - 5.0, GOLD)
				draw_circle(c, r - 16.0, Color(1, 1, 1, 0.85))
			_:
				draw_circle(c, r - 8.0, GOLD_DARK)
				draw_circle(c, r - 13.0, CREAM)
