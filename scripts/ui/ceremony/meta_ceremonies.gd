extends RefCounted
## MetaCeremonies — preload (res://scripts/ui/ceremony/meta_ceremonies.gd).
##
## M43 master — the SHIPPING meta reward ceremonies, built from the owner-accepted M43-C005-C001
## visual masters (OWNER_VISUAL_DECISION_V02: Collection Set Complete, Master Collection, Robot
## Unlock, Gift Meter milestone, Feature Unlock, World Transition shell, generic small reward).
## Each builder returns a configured (NEW) BasePopup for ONE already-committed event from
## CeremonyEvents; push it on the app ModalStack to open.
##
## PRESENTATION ONLY: builders read the event facts they are given (committed reward amounts
## come from the same config the grant used) and never call a reward / economy / save service.
## A ceremony ends through its one CTA; Back is consumed (never dismissible, so nothing is left
## half-shown). `reduced` (Reduced Effects) keeps every label/value and only removes motion.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const ART := {
	"set_complete": "res://assets/ui/final/collection/collection_complete_emblem.png",
	"reward_glow": "res://assets/ui/final/popups/victory/reward_glow.png",
	"sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"pack_standard": "res://assets/ui/final/rewards/card_pack_standard.png",
	"pack_premium": "res://assets/ui/final/rewards/card_pack_premium.png",
	"random_booster": "res://assets/ui/final/boosters/random.png",
	"booster_choice": "res://assets/ui/final/rewards/booster_of_choice.png",
	"card_back": "res://assets/ui/final/collection/states/card_back.png",
	"heart": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
}
## Reward resource -> [icon key, UiText key]. Fixed order = row order.
const REWARD_ROWS := {
	"scrub_bucks": ["sb", "CEREMONY_ROW_SB"],
	"bot_parts": ["bot_parts", "CEREMONY_ROW_BOT_PARTS"],
	"standard_card_packs": ["pack_standard", "CEREMONY_ROW_STANDARD_PACK"],
	"premium_card_packs": ["pack_premium", "CEREMONY_ROW_PREMIUM_PACK"],
	"random_booster_charges": ["random_booster", "CEREMONY_ROW_RANDOM_BOOSTER"],
	"selected_booster_charges": ["booster_choice", "CEREMONY_ROW_BOOSTER_CHOICE"],
	"guaranteed_new_cards": ["card_back", "CEREMONY_ROW_NEW_CARD"],
	"hearts": ["heart", "CEREMONY_ROW_HEART"],
}
const GLOW_SPIN_S := 9.0   ## the C001-accepted slow celebratory glow turn (FULL only)

## One ceremony popup for a CeremonyEvents event, or null when the kind has no builder.
static func build(event: Dictionary, reduced: bool = false):
	match String(event.get("kind", "")):
		"set_complete":
			return set_complete(event, reduced)
	return null

static func card_art(card_id: String) -> String:
	var p := card_id.substr(1).split("_c")
	return "res://assets/ui/final/collection/cards/set_%02d/card_%02d.png" % [int(p[0]), int(p[1]) + 1]

# ----------------------------------------------------------------- shared parts --

static func _popup(id: String, frame: String, title: String, event: Dictionary) -> BasePopup:
	var p := BasePopup.new("ceremony_" + id)
	p.set_frame(frame)
	p.set_close_enabled(false)
	p.dismissible = false
	p.set_title(title)
	p.context = {"ceremony_key": String(event.get("key", "")), "kind": String(event.get("kind", ""))}
	p.set_meta("event", event.duplicate(true))
	return p

## Hero art with the celebratory glow behind it (glow turns slowly in FULL, static in Reduced).
static func _hero(p: BasePopup, art: String, size: Vector2, reduced: bool) -> Control:
	var box := CenterContainer.new()
	box.name = "HeroBox"
	box.custom_minimum_size = size
	p.get_content().add_child(box)
	var g := HomeStyle.art("HeroGlow")
	g.texture = load(ART["reward_glow"])
	g.custom_minimum_size = size * 1.15
	g.modulate = Color(1, 1, 1, 0.85)
	g.pivot_offset = size * 0.575
	box.add_child(g)
	if not reduced:
		g.set_meta("spin", true)
	var h := HomeStyle.art("HeroArt")
	h.texture = load(art)
	h.custom_minimum_size = size
	box.add_child(h)
	return box

## Committed reward rows (icon + live amount) in the fixed REWARD_ROWS order.
static func _reward_rows(p: BasePopup, rewards: Dictionary, row_h: int = 84) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "RewardRows"
	v.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(v)
	for key in REWARD_ROWS:
		if not rewards.has(key) or int(rewards[key]) <= 0:
			continue
		var spec: Array = REWARD_ROWS[key]
		var card := PanelContainer.new()
		card.name = "Row_" + String(key)
		card.set_meta("reward_key", key)
		card.set_meta("amount", int(rewards[key]))
		card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, Color(0.890, 0.765, 0.545), 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_XS))
		v.add_child(card)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
		card.add_child(h)
		var icon := HomeStyle.art("Icon")
		icon.texture = load(ART[spec[0]])
		icon.custom_minimum_size = Vector2(row_h - 8, row_h - 8)
		h.add_child(icon)
		var l := BasePopup.body_label(UiText.t(spec[1], [UiText.num(int(rewards[key]))]), UiTokens.FONT_BODY + 2)
		l.name = "Text"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
	return v

## Start the decorative glow turn (FULL). Every label/value already exists, so Reduced
## Effects (no motion) shows exactly the same truth. Tweens are bound to the popup.
static func start_motion(p: BasePopup) -> void:
	if not p.is_inside_tree():
		return
	for g in p.find_children("HeroGlow", "TextureRect", true, false):
		if g.has_meta("spin"):
			var tw := p.create_tween().set_loops()
			tw.tween_property(g, "rotation", TAU, GLOW_SPIN_S).from(0.0)

# ------------------------------------------------------------- Collection set ----

## SB-M43-068: Collection set 9/9 complete. Shows the set emblem, the set's nine canonical
## cards, 9 / 9 and the exact per-set reward (event rewards = the config row the grant used).
static func set_complete(event: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("set_complete", "reward", UiText.t("CEREMONY_SET_TITLE"), event)
	_hero(p, ART["set_complete"], Vector2(230, 230), reduced)
	var n := int(event["set"])
	p.add_body_line(UiText.t("CEREMONY_SET_NAME", [n, String(event.get("name", ""))]), "SetName", BasePopup.ROYAL_EDGE, 36)
	var thumbs := GridContainer.new()
	thumbs.name = "SetCards"
	thumbs.columns = 9
	thumbs.add_theme_constant_override("h_separation", 4)
	var center := CenterContainer.new()
	center.add_child(thumbs)
	p.get_content().add_child(center)
	for k in range(9):
		var a := HomeStyle.art("Thumb%d" % k)
		a.texture = load(card_art("s%d_c%d" % [n, k]))
		a.custom_minimum_size = Vector2(62, 76)
		thumbs.add_child(a)
	p.add_body_line(UiText.t("CEREMONY_SET_PROGRESS", [9, 9]), "Progress", BasePopup.INK, 30)
	_reward_rows(p, event.get("rewards", {}))
	p.add_body_line(UiText.t("CEREMONY_SET_COMMITTED"), "CommittedNote", BasePopup.INK, 24)
	p.add_action("continue", UiText.t("CEREMONY_CONTINUE"), "primary", true)
	return p
