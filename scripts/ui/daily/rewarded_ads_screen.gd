extends RefCounted
## RewardedAdsScreen — preload (res://scripts/ui/daily/rewarded_ads_screen.gd).
##
## M43-C015R (SB-M43-R15-001) — the REWARDED ADS destination in the approved M43 popup family
## (BasePopup large frame, royal title, cream reward rows, green CTAs, tan CLOSE). It shows the
## five configured rewards of today's Rewarded Ads track (RewardedDailyService) BEFORE any
## action, each with one live state:
##   ready free claim (CLAIM) / ready video (WATCH AD) / pending (busy, nothing granted yet) /
##   claimed (CLAIMED) / video unavailable (NO VIDEO, disabled) / date rollback (locked) /
##   not yet reached (LOCKED, "Unlocks after reward n-1": SB-M43-R15-001-R01 sequential track).
## Presentation + intent only: slot 1 goes through ProductionActionFacade.claim_rewarded_daily_free
## (committed + saved before any success text); slots 2..5 through start_rewarded_daily, whose
## grant happens ONLY in RewardedGrantService.resolve on a verified completion. A cancel / skip /
## failure / timeout / unverified result shows "No reward" and grants nothing; a UI timeout
## abandons the request so a late callback grants nothing. No hero art floats outside the frame.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const SLOTS := 5
const CTA_SIZE := Vector2(220, 96)
const UI_TIMEOUT_S := 30.0

static func open(stack, app, ui_timeout_s: float = UI_TIMEOUT_S) -> BasePopup:
	var p := BasePopup.new("rewarded_ads")
	p.set_frame("large")
	p.set_title(UiText.t("RADS_TITLE"))
	p.add_body_line(UiText.t("RADS_INTRO"), "Intro", BasePopup.INK, 22)
	var list := VBoxContainer.new()
	list.name = "Slots"
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(list)
	var rd = app.economy.rewarded_daily
	for slot in range(1, SLOTS + 1):
		list.add_child(_slot_row(p, slot, rd.reward_for(slot)))
	var note := BasePopup.body_label("", 22, BasePopup.INK)
	note.name = "Note"
	p.get_content().add_child(note)
	p.add_body_line(UiText.t("RADS_RESETS"), "Resets", BasePopup.INK, 20)
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
	p.action_selected.connect(func(id, _c):
		if id == "slot:1":
			var r: Dictionary = app.actions.claim_rewarded_daily_free()
			_set_note(p, UiText.t("RADS_GRANTED", [UiText.reward_text(r.get("reward", {}))]) if bool(r.get("ok", false)) else _reason_text(String(r.get("reason", ""))))
			refresh(p, app)
			p.rearm_soon()
		elif id.begins_with("slot:"):
			_watch(p, app, int(id.substr(5)), ui_timeout_s))
	refresh(p, app)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _slot_row(p: BasePopup, slot: int, reward: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "Slot_%d" % slot
	row.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 4, 26, 4, 4), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	row.add_child(h)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(info)
	var title := BasePopup.body_label(UiText.t("RADS_SLOT", [slot]), 26, BasePopup.ROYAL_EDGE)
	title.name = "SlotTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(title)
	var rt := BasePopup.body_label(UiText.reward_text(reward), 22, BasePopup.INK)
	rt.name = "RewardText"
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(rt)
	var st := BasePopup.body_label("", 20, Color(0.2, 0.55, 0.12))
	st.name = "State"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(st)
	var b := p.add_action("slot:%d" % slot, "", "primary", false, "", h)
	b.custom_minimum_size = CTA_SIZE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return row

