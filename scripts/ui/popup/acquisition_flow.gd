extends RefCounted
## AcquisitionFlow — preload (res://scripts/ui/popup/acquisition_flow.gd).
##
## M43-C003 — the ONE controller for the acquisition surfaces, built on the M43-C002
## BasePopup / ModalStack (no second popup or modal authority):
##   Life           open_life(source)        SB-M43-030..035 (Home Heart + / zero-Heart gate)
##   Booster Acquire open_booster(host, id)  SB-M43-037..044 (one data-driven component)
##   Shop handoff   open_shop(context)       SB-M43-036 / 022 consumer (ShopHandoff ticket)
##   Insufficient   open_insufficient(ctx)   shared by Life / Booster / 2x
## (2x Acquire lives in speed_acquisition_popup.gd, driven by the gameplay host, and uses
## open_insufficient here.)
##
## Presentation + intent only. Every mutation goes through ProductionActionFacade (SB
## purchases), the gameplay host's canonical booster execution (charge-first, solver-safe),
## or RewardedGrantService (verified rewarded grants). The flow never touches wallet,
## Hearts or charges directly, and shows success only after the authority committed.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")

const HEART_ART := "res://assets/ui/final/popups/failure/heart_large.png"
const LIFE_HERO_ART := "res://assets/ui/final/popups/help/help_scrubby_pose.png"
const REFILL_ART := "res://assets/ui/final/popups/failure/refill_heart_bundle.png"
const CLOCK_ART := "res://assets/ui/final/common/icons/icon_clock.png"
const SB_ART := "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png"
const HEART_ICON_ART := "res://assets/ui/final/common/currencies/icon_currency_heart.png"
const SHOP_ART := "res://assets/ui/final/shop/shop_header_emblem.png"
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

## M43-C008 (SB-M43-108): the active robot's approved help pose (Scrubby default / fallback).
func _help_pose() -> String:
	if _economy == null:
		return LIFE_HERO_ART
	var id: String = _economy.robots.active_robot()
	return LIFE_HERO_ART if id == String(RobotRoster.load_roster()["initial_robot_id"]) else RobotRoster.asset(id, "help_pose")
## Canonical booster data (icons = the same production art as the V02 booster row).
const BOOSTER_DEFS := {
	"plus_one_slot": {"icon": "res://assets/ui/final/boosters/extra_slot.png", "target": ""},
	"random": {"icon": "res://assets/ui/final/boosters/random.png", "target": ""},
	"selector": {"icon": "res://assets/ui/final/boosters/selector.png", "target": "batch"},
	"tornado": {"icon": "res://assets/ui/final/boosters/tornado.png", "target": "color"},
}
## UI safety bound for an unresolved rewarded video (a stuck provider must not leave the
## popup busy forever). Not an ad policy: frequency/cooldown/caps are M57.
var reward_ui_timeout_s := 90.0
const MAX_TARGET_CHIPS := 12

var _stack
var _economy
var _actions
var _shop
var _reward_waits: Dictionary = {}   ## rewarded token -> {popup, pending, kind, host, booster}
var last_result: Dictionary = {}     ## diagnostic: last committed/refused acquisition result

func bind(stack, economy, actions, shop) -> void:
	_stack = stack
	_economy = economy
	_actions = actions
	_shop = shop
	if _economy != null and not _economy.rewarded.resolved.is_connected(_on_rewarded_resolved):
		_economy.rewarded.resolved.connect(_on_rewarded_resolved)
	if _shop != null and not _shop.shop_requested.is_connected(_on_shop_requested):
		_shop.shop_requested.connect(_on_shop_requested)

func unbind() -> void:
	if _economy != null and _economy.rewarded.resolved.is_connected(_on_rewarded_resolved):
		_economy.rewarded.resolved.disconnect(_on_rewarded_resolved)
	if _shop != null and _shop.shop_requested.is_connected(_on_shop_requested):
		_shop.shop_requested.disconnect(_on_shop_requested)
	_reward_waits.clear()

func get_shop():
	return _shop

## The open popup with `popup_id`, or null.
func find_open(popup_id: String):
	if _stack == null:
		return null
	for c in _stack.get_child(0).get_children():
		if c.popup_id == popup_id and c.is_open():
			return c
	return null

# ================================================================== Life ==========

