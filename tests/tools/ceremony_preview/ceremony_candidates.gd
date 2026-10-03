extends RefCounted
## CeremonyCandidates — PREVIEW HARNESS ONLY (tests/tools/ceremony_preview/).
##
## M43-C005-C001 (SB-M43-076) visual-master candidates for owner review. NOT shipping UI:
## nothing under scripts/ references this file, no production route opens it, and it is
## excluded from the main game. Every candidate is the accepted M43-C002 BasePopup family
## (promoted frame + royal title pill + live labels + green/cream CTAs) bound to a read-only
## fixture Dictionary. Builders never touch AppState, economy, collection, robots, Gift,
## Daily or RewardGrantService; actions are inert (the harness only closes the popup).
##
## Fixture truth sources (read-only): data/config/economy_rewards_v1.json through
## EconomyConfig (collection set rewards, master reward, Gift milestones, pack draw counts),
## CollectionInventory's catalog for card rarity (constructed WITHOUT a reward service: the
## catalog is built, nothing is added), and coordination/OWNER_ROBOT_ROSTER_V01.md for robot
## identity / role / perk text.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")

const ART := {
	"pack_standard": "res://assets/ui/final/rewards/card_pack_standard.png",
	"pack_premium": "res://assets/ui/final/rewards/card_pack_premium.png",
	"card_back": "res://assets/ui/final/collection/states/card_back.png",
	"card_new_glow": "res://assets/ui/final/collection/states/card_new_glow.png",
	"frame_COMMON": "res://assets/ui/final/collection/card_frame_common.png",
	"frame_RARE": "res://assets/ui/final/collection/card_frame_rare.png",
	"frame_EPIC": "res://assets/ui/final/collection/card_frame_epic.png",
	"frame_LEGENDARY": "res://assets/ui/final/collection/card_frame_legendary.png",
	"set_complete": "res://assets/ui/final/collection/collection_complete_emblem.png",
	"master_complete": "res://assets/ui/final/collection/master_collection_emblem.png",
	"reward_glow": "res://assets/ui/final/popups/victory/reward_glow.png",
	"robot_burst": "res://assets/ui/final/robots/robot_unlocked_burst.png",
	"perk_frame": "res://assets/ui/final/robots/robot_perk_emblem_frame.png",
	"gift_small": "res://assets/ui/final/rewards/gift_box.png",
	"gift_1000": "res://assets/ui/final/home/gift_meter/gift_meter_reward_crate.png",
	"world_01": "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png",
	"sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"random_booster": "res://assets/ui/final/boosters/random.png",
	"booster_choice": "res://assets/ui/final/rewards/booster_of_choice.png",   # M43-C005-C004 owner-approved
	"heart": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
}
## Reward resource -> [icon key, label template]. Every row has an approved final icon.
const REWARD_ROWS := {
	"scrub_bucks": ["sb", "+%s Scrub Bucks"],
	"bot_parts": ["bot_parts", "+%s Bot Parts"],
	"standard_card_packs": ["pack_standard", "+%s Standard Card Pack"],
	"premium_card_packs": ["pack_premium", "+%s Premium Card Pack"],
	"random_booster_charges": ["random_booster", "+%s Random Booster"],
	"selected_booster_charges": ["booster_choice", "+%s Booster of your choice"],
	"guaranteed_new_cards": ["card_back", "+%s guaranteed NEW card"],
	"hearts": ["heart", "+%s Heart"],
}
const RARITY_COLOR := {"COMMON": Color(0.47, 0.53, 0.62), "RARE": Color(0.10, 0.45, 0.92),
	"EPIC": Color(0.56, 0.25, 0.86), "LEGENDARY": Color(0.92, 0.62, 0.05)}
const NEW_GREEN := Color(0.20, 0.66, 0.14)
const PREVIEW_TAG := "PREVIEW HARNESS · SHELL TEST ONLY"

# ======================================================================= fixtures ==

