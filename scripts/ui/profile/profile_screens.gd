extends RefCounted
## ProfileScreens — preload (res://scripts/ui/profile/profile_screens.gd).
##
## M43-C010 / C010R app-level destinations in the approved popup family (every value live):
##   - PROFILE (SB-M43-124, R10-006/007; SB-M43-125-REBUILD master v01): hero card (active
##     robot, level badge, Bot Parts meter), stat tiles (level, cleared, Collection, robots,
##     achievements, login days) and a Personal Bests table (current vs own best; self only);
##   - ACHIEVEMENTS (SB-M43-126): data-driven list with progress and completed state;
##   - EVENTS (SB-M43-128/129, R10-001..005): configured Weekly Cleaning Events (window,
##     countdown, progress, fixed milestone rewards, ended/claimed) and the opt-in First-Try
##     Cleanup; an honest empty state when nothing is scheduled. No event currency;
##   - RANKS (SB-M43-122): the player's own rank ladder from campaign levels cleared.
## Claims / joins go through ProductionActionFacade. These screens own no rule or value.

const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const PersonalRank = preload("res://scripts/progression/personal_rank.gd")
const UiProgressMeter = preload("res://scripts/ui/components/ui_progress_meter.gd")

# ---------------------------------------------------------------- PROFILE ----

const F := "res://assets/ui/final/"

## SB-M43-125-REBUILD: native rebuild of scrubbots_profile_master_v01 — hero card, 2x3 stat
## tiles, Personal Bests table (Current / Best), self-only note, three actions.
static func open_profile(stack, app) -> BasePopup:
	var e = app.economy
	var rid: String = e.robots.active_robot()
	var p := BasePopup.new("profile")
	p.set_frame("large")
	p.set_title(UiText.t("PROFILE_TITLE"))
	var c := p.get_content()
	var s := Achievements.stats(app)
	var ach := Achievements.evaluate(app)
	var done := ach.filter(func(a): return a["done"]).size()
	var level := int(app.progression.current_level())
	c.add_child(_hero(rid, level, e.robots.next_robot_progress()))
	var grid := GridContainer.new()
	grid.name = "ProfileStats"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
	grid.add_theme_constant_override("v_separation", UiTokens.SPACE_SM)
	c.add_child(grid)
	for t in [
		["Level", "home/top_hud/profile_rank_badge.png", UiText.t("PROFILE_LEVEL"), UiText.num(level)],
		["Cleared", "daily/daily_task_check.png", UiText.t("PROFILE_LEVELS_CLEARED"), UiText.num(int(s["levels_completed"]))],
		["Collection", "home/shortcuts/icon_shortcut_collection.png", UiText.t("PROFILE_COLLECTION"), UiText.t("HOME_RATIO", [UiText.num(int(s["cards_unique"])), UiText.num(e.collection.all_card_ids().size())])],
		["Robots", "common/navigation/icon_nav_robots.png", UiText.t("PROFILE_ROBOTS"), UiText.t("HOME_RATIO", [UiText.num(int(s["robots_unlocked"])), UiText.num(RobotRoster.ids().size())])],
		["AchievementSummary", "profile/profile_trophy_icon.png", UiText.t("PROFILE_ACHIEVEMENTS"), UiText.t("HOME_RATIO", [UiText.num(done), UiText.num(ach.size())])],
		["LoginDays", "daily/daily_login_calendar.png", UiText.t("PROFILE_LOGIN_DAYS"), UiText.num(int(e.daily.streak()))],
	]:
		grid.add_child(_tile(t[0], t[1], t[2], t[3], UiText.num(level) if t[0] == "Level" else ""))
	var r = e.records
	var card := PanelContainer.new()
	card.name = "ProfileBests"
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 26, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	c.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	card.add_child(v)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROYAL, BasePopup.ROYAL_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	v.add_child(head)
	var title := HomeStyle.label(UiText.t("PROFILE_BESTS"), 36)
	title.name = "BestsTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var cols := HBoxContainer.new()
	cols.name = "BestsColumns"
	v.add_child(cols)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(gap)
	for k in ["BEST_CURRENT", "BEST_BEST"]:
		cols.add_child(_cell(UiText.t(k), 24))
	cols.add_child(_spacer(UiTokens.SPACE_SM))
	_best_row(v, "BestStreak", "daily/daily_streak_flame.png", UiText.t("BEST_WIN_STREAK"), int(e.streak.streak()), int(s["best_win_streak"]))
	_best_row(v, "BestFirstTry", "popups/victory/victory_emblem.png", UiText.t("BEST_FIRST_TRY"), int(r.get_value("first_try_run")), int(r.get_value("best_first_try_run")))
	_best_row(v, "BestBoosterless", "profile/profile_no_booster_icon.png", UiText.t("BEST_BOOSTERLESS"), int(r.get_value("boosterless_run")), int(r.get_value("best_boosterless_run")))
	p.add_body_line(UiText.t("PROFILE_BOOSTERLESS_TOTAL", [UiText.num(int(r.get_value("boosterless_wins")))]), "BoosterlessTotal", BasePopup.INK, 22)
	p.add_body_line(UiText.t("PROFILE_SELF_ONLY"), "SelfOnly", BasePopup.INK, 24)
	p.add_action("achievements", UiText.t("ACHIEVEMENTS_TITLE"), "primary", false)
	p.add_action("notifications", UiText.t("NOTIFY_TITLE"), "secondary", false)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id == "achievements" or id == "notifications":
			var a = open_achievements(stack, app) if id == "achievements" else open_notifications(stack, app)
			if a != null:
				a.closed.connect(func(_x):
					if is_instance_valid(p):
						p.rearm(), CONNECT_ONE_SHOT))
	if not stack.push(p):
		p.free()
		return null
	return p