## Open the canonical Life popup (Home Heart +, zero-Heart gate, restart gate). One Life
## at a time: a second request while one is open returns the open one.
func open_life(source: String):
	if _economy == null or _stack == null:
		return null
	var open = find_open("life")
	if open != null:
		return open
	var p := BasePopup.new("life")
	p.context = {"source": source}
	p.set_frame("medium")
	p.set_hero(_help_pose(), Vector2(260, 260), 70)
	p.set_title(UiText.t("LIFE_TITLE"))
	var c: VBoxContainer = p.get_content()
	# Big heart with the live count on it (reference composition).
	var heart_box := CenterContainer.new()
	heart_box.name = "HeartBox"
	c.add_child(heart_box)
	var heart := HomeStyle.art("Heart")
	heart.texture = load(HEART_ART)
	heart.custom_minimum_size = Vector2(210, 190)
	heart_box.add_child(heart)
	var count := HomeStyle.label("", 84, Color(1, 1, 1), 14)
	count.name = "HeartCount"
	count.add_theme_color_override("font_outline_color", Color(0.45, 0.02, 0.06))
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	heart.add_child(count)
	p.add_body_line("", "HeartsOfMax")
	# Timer panel: "Next life in:" + clock pill (live) / full ready state (static 15:00).
	var panel := PanelContainer.new()
	panel.name = "TimerPanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, Color(0.890, 0.765, 0.545), 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	c.add_child(panel)
	var tcol := VBoxContainer.new()
	tcol.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	panel.add_child(tcol)
	var tt := BasePopup.body_label("", UiTokens.FONT_BODY)
	tt.name = "TimerTitle"
	tcol.add_child(tt)
	var pill_row := CenterContainer.new()
	tcol.add_child(pill_row)
	var pill := PanelContainer.new()
	pill.name = "TimerPill"
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(Color(0.30, 0.30, 0.34), Color(0.2, 0.2, 0.24), 2, 30, 0), UiTokens.SPACE_LG, UiTokens.SPACE_XS))
	pill_row.add_child(pill)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	pill.add_child(ph)
	var clock := HomeStyle.art("Clock")
	clock.texture = load(CLOCK_ART)
	clock.custom_minimum_size = Vector2(52, 52)
	ph.add_child(clock)
	var tv := HomeStyle.label("", 38)
	tv.name = "TimerValue"
	tv.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(tv)
	c.add_child(_balance_row())
	var sb1 := p.add_action("heart_plus_one", "", "offer", false, "sb")
	_badge(sb1, HEART_ICON_ART, "+1")
	var sbr := p.add_action("heart_refill", "", "offer", false, "sb")
	_badge(sbr, HEART_ICON_ART, "")
	var watch := p.add_action("watch", UiText.t("REWARDED_FREE"), "primary", false)
	_play_glyph(watch)
	_badge(watch, HEART_ICON_ART, "+1")
	p.add_footer_note(UiText.t("LIFE_CHEER"), "Cheer")
	p.add_body_line("", "RewardedNote", BasePopup.INK, 24)
	p.add_body_line("", "Status", BasePopup.INK, UiTokens.FONT_BODY)
	p.action_selected.connect(_on_life_action.bind(p))
	# Live countdown: a popup-owned 1 s redraw timer (freed with the popup). The value is
	# always HeartService wall-clock truth, never an accumulated local timer.
	var t := Timer.new()
	t.name = "LiveRefresh"
	t.wait_time = 1.0
	t.ignore_time_scale = true
	t.timeout.connect(_refresh_life.bind(p))
	p.add_child(t)
	if not _stack.push(p):
		p.free()
		return null
	t.start()
	_refresh_life(p)
	return p

## Life view model straight from HeartService / wallet / rewarded authority.
func life_model() -> Dictionary:
	var h: int = _economy.hearts.hearts()
	var m: int = _economy.hearts.max_hearts()
	var cfg = _economy.config
	return {"hearts": h, "max": m, "full": h >= m, "seconds_to_next": _economy.hearts.seconds_to_next(),
		"regen_seconds": int(cfg.hearts_regen_seconds()), "sb": _economy.wallet.scrub_bucks(),
		"plus_one_sb": int(cfg.hearts_plus_one_sb()), "missing": maxi(m - h, 0),
		"refill_sb": maxi(m - h, 0) * int(cfg.hearts_full_refill_sb_per_missing()),
		"rewarded": _economy.rewarded.can_start(RewardedGrantService.HEART)}