## Re-render every slot from live state (never cached).
static func refresh(p: BasePopup, app) -> void:
	var rd = app.economy.rewarded_daily
	var locked := false
	for slot in range(1, SLOTS + 1):
		var st: String = rd.slot_state(slot)
		var row: Control = p.find_child("Slot_%d" % slot, true, false)
		row.set_meta("state", st)
		(row.find_child("State", true, false) as Label).text = {
			"ready_free": UiText.t("RADS_STATE_FREE"), "ready_ad": UiText.t("RADS_STATE_AD"),
			"pending": UiText.t("RADS_STATE_PENDING"), "claimed": UiText.t("RADS_STATE_CLAIMED"),
			"ad_unavailable": UiText.t("RADS_STATE_UNAVAILABLE"), "locked_rollback": UiText.t("RADS_STATE_LOCKED"),
			"locked_sequence": UiText.t("RADS_STATE_NEXT", [slot - 1]),
			"unavailable": UiText.t("RADS_STATE_UNAVAILABLE")}[st]
		var b := p.get_action_button("slot:%d" % slot)
		b.text = {"ready_free": UiText.t("POPUP_CLAIM"), "ready_ad": UiText.t("RADS_WATCH"), "pending": UiText.t("RADS_WAIT"),
			"claimed": UiText.t("RADS_CLAIMED"), "ad_unavailable": UiText.t("RADS_NO_VIDEO"), "locked_rollback": UiText.t("RADS_WAIT"),
			"locked_sequence": UiText.t("RADS_LOCKED"), "unavailable": UiText.t("RADS_NO_VIDEO")}[st]
		p.set_action_blocked("slot:%d" % slot, app.is_blocked or not (st == "ready_free" or st == "ready_ad"))
		row.modulate = Color(1, 1, 1, 0.72) if st == "claimed" else Color(1, 1, 1, 1)
		locked = locked or st == "locked_rollback"
	if locked:
		_set_note(p, UiText.t("RADS_LOCKED_NOTE"))

static func _set_note(p: BasePopup, text: String) -> void:
	var n: Label = p.find_child("Note", true, false)
	if n != null:
		n.text = text

static func _reason_text(reason: String) -> String:
	match reason:
		"unavailable", "provider_refused":
			return UiText.t("REWARDED_UNAVAILABLE_NOTE")
		"clock_rollback":
			return UiText.t("RADS_LOCKED_NOTE")
		"locked_sequence":
			return UiText.t("RADS_ORDER_NOTE")
		"already_claimed":
			return UiText.t("RADS_STATE_CLAIMED")
	return UiText.t("REWARDED_NO_GRANT", [UiText.reason("REWARDED_REASON_", reason)])

## One rewarded video for slot 2..5. Success text appears only after the verified, committed
## (and saved) grant reported by RewardedGrantService.resolved.
static func _watch(p: BasePopup, app, slot: int, ui_timeout_s: float) -> void:
	var rewarded = app.economy.rewarded
	var r: Dictionary = app.actions.start_rewarded_daily(slot)
	if not bool(r.get("ok", false)):
		_set_note(p, _reason_text(String(r.get("reason", "unavailable"))))
		refresh(p, app)
		p.rearm()
		return
	var token := String(r["token"])
	var done: Dictionary = rewarded.result_for(token)
	if not done.is_empty():   # provider delivered synchronously
		p.rearm()
		_outcome(p, app, done)
		return
	var pt: int = p.begin_pending("slot:%d" % slot, UiText.t("REWARDED_LOADING"), ui_timeout_s)
	refresh(p, app)
	var on_resolved := func(tok: String, _product: String, result: Dictionary) -> void:
		if tok != token or not is_instance_valid(p) or not p.is_open():
			return
		p.resolve_pending(pt, result)
		_outcome(p, app, result)
	rewarded.resolved.connect(on_resolved)
	p.closed.connect(func(_reason):
		if rewarded.resolved.is_connected(on_resolved):
			rewarded.resolved.disconnect(on_resolved)
		if rewarded.is_pending(token):
			rewarded.abandon(token, "timeout"), CONNECT_ONE_SHOT)
	p.pending_resolved.connect(func(_a, result: Dictionary):
		# UI timeout: abandon so a late provider callback grants nothing.
		if String(result.get("reason", "")) == "timeout" and rewarded.is_pending(token):
			rewarded.abandon(token, "timeout")
			_outcome(p, app, result), CONNECT_ONE_SHOT)

static func _outcome(p: BasePopup, app, result: Dictionary) -> void:
	if not is_instance_valid(p) or not p.is_open():
		return
	if bool(result.get("ok", false)):
		var slot := int(String(result.get("product", "")).trim_prefix("daily_slot:"))
		_set_note(p, UiText.t("RADS_GRANTED", [UiText.reward_text(app.economy.rewarded_daily.reward_for(slot))]))
	else:
		_set_note(p, _reason_text(String(result.get("reason", "failed"))))
	refresh(p, app)