## Blue hero card: active robot portrait in the round HUD frame, its name, the campaign level
## badge and the same Bot Parts meter as the Home top HUD (next 250-part robot, never XP).
static func _hero(rid: String, level: int, parts: Dictionary) -> PanelContainer:
	var hero := PanelContainer.new()
	hero.name = "ProfileHero"
	hero.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROYAL, BasePopup.ROYAL_EDGE, 4, 30, 6, 4), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	hero.add_child(row)
	var avatar := HomeStyle.art("ProfileAvatarFrame")
	avatar.texture = load(F + "home/top_hud/profile_avatar_frame.png")
	avatar.custom_minimum_size = Vector2(170, 170)
	row.add_child(avatar)
	var portrait := HomeStyle.art("ProfilePortrait")
	portrait.texture = load(RobotRoster.asset(rid, "portrait"))
	portrait.anchor_top = 0.04   # the portrait's own transparent margin keeps it inside the ring
	portrait.anchor_right = 1.0
	portrait.anchor_bottom = 1.0
	avatar.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var n := HomeStyle.label(String(RobotRoster.entry(rid).get("name", "")), 48)
	n.name = "ActiveRobot"
	info.add_child(n)
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", -10)   # badge overlaps the bar end
	info.add_child(lvl_row)
	lvl_row.add_child(_badge("HeroLevel", UiText.num(level), Vector2(84, 76)))
	var meter := UiProgressMeter.new("ProfileBotParts")
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter.set_progress(int(parts.get("parts", 0)), int(parts.get("cost", 0)),
		UiText.t("HOME_RATIO", [UiText.num(int(parts.get("parts", 0))), UiText.num(int(parts.get("cost", 0)))]))
	HomeStyle.style_meter(meter.bar, HomeStyle.GOLD if bool(parts.get("can_unlock", false)) else HomeStyle.GREEN, 42)
	meter.caption.add_theme_font_size_override("font_size", 28)
	meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter.caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meter.caption.clip_text = false
	meter.caption.reparent(meter.bar, false)
	meter.caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	lvl_row.add_child(meter)
	return hero