func _refresh_life(p) -> void:
	if not is_instance_valid(p) or not p.is_open():
		return
	var v := life_model()
	var full: bool = v["full"]
	(p.find_child("HeartCount", true, false) as Label).text = str(v["hearts"])
	(p.find_child("HeartsOfMax", true, false) as Label).text = UiText.t("LIFE_HEARTS", [v["hearts"], v["max"]])
	(p.find_child("TimerTitle", true, false) as Label).text = UiText.t("LIFE_FULL" if full else "LIFE_NEXT_IN")
	# Full: canonical static ready state (the regen interval, 15:00); no second timer.
	(p.find_child("TimerValue", true, false) as Label).text = _mmss(v["regen_seconds"] if full else v["seconds_to_next"])
	(p.find_child("Balance", true, false) as Label).text = UiText.t("ACQ_BALANCE", [UiText.num(v["sb"])])
	var b1: Button = p.get_action_button("heart_plus_one")
	b1.text = UiText.t("ACQ_PRICE_SB", [UiText.num(v["plus_one_sb"])])
	var br: Button = p.get_action_button("heart_refill")
	# Full: no refill is possible, so no price/amount is advertised.
	br.text = UiText.t("LIFE_REFILL_FULL") if full else UiText.t("ACQ_PRICE_SB", [UiText.num(v["refill_sb"])])
	(br.get_node("Badge") as Control).visible = not full
	(br.get_node("Badge/Text") as Label).text = "+%d" % v["missing"]
	p.set_action_blocked("heart_plus_one", full)
	p.set_action_blocked("heart_refill", full)
	var rw: Dictionary = v["rewarded"]
	var rw_ok: bool = rw.get("ok", false)
	p.set_action_blocked("watch", not rw_ok)
	var watch: Button = p.get_action_button("watch")
	watch.text = UiText.t("REWARDED_FREE") if rw_ok or full else UiText.t("REWARDED_UNAVAILABLE")
	var note := ""
	if full:
		note = UiText.t("LIFE_FULL_NOTE")
	elif not rw_ok and String(rw.get("reason", "")) != "pending":
		note = UiText.t("REWARDED_UNAVAILABLE_NOTE")
	(p.find_child("RewardedNote", true, false) as Label).text = note

func _on_life_action(id: String, _ctx: Dictionary, p) -> void:
	match id:
		"heart_plus_one", "heart_refill":
			var r: Dictionary = _actions.buy_heart() if id == "heart_plus_one" else _actions.refill_hearts()
			last_result = r
			if r.get("ok", false):
				_status(p, UiText.t("LIFE_BOUGHT", [int(r.get("hearts", 0))]))
			elif String(r.get("reason", "")) == "insufficient_sb":
				_status(p, UiText.t("ACQ_NOT_ENOUGH"))
				var v := life_model()
				open_insufficient({"source": "life", "product": id, "item_label": UiText.t("LIFE_ITEM_" + id.to_upper()),
					"price_sb": v["plus_one_sb"] if id == "heart_plus_one" else v["refill_sb"], "balance_sb": v["sb"]})
			else:
				_status(p, UiText.reason("ACQ_REASON_", String(r.get("reason", "failed"))))
			p.rearm_soon()
			_refresh_life(p)
		"watch":
			_start_rewarded(p, RewardedGrantService.HEART, {"kind": "heart"})

# ======================================================== Booster Acquire ==========

