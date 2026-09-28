extends RefCounted
## Popups — preload (res://scripts/ui/popup/popups.gd).
##
## M43-C002 builders: each returns ONE configured BasePopup (push it on the ModalStack).
## Every builder is pure presentation over caller-supplied data: none holds a service,
## grants, spends or decides a consequence. Copy is UiText keys + live values.
##
##   pause(spec)            SB-M43-019  Resume / Restart / Home + live level context
##   attempt_confirm(...)   SB-M43-020/021 Restart / Home confirmation from a host
##                          consequence dict (derived from M30/M39 authority, not UI)
##   confirm(spec)          SB-M43-017  generic destructive/costly confirm (+warning)
##   reward(spec)           SB-M43-018  displays caller-COMMITTED rows only
##   insufficient_sb(spec)  SB-M43-022  Shop route with a detached pending context
##   network_error(spec)    SB-M43-023  retry (pending) / cancel for ads/store/cloud/live
##   busy(spec)             SB-M43-024  non-dismissible pending state with timeout
##   feedback(result)       SB-M43-025  caller-committed success/failure

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

const NETWORK_SURFACES := ["rewarded_ad", "store", "cloud", "live_event"]

## spec: {level:int}
static func pause(spec: Dictionary) -> BasePopup:
	var p := BasePopup.new("pause")
	p.set_frame("medium")
	p.set_title(UiText.t("PAUSE_TITLE"))
	var lvl := int(spec.get("level", 0))
	p.add_body_line(UiText.t("RESULTS_LEVEL", [lvl]) if lvl > 0 else "", "LevelContext", BasePopup.INK, 36)
	p.add_action("resume", UiText.t("PAUSE_RESUME"), "primary", true)
	p.add_action("restart", UiText.t("PAUSE_RESTART"), "secondary", false)
	p.add_action("home", UiText.t("PAUSE_HOME"), "secondary", false)
	p.context = {"level": lvl}
	return p

## Restart / Home confirmation. `kind` "restart" | "home"; `c` is the host's
## attempt_consequence() (read from WinStreakService.gameplay_started + HeartService).
static func attempt_confirm(kind: String, c: Dictionary) -> BasePopup:
	var started := bool(c.get("gameplay_started", false))
	var p := BasePopup.new("confirm_" + kind)
	p.set_frame("warning" if started else "medium")
	p.set_title(UiText.t("RESTART_TITLE" if kind == "restart" else "LEAVE_TITLE"))
	var lvl := int(c.get("level", 0))
	if lvl > 0:
		p.add_body_line(UiText.t("RESULTS_LEVEL", [lvl]), "LevelContext")
	for line in consequence_lines(c):
		p.add_body_line(line["text"], line["name"], BasePopup.WARN_INK if line["loss"] else BasePopup.INK)
	p.add_action("confirm", UiText.t("CONFIRM_RESTART" if kind == "restart" else "CONFIRM_LEAVE"), "primary", true)
	p.add_action("cancel", UiText.t("CONFIRM_KEEP_PLAYING"), "secondary", true)
	p.context = {"kind": kind, "consequence": c.duplicate(true)}
	return p

## Display lines for a consequence dict: [{name, text, loss}]. Pure; no authority read.
static func consequence_lines(c: Dictionary) -> Array:
	if not bool(c.get("gameplay_started", false)):
		return [{"name": "ConsequenceFree", "text": UiText.t("CONSEQ_FREE"), "loss": false}]
	var out: Array = [{"name": "ConsequenceIntro", "text": UiText.t("CONSEQ_LOSS_INTRO"), "loss": true}]
	if bool(c.get("heart_loss", false)):
		out.append({"name": "ConsequenceHeart", "text": UiText.t("CONSEQ_HEART",
			[int(c["hearts_before"]), int(c["hearts_after"])]), "loss": true})
	if bool(c.get("streak_reset", false)):
		out.append({"name": "ConsequenceStreak", "text": UiText.t("CONSEQ_STREAK", [int(c["streak_before"])]), "loss": true})
	return out

## Generic confirm. spec: {id?, title, body, confirm_text?, cancel_text?, warning?, context?}
## Emits action_selected("confirm", context) at most once; any other close = cancel.
static func confirm(spec: Dictionary) -> BasePopup:
	var p := BasePopup.new(String(spec.get("id", "confirm")))
	var warn := bool(spec.get("warning", false))
	p.set_frame("warning" if warn else "medium")
	p.set_title(String(spec.get("title", "")))
	p.add_body_line(String(spec.get("body", "")), "Body", BasePopup.WARN_INK if warn else BasePopup.INK)
	p.add_action("confirm", String(spec.get("confirm_text", UiText.t("CONFIRM_OK"))), "primary", true)
	p.add_action("cancel", String(spec.get("cancel_text", UiText.t("CONFIRM_CANCEL"))), "secondary", true)
	p.context = (spec.get("context", {}) as Dictionary).duplicate(true)
	return p

