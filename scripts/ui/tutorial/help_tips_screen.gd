extends RefCounted
## HelpTipsScreen — preload (res://scripts/ui/tutorial/help_tips_screen.gd).
##
## M44 (SB-M44-014/015) — the optional, READ-ONLY Help & Tips destination (Settings -> HELP &
## TIPS) in the approved popup family: the core rules taught in L1-L3 and all four boosters
## (name, one-sentence effect, live owned charges). It has exactly one action (CLOSE): it
## cannot restart a level or the tutorial, replay the opening cinematic, claim / grant /
## spend anything, start 2x or write any state.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const TouchScroll = preload("res://scripts/ui/components/touch_scroll.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const POPUP_ID := "help_tips"
const RULES := ["HELP_RULE_FRONT", "HELP_RULE_SLOTS", "HELP_RULE_CLEAN", "HELP_RULE_WAIT", "HELP_RULE_HEARTS", "HELP_RULE_SPEED"]

static func open(stack, app) -> BasePopup:
	if stack == null or app == null or app.economy == null:
		return null
	var p := BasePopup.new(POPUP_ID)
	p.set_frame("large")
	p.set_title(UiText.t("HELP_TITLE"))
	var scroll := ScrollContainer.new()
	scroll.name = "HelpScroll"
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.get_content().add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "HelpList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	scroll.add_child(list)
	TouchScroll.enable(scroll)
	list.add_child(_line(UiText.t("HELP_SECTION_RULES"), "RulesHeader", BasePopup.ROYAL_EDGE, 30))
	for k in RULES:
		list.add_child(_line(UiText.t(k), "Rule_" + String(k), BasePopup.INK, 24))
	list.add_child(_line(UiText.t("HELP_SECTION_BOOSTERS"), "BoostersHeader", BasePopup.ROYAL_EDGE, 30))
	for id in BoosterInventory.BOOSTERS:
		var up := String(id).to_upper()
		list.add_child(_line(UiText.t("FTUE_BOOSTER_LINE", [UiText.t("BOOSTER_NAME_" + up),
			UiText.num(app.economy.boosters.charges(String(id))), UiText.t("BOOSTER_EFFECT_" + up)]), "Booster_" + String(id), BasePopup.INK, 24))
	p.add_action("close", UiText.t("SHOP_CLOSE"), "secondary", true)
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