## Read-only fixture truth. Returns {config, catalog}: catalog = CollectionInventory built
## with NO reward service (only its card catalog is read; nothing is ever added).
static func truth() -> Dictionary:
	var cfg := EconomyConfig.new()
	return {"config": cfg, "catalog": CollectionInventory.new(cfg, null)}

## Card art path for canonical card id "s<set>_c<k>" (k = 0..8 in rarity-profile order).
static func card_art(card_id: String) -> String:
	var p := card_id.substr(1).split("_c")
	return "res://assets/ui/final/collection/cards/set_%02d/card_%02d.png" % [int(p[0]), int(p[1]) + 1]

static func _card(t: Dictionary, card_id: String, is_new: bool, copies: int) -> Dictionary:
	return {"id": card_id, "set": int(card_id.substr(1).split("_c")[0]), "rarity": t["catalog"].card_rarity(card_id),
		"new": is_new, "copies": copies, "art": card_art(card_id)}

static func set_name(t: Dictionary, set_no: int) -> String:
	for e in t["config"].collection_config().get("set_rewards", []):
		if int(e.get("set", 0)) == set_no:
			return String(e.get("name", ""))
	return ""

## Fixture: a COMMITTED Standard pack result (3 draws) as the presentation would receive it.
static func standard_pack_fixture(t: Dictionary) -> Dictionary:
	return {"kind": "standard", "draws": int(t["config"].collection_config()["standard_pack_draws"]),
		"cards": [_card(t, "s3_c1", true, 1), _card(t, "s3_c4", false, 2), _card(t, "s7_c2", true, 1)]}

## Fixture: a COMMITTED Premium pack result (5 draws, includes Rare-or-better).
static func premium_pack_fixture(t: Dictionary) -> Dictionary:
	return {"kind": "premium", "draws": int(t["config"].collection_config()["premium_pack_draws"]),
		"cards": [_card(t, "s2_c0", true, 1), _card(t, "s4_c6", true, 1), _card(t, "s9_c3", false, 3),
			_card(t, "s11_c4", true, 1), _card(t, "s14_c8", true, 1)]}

static func set_complete_fixture(t: Dictionary, set_no: int = 6) -> Dictionary:
	for e in t["config"].collection_config().get("set_rewards", []):
		if int(e.get("set", 0)) == set_no:
			return {"set": set_no, "name": String(e["name"]), "owned": 9, "total": int(t["config"].collection_config()["cards_per_set"]),
				"rewards": {"scrub_bucks": int(e["scrub_bucks"]), "bot_parts": int(e["bot_parts"])}}
	return {}

static func master_fixture(t: Dictionary) -> Dictionary:
	var m: Dictionary = t["config"].collection_config()["all_sets_complete"]
	return {"sets": int(m["required_completed_sets"]), "rewards": {"scrub_bucks": int(m["scrub_bucks"]), "bot_parts": int(m["bot_parts"])}}

## Robot fixture from the owner roster table (OWNER_ROBOT_ROSTER_V01.md §2), verbatim.
static func robot_fixture(robot: String = "Moppy", parts_after: int = 37) -> Dictionary:
	var row := roster_row(robot)
	var key := robot.to_lower()
	var perk: String = String(row.get("perk", "")).replace("**", "")
	var perk_name := perk.get_slice(":", 0).strip_edges()
	return {"id": key, "name": robot.to_upper(), "role": row.get("role", ""), "perk_name": perk_name,
		"perk_text": perk.get_slice(":", 1).strip_edges(), "parts_left": parts_after,
		"hero": "res://assets/ui/final/characters/robots/%s/%s_master.png" % [key, key],
		"perk_icon": "res://assets/ui/final/robots/perks/perk_first_clear_sb_bonus.png" if key == "moppy" else ""}

## {number, robot, role, accent, perk} parsed from the owner roster markdown table.
static func roster_row(robot: String) -> Dictionary:
	var f := FileAccess.open("res://coordination/OWNER_ROBOT_ROSTER_V01.md", FileAccess.READ)
	if f == null:
		return {}
	for line in f.get_as_text().split("\n"):
		var cells := line.split("|")
		if cells.size() >= 7 and cells[2].replace("*", "").strip_edges() == robot:
			return {"number": cells[1].strip_edges(), "robot": robot, "role": cells[3].strip_edges(),
				"accent": cells[4].strip_edges(), "perk": cells[5].strip_edges()}
	return {}