## Rank badge art with the live number centred on it.
static func _badge(n: String, text: String, sz: Vector2) -> TextureRect:
	var b := HomeStyle.art("Badge")
	b.texture = load(F + "home/top_hud/profile_rank_badge.png")
	b.custom_minimum_size = sz
	b.z_index = 1
	var l := HomeStyle.label(text, 28)
	l.name = n
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(l)
	return b

## Cream stat tile: icon + caption + big live value (child "Value").
static func _tile(n: String, icon: String, caption: String, value: String, badge_text: String) -> PanelContainer:
	var t := PanelContainer.new()
	t.name = n
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	t.add_child(row)
	var art: TextureRect
	if badge_text.is_empty():
		art = HomeStyle.art("Icon")
		art.texture = load(F + icon)
		art.custom_minimum_size = Vector2(UiTokens.ICON_LG, UiTokens.ICON_LG)
	else:
		art = _badge("BadgeLevel", badge_text, Vector2(UiTokens.ICON_LG, UiTokens.ICON_LG))
		art.name = "Icon"
	row.add_child(art)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var cap := _text(caption, 26)
	cap.name = "Caption"
	col.add_child(cap)
	var val := _text(value, 44)
	val.name = "Value"
	col.add_child(val)
	return t

## Personal Best row: icon, label, live current and own best (no one else is compared).
static func _best_row(parent: Control, n: String, icon: String, label: String, current: int, best: int) -> void:
	var row := PanelContainer.new()
	row.name = n
	row.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW.lightened(0.4), BasePopup.ROW_EDGE, 2, 18, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	parent.add_child(row)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	row.add_child(h)
	var art := HomeStyle.art("Icon")
	art.texture = load(F + icon)
	art.custom_minimum_size = Vector2(UiTokens.ICON_MD, UiTokens.ICON_MD)
	h.add_child(art)
	var l := _text(label, 26)
	l.name = "Label"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var cur := _cell(UiText.num(current), 40)
	cur.name = "Current"
	h.add_child(cur)
	var bst := _cell(UiText.num(best), 40)
	bst.name = "Best"
	h.add_child(bst)

## Left-aligned single-line ink label (text_fits() catches any overflow).
static func _text(text: String, size: int) -> Label:
	var l := BasePopup.body_label(text, size)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l

