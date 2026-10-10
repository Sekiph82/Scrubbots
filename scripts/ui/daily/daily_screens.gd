extends RefCounted
## DailyScreens — preload (res://scripts/ui/daily/daily_screens.gd).
##
## M43-C009 / C009R app-level destinations in the approved popup family (every value live):
##   - TASKS (SB-M43-112/114, R09-001/005): today's three Daily Scrub Orders (DailyOrders),
##     progress, the canonical 75/100/125 SB per task, and the all-3 reward presented as an
##     earned ScrubBox that grants the canonical one Mystery Booster charge exactly once;
##   - DAILY (SB-M43-115/117): visible consecutive-login count, repeating D1..D5 cycle with
##     claimed / today / upcoming states and the configured rewards (DailyService);
##   - GIFT BAR (SB-M43-118/120): queued Gift Meter milestones to claim + claimed history.
## Every claim goes through ProductionActionFacade (idempotent tx ids, durable save). These
## screens own no calendar, reward value or progress rule. The ScrubBox is never sold.

const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const GiftProgressModel = preload("res://scripts/economy/gift_progress_model.gd")

const ART := {
	"check": "res://assets/ui/final/daily/daily_task_check.png",
	"day": "res://assets/ui/final/daily/daily_day_reward_frame.png",
	"day5": "res://assets/ui/final/daily/daily_day5_reward_frame.png",
	"flame": "res://assets/ui/final/daily/daily_streak_flame.png",
	"calendar": "res://assets/ui/final/daily/daily_login_calendar.png",
	"box": "res://assets/ui/final/rewards/chest_small.png",
	"gift": "res://assets/ui/final/rewards/gift_box.png",
}
const HISTORY_ROWS := 8

# ------------------------------------------------------------------ TASKS ----