static func gift_fixture(t: Dictionary, milestone: int) -> Dictionary:
	return {"milestone": milestone, "cycle_max": t["config"].gift_meter_cycle_max(),
		"rewards": t["config"].gift_meter_milestone(milestone)}

## Generic feature fixture — Cards Exchange used as a LABEL only (its real unlock policy is
## untouched; no campaign level exists in the fixture).
static func feature_fixture() -> Dictionary:
	return {"name": "CARDS EXCHANGE", "body": "Trade extra card copies for Scrub Bucks.",
		"icon": "res://assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png", "new_badge": true, "fixture": true}

## Generic world-transition shell: SLOTS only. No world id, no range, no future art.
static func world_shell_fixture() -> Dictionary:
	return {"title_slot": "WORLD NAME", "subtitle_slot": "Area subtitle", "art": ART["world_01"], "fixture": true}

# ====================================================================== builders ==

## The candidate builders. Each returns a configured (NEW) BasePopup; push it on a
## ModalStack to open. `reduced` = Reduced Effects: identical content, no motion.
static func build(kind: String, fx: Dictionary, reduced: bool = false):
	match kind:
		"standard_pack", "premium_pack": return pack_opening(fx, reduced)
		"set_complete": return set_complete(fx, reduced)
		"master_complete": return master_complete(fx, reduced)
		"robot_unlock": return robot_unlock(fx, reduced)
		"gift_milestone": return gift_milestone(fx, reduced)
		"feature_unlock": return feature_unlock(fx, reduced)
		"world_shell": return world_shell(fx, reduced)
		"generic_reward": return generic_reward(fx, reduced)
	return null

static func _popup(id: String, frame: String, title: String) -> BasePopup:
	var p := BasePopup.new("ceremony_" + id)
	p.set_frame(frame)
	p.set_close_enabled(false)   # ceremonies end through their one CTA (Back is consumed)
	p.set_title(title)
	p.set_meta("preview_harness", true)
	return p

## Hero art with an optional celebratory glow behind it (glow spins slowly unless reduced).
static func _hero(p: BasePopup, art: String, size: Vector2, glow: String, reduced: bool) -> Control:
	var box := CenterContainer.new()
	box.name = "HeroBox"
	box.custom_minimum_size = size
	p.get_content().add_child(box)
	if not glow.is_empty():
		var g := HomeStyle.art("HeroGlow")
		g.texture = load(glow)
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

## Rows of committed rewards (icon + live amount), in the fixed REWARD_ROWS order.
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
		var l := BasePopup.body_label(spec[1] % UiText.num(int(rewards[key])), UiTokens.FONT_BODY + 2)
		l.name = "Text"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
	return v

static func _chip(text: String, bg: Color, min_size: Vector2 = Vector2.ZERO, fs: int = 22) -> PanelContainer:
	var c := PanelContainer.new()
	c.custom_minimum_size = min_size
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, bg.darkened(0.35), 3, 18, 0), 12, 2))
	var l := Label.new()
	l.name = "Text"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", bg.darkened(0.5))
	c.add_child(l)
	return c

static func _committed_note(p: BasePopup, text: String = "Already added to your collection.") -> void:
	p.add_body_line(text, "CommittedNote", BasePopup.INK, 24)

# ------------------------------------------------------------------ pack opening --