## Fixed-width centred column cell (Current / Best header and values line up).
static func _cell(text: String, size: int) -> Label:
	var l := _text(text, size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(130, 0)
	return l

static func _spacer(w: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

# ----------------------------------------------------------- ACHIEVEMENTS ----

static func open_achievements(stack, app) -> BasePopup:
	var p := BasePopup.new("achievements")
	p.set_frame("large")
	p.set_title(UiText.t("ACHIEVEMENTS_TITLE"))
	var scroll := ScrollContainer.new()
	scroll.name = "AchievementList"
	scroll.custom_minimum_size = Vector2(0, 900)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	for a in Achievements.evaluate(app):
		var card := PanelContainer.new()
		card.name = "Ach_" + String(a["id"])
		card.set_meta("done", a["done"])
		card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
		var v := VBoxContainer.new()
		card.add_child(v)
		var t := BasePopup.body_label(UiText.t("ACH_" + String(a["id"]).to_upper()), 26, BasePopup.ROYAL_EDGE)
		t.name = "Title"
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(t)
		var pr := ProgressBar.new()
		pr.name = "Progress"
		pr.show_percentage = false
		pr.custom_minimum_size = Vector2(0, 18)
		pr.max_value = int(a["target"])
		pr.value = int(a["value"])
		v.add_child(pr)
		var st := BasePopup.body_label(UiText.t("ACH_DONE") if a["done"] else UiText.t("TASK_PROGRESS", [UiText.num(int(a["value"])), UiText.num(int(a["target"]))]), 20, BasePopup.INK)
		st.name = "State"
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(st)
		list.add_child(card)
	p.add_body_line(UiText.t("ACH_NO_REWARD"), "Policy", BasePopup.INK, 20)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	if not stack.push(p):
		p.free()
		return null
	return p

# ----------------------------------------------------------------- EVENTS ----

static func open_events(stack, app) -> BasePopup:
	var p := BasePopup.new("events")
	p.set_frame("large")
	p.set_title(UiText.t("EVENTS_TITLE"))
	var list := VBoxContainer.new()
	list.name = "EventList"
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(list)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id.begins_with("ev:"):
			var parts: PackedStringArray = id.split(":")
			app.actions.claim_event_milestone(parts[1], int(parts[2]))
		elif id == "ft_join":
			app.actions.join_first_try()
		elif id == "ft_claim":
			app.actions.claim_first_try()
		else:
			return
		refresh_events(p, app)
		p.rearm_soon())
	refresh_events(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

static func refresh_events(p: BasePopup, app) -> void:
	var ev = app.economy.events
	var list: VBoxContainer = p.find_child("EventList", true, false)
	var stash: Control = p.find_child("EventStash", true, false)
	if stash == null:
		stash = Control.new()
		stash.name = "EventStash"
		stash.visible = false
		p.get_content().add_child(stash)
	for c in list.get_children():
		for b in c.find_children("*", "Button", true, false):
			b.reparent(stash)
		list.remove_child(c)
		c.queue_free()
	var any := false
	for v in ev.list():
		any = true
		var card := _card("Event_" + String(v["id"]))
		var box: VBoxContainer = card.get_child(0)
		box.add_child(_label("Title", UiText.t("EVENT_WEEKLY_TITLE"), 28, BasePopup.ROYAL_EDGE))
		var when := ""
		match String(v["phase"]):
			"active":
				when = UiText.t("EVENT_ENDS_IN", [_dhm(int(v["ends_in"]))])
			"upcoming":
				when = UiText.t("EVENT_STARTS_IN", [_dhm(int(v["starts_in"]))])
			_:
				when = UiText.t("EVENT_ENDED")
		box.add_child(_label("When", when, 22, BasePopup.INK))
		box.add_child(_label("Progress", UiText.t("EVENT_PROGRESS", [UiText.num(int(v["progress"]))]), 22, BasePopup.INK))
		for i in range(v["milestones"].size()):
			var m: Dictionary = v["milestones"][i]
			var h := HBoxContainer.new()
			h.name = "Milestone_%d" % i
			box.add_child(h)
			var t := _label("Text", UiText.t("EVENT_MILESTONE", [UiText.num(int(m["target"])), UiText.reward_text(m["reward"])]), 22, BasePopup.INK)
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(t)
			var b := _button(p, stash, "ev:%s:%d" % [v["id"], i], h)
			b.text = UiText.t("TASK_CLAIMED") if m["claimed"] else UiText.t("POPUP_CLAIM")
			p.set_action_blocked(b.get_meta("aid"), not bool(m["claimable"]) or app.is_blocked)
		box.add_child(_label("Rule", UiText.t("EVENT_RULE"), 18, BasePopup.INK))
		list.add_child(card)
	var f: Dictionary = ev.first_try()
	if not f.is_empty():
		any = true
		var card := _card("FirstTry")
		var box: VBoxContainer = card.get_child(0)
		box.add_child(_label("Title", UiText.t("FIRST_TRY_TITLE"), 28, BasePopup.ROYAL_EDGE))
		box.add_child(_label("Rule", UiText.t("FIRST_TRY_RULE", [UiText.num(int(f["levels"]))]), 20, BasePopup.INK))
		box.add_child(_label("Reward", UiText.t("FIRST_TRY_REWARD", [UiText.reward_text(f["reward"])]), 22, BasePopup.INK))
		box.add_child(_label("Run", UiText.t("FIRST_TRY_RUN", [UiText.num(int(f["run"])), UiText.num(int(f["levels"]))]), 22, BasePopup.INK))
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(h)
		var bj := _button(p, stash, "ft_join", h)
		bj.text = UiText.t("FIRST_TRY_JOINED") if f["joined"] else UiText.t("FIRST_TRY_JOIN")
		p.set_action_blocked("ft_join", bool(f["joined"]) or app.is_blocked)
		var bc := _button(p, stash, "ft_claim", h)
		bc.text = UiText.t("TASK_CLAIMED") if f["claimed"] else UiText.t("POPUP_CLAIM")
		p.set_action_blocked("ft_claim", not (f["joined"] and f["complete"] and not f["claimed"]) or app.is_blocked)
		list.add_child(card)
	if not any:
		list.add_child(_label("Empty", UiText.t("EVENTS_EMPTY") if ev.config_ok else UiText.t("EVENTS_UNAVAILABLE"), 26, BasePopup.INK))

static func _card(n: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = n
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var v := VBoxContainer.new()
	card.add_child(v)
	return card

static func _label(n: String, text: String, size: int, color: Color) -> Label:
	var l := BasePopup.body_label(text, size, color)
	l.name = n
	return l

static func _button(p: BasePopup, stash: Control, aid: String, parent: Control) -> Button:
	var b: Button = p.get_action_button(aid)
	if b == null:
		b = p.add_action(aid, "", "secondary", false, "", parent)
	else:
		b.reparent(parent)
	b.set_meta("aid", aid)
	b.custom_minimum_size = Vector2(190, 72)
	return b

static func _dhm(sec: int) -> String:
	return UiText.t("TIME_DHM", [sec / 86400, (sec % 86400) / 3600, (sec % 3600) / 60])

# ------------------------------------------------------------------ RANKS ----

## SB-M43-122 (owner 2026-10-31): the player's personal rank ladder (PersonalRank), derived
## from campaign levels cleared. Read-only: no other players, no server, grants nothing.
static func open_ranks(stack, app) -> BasePopup:
	var p := BasePopup.new("ranks")
	p.set_frame("large")
	p.set_title(UiText.t("RANKS_TITLE"))
	var n := int(app.progression.completed_count())
	var tiers := PersonalRank.load_tiers()
	var r := PersonalRank.for_cleared(n)
	if r.is_empty():
		p.add_body_line(UiText.t("RANKS_UNAVAILABLE"), "Unavailable", BasePopup.INK, 24)
	else:
		var cur := int(r["index"])
		p.add_body_line(UiText.t("RANKS_CURRENT", [UiText.t(r["name_key"])]), "CurrentRank", BasePopup.ROYAL_EDGE, 34)
		p.add_body_line(UiText.t("PROFILE_CLEARED", [UiText.num(n)]), "Cleared", BasePopup.INK, 24)
		var meter := UiProgressMeter.new("NextMeter")
		meter.caption.add_theme_color_override("font_color", BasePopup.INK)
		meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if r["next_id"] != "":
			meter.set_progress(r["into"], r["span"], UiText.t("RANKS_NEXT", [UiText.num(int(r["next_min"]) - n), UiText.t(tiers[cur + 1]["name_key"])]))
		else:
			meter.set_progress(1, 1, UiText.t("RANKS_TOP"))
		p.get_content().add_child(meter)
		var list := VBoxContainer.new()
		list.name = "Ladder"
		list.add_theme_constant_override("separation", UiTokens.SPACE_XS)
		p.get_content().add_child(list)
		for i in range(tiers.size()):
			var t: Dictionary = tiers[i]
			var card := _card("Tier_" + String(t["id"]))
			card.set_meta("reached", i <= cur)
			card.set_meta("current", i == cur)
			if i == cur:
				card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.GOLD_BODY, BasePopup.GOLD_EDGE, 4, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
			elif i > cur:
				card.modulate.a = 0.6
			var h := HBoxContainer.new()
			card.get_child(0).add_child(h)
			var nl := _label("Name", UiText.t("RANKS_TIER_ROW", [UiText.t(t["name_key"]), UiText.num(int(t["min_cleared"]))]), 24, BasePopup.INK)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			h.add_child(nl)
			var st := "RANKS_STATE_CURRENT" if i == cur else ("RANKS_STATE_REACHED" if i < cur else "")
			h.add_child(_label("State", UiText.t(st) if st != "" else "", 22, BasePopup.ROYAL_EDGE))
			list.add_child(card)
	p.add_body_line(UiText.t("RANKS_SELF_ONLY"), "SelfOnly", BasePopup.INK, 20)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	if not stack.push(p):
		p.free()
		return null
	return p

# --------------------------------------------------------------- COMEBACK ----

## SB-M43-143/144: non-punitive return summary after a genuine absence. Lists only state that
## is already true (Hearts, Daily, Gift, Tasks, Events) and grants nothing itself.
static func open_comeback(stack, app) -> BasePopup:
	var e = app.economy
	var b := HomeBadges.compute(app)
	var p := BasePopup.new("comeback")
	p.set_frame("medium")
	p.set_hero(RobotRoster.asset(e.robots.active_robot(), "help_pose"), Vector2(220, 220), 70)
	p.set_title(UiText.t("COMEBACK_TITLE"))
	p.add_body_line(UiText.t("COMEBACK_HEARTS", [UiText.num(e.hearts.hearts()), UiText.num(e.hearts.max_hearts())]), "Hearts", BasePopup.INK, 24)
	var lines := [["daily", "COMEBACK_DAILY"], ["gift_bar", "COMEBACK_GIFT"], ["tasks", "COMEBACK_TASKS"], ["events", "COMEBACK_EVENTS"]]
	for l in lines:
		if int(b[l[0]]) > 0:
			var txt := UiText.t(l[1]) if l[0] == "daily" else UiText.t(l[1], [UiText.num(int(b[l[0]]))])
			p.add_body_line(txt, "Ready_" + l[0], BasePopup.INK, 24)
	p.add_action("ok", UiText.t("COMEBACK_CONTINUE"), "primary", true)
	if not stack.push(p):
		p.free()
		return null
	e.returns.mark_summary_shown()
	app.mark_dirty()
	return p

# ---------------------------------------------------------- NOTIFICATIONS ----

## SB-M43-147: global + per-category reminder preferences and quiet hours (NotificationPolicy).
## Opt-in (OFF by default). Delivery itself needs a platform notification plugin (SB-M43-146),
## which this build does not ship, so the screen says so instead of asking the OS.
static func open_notifications(stack, app) -> BasePopup:
	var p := BasePopup.new("notifications")
	p.set_frame("large")
	p.set_title(UiText.t("NOTIFY_TITLE"))
	var n = app.economy.notify
	p.add_action("notify_all", "", "primary", false)
	for c in n.CATEGORIES:
		var row := HBoxContainer.new()
		row.name = "Cat_" + c
		p.get_content().add_child(row)
		var l := _label("Text", UiText.t("NOTIFY_CAT_" + c.to_upper()), 24, BasePopup.INK)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(l)
		var b := p.add_action("notify:" + c, "", "secondary", false, "", row)
		b.custom_minimum_size = Vector2(160, 70)
	p.add_body_line(UiText.t("NOTIFY_QUIET", ["%02d:00" % n.quiet_from, "%02d:00" % n.quiet_to]), "Quiet", BasePopup.INK, 22)
	p.add_body_line(UiText.t("NOTIFY_PLATFORM_PENDING"), "Platform", BasePopup.INK, 20)
	p.add_action("back", UiText.t("SHOP_BACK"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id == "notify_all":
			n.enabled = not n.enabled
		elif id.begins_with("notify:"):
			n.set_category(id.substr(7), not bool(n.categories[id.substr(7)]))
		else:
			return
		app.request_save()
		refresh_notifications(p, app)
		p.rearm_soon())
	refresh_notifications(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

static func refresh_notifications(p: BasePopup, app) -> void:
	var n = app.economy.notify
	p.get_action_button("notify_all").text = UiText.t("NOTIFY_ALL_ON") if n.enabled else UiText.t("NOTIFY_ALL_OFF")
	for c in n.CATEGORIES:
		p.get_action_button("notify:" + c).text = UiText.t("NOTIFY_ON") if n.categories[c] else UiText.t("NOTIFY_OFF")
		p.set_action_blocked("notify:" + c, not n.enabled)