## Reward / confirmation of an action the CALLER already committed.
## spec: {committed:true, title, rows:[{text, icon?}], context?}. Returns null unless
## `committed` is exactly true — this popup can never be used to preview or grant.
static func reward(spec: Dictionary) -> BasePopup:
	var committed = spec.get("committed", false)
	if not (committed is bool and committed):
		return null
	var p := BasePopup.new(String(spec.get("id", "reward")))
	p.set_frame("reward")
	p.set_title(String(spec.get("title", UiText.t("REWARD_TITLE"))))
	var i := 0
	for r in spec.get("rows", []):
		var row := HBoxContainer.new()
		row.name = "Row%d" % i
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
		var icon_path := String(r.get("icon", ""))
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var icon := HomeStyle.art("Icon")
			icon.custom_minimum_size = Vector2(72, 72)
			icon.texture = load(icon_path)
			row.add_child(icon)
		var l := BasePopup.body_label(String(r.get("text", "")), UiTokens.FONT_BODY + 4)
		l.name = "Text"
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if row.get_child_count() > 0 else HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(l)
		p.get_content().add_child(row)
		i += 1
	p.add_action("ok", UiText.t("REWARD_OK"), "primary", true)
	p.context = (spec.get("context", {}) as Dictionary).duplicate(true)
	return p

## Insufficient Scrub Bucks. spec: {item_label, price_sb, balance_sb, pending:{...}}.
## "shop" / "cancel" both close and hand the caller the detached pending context so it can
## resume or cancel its acquisition cleanly. Nothing is spent or granted here.
static func insufficient_sb(spec: Dictionary) -> BasePopup:
	var p := BasePopup.new("insufficient_sb")
	p.set_frame("medium")
	p.set_title(UiText.t("INSUFFICIENT_TITLE"))
	var price := int(spec.get("price_sb", 0))
	var bal := int(spec.get("balance_sb", 0))
	p.add_body_line(UiText.t("INSUFFICIENT_BODY", [String(spec.get("item_label", "")), UiText.num(price)]), "Body")
	p.add_body_line(UiText.t("INSUFFICIENT_BALANCE", [UiText.num(bal), UiText.num(maxi(price - bal, 0))]), "Balance", BasePopup.WARN_INK)
	p.add_action("shop", UiText.t("INSUFFICIENT_SHOP"), "primary", true)
	p.add_action("cancel", UiText.t("CONFIRM_CANCEL"), "secondary", true)
	p.context = {"pending": (spec.get("pending", {}) as Dictionary).duplicate(true),
		"price_sb": price, "balance_sb": bal}
	return p

## Network-required / error. spec: {surface, context?}. "retry" latches; the caller calls
## begin_pending()/resolve_pending() for the one retry transaction. "cancel" closes.
static func network_error(spec: Dictionary) -> BasePopup:
	var surface := String(spec.get("surface", "store"))
	if not NETWORK_SURFACES.has(surface):
		surface = "store"
	var p := BasePopup.new("network_" + surface)
	p.set_frame("warning")
	p.set_title(UiText.t("NETWORK_TITLE"))
	p.add_body_line(UiText.t("NETWORK_BODY_" + surface.to_upper()), "Body")
	p.add_action("retry", UiText.t("NETWORK_RETRY"), "primary", false)
	p.add_action("cancel", UiText.t("CONFIRM_CANCEL"), "secondary", true)
	p.context = (spec.get("context", {}) as Dictionary).duplicate(true)
	p.context["surface"] = surface
	return p

## Busy / loading for one unresolved external transaction. Non-dismissible; the caller
## resolves the token from get_pending_token() after push (begin_on_open handles it).
## spec: {title?, body?, timeout_s?, action_id?}
static func busy(spec: Dictionary) -> BasePopup:
	var p := BasePopup.new("busy")
	p.set_frame("small")
	p.set_close_enabled(false)
	p.set_title(String(spec.get("title", UiText.t("BUSY_TITLE"))))
	var action := String(spec.get("action_id", "transaction"))
	var body := String(spec.get("body", UiText.t("POPUP_BUSY")))
	var timeout := float(spec.get("timeout_s", 0.0))
	p.opened.connect(func(): p.begin_pending(action, body, timeout), CONNECT_ONE_SHOT)
	return p

## Caller-committed success/failure. result: {ok:bool, title?, text?, reason?}.
static func feedback(result: Dictionary) -> BasePopup:
	var ok := bool(result.get("ok", false))
	var p := BasePopup.new("feedback_" + ("success" if ok else "failure"))
	p.set_frame("reward" if ok else "warning")
	p.set_title(String(result.get("title", UiText.t("FEEDBACK_SUCCESS" if ok else "FEEDBACK_FAILURE"))))
	var text := String(result.get("text", ""))
	if text.is_empty() and not ok:
		text = UiText.t("FEEDBACK_REASON", [String(result.get("reason", "failed"))])
	p.add_body_line(text, "Body", BasePopup.INK if ok else BasePopup.WARN_INK)
	p.add_action("ok", UiText.t("REWARD_OK" if ok else "FEEDBACK_OK"), "primary", true)
	p.context = {"ok": ok}
	return p