## Pack opening: the pack art, then exactly `draws` revealed cards (3 in one row; 5 as
## 3 + 2). Each card: rarity frame + real card art, a rarity chip and NEW / DUPLICATE.
## Contents are a committed fixture; there is no reroll and no "open again".
static func pack_opening(fx: Dictionary, reduced: bool) -> BasePopup:
	var premium: bool = fx["kind"] == "premium"
	var p := _popup(String(fx["kind"]) + "_pack", "large", "PREMIUM PACK" if premium else "STANDARD PACK")
	p.set_meta("fixture", fx.duplicate(true))
	var pack := _hero(p, ART["pack_premium" if premium else "pack_standard"], Vector2(150, 225) if premium else Vector2(170, 255), ART["reward_glow"], reduced)
	pack.name = "PackArt"
	p.add_body_line("%d cards" % int(fx["draws"]), "DrawCount", BasePopup.INK, 26)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)   # room for the NEW / DUPLICATE badges on the card tops
	p.get_content().add_child(gap)
	var grid := VBoxContainer.new()
	grid.name = "Cards"
	grid.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(grid)
	var cards: Array = fx["cards"]
	var per_row := 3
	var w := 196 if premium else 210
	var row: HBoxContainer = null
	for i in range(cards.size()):
		if i % per_row == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", UiTokens.SPACE_MD)
			grid.add_child(row)
		row.add_child(_card_tile(cards[i], i, w, reduced))
	_committed_note(p)
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

static func _card_tile(c: Dictionary, i: int, w: int, reduced: bool) -> Control:
	var rarity := String(c["rarity"])
	var tile := VBoxContainer.new()
	tile.name = "CardTile_%d" % i
	tile.set_meta("card", c.duplicate(true))
	tile.add_theme_constant_override("separation", 4)
	var face := Control.new()
	face.name = "Face"
	face.custom_minimum_size = Vector2(w, w * 1.32)
	face.pivot_offset = Vector2(w, w * 1.32) * 0.5
	tile.add_child(face)
	if bool(c["new"]):
		var glow := HomeStyle.art("NewGlow")
		glow.texture = load(ART["card_new_glow"])
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -10
		glow.offset_right = 10
		glow.offset_top = -10
		glow.offset_bottom = 10
		face.add_child(glow)
	var frame := HomeStyle.art("RarityFrame")
	frame.texture = load(ART["frame_" + rarity])
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.add_child(frame)
	var art := HomeStyle.art("CardArt")
	art.texture = load(String(c["art"]))
	art.anchor_left = 0.13
	art.anchor_right = 0.87
	art.anchor_top = 0.13
	art.anchor_bottom = 0.88
	face.add_child(art)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 6)
	tile.add_child(chips)
	var r := _chip(rarity, RARITY_COLOR[rarity])
	r.name = "Rarity"
	chips.add_child(r)
	# NEW / DUPLICATE sits ON the card (top edge) so the tile keeps the card width.
	var b := _chip("NEW" if bool(c["new"]) else "DUPLICATE", NEW_GREEN if bool(c["new"]) else Color(0.62, 0.50, 0.30), Vector2.ZERO, 20)
	b.name = "NewState"
	b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	b.grow_horizontal = Control.GROW_DIRECTION_BOTH
	b.offset_top = -12
	face.add_child(b)
	if not bool(c["new"]):
		var own := BasePopup.body_label("You now have %d" % int(c["copies"]), 20)
		own.name = "Copies"
		tile.add_child(own)
	if not reduced:
		face.set_meta("flip_delay", 0.25 + 0.18 * i)
	return tile

# ---------------------------------------------------------------- collection ------

