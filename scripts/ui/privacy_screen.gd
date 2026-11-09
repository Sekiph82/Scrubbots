extends RefCounted
## PrivacyScreen — preload (res://scripts/ui/privacy_screen.gd).
##
## SB-M58-008/009/014 — Settings -> PRIVACY in the approved popup family: the SHARE ANALYTICS
## switch (default OFF; the ONLY production caller of AnalyticsService.set_consent, which
## persists it to the analytics state file at once), one ADS line (this build has no ads SDK,
## so there is no ad choice and no placeholder toggle), the short privacy summary and the note
## that the full policy link is added before release (URL: owner). One action: CLOSE.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")

const POPUP_ID := "privacy"
const SUMMARY := ["PRIVACY_SUMMARY_DEVICE", "PRIVACY_SUMMARY_NO_ACCOUNT", "PRIVACY_SUMMARY_NOTIFY", "PRIVACY_SUMMARY_DELETE"]

static func open(stack, app) -> BasePopup:
	if stack == null or app == null or app.analytics == null:
		return null
	var p := BasePopup.new(POPUP_ID)
	p.set_frame("large")
	p.set_title(UiText.t("PRIVACY_TITLE"))
	var scroll := ScrollContainer.new()
	scroll.name = "PrivacyScroll"
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "PrivacyList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)
	var box := VBoxContainer.new()
	box.name = "AnalyticsRow"
	var t: CheckButton = SettingsPanel._make_toggle(UiText.t("PRIVACY_ANALYTICS"))
	t.name = "AnalyticsToggle"
	t.set_pressed_no_signal(app.analytics.has_consent())
	t.toggled.connect(func(on: bool): app.analytics.set_consent(on))
	box.add_child(t)
	box.add_child(_line(UiText.t("PRIVACY_ANALYTICS_HINT"), "AnalyticsHint", BasePopup.INK, 24))
	list.add_child(SettingsPanel._card(box))
	list.add_child(_line(UiText.t("PRIVACY_ADS"), "AdsNote", BasePopup.INK, 24))
	list.add_child(_line(UiText.t("PRIVACY_SUMMARY_HEADER"), "SummaryHeader", BasePopup.ROYAL_EDGE, 30))
	for k in SUMMARY:
		list.add_child(_line(UiText.t(k), "Summary_" + String(k), BasePopup.INK, 24))
	list.add_child(_line(UiText.t("PRIVACY_POLICY_LINK"), "PolicyLink", BasePopup.INK, 24))
	p.add_action("close", UiText.t("SETTINGS_CLOSE"), "secondary", true)
	if not stack.push(p):
		p.free()
		return null
	return p

static func _line(text: String, n: String, color: Color, px: int) -> Label:
	var l := BasePopup.body_label(text, px, color)
	l.name = n
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
