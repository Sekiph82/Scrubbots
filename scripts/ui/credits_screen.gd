extends RefCounted
## CreditsScreen — preload (res://scripts/ui/credits_screen.gd).
##
## SB-M59-010 — Settings -> CREDITS: the read-only third-party notices the MIT / engine
## licences require to ship with the app, in the approved popup family (large frame, scroll,
## one CLOSE). Texts come from their sources, never retyped: the Godot licence and its
## third-party components from Engine.get_license_text() / get_copyright_info() /
## get_license_info() (this covers the engine's bundled default font; the game bundles no
## other font), the two addon licences from their LICENSE files (shipped by the export
## presets' include_filter, checked by tools/check_release_versioning.py).

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")

const POPUP_ID := "credits"
## UiText name key -> licence file (shipped addons, MIT).
const ADDONS := {
	"CREDITS_NAME_GAME_FEEL_FLOW": "res://addons/game_feel_flow/LICENSE",
	"CREDITS_NAME_SALTMIRE_SPARK": "res://addons/saltmire_spark/LICENSE.txt",
}

static func open(stack) -> BasePopup:
	if stack == null:
		return null
	var p := BasePopup.new(POPUP_ID)
	p.set_frame("large")
	p.set_title(UiText.t("CREDITS_TITLE"))
	var scroll := ScrollContainer.new()
	scroll.name = "CreditsScroll"
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "CreditsList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)
	list.add_child(_line(UiText.t("CREDITS_INTRO"), "Intro", BasePopup.INK, 24))
	list.add_child(_line(UiText.t("CREDITS_NAME_GODOT"), "GodotHeader", BasePopup.ROYAL_EDGE, 30))
	list.add_child(_line(Engine.get_license_text(), "GodotLicense", BasePopup.INK, 20))
	for key in ADDONS:
		list.add_child(_line(UiText.t(key), "Header_" + key, BasePopup.ROYAL_EDGE, 30))
		list.add_child(_line(FileAccess.get_file_as_string(ADDONS[key]), "License_" + key, BasePopup.INK, 20))
	list.add_child(_line(UiText.t("CREDITS_GODOT_COMPONENTS"), "ComponentsHeader", BasePopup.ROYAL_EDGE, 30))
	var rows: PackedStringArray = []
	for c in Engine.get_copyright_info():
		for part in c["parts"]:
			rows.append("%s: © %s (%s)" % [c["name"], ", ".join(part["copyright"]), part["license"]])
	list.add_child(_line("\n".join(rows), "Components", BasePopup.INK, 20))
	var licenses: Dictionary = Engine.get_license_info()
	for id in licenses:
		list.add_child(_line(String(id), "LicenseHeader_" + String(id).validate_node_name(), BasePopup.ROYAL_EDGE, 24))
		list.add_child(_line(String(licenses[id]), "License_" + String(id).validate_node_name(), BasePopup.INK, 20))
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