static func set_complete(fx: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("set_complete", "reward", "SET COMPLETE!")
	p.set_meta("fixture", fx.duplicate(true))
	_hero(p, ART["set_complete"], Vector2(230, 230), ART["reward_glow"], reduced)
	p.add_body_line("Set %d · %s" % [int(fx["set"]), String(fx["name"])], "SetName", BasePopup.ROYAL_EDGE, 36)
	var thumbs := GridContainer.new()
	thumbs.name = "SetCards"
	thumbs.columns = 9
	thumbs.add_theme_constant_override("h_separation", 4)
	var center := CenterContainer.new()
	center.add_child(thumbs)
	p.get_content().add_child(center)
	for k in range(int(fx["total"])):
		var a := HomeStyle.art("Thumb%d" % k)
		a.texture = load(card_art("s%d_c%d" % [int(fx["set"]), k]))
		a.custom_minimum_size = Vector2(62, 76)
		thumbs.add_child(a)
	p.add_body_line("%d / %d cards" % [int(fx["owned"]), int(fx["total"])], "Progress", BasePopup.INK, 30)
	_reward_rows(p, fx["rewards"])
	_committed_note(p, "Set reward already added to your account.")
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

static func master_complete(fx: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("master_complete", "reward", "MASTER COLLECTION!")
	p.set_meta("fixture", fx.duplicate(true))
	_hero(p, ART["master_complete"], Vector2(320, 320), ART["reward_glow"], reduced)
	p.add_body_line("All %d sets complete" % int(fx["sets"]), "MasterProgress", BasePopup.ROYAL_EDGE, 38)
	p.add_body_line("One-time master reward", "OneTime", BasePopup.INK, 26)
	_reward_rows(p, fx["rewards"], 96)
	_committed_note(p, "Master reward already added to your account.")
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

# ----------------------------------------------------------------- robot unlock ---

static func robot_unlock(fx: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("robot_unlock", "reward", "NEW ROBOT UNLOCKED!")
	p.set_meta("fixture", fx.duplicate(true))
	_hero(p, String(fx["hero"]), Vector2(330, 396), ART["robot_burst"], reduced)
	p.add_body_line(String(fx["name"]), "RobotName", BasePopup.ROYAL_EDGE, 52)
	p.add_body_line(String(fx["role"]), "RobotRole", BasePopup.INK, 26)
	var perk := PanelContainer.new()
	perk.name = "Perk"
	perk.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROYAL, 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	p.get_content().add_child(perk)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	perk.add_child(ph)
	if String(fx["perk_icon"]) != "":
		var pi := HomeStyle.art("PerkIcon")
		pi.texture = load(String(fx["perk_icon"]))
		pi.custom_minimum_size = Vector2(92, 92)
		ph.add_child(pi)
	var pv := VBoxContainer.new()
	pv.custom_minimum_size = Vector2(420, 0)   # wrap width for the perk text inside the HBox
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_child(pv)
	var pn := BasePopup.body_label(String(fx["perk_name"]), 30, BasePopup.ROYAL_EDGE)
	pn.name = "PerkName"
	pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pv.add_child(pn)
	var pt := BasePopup.body_label(String(fx["perk_text"]), 26)
	pt.name = "PerkText"
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pv.add_child(pt)
	var parts := HBoxContainer.new()
	parts.name = "PartsLeft"
	parts.alignment = BoxContainer.ALIGNMENT_CENTER
	parts.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	p.get_content().add_child(parts)
	var bi := HomeStyle.art("BotPartsIcon")
	bi.texture = load(ART["bot_parts"])
	bi.custom_minimum_size = Vector2(52, 52)
	parts.add_child(bi)
	var pl := BasePopup.body_label("Bot Parts left: %s" % UiText.num(int(fx["parts_left"])), 28)
	pl.name = "Text"
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF   # single value line inside an HBox
	parts.add_child(pl)
	p.add_action("equip", "EQUIP " + String(fx["name"]), "primary", true)
	p.add_action("keep", "KEEP CURRENT", "secondary", true)
	return p

# --------------------------------------------------------------------- Gift -------

static func gift_milestone(fx: Dictionary, reduced: bool) -> BasePopup:
	var big: bool = int(fx["milestone"]) == int(fx["cycle_max"])
	var p := _popup("gift_%d" % int(fx["milestone"]), "reward", "GIFT METER %s!" % UiText.num(int(fx["milestone"])))
	p.set_meta("fixture", fx.duplicate(true))
	_hero(p, ART["gift_1000" if big else "gift_small"], Vector2(300, 300) if big else Vector2(220, 220), ART["reward_glow"], reduced)
	p.add_body_line("Milestone %s / %s" % [UiText.num(int(fx["milestone"])), UiText.num(int(fx["cycle_max"]))], "Milestone", BasePopup.ROYAL_EDGE, 34)
	var rewards: Dictionary = (fx["rewards"] as Dictionary).duplicate()
	var fallback := int(rewards.get("guaranteed_new_fallback_sb", 0))
	rewards.erase("guaranteed_new_fallback_sb")   # a fallback condition, not an extra reward
	_reward_rows(p, rewards, 76)
	if fallback > 0:
		p.add_body_line("If every card is already owned, the NEW card becomes %s Scrub Bucks." % UiText.num(fallback), "FallbackNote", BasePopup.INK, 22)
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

# ------------------------------------------------------------- feature / world ----

static func feature_unlock(fx: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("feature_unlock", "medium", "NEW FEATURE!")
	p.set_meta("fixture", fx.duplicate(true))
	var hero := _hero(p, String(fx["icon"]), Vector2(240, 220), ART["reward_glow"], reduced)
	if bool(fx.get("new_badge", false)):
		var badge := _chip("NEW", NEW_GREEN, Vector2.ZERO, 26)
		badge.name = "NewBadge"
		hero.add_child(badge)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.add_body_line(String(fx["name"]), "FeatureName", BasePopup.ROYAL_EDGE, 44)
	p.add_body_line(String(fx["body"]), "FeatureBody", BasePopup.INK, 28)
	if bool(fx.get("fixture", false)):
		p.add_body_line("FIXTURE LABEL · real unlock policy unchanged", "FixtureTag", BasePopup.WARN_INK, 20)
	p.add_action("got_it", "GOT IT", "primary", true)
	return p

static func world_shell(fx: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("world_shell", "large", String(fx["title_slot"]))
	p.set_meta("fixture", fx.duplicate(true))
	var slot := PanelContainer.new()
	slot.name = "WorldArtSlot"
	slot.custom_minimum_size = Vector2(0, 520)
	slot.clip_contents = true
	slot.add_theme_stylebox_override("panel", HomeStyle.box(Color(0.125, 0.145, 0.2), BasePopup.ROYAL_EDGE, 5, 22, 0))
	p.get_content().add_child(slot)
	var art := TextureRect.new()
	art.name = "WorldArt"
	art.texture = load(String(fx["art"]))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(art)
	var tag := _chip(PREVIEW_TAG, Color(0.70, 0.12, 0.10), Vector2.ZERO, 22)
	tag.name = "PreviewTag"
	tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_child(tag)
	p.add_body_line(String(fx["subtitle_slot"]), "SubtitleSlot", BasePopup.ROYAL_EDGE, 34)
	p.add_body_line("New cleaning area ready.", "WorldBody", BasePopup.INK, 28)
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

# ----------------------------------------------------------------- generic reward --

## Compact reward confirmation (Daily / Tasks 3/3 / small events): title + 1..4 rows.
## Returns null for 0 or > 4 rows.
static func generic_reward(fx: Dictionary, _reduced: bool):
	var rewards: Dictionary = fx.get("rewards", {})
	var n := 0
	for k in rewards:
		if REWARD_ROWS.has(k) and int(rewards[k]) > 0:
			n += 1
	if n < 1 or n > 4:
		return null
	var p := _popup("generic_reward", "small", String(fx.get("title", "REWARD")))
	p.set_meta("fixture", fx.duplicate(true))
	_reward_rows(p, rewards, 64)
	p.add_action("continue", "CONTINUE", "primary", true)
	return p

# ------------------------------------------------------------------- motion --------

## Start the candidate's decorative motion (glow spin, card flips). Presentation only;
## every label/value already exists, so Reduced Effects (no motion) shows the same truth.
static func start_motion(p: BasePopup) -> void:
	if not p.is_inside_tree():
		return
	for g in p.find_children("HeroGlow", "TextureRect", true, false):
		if g.has_meta("spin"):
			var tw := p.create_tween().set_loops()
			tw.tween_property(g, "rotation", TAU, 9.0).from(0.0)
	for f in p.find_children("Face", "Control", true, false):
		if f.has_meta("flip_delay"):
			f.scale = Vector2(0.0, 1.0)
			var tw2 := p.create_tween()
			tw2.tween_interval(float(f.get_meta("flip_delay")))
			tw2.tween_property(f, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
