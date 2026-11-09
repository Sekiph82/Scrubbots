extends RefCounted
## CloudConflictScreen — preload (res://scripts/ui/cloud_conflict_screen.gd).
##
## SB-M49-030 / SB-M43-159 — the account/cloud conflict choice (ui_surface_registry
## "account_conflict") in the approved popup family. Shown only while CloudSaveService is in
## CONFLICT: both copies side by side (level, Scrub Bucks, robots, last played; all recomputed
## by CloudSave from each payload) and two choices. Each choice discards the other copy, so it
## opens a warning confirm first; only CONFIRM calls CloudSaveService.choose(). Cancel / back
## re-arms the choice; closing the screen leaves the conflict (and both saves) untouched.
## Platform sign-in stays the platform's own UI; this screen never signs in or out.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const POPUP_ID := "account_conflict"

static func open(stack, cloud) -> BasePopup:
	if stack == null or cloud == null or cloud.state() != cloud.CONFLICT:
		return null
	var info: Dictionary = cloud.conflict()
	var p := BasePopup.new(POPUP_ID)
	p.set_frame("large")
	p.set_title(UiText.t("CLOUD_CONFLICT_TITLE"))
	p.add_body_line(UiText.t("CLOUD_CONFLICT_BODY"), "Body")
	var sides := HBoxContainer.new()
	sides.name = "Sides"
	sides.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	p.get_content().add_child(sides)
	sides.add_child(_side("Device", UiText.t("CLOUD_SIDE_DEVICE"), info["local"]))
	sides.add_child(_side("Cloud", UiText.t("CLOUD_SIDE_CLOUD"), info["remote"]))
	p.add_action(cloud.KEEP_DEVICE, UiText.t("CLOUD_KEEP_DEVICE"), "secondary", false)
	p.add_action(cloud.KEEP_CLOUD, UiText.t("CLOUD_KEEP_CLOUD"), "secondary", false)
	p.action_selected.connect(func(id: String, _c): _confirm(stack, cloud, p, id))
	if not stack.push(p):
		p.free()
		return null
	return p

static func _side(n: String, title: String, s: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.name = n
	box.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	box.add_child(_line(title, "Title", BasePopup.ROYAL_EDGE, UiTokens.FONT_BODY))
	box.add_child(_line(UiText.t("CLOUD_SUMMARY_LEVEL", [UiText.num(int(s["level"]))]), "Level", BasePopup.INK, 26))
	box.add_child(_line(UiText.t("CLOUD_SUMMARY_SB", [UiText.num(int(s["scrub_bucks"]))]), "ScrubBucks", BasePopup.INK, 26))
	box.add_child(_line(UiText.t("CLOUD_SUMMARY_ROBOTS", [UiText.num(int(s["robots"]))]), "Robots", BasePopup.INK, 26))
	box.add_child(_line(UiText.t("CLOUD_SUMMARY_LAST", [_date(int(s["saved_at"]))]), "LastPlayed", BasePopup.INK, 26))
	var card: Control = SettingsPanel._card(box)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card

static func _line(text: String, n: String, color: Color, px: int) -> Label:
	var l := BasePopup.body_label(text, px, color)
	l.name = n
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

## Device-local date and time of a unix timestamp, digits only (locale-neutral).
static func _date(ts: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(ts + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]

static func _confirm(stack, cloud, p: BasePopup, choice: String) -> void:
	var c := Popups.confirm({"id": "account_conflict_confirm", "title": UiText.t("CLOUD_CONFIRM_TITLE"),
		"body": UiText.t("CLOUD_CONFIRM_DEVICE" if choice == cloud.KEEP_DEVICE else "CLOUD_CONFIRM_CLOUD"),
		"confirm_text": UiText.t("CLOUD_CONFIRM_REPLACE"), "warning": true})
	c.closed.connect(func(why: String):
		if why == "action:confirm":
			cloud.choose(choice)
			p.close("chosen")
		else:
			p.rearm())
	if not stack.push(c):
		c.free()
		p.rearm()
