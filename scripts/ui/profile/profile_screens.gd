extends RefCounted
## ProfileScreens — preload (res://scripts/ui/profile/profile_screens.gd).
##
## M43-C010 / C010R app-level destinations in the approved popup family (every value live):
##   - PROFILE (SB-M43-124, R10-006/007): active robot, campaign level, lifetime stats,
##     Collection completion, achievement summary and Personal Bests (self-comparison only),
##     each best shown with a self-ghost bar (current vs own best; informational only);
##   - ACHIEVEMENTS (SB-M43-126): data-driven list with progress and completed state;
##   - EVENTS (SB-M43-128/129, R10-001..005): configured Weekly Cleaning Events (window,
##     countdown, progress, fixed milestone rewards, ended/claimed) and the opt-in First-Try
##     Cleanup; an honest empty state when nothing is scheduled. No event currency.
## Claims / joins go through ProductionActionFacade. These screens own no rule or value.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")

# ---------------------------------------------------------------- PROFILE ----

static func open_profile(stack, app) -> BasePopup:
	var e = app.economy
	var rid: String = e.robots.active_robot()
	var p := BasePopup.new("profile")
	p.set_frame("large")
	p.set_hero(RobotRoster.asset(rid, "portrait"), Vector2(220, 220), 70)
	p.set_title(UiText.t("PROFILE_TITLE"))
	p.add_body_line(UiText.t("PROFILE_ROBOT", [String(RobotRoster.entry(rid).get("name", ""))]), "ActiveRobot", BasePopup.ROYAL_EDGE, 30)
	var s := Achievements.stats(app)
	var ach := Achievements.evaluate(app)
	var done := ach.filter(func(a): return a["done"]).size()
	var rows := [
		["Level", UiText.t("PROFILE_LEVEL", [UiText.num(int(app.progression.current_level()))])],
		["Cleared", UiText.t("PROFILE_CLEARED", [UiText.num(int(s["levels_completed"]))])],
		["Collection", UiText.t("PROFILE_COLLECTION", [UiText.num(int(s["cards_unique"])), UiText.num(e.collection.all_card_ids().size()), UiText.num(int(s["sets_completed"]))])],
		["Robots", UiText.t("PROFILE_ROBOTS", [UiText.num(int(s["robots_unlocked"])), UiText.num(RobotRoster.ids().size())])],
		["AchievementSummary", UiText.t("PROFILE_ACHIEVEMENTS", [UiText.num(done), UiText.num(ach.size())])],
		["LoginDays", UiText.t("DAILY_CONSECUTIVE", [UiText.num(int(e.daily.streak()))])],
	]
	for r in rows:
		p.add_body_line(r[1], r[0], BasePopup.INK, 24)
	p.add_body_line(UiText.t("PROFILE_BESTS"), "BestsTitle", BasePopup.ROYAL_EDGE, 26)
	var r = e.records
	_best_row(p, "BestStreak", UiText.t("BEST_WIN_STREAK"), int(e.streak.streak()), int(s["best_win_streak"]))
	_best_row(p, "BestFirstTry", UiText.t("BEST_FIRST_TRY"), int(r.get_value("first_try_run")), int(r.get_value("best_first_try_run")))
	_best_row(p, "BestBoosterless", UiText.t("BEST_BOOSTERLESS"), int(r.get_value("boosterless_run")), int(r.get_value("best_boosterless_run")))
	p.add_body_line(UiText.t("PROFILE_BOOSTERLESS_TOTAL", [UiText.num(int(r.get_value("boosterless_wins")))]), "BoosterlessTotal", BasePopup.INK, 22)
	p.add_body_line(UiText.t("PROFILE_SELF_ONLY"), "SelfOnly", BasePopup.INK, 20)
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

## "label · current N · best M" with a self-ghost bar (current against the player's own best).
static func _best_row(p: BasePopup, n: String, label: String, current: int, best: int) -> void:
	var row := VBoxContainer.new()
	row.name = n
	p.get_content().add_child(row)
	var l := BasePopup.body_label(UiText.t("BEST_ROW", [label, UiText.num(current), UiText.num(best)]), 22, BasePopup.INK)
	l.name = "Text"
	row.add_child(l)
	var bar := ProgressBar.new()
	bar.name = "Ghost"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = maxi(1, best)
	bar.value = mini(current, maxi(1, best))
	row.add_child(bar)

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