## Open the ONE data-driven Booster Acquire component for `id` over `host`. Mode follows
## authoritative charges: owned charge -> USE (no purchase CTA); zero -> SB / rewarded.
func open_booster(host, id: String):
	if _economy == null or _stack == null or not BOOSTER_DEFS.has(id) or host == null:
		return null
	var open = find_open("booster_" + id)
	if open != null:
		return open
	var def: Dictionary = BOOSTER_DEFS[id]
	var p := BasePopup.new("booster_" + id)
	p.context = {"booster": id, "target": null}
	p.set_meta("host", host)
	p.set_frame("medium")
	p.set_title(UiText.t("BOOSTER_NAME_" + id.to_upper()))
	var c: VBoxContainer = p.get_content()
	var top := HBoxContainer.new()
	top.name = "Summary"
	top.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	c.add_child(top)
	var icon := HomeStyle.art("BoosterIcon")
	icon.texture = load(def["icon"])
	icon.custom_minimum_size = Vector2(170, 170)
	top.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(info)
	var eff := BasePopup.body_label(UiText.t("BOOSTER_EFFECT_" + id.to_upper()), UiTokens.FONT_BODY)
	eff.name = "Effect"
	eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(eff)
	var owned := BasePopup.body_label("", UiTokens.FONT_BODY)
	owned.name = "Owned"
	owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(owned)
	if String(def["target"]) != "":
		p.add_body_line(UiText.t("BOOSTER_PICK_" + String(def["target"]).to_upper()), "PickTitle")
		var flow := HFlowContainer.new()
		flow.name = "Targets"
		flow.alignment = FlowContainer.ALIGNMENT_CENTER
		flow.add_theme_constant_override("h_separation", UiTokens.SPACE_SM)
		flow.add_theme_constant_override("v_separation", UiTokens.SPACE_SM)
		c.add_child(flow)
	p.add_body_line("", "Safety", BasePopup.WARN_INK)
	c.add_child(_balance_row())
	p.add_action("use", "", "primary", false)
	p.add_action("sb", "", "offer", false)
	var watch := p.add_action("watch", UiText.t("REWARDED_FREE"), "primary", false)
	_play_glyph(watch)
	_badge(watch, def["icon"], "+1")
	p.add_body_line("", "Status", BasePopup.INK)
	p.action_selected.connect(_on_booster_action.bind(p))
	if not _stack.push(p):
		p.free()
		return null
	_refresh_booster(p, true)
	return p

## Booster view model: live charges / price / rewarded policy + the host's legality proof
## (`leg` = a cached host.booster_legality(id); recomputed only after a state change).
func booster_model(host, id: String, leg: Dictionary = {}) -> Dictionary:
	if leg.is_empty():
		leg = host.booster_legality(id)
	return {"id": id, "charges": _economy.boosters.charges(id), "price": int(_economy.config.booster_price(id)),
		"sb": _economy.wallet.scrub_bucks(), "legal": bool(leg.get("legal", false)),
		"reason": String(leg.get("reason", "")), "targets": leg.get("targets", []),
		"target_kind": String(BOOSTER_DEFS[id]["target"]),
		"rewarded": _economy.rewarded.can_start(RewardedGrantService.booster_product(id))}

func _refresh_booster(p, rebuild_targets: bool = false) -> void:
	if not is_instance_valid(p) or not p.is_open():
		return
	var host = p.get_meta("host")
	if host == null or not is_instance_valid(host):
		return
	var id := String(p.context["booster"])
	if rebuild_targets or not p.has_meta("legality"):
		p.set_meta("legality", host.booster_legality(id))
	var v := booster_model(host, id, p.get_meta("legality"))
	p.set_meta("model", v)
	var has_charge: bool = v["charges"] > 0
	(p.find_child("Owned", true, false) as Label).text = UiText.t("BOOSTER_OWNED", [v["charges"]])
	(p.find_child("Balance", true, false) as Label).text = UiText.t("ACQ_BALANCE", [UiText.num(v["sb"])])
	if rebuild_targets and v["target_kind"] != "":
		_build_targets(p, v)
	var needs_target: bool = v["target_kind"] != ""
	var target_ok: bool = not needs_target or p.context.get("target") != null
	(p.find_child("Safety", true, false) as Label).text = "" if v["legal"] else UiText.t("BOOSTER_SAFETY_" + id.to_upper())
	var use_b: Button = p.get_action_button("use")
	use_b.text = UiText.t("BOOSTER_USE_OWNED", [v["charges"]])
	p.set_action_visible("use", has_charge)
	p.set_action_blocked("use", not (v["legal"] and target_ok))
	var sb_b: Button = p.get_action_button("sb")
	sb_b.text = UiText.t("BOOSTER_USE_SB", [UiText.num(v["price"])])
	p.set_action_visible("sb", not has_charge)
	p.set_action_blocked("sb", not (v["legal"] and target_ok))
	var rw_ok: bool = v["rewarded"].get("ok", false)
	# Rewarded CTA only when the provider policy offers this booster placement.
	p.set_action_visible("watch", not has_charge and rw_ok)