static func open_tasks(stack, app) -> BasePopup:
	var p := BasePopup.new("tasks")
	p.set_frame("large")
	p.set_title(UiText.t("TASKS_TITLE"))
	p.add_body_line(UiText.t("TASKS_SUBTITLE"), "Subtitle", BasePopup.INK, 24)
	var sb: Array = app.economy.config.daily_config().get("task_sb", [])
	for o in app.economy.orders.orders():
		var i := int(o["index"])
		var card := _row_card("Task_%d" % i)
		var h: HBoxContainer = card.get_child(0)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var t := BasePopup.body_label("", 26, BasePopup.ROYAL_EDGE)
		t.name = "Text"
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(t)
		var pr := ProgressBar.new()
		pr.name = "Progress"
		pr.show_percentage = false
		pr.custom_minimum_size = Vector2(0, 22)
		v.add_child(pr)
		var n := BasePopup.body_label("", 22, BasePopup.INK)
		n.name = "Count"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(n)
		var b := p.add_action("task:%d" % i, "", "secondary", false, "", h)
		b.custom_minimum_size = Vector2(210, 80)
		b.set_meta("sb", int(sb[i]) if i < sb.size() else 0)
		p.get_content().add_child(card)
	var box := _row_card("ScrubBox")
	var bh: HBoxContainer = box.get_child(0)
	var bi := HomeStyle.art("BoxArt")
	bi.texture = load(ART["box"])
	bi.custom_minimum_size = Vector2(110, 110)
	bh.add_child(bi)
	var bl := BasePopup.body_label("", 24, BasePopup.ROYAL_EDGE)
	bl.name = "Text"
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bh.add_child(bl)
	var bb := p.add_action("scrubbox", "", "secondary", false, "", bh)
	bb.custom_minimum_size = Vector2(210, 80)
	p.get_content().add_child(box)
	p.add_body_line(UiText.t("TASKS_RESET_NOTE"), "ResetNote", BasePopup.INK, 20)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c): _on_tasks_action(stack, app, p, id))
	refresh_tasks(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

static func order_text(o: Dictionary) -> String:
	if not bool(o["available"]):
		return UiText.t("TASK_NONE")
	match String(o["metric"]):
		"levels_won":
			return UiText.t("TASK_WIN_ONE") if int(o["target"]) == 1 else UiText.t("TASK_WIN_N", [UiText.num(int(o["target"]))])
		"levels_won_no_booster":
			return UiText.t("TASK_WIN_NO_BOOSTER")
		"levels_won_min_class":
			return UiText.t("TASK_WIN_CLASS", [UiText.t("DIFFICULTY_" + String(o["min_class"]))])
		"cells_cleared":
			return UiText.t("TASK_CLEAR_CELLS", [UiText.num(int(o["target"]))])
	return ""

static func refresh_tasks(p: BasePopup, app) -> void:
	var d = app.economy.daily
	var all_done := true
	for o in app.economy.orders.orders():
		var i := int(o["index"])
		var card: Control = p.find_child("Task_%d" % i, true, false)
		(card.find_child("Text", true, false) as Label).text = order_text(o)
		var pr: ProgressBar = card.find_child("Progress", true, false)
		pr.max_value = maxi(1, int(o["target"]))
		pr.value = int(o["progress"])
		(card.find_child("Count", true, false) as Label).text = UiText.t("TASK_PROGRESS", [UiText.num(int(o["progress"])), UiText.num(int(o["target"]))])
		var b := p.get_action_button("task:%d" % i)
		if bool(o["claimed"]):
			b.text = UiText.t("TASK_CLAIMED")
		else:
			b.text = UiText.t("TASK_REWARD_SB", [UiText.num(int(b.get_meta("sb")))])
		p.set_action_blocked("task:%d" % i, not bool(o["done"]) or bool(o["claimed"]) or app.is_blocked)
		all_done = all_done and bool(o["done"])
	var box: Control = p.find_child("ScrubBox", true, false)
	var claimed: bool = d.all_tasks_bonus_claimed()
	(box.find_child("Text", true, false) as Label).text = UiText.t("TASKS_BOX_OPENED") if claimed else UiText.t("TASKS_BOX", [UiText.num(d.tasks_done_count()), UiText.num(3)])
	p.get_action_button("scrubbox").text = UiText.t("TASK_CLAIMED") if claimed else UiText.t("TASKS_BOX_OPEN")
	p.set_action_blocked("scrubbox", claimed or not all_done or app.is_blocked)

static func _on_tasks_action(stack, app, p: BasePopup, id: String) -> void:
	if id.begins_with("task:"):
		app.actions.claim_daily_task(int(id.substr(5)))
	elif id == "scrubbox":
		var r: Dictionary = app.actions.claim_daily_all_tasks()
		if bool(r.get("ok", false)):
			var c = open_scrubbox(stack, app, r)
			if c != null:
				c.closed.connect(func(_x):
					if is_instance_valid(p):
						refresh_tasks(p, app)
						p.rearm(), CONNECT_ONE_SHOT)
				refresh_tasks(p, app)
				return
	else:
		return
	refresh_tasks(p, app)
	p.rearm_soon()

## The earned all-3 ScrubBox: shows exactly what the committed claim granted (the canonical
## Mystery Booster = one charge of a random one of the four boosters, SB-M39-054). Opened only after the facade commit; no purchase / reroll / speed-up.
static func open_scrubbox(stack, app, result: Dictionary) -> BasePopup:
	var p := BasePopup.new("ceremony_scrubbox")
	p.set_frame("medium")
	p.set_hero(ART["box"], Vector2(300, 300), 90)
	p.set_title(UiText.t("SCRUBBOX_TITLE"))
	var row := HBoxContainer.new()
	row.name = "Reward"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(row)
	var icon := HomeStyle.art("RewardIcon")
	icon.texture = load(ART["gift"])   # SB-M39-054: neutral Mystery Booster art, not the RANDOM booster
	icon.custom_minimum_size = Vector2(120, 120)
	row.add_child(icon)
	var n := int(result.get("random_any_booster_charges", 0))
	var l := BasePopup.body_label(UiText.reward_text({"random_any_booster_charges": n}), 32, BasePopup.ROYAL_EDGE)
	l.name = "RewardText"
	l.autowrap_mode = TextServer.AUTOWRAP_OFF   # sized by its text inside the centred row
	row.add_child(l)
	p.add_body_line(UiText.t("SCRUBBOX_EARNED"), "Earned", BasePopup.INK, 22)
	p.add_action("ok", UiText.t("POPUP_COLLECT"), "primary", true)
	if not stack.push(p):
		p.free()
		return null
	return p

# ------------------------------------------------------------------ DAILY ----

## Per-day state for the current 5-day cycle: "claimed" / "today" / "claimed_today" / "upcoming".
static func day_states(daily) -> Array:
	var claimed: bool = daily.claimed_today()
	var next: int = daily.next_claim_cycle_day()
	var out: Array = []
	for day in range(1, 6):
		if day < next:
			out.append("claimed")
		elif day == next:
			out.append("claimed_today" if claimed else "today")
		else:
			out.append("upcoming")
	return out

static func open_daily(stack, app) -> BasePopup:
	var p := BasePopup.new("daily_login")
	p.set_frame("large")
	p.set_title(UiText.t("DAILY_TITLE"))
	# M43-C015R (SB-M43-R15-003): owner F5 review — no hero floating above the frame. The
	# calendar is a contained icon inside the content; flame + streak are one centred pair.
	var cal_box := CenterContainer.new()
	cal_box.name = "CalendarBox"
	p.get_content().add_child(cal_box)
	var cal := HomeStyle.art("Calendar")
	cal.texture = load(ART["calendar"])
	cal.custom_minimum_size = CALENDAR_SIZE
	cal_box.add_child(cal)
	var streak_box := CenterContainer.new()
	streak_box.name = "StreakBox"
	p.get_content().add_child(streak_box)
	var streak := HBoxContainer.new()
	streak.name = "StreakRow"
	streak.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	streak_box.add_child(streak)
	var fl := HomeStyle.art("Flame")
	fl.texture = load(ART["flame"])
	fl.custom_minimum_size = Vector2(52, 52)
	streak.add_child(fl)
	var sl := BasePopup.body_label("", 30, BasePopup.ROYAL_EDGE)
	sl.name = "Streak"
	sl.autowrap_mode = TextServer.AUTOWRAP_OFF
	streak.add_child(sl)
	var grid := GridContainer.new()
	grid.name = "Days"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
	grid.add_theme_constant_override("v_separation", UiTokens.SPACE_SM)
	var center := CenterContainer.new()
	center.add_child(grid)
	p.get_content().add_child(center)
	for day in range(1, 6):
		grid.add_child(_day_card(day, app.economy.daily.login_reward_for(day)))
	p.add_body_line(UiText.t("DAILY_RULE"), "Rule", BasePopup.INK, 20)
	p.add_action("claim", UiText.t("POPUP_CLAIM"), "primary", false)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id == "claim":
			var r: Dictionary = app.actions.claim_daily_login()
			refresh_daily(p, app)
			var c = open_daily_reward(stack, app, r) if bool(r.get("ok", false)) else null
			if c != null:
				c.closed.connect(func(_x):
					if is_instance_valid(p):
						p.rearm(), CONNECT_ONE_SHOT)
			else:
				p.rearm_soon())
	refresh_daily(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

## R15-003: three cards + two gaps fit the large frame's 652 px body at its 880 px reference
## width (3 x 210 + 2 x 8 = 646), so the grid can never push the body past the frame.
const CALENDAR_SIZE := Vector2(132, 132)
const DAY_CARD_SIZE := Vector2(210, 280)
const CHECK_SIZE := 34
## Card insets keep every label / check clear of the frame art (top gem, Day 5 crown).
const DAY_CARD_INSET := {"side": 26, "top": 46, "top_day5": 56, "bottom": 30}
static func _day_card(day: int, reward: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "Day_%d" % day
	card.custom_minimum_size = DAY_CARD_SIZE
	var st := StyleBoxTexture.new()
	st.texture = load(ART["day5"] if day == 5 else ART["day"])
	st.content_margin_left = DAY_CARD_INSET["side"]
	st.content_margin_right = DAY_CARD_INSET["side"]
	st.content_margin_top = DAY_CARD_INSET["top_day5"] if day == 5 else DAY_CARD_INSET["top"]
	st.content_margin_bottom = DAY_CARD_INSET["bottom"]
	card.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	# Title row: [balance | DAY n | check]. The check lives in the title row (balanced by an
	# equal spacer so the title stays centred) instead of adding a row, so the longest real
	# state (Day 5 claimed today: four reward lines + state) fits the fixed card.
	var head := HBoxContainer.new()
	head.name = "TitleRow"
	head.add_theme_constant_override("separation", 0)
	v.add_child(head)
	var bal := Control.new()
	bal.custom_minimum_size = Vector2(CHECK_SIZE, 0)
	bal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(bal)
	var t := BasePopup.body_label(UiText.t("DAILY_DAY", [day]), 28, BasePopup.ROYAL_EDGE)
	t.name = "DayLabel"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var chk := HomeStyle.art("Check")
	chk.texture = load(ART["check"])
	chk.custom_minimum_size = Vector2(CHECK_SIZE, CHECK_SIZE)
	chk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chk.name = "Check"
	head.add_child(chk)
	var r := BasePopup.body_label(UiText.reward_text(reward), 18, BasePopup.INK)
	r.name = "RewardText"
	r.custom_minimum_size = Vector2(DAY_CARD_SIZE.x - 2 * DAY_CARD_INSET["side"], 0)
	v.add_child(r)
	var s := BasePopup.body_label("", 18, Color(0.2, 0.55, 0.12))
	s.name = "State"
	v.add_child(s)
	return card

static func refresh_daily(p: BasePopup, app) -> void:
	var d = app.economy.daily
	(p.find_child("Streak", true, false) as Label).text = UiText.t("DAILY_CONSECUTIVE", [UiText.num(int(d.streak()))])
	var states := day_states(d)
	for day in range(1, 6):
		var card: Control = p.find_child("Day_%d" % day, true, false)
		var st := String(states[day - 1])
		var lab: Label = card.find_child("State", true, false)
		lab.text = {"claimed": UiText.t("DAILY_STATE_CLAIMED"), "claimed_today": UiText.t("DAILY_CARD_CLAIMED_TODAY"),
			"today": UiText.t("DAILY_CARD_TODAY"), "upcoming": ""}[st]
		# Hidden via alpha (not visible=false) so the title row keeps its balanced width.
		(card.find_child("Check", true, false) as Control).modulate.a = 1.0 if (st == "claimed" or st == "claimed_today") else 0.0
		card.modulate = Color(1, 1, 1, 1) if st != "upcoming" else Color(1, 1, 1, 0.72)
		card.set_meta("state", st)
	p.set_action_blocked("claim", d.claimed_today() or app.is_blocked)
	p.get_action_button("claim").text = UiText.t("DAILY_STATE_CLAIMED") if d.claimed_today() else UiText.t("POPUP_CLAIM")

## SB-M43-075: celebration of the committed login reward (opened only after the facade
## commit; shows exactly the granted bundle). Day 5 closes the cycle with its own line.
## No motion: identical in Reduced Effects (SB-M43-077).
static func open_daily_reward(stack, app, result: Dictionary) -> BasePopup:
	var day := int(result.get("day", 0))
	var p := BasePopup.new("ceremony_daily")
	p.set_frame("medium")
	p.set_hero(ART["calendar"], Vector2(240, 240), 80)
	p.set_title(UiText.t("DAILY_DAY", [day]))
	p.add_body_line(UiText.reward_text(result.get("reward", {})), "RewardText", BasePopup.ROYAL_EDGE, 32)
	p.add_body_line(UiText.t("DAILY_CYCLE_DONE") if day == 5 else UiText.t("DAILY_CONSECUTIVE", [UiText.num(int(app.economy.daily.streak()))]), "Streak", BasePopup.INK, 24)
	p.add_action("ok", UiText.t("POPUP_COLLECT"), "primary", true)
	if not stack.push(p):
		p.free()
		return null
	return p

# --------------------------------------------------------------- GIFT BAR ----

static func open_gift_bar(stack, app) -> BasePopup:
	var p := BasePopup.new("gift_bar")
	p.set_frame("large")
	p.set_hero(ART["gift"], Vector2(220, 220), 70)
	p.set_title(UiText.t("GIFTS_TITLE"))
	var pl := BasePopup.body_label("", 24, BasePopup.INK)
	pl.name = "Progress"
	p.get_content().add_child(pl)
	var scroll := ScrollContainer.new()
	scroll.name = "GiftList"
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "Gifts"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)   # M47-TOUCH-R01: finger swipe scrolls over rows / buttons
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id.begins_with("gift:"):
			app.actions.claim_gift(id.substr(5))
			refresh_gift_bar(p, app)
			p.rearm_soon())
	refresh_gift_bar(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

## Claimable first (oldest first), then the most recent claimed history.
static func gift_rows(gift) -> Array:
	var q: Array = gift.gift_bar_queue()
	var open := q.filter(func(o): return not bool(o.get("claimed", false)))
	var done := q.filter(func(o): return bool(o.get("claimed", false)))
	done.reverse()
	return open + done.slice(0, HISTORY_ROWS)

static func refresh_gift_bar(p: BasePopup, app) -> void:
	var gm := GiftProgressModel.from_service(app.economy.gift)
	(p.find_child("Progress", true, false) as Label).text = UiText.t("GIFTS_PROGRESS", [UiText.num(gm["progress"]), UiText.num(gm["cycle_max"]), UiText.num(gm["next"])])
	var list: VBoxContainer = p.find_child("Gifts", true, false)
	var rows := gift_rows(app.economy.gift)
	# Keep every CLAIM button alive (the popup's action registry owns them): park them in a
	# hidden stash before the old rows are freed, and reuse them for the new rows.
	var stash: Control = p.find_child("GiftStash", true, false)
	if stash == null:
		stash = Control.new()
		stash.name = "GiftStash"
		stash.visible = false
		p.get_content().add_child(stash)
	for c in list.get_children():
		for btn in c.find_children("*", "Button", true, false):
			btn.reparent(stash)
		list.remove_child(c)
		c.queue_free()
	if rows.is_empty():
		var e := BasePopup.body_label(UiText.t("GIFTS_EMPTY"), 24, BasePopup.INK)
		e.name = "Empty"
		e.set_meta("occ", "")
		list.add_child(e)
		return
	for o in rows:
		var card := _row_card("Gift_" + String(o["id"]).replace(":", "_"))
		card.set_meta("occ", String(o["id"]))
		var h: HBoxContainer = card.get_child(0)
		var t := BasePopup.body_label(UiText.t("GIFTS_ROW", [UiText.num(int(o["milestone"])), UiText.reward_text(app.economy.config.gift_meter_milestone(int(o["milestone"])))]), 22, BasePopup.INK)
		t.name = "Text"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		h.add_child(t)
		list.add_child(card)
		var aid := "gift:" + String(o["id"])
		var claimed := bool(o.get("claimed", false))
		var b: Button = p.get_action_button(aid)
		if b == null:
			b = p.add_action(aid, "", "secondary", false, "", h)
		else:
			b.reparent(h)
		b.custom_minimum_size = Vector2(190, 76)
		b.text = UiText.t("TASK_CLAIMED") if claimed else UiText.t("POPUP_CLAIM")
		card.set_meta("claimed", claimed)
		p.set_action_blocked(aid, claimed or app.is_blocked)

# ------------------------------------------------------------------ shared ----

static func _row_card(n: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = n
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	return card
