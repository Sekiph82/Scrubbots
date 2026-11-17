extends RefCounted
## EventTutorial — preload (res://scripts/ui/events/event_tutorial.gd).
##
## SB-EV02-009 — ONE reusable three-step walkthrough for every V02 event: 24 events x 3 steps =
## 72 native UI states, each built from data (state()) and that event's live view, never from
## painted screenshots. Coachmark grammar of the owner storyboards: the step's target block is
## lit with a gold frame while the other blocks dim, and a cream speech bubble with a blue
## border and a pointer explains one fact:
##   1 intro    — the event hero + emblem, its canonical host robot, the goal and participants;
##   2 how-to   — a REAL campaign level board (BoardRenderer: one Image, one TextureRect, half its
##                artwork cleaned) and what one win adds to this event (+gain, live diagram:
##                race / table / stages / bracket / team / colors / milestone meter);
##   3 rewards  — the event's real reward steps (existing reward types), time left and JOIN.
## No gameplay of its own: nothing here can clear a cell or play a level. Reduced Effects =
## the meter jumps to its value instead of animating. Locked before Level 30 like every Events entry.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiEventCard = preload("res://scripts/ui/components/ui_event_card.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")

const STEPS := 3
const FOCUS := ["hero", "board", "rewards"]
## A real campaign level (Level 4, catalog entry level_004_orange_cat) shown as the board.
const LEVEL := "res://data/levels/level_004_orange_cat.json"
const CREAM := Color(1.0, 0.965, 0.863)
const BUBBLE_EDGE := Color(0.122, 0.384, 0.851)
const DIM := Color(1, 1, 1, 0.45)
const BG01 := Color("#202533")   ## gameplay background seen through CLEARED cells

## The event's canonical host robot (roster order, rotating through the ten robots).
static func host_robot(v: Dictionary, ev) -> String:
	return EventsV02.ROBOTS[maxi(0, ev.event_ids().find(v["id"])) % EventsV02.ROBOTS.size()]

## What one qualifying win adds to this event (step 2 caption).
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

## Data of one of the 72 states (what the tests assert and _show renders).
static func state(v: Dictionary, step: int, ev) -> Dictionary:
	var s := {"step": step, "focus": FOCUS[step - 1], "event": v["id"], "title": EventsV02Ui.title(v["id"])}
	match step:
		1:
			s["bubble"] = EventsV02Ui.goal(v)
			s["detail"] = EventsV02Ui.participants(v)
			s["hero"] = EventsV02Ui.HERO % v["id"]
			s["icon"] = EventsV02Ui.ICON % v["id"]
			s["robot"] = host_robot(v, ev)
		2:
			s["gain"] = gain_text(v)
			s["bubble"] = UiText.t("EV2_TUT2", [s["title"], s["gain"]])
			s["level"] = LEVEL
			s["diagram"] = v["kind"]
			s["lines"] = diagram_lines(v, ev)
		3:
			s["bubble"] = UiText.t("EV2_TUT3", [s["title"], UiText.time_left(int(v["ends_in"] if v["phase"] != "upcoming" else v["starts_in"]))])
			s["rewards"] = (v["steps"] as Array).map(func(x): return {"label": EventsV02Ui.step_label(v, x), "reward": x["reward"]})
			s["join"] = v["phase"] == "active" and not v["joined"]
	return s

static func open(stack, app, iid: String) -> BasePopup:
	if not app.feature_unlocked("events"):
		return null
	var v: Dictionary = app.economy.events_v02.view(iid)
	if v.is_empty():
		return null
	var p := BasePopup.new("event_tutorial")
	p.set_frame("large")
	p.set_meta("iid", iid)
	p.set_meta("step", 1)
	var body := VBoxContainer.new()
	body.name = "Tutorial"
	body.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	body.custom_minimum_size.y = 1180
	p.get_content().add_child(body)
	p.add_action("tut_join", UiText.t("EV2_JOIN"), "primary", true)
	p.add_action("tut_back", UiText.t("EV2_BACK"), "secondary", false, "nav")
	p.add_action("tut_next", UiText.t("EV2_NEXT"), "secondary", false, "nav")
	p.add_action("tut_close", UiText.t("EV2_GOT_IT"), "secondary", true, "nav")
	p.action_selected.connect(func(id, _c):
		match id:
			"tut_next":
				p.set_meta("step", mini(STEPS, int(p.get_meta("step")) + 1))
			"tut_back":
				p.set_meta("step", maxi(1, int(p.get_meta("step")) - 1))
			"tut_join":
				app.actions.join_event(iid)
				return
			_:
				return
		show_step(p, app, int(p.get_meta("step")))
		p.rearm_soon())
	app.actions.mark_event_tutorial_seen(String(v["id"]))
	show_step(p, app, 1)
	if not stack.push(p):
		p.free()
		return null
	return p