func _build_targets(p, v: Dictionary) -> void:
	var flow: HFlowContainer = p.find_child("Targets", true, false)
	for ch in flow.get_children():
		flow.remove_child(ch)
		ch.queue_free()
	var keep = p.context.get("target")
	var kept := false
	var shown := 0
	for t in v["targets"]:
		if shown >= MAX_TARGET_CHIPS:
			break
		var b := Button.new()
		b.name = ("Target_" + str(t["key"])).validate_node_name()
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN + 16, UiTokens.TOUCH_MIN)
		b.text = String(t.get("label", ""))
		b.add_theme_font_size_override("font_size", 34)
		var col: Color = t.get("color", Color(0.5, 0.5, 0.5))
		b.add_theme_stylebox_override("normal", HomeStyle.box(col, Color(1, 1, 1, 0.55), 3, 22, 4, 2))
		b.add_theme_stylebox_override("hover", HomeStyle.box(col, Color(1, 1, 1, 0.8), 3, 22, 4, 2))
		b.add_theme_stylebox_override("pressed", HomeStyle.box(col, BasePopup.ROYAL_EDGE, 8, 22, 6, 2))
		b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var key = t["key"]
		b.pressed.connect(_on_target_pressed.bind(p, key, b))
		flow.add_child(b)
		if keep != null and key == keep:
			b.set_pressed_no_signal(true)
			kept = true
		shown += 1
	# A target that is no longer legal is never silently kept.
	if not kept:
		p.context["target"] = null

func _on_target_pressed(p, key, b: Button) -> void:
	if not p.is_open() or not p.is_top() or p.is_busy():
		b.button_pressed = p.context.get("target") == key
		return
	p.context["target"] = key
	for ch in (p.find_child("Targets", true, false) as Node).get_children():
		(ch as Button).set_pressed_no_signal(ch == b)
	_refresh_booster(p)

func _on_booster_action(id: String, ctx: Dictionary, p) -> void:
	var host = p.get_meta("host")
	var booster := String(p.context["booster"])
	if host == null or not is_instance_valid(host):
		p.rearm()
		return
	match id:
		"use", "sb":
			var r: Dictionary = host.execute_booster(booster, ctx.get("target"))
			last_result = r
			if r.get("ok", false):
				p.close("booster_used")
				return
			if String(r.get("reason", "")) == "insufficient_sb":
				_status(p, UiText.t("ACQ_NOT_ENOUGH"))
				var v: Dictionary = p.get_meta("model")
				open_insufficient({"source": "booster", "product": RewardedGrantService.booster_product(booster),
					"booster": booster, "target": ctx.get("target"), "item_label": UiText.t("BOOSTER_NAME_" + booster.to_upper()),
					"price_sb": v["price"], "balance_sb": _economy.wallet.scrub_bucks()})
			else:
				_status(p, UiText.t("BOOSTER_NOT_USED"))
			p.rearm_soon()
			_refresh_booster(p, true)
		"watch":
			_start_rewarded(p, RewardedGrantService.booster_product(booster), {"kind": "booster", "booster": booster})

# ============================================================= Need a Hand ==========

## M43-C004 (SB-M43-054/058/059): Need a Hand over the Fail surface. `offer` is the host's
## get_assistance_offer() (exactly two distinct canonical boosters, else nothing opens).
## Each card owns its acquisition: zero charge -> its own BUY · <price> SB and its own
## WATCH AD; owned charge -> OWNED state, no acquisition CTA (charge-first). Acquisition
## only saves one charge for the next attempt; nothing executes on the terminal board.
## Top-right X / Back closes with no effect; there is no NO THANKS.
func open_need_a_hand(offer: Dictionary):
	if _economy == null or _stack == null or not bool(offer.get("show", false)):
		return null
	var ids: Array = (offer.get("picks", []) as Array).map(func(p): return String(p.get("id", "")))
	if ids.size() != 2 or ids[0] == ids[1] or not (BOOSTER_DEFS.has(ids[0]) and BOOSTER_DEFS.has(ids[1])):
		return null
	var open = find_open("need_a_hand")
	if open != null:
		return open
	var p := BasePopup.new("need_a_hand")
	p.context = {"level": int(offer.get("level", 0)), "boosters": ids.duplicate()}
	p.set_frame("medium")
	p.set_title(UiText.t("NAH_TITLE"))
	p.add_body_line(UiText.t("NAH_SUBTITLE"), "Subtitle", BasePopup.ROYAL, UiTokens.FONT_BODY)
	var row := HBoxContainer.new()
	row.name = "Cards"
	row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	p.get_content().add_child(row)
	for id in ids:
		row.add_child(_nah_card(p, id))
	var bubble := HBoxContainer.new()
	bubble.name = "Bubble"
	bubble.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(bubble)
	var say := PanelContainer.new()
	say.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	say.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	bubble.add_child(say)
	var sl := BasePopup.body_label(UiText.t("NAH_BUBBLE"), 26)
	sl.name = "BubbleText"
	say.add_child(sl)
	var scrubby := HomeStyle.art("Scrubby")
	scrubby.texture = load(_help_pose())
	scrubby.custom_minimum_size = Vector2(120, 132)
	bubble.add_child(scrubby)
	p.add_body_line(UiText.t("NAH_NO_GUARANTEE"), "NoGuarantee", BasePopup.INK, 22)
	p.add_body_line("", "Status", BasePopup.INK, 26)
	p.action_selected.connect(_on_nah_action.bind(p))
	if not _stack.push(p):
		p.free()
		return null
	_refresh_nah(p)
	return p