## Renders `step` of the popup's event (also used directly by tests / captures).
static func show_step(p: BasePopup, app, step: int) -> void:
	var ev = app.economy.events_v02
	var v: Dictionary = ev.view(String(p.get_meta("iid")))
	var st := state(v, step, ev)
	p.set_meta("step", step)
	p.set_meta("state", st)
	p.set_title(String(st["title"]).to_upper())   # English product names: no Turkish dotted-I casing
	var body: VBoxContainer = p.find_child("Tutorial", true, false)
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	body.add_child(_ink("StepLabel", UiText.t("EV2_STEP", [UiText.num(step), UiText.num(STEPS)]), 24))
	var reduced: bool = app.effects != null and app.effects.is_reduced()
	var blocks := {"hero": _hero_block(String(v["id"]), host_robot(v, ev)), "board": _board_block(v, st, ev, reduced and step == 2, step == 2), "rewards": _reward_block(v)}
	for k in FOCUS:
		var b: Control = blocks[k]
		if k == st["focus"]:
			b.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, HomeStyle.GOLD, 6, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
			b.set_meta("focus", true)
		else:
			b.modulate = DIM
		body.add_child(b)
		if k == st["focus"]:
			body.add_child(_bubble(String(st["bubble"]) + ("\n" + String(st["detail"]) if st.has("detail") else "")))
	p.set_action_visible("tut_back", step > 1)
	p.set_action_visible("tut_next", step < STEPS)
	p.set_action_visible("tut_close", step == STEPS)
	p.set_action_visible("tut_join", step == STEPS and bool(st["join"]))
	p.set_action_blocked("tut_join", app.is_blocked)

static func _block(n: String) -> PanelContainer:
	var b := PanelContainer.new()
	b.name = n
	b.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	return b

static func _hero_block(id: String, robot_id: String) -> PanelContainer:
	var b := _block("HeroBlock")
	var hero := EventsV02Ui._art("EventHero", EventsV02Ui.HERO % id, 300)
	b.add_child(hero)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -150
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(row)
	var icon := EventsV02Ui._art("EventIcon", EventsV02Ui.ICON % id, 140)
	icon.custom_minimum_size = Vector2(140, 140)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var robot := EventsV02Ui._art("Robot", RobotRoster.asset(robot_id, "portrait"), 150)
	robot.custom_minimum_size = Vector2(150, 150)
	robot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	robot.set_meta("robot", robot_id)
	row.add_child(robot)
	return b

## Real level board + the event's gain caption and live diagram with its meter.
static func _board_block(v: Dictionary, st: Dictionary, ev, reduced: bool, animate: bool) -> PanelContainer:
	var b := _block("BoardBlock")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	b.add_child(h)
	h.add_child(board_view(300.0))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	h.add_child(col)
	var gain := HomeStyle.label(gain_text(v), 30, HomeStyle.GREEN_EDGE, 0)
	gain.name = "Gain"
	gain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(gain)
	for line in st.get("lines", diagram_lines(v, ev)):
		col.add_child(_ink("Line", line, 20))
	var bar := ProgressBar.new()
	bar.name = "Meter"
	bar.show_percentage = false
	var next := _next_target(v)
	bar.max_value = maxi(1, next)
	HomeStyle.style_meter(bar, HomeStyle.GREEN, 36)
	col.add_child(bar)
	var to := clampf(float(_score(v)) + 1.0, 0.0, bar.max_value)
	if animate and not reduced:
		bar.value = float(_score(v))
		bar.set_meta("animated", true)
		bar.ready.connect(func(): bar.create_tween().tween_property(bar, "value", to, 0.8))
	else:
		bar.value = to
		bar.set_meta("animated", false)
	return b

## The real level, half of its artwork cleaned (CLEARED cells show BG01 through).
static func board_view(side: float) -> Control:   ## BG01 panel holding the "Board" renderer
	var r = LevelLoader.load_from_path(LEVEL)
	if not r.is_ok():
		var none := Control.new()
		none.name = "Board"
		return none
	var board = BoardState.from_level_data(r.level_data)
	var half: int = board.get_artwork_cell_count() / 2
	var n := 0
	for i in range(board.get_cell_count()):
		if n < half and not board.is_void(i):
			board.set_cell_state(i, BoardState.CellState.CLEARED)
			n += 1
	var view = BoardRenderer.new()
	view.name = "Board"
	view.configure(board, r.level_data.palette, Vector2(side, side))
	var back := PanelContainer.new()   # BG01 behind the board, as in gameplay
	back.name = "BoardBack"
	back.add_theme_stylebox_override("panel", HomeStyle.box(BG01, BG01, 0, 8, 0))
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_child(view)
	return back