## One self-contained booster card; its two CTAs are popup actions placed inside it.
func _nah_card(p, id: String) -> Control:
	var card := PanelContainer.new()
	card.name = "Card_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.set_meta("booster", id)
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(Color(1.0, 0.973, 0.918), BasePopup.ROYAL, 4, 26, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	card.add_child(col)
	var name_l := BasePopup.body_label(UiText.t("BOOSTER_NAME_" + id.to_upper()), 36, BasePopup.ROYAL_EDGE)
	name_l.name = "Name"
	col.add_child(name_l)
	var icon_box := CenterContainer.new()
	col.add_child(icon_box)
	var icon := HomeStyle.art("Icon")
	icon.texture = load(BOOSTER_DEFS[id]["icon"])
	icon.custom_minimum_size = Vector2(140, 140)
	icon_box.add_child(icon)
	var ben := BasePopup.body_label(UiText.t("NAH_BENEFIT_" + id.to_upper()), 26)
	ben.name = "Benefit"
	ben.custom_minimum_size = Vector2(0, 68)
	col.add_child(ben)
	var owned := BasePopup.body_label("", 26)
	owned.name = "Owned"
	col.add_child(owned)
	for b in [p.add_action("buy:" + id, "", "offer", false, "", col), p.add_action("watch:" + id, UiText.t("NAH_WATCH"), "primary", false, "", col)]:
		b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
		b.add_theme_font_size_override("font_size", 30)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			b.add_theme_stylebox_override(st, sb)
	var note := BasePopup.body_label("", 22)
	note.name = "Note"
	col.add_child(note)
	return card

## Card states straight from BoosterInventory / EconomyConfig / wallet / rewarded policy.
func need_a_hand_model(id: String) -> Dictionary:
	return {"id": id, "charges": _economy.boosters.charges(id), "price": int(_economy.config.booster_price(id)),
		"sb": _economy.wallet.scrub_bucks(), "rewarded": _economy.rewarded.can_start(RewardedGrantService.booster_product(id))}

func _refresh_nah(p) -> void:
	if not is_instance_valid(p) or not p.is_open():
		return
	for id in p.context["boosters"]:
		var v := need_a_hand_model(id)
		var card: Control = p.find_child("Card_" + id, true, false)
		var owned: bool = v["charges"] > 0
		(card.find_child("Owned", true, false) as Label).text = UiText.t("NAH_OWNED", [v["charges"]])
		var buy: Button = p.get_action_button("buy:" + id)
		buy.text = UiText.t("NAH_BUY", [UiText.num(v["price"])])
		p.set_action_visible("buy:" + id, not owned)
		p.set_action_visible("watch:" + id, not owned)
		var rw_ok: bool = v["rewarded"].get("ok", false)
		p.set_action_blocked("watch:" + id, not rw_ok)
		var note := ""
		if owned:
			note = UiText.t("NAH_OWNED_READY")
		elif not rw_ok and String(v["rewarded"].get("reason", "")) != "pending":
			note = UiText.t("NAH_AD_UNAVAILABLE")
		(card.find_child("Note", true, false) as Label).text = note

func _on_nah_action(action: String, _ctx: Dictionary, p) -> void:
	var parts := action.split(":")
	var id: String = parts[1] if parts.size() == 2 else ""
	if not (p.context["boosters"] as Array).has(id):
		p.rearm()
		return
	if parts[0] == "watch":
		_start_rewarded(p, RewardedGrantService.booster_product(id), {"kind": "charge", "booster": id})
		return
	var r: Dictionary = _actions.buy_booster_charge(id)
	last_result = r
	if r.get("ok", false):
		_status(p, UiText.t("NAH_BOUGHT", [UiText.t("BOOSTER_NAME_" + id.to_upper())]))
	elif String(r.get("reason", "")) == "insufficient_sb":
		_status(p, UiText.t("ACQ_NOT_ENOUGH"))
		open_insufficient({"source": "need_a_hand", "product": RewardedGrantService.booster_product(id),
			"booster": id, "level": int(p.context["level"]), "item_label": UiText.t("BOOSTER_NAME_" + id.to_upper()),
			"price_sb": int(_economy.config.booster_price(id)), "balance_sb": _economy.wallet.scrub_bucks()})
	else:
		_status(p, UiText.reason("ACQ_REASON_", String(r.get("reason", "failed"))))
	p.rearm_soon()
	_refresh_nah(p)

# ================================================================== rewarded ======

func _start_rewarded(p, product: String, wait: Dictionary) -> void:
	var r: Dictionary = _actions.start_rewarded(product)
	if not r.get("ok", false):
		last_result = r
		_status(p, UiText.t("REWARDED_UNAVAILABLE_NOTE"))
		p.rearm()
		_refresh(p)
		return
	var token := String(r["token"])
	var done: Dictionary = _economy.rewarded.result_for(token)
	if not done.is_empty():
		# Provider delivered synchronously.
		p.rearm()
		_apply_reward_outcome(p, done, wait)
		return
	wait["popup"] = p
	wait["pending"] = p.begin_pending("watch", UiText.t("REWARDED_LOADING"), reward_ui_timeout_s)
	_reward_waits[token] = wait
	p.pending_resolved.connect(_on_popup_pending.bind(token), CONNECT_ONE_SHOT)

## Popup-side resolution: a UI timeout abandons the unresolved reward (grants nothing).
func _on_popup_pending(_action: String, result: Dictionary, token: String) -> void:
	if String(result.get("reason", "")) == "timeout" and _economy.rewarded.is_pending(token):
		_economy.rewarded.abandon(token, "timeout")

func _on_rewarded_resolved(token: String, _product: String, result: Dictionary) -> void:
	last_result = result
	if not _reward_waits.has(token):
		return
	var wait: Dictionary = _reward_waits[token]
	_reward_waits.erase(token)
	var p = wait.get("popup")
	if p == null or not is_instance_valid(p) or not p.is_open():
		return   # grant (if any) is committed; no UI left to update
	p.resolve_pending(int(wait.get("pending", 0)), result)
	_apply_reward_outcome(p, result, wait)

## UI after an authoritative rewarded result. A booster grant then proceeds ONLY through
## the host's canonical legal execution; an illegal/refused use keeps the granted charge.
func _apply_reward_outcome(p, result: Dictionary, wait: Dictionary) -> void:
	if not result.get("ok", false):
		_status(p, UiText.t("REWARDED_NO_GRANT", [UiText.reason("REWARDED_REASON_", String(result.get("reason", "failed")))]))
		_refresh(p)
		return
	if String(wait.get("kind", "")) == "heart":
		_status(p, UiText.t("LIFE_REWARDED"))
		_refresh(p)
		return
	if String(wait.get("kind", "")) == "charge":
		# Need a Hand: the charge is saved for the next attempt; never executed here.
		_status(p, UiText.t("NAH_BOUGHT", [UiText.t("BOOSTER_NAME_" + String(wait.get("booster", "")).to_upper())]))
		_refresh(p)
		return
	var host = p.get_meta("host") if p.has_meta("host") else null
	var booster := String(wait.get("booster", ""))
	if host != null and is_instance_valid(host):
		var v := booster_model(host, booster)
		var target_ok: bool = v["target_kind"] == "" or p.context.get("target") != null
		if v["legal"] and target_ok:
			var r: Dictionary = host.execute_booster(booster, p.context.get("target"))
			if r.get("ok", false):
				p.close("booster_used")
				return
	_status(p, UiText.t("BOOSTER_CHARGE_SAVED"))
	_refresh(p, true)

func _refresh(p, rebuild: bool = false) -> void:
	if p.popup_id == "life":
		_refresh_life(p)
	elif p.popup_id.begins_with("booster_"):
		_refresh_booster(p, rebuild)
	elif p.popup_id == "need_a_hand":
		_refresh_nah(p)

# ============================================================= Shop / insufficient ==

## Insufficient SB (Life / Booster / 2x). "shop" opens the canonical Shop handoff with the
## exact pending product; the originating popup stays open underneath.
func open_insufficient(ctx: Dictionary):
	if _stack == null:
		return null
	var p = Popups.insufficient_sb({"item_label": ctx.get("item_label", ""), "price_sb": int(ctx.get("price_sb", 0)),
		"balance_sb": int(ctx.get("balance_sb", 0)), "pending": ctx})
	p.action_selected.connect(_on_insufficient_action)
	if not _stack.push(p):
		p.free()
		return null
	return p

func _on_insufficient_action(id: String, ctx: Dictionary) -> void:
	if id == "shop":
		open_shop(ctx.get("pending", {}))

## Canonical Shop / SB acquisition intent (Home SB +, insufficient SB). Returns the ticket.
func open_shop(context: Dictionary) -> Dictionary:
	if _shop == null:
		return {}
	var ctx := context.duplicate(true)
	if not ctx.has("source"):
		ctx["source"] = "unknown"
	return _shop.open(ctx)

## M43-C006: every Shop intent opens the real Shop destination (ShopScreen). Closing it
## finishes the ticket, so the originating popup resumes with its exact pending context.
func _on_shop_requested(ticket: Dictionary) -> void:
	if _stack == null:
		return
	if _economy != null and _actions != null:
		ShopScreen.open(_stack, _economy, _actions, ticket, Callable(_shop, "finish"))
		return
	var p := BasePopup.new("shop")
	p.context = {"ticket_id": ticket["ticket_id"]}
	p.set_frame("medium")
	p.set_title(UiText.t("SHOP_TITLE"))
	var art := CenterContainer.new()
	var em := HomeStyle.art("ShopEmblem")
	em.texture = load(SHOP_ART)
	em.custom_minimum_size = Vector2(170, 170)
	art.add_child(em)
	p.get_content().add_child(art)
	p.add_body_line(UiText.t("SHOP_SOON"), "Body")
	var need := String(ticket.get("item_label", ""))
	if not need.is_empty():
		p.add_body_line(UiText.t("SHOP_FOR", [need, UiText.num(int(ticket.get("price_sb", 0)))]), "PendingProduct")
	p.add_action("back", UiText.t("SHOP_BACK"), "primary", true)
	var tid := String(ticket["ticket_id"])
	p.closed.connect(func(_r): _shop.finish(tid, "cancelled"))
	if not _stack.push(p):
		p.free()
		_shop.finish(tid, "cancelled")

# ================================================================== helpers =======

func _balance_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "BalanceRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	var ic := HomeStyle.art("SbIcon")
	ic.texture = load(SB_ART)
	ic.custom_minimum_size = Vector2(52, 52)
	row.add_child(ic)
	var l := BasePopup.body_label("", UiTokens.FONT_BODY)
	l.name = "Balance"
	l.autowrap_mode = TextServer.AUTOWRAP_OFF   # single live value line inside an HBox
	row.add_child(l)
	return row

func _status(p, text: String) -> void:
	var l: Label = p.find_child("Status", true, false)
	if l != null:
		l.text = text

## "+N" badge on a CTA's top-right corner (existing icon + live count).
func _badge(b: Button, icon_path: String, text: String) -> void:
	var badge := Control.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -64
	badge.offset_right = 12
	badge.offset_top = -22
	badge.offset_bottom = 54
	b.add_child(badge)
	var ic := HomeStyle.art("Icon")
	ic.texture = load(icon_path)
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(ic)
	var l := HomeStyle.label(text, 26, Color(1, 1, 1), 8)
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(l)

## Native "play video" glyph on the rewarded CTA (no new art).
func _play_glyph(b: Button) -> void:
	var g := Control.new()
	g.name = "PlayGlyph"
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.anchor_top = 0.5
	g.anchor_bottom = 0.5
	g.offset_left = 28
	g.offset_right = 84
	g.offset_top = -28
	g.offset_bottom = 28
	g.draw.connect(func():
		var s: Vector2 = g.size
		g.draw_rect(Rect2(Vector2.ZERO, s), Color(0.106, 0.365, 0.788), true)
		g.draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1), false, 3.0)
		var pts := PackedVector2Array([s * Vector2(0.36, 0.26), s * Vector2(0.74, 0.5), s * Vector2(0.36, 0.74)])
		g.draw_colored_polygon(pts, Color(1, 1, 1)))
	b.add_child(g)

static func _mmss(seconds: int) -> String:
	var s := maxi(seconds, 0)
	return "%02d:%02d" % [s / 60, s % 60]