static func _score(v: Dictionary) -> int:
	match String(v["kind"]):
		"team_milestones", "team_versus":
			return int(v["team_total"])
		"streak":
			return int(v["best"])
	return int(v["progress"])

static func _next_target(v: Dictionary) -> int:
	for s in v["steps"]:
		if s["rid"].begins_with("m") and int(s["value"]) > _score(v):
			return int(s["value"])
	if v["kind"] == "race":
		return int(v["params"]["goal"])
	return maxi(1, _score(v) + 1)

## Event-specific progress representation, all from the live view.
static func diagram_lines(v: Dictionary, ev) -> Array:
	var out: Array = []
	var rec: Dictionary = ev._record(v["iid"])
	match String(v["kind"]):
		"race", "ranking":
			for r in (v["standings"] as Array).slice(0, 5):
				out.append("%s  %s" % [UiText.t("EV2_YOU") if r["player"] else "%s · %s" % [ev.entrant(rec, int(r["idx"]))["name"], UiText.t("EV2_CPU")], UiText.num(int(r["score"]))])
		"royale":
			for i in range((v["stage_counts"] as Array).size()):
				out.append(UiText.t("EV2_STAGE", [UiText.num(i + 1), UiText.num(int(v["stage_counts"][i]))]))
		"bracket":
			for r in range(3):
				out.append(UiText.t("EV2_ROUND_%d" % (r + 1)))
		"team_milestones", "team_versus":
			out.append(EventsV02Ui.participants(v))
			out.append(UiText.t("EV2_TEAM_TOTAL", [UiText.num(int(v["team_total"]))]))
			if v["kind"] == "team_versus":
				out.append(UiText.t("EV2_OPP_TOTAL", [UiText.num(int(v["opponent_total"]))]))
		"colors":
			for c in v["params"]["colors"]:
				out.append(UiText.t("EV2_COLOR_ROW", [EventsV02Ui.color_name(String(c)), UiText.num(int(v["colors"].get(c, 0))), UiText.num(300)]))
		"quest":
			out.append(UiText.t("EV2_OBJECTIVES", [UiText.num(int(v["objectives"]))]))
		_:
			out.append(UiText.t("EV2_PROGRESS", [UiText.num(_score(v))]))
	var targets: Array = (v["steps"] as Array).filter(func(x): return String(x["rid"]).begins_with("m")).map(func(x): return UiText.num(int(x["value"])))
	if not targets.is_empty():   # the event's own target track, e.g. 3 > 7 > 12 > 20
		out.append(" > ".join(targets))
	return out

static func _reward_block(v: Dictionary) -> PanelContainer:
	var b := _block("RewardBlock")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	b.add_child(col)
	var when := HBoxContainer.new()
	when.alignment = BoxContainer.ALIGNMENT_END
	when.add_child(UiEventCard._pill("WhenPill", "When", EventsV02Ui.when_text(v), "common/icons/icon_clock.png"))
	col.add_child(when)
	var path := HFlowContainer.new()
	path.name = "RewardPath"
	path.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
	col.add_child(path)
	for s in v["steps"]:
		var chip := VBoxContainer.new()
		chip.name = "Reward_" + String(s["rid"])
		chip.custom_minimum_size = Vector2(150, 0)
		var icon := HomeStyle.art("Icon")
		icon.texture = load(UiEventCard.F + "rewards/%s.png" % UiEventCard.reward_icon(s["reward"]))
		icon.custom_minimum_size = Vector2(72, 72)
		chip.add_child(icon)
		var l := _ink("Label", EventsV02Ui.step_label(v, s), 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(l)
		path.add_child(chip)
	return b

## Cream speech bubble, thick blue border, navy copy, pointer up at the lit block.
static func _bubble(text: String) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.name = "Bubble"
	wrap.add_theme_constant_override("separation", 0)
	var tip := Control.new()
	tip.name = "Pointer"
	tip.custom_minimum_size = Vector2(0, 26)
	var poly := Polygon2D.new()
	poly.color = BUBBLE_EDGE
	poly.polygon = PackedVector2Array([Vector2(70, 26), Vector2(100, 0), Vector2(130, 26)])
	tip.add_child(poly)
	wrap.add_child(tip)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, BUBBLE_EDGE, 6, 26, 0), UiTokens.SPACE_LG, UiTokens.SPACE_MD))
	wrap.add_child(panel)
	var l := _ink("Text", text, 28)
	panel.add_child(l)
	return wrap

static func _ink(n: String, text: String, size: int) -> Label:
	var l := BasePopup.body_label(text, size, BasePopup.INK)
	l.name = n
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l
