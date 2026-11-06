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
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

const ART := {
	"set_complete": "res://assets/ui/final/collection/collection_complete_emblem.png",
	"master_complete": "res://assets/ui/final/collection/master_collection_emblem.png",
	"reward_glow": "res://assets/ui/final/popups/victory/reward_glow.png",
	"robot_burst": "res://assets/ui/final/robots/robot_unlocked_burst.png",
	"gift_small": "res://assets/ui/final/rewards/gift_box.png",
	"gift_big": "res://assets/ui/final/home/gift_meter/gift_meter_reward_crate.png",
	"sb": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"pack_standard": "res://assets/ui/final/rewards/card_pack_standard.png",
	"pack_premium": "res://assets/ui/final/rewards/card_pack_premium.png",
	"mystery_booster": "res://assets/ui/final/rewards/gift_box.png",   # SB-M39-054: neutral, never the RANDOM booster icon
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
	"random_any_booster_charges": ["mystery_booster", "CEREMONY_ROW_MYSTERY_BOOSTER"],
	"selected_booster_charges": ["booster_choice", "CEREMONY_ROW_BOOSTER_CHOICE"],
	"guaranteed_new_cards": ["card_back", "CEREMONY_ROW_NEW_CARD"],
	"hearts": ["heart", "CEREMONY_ROW_HEART"],
}
const GLOW_SPIN_S := 9.0   ## the C001-accepted slow celebratory glow turn (FULL only)
## SB-VIDEO-006: the owner's keyed Flow box opening per gift hero (rewards/gift_videos/PROVENANCE.md).
## The video box is taller than the static hero (box + the sparkle burst above it); its _still.png
## is the keyed LAST frame (open glowing box) held after playback.
const CHROMA_KEY_GREEN := preload("res://scripts/ui/feel/chroma_key_green.gdshader")
const GIFT_VIDEO_DIR := "res://assets/ui/final/rewards/gift_videos/"
const GIFT_VIDEO_SIZE := {"gift_small": Vector2(300, 420), "gift_big": Vector2(300, 450)}
## Injectable for tests: hero art key -> VideoStream (missing / null = the static hero art, as on failure).
static var gift_video := {
	"gift_small": load(GIFT_VIDEO_DIR + "gift_small_opening.ogv"),
	"gift_big": load(GIFT_VIDEO_DIR + "gift_big_opening.ogv"),
}
## SB-VIDEO-007: the owner's magenta-keyed Flow set-complete badge (rewards/set_complete_video/
## PROVENANCE.md): square crop (badge + star burst, soft edge fade), still = keyed last frame.
const CHROMA_KEY_MAGENTA := preload("res://scripts/ui/feel/chroma_key_magenta.gdshader")
const SET_VIDEO_DIR := "res://assets/ui/final/rewards/set_complete_video/"
const SET_VIDEO_SIZE := Vector2(320, 320)
const SET_VIDEO_EDGE := 0.06
## Injectable for tests (null = the static emblem, as on failure).
static var set_video: VideoStream = load(SET_VIDEO_DIR + "set_complete_badge.ogv")
## SB-VIDEO-009: the owner's magenta-keyed Flow "new region" Scrubby (popups/new_region_video/
## PROVENANCE.md), generic for every world, played over the world art; still = keyed last frame.
const REGION_VIDEO_DIR := "res://assets/ui/final/popups/new_region_video/"
## Injectable for tests (null = the world art alone, as on failure).
static var region_video: VideoStream = load(REGION_VIDEO_DIR + "new_region_scrubby.ogv")

## One ceremony popup for a CeremonyEvents event, or null when the kind has no builder.
static func build(event: Dictionary, reduced: bool = false):
	match String(event.get("kind", "")):
		"set_complete":
			return set_complete(event, reduced)
		"master_complete":
			return master_complete(event, reduced)
		"robot_unlock":
			return robot_unlock(event, reduced)
		"gift_milestone":
			return gift_milestone(event, reduced)
		"feature_unlock":
			return feature_unlock(event, reduced)
		"world_unlock":
			return world_unlock(event, reduced)
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
static func _hero(p: BasePopup, art: String, size: Vector2, reduced: bool, glow: String = "") -> Control:
	var box := CenterContainer.new()
	box.name = "HeroBox"
	box.custom_minimum_size = size
	p.get_content().add_child(box)
	var g := HomeStyle.art("HeroGlow")
	g.texture = load(glow if not glow.is_empty() else ART["reward_glow"])
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

## Start the decorative glow turn (FULL) and a gift / set-complete hero or new-region video. Every label/value
## already exists, so Reduced Effects (no motion) shows exactly the same truth. Tweens are bound
## to the popup.
static func start_motion(p: BasePopup) -> void:
	if not p.is_inside_tree():
		return
	for g in p.find_children("HeroGlow", "TextureRect", true, false):
		if g.has_meta("spin"):
			var tw := p.create_tween().set_loops()
			tw.tween_property(g, "rotation", TAU, GLOW_SPIN_S).from(0.0)
	for box in p.find_children("HeroBox", "CenterContainer", true, false):
		if not box.has_meta("video"):
			continue
		var art := String(box.get_meta("video"))
		var h := box.get_node("HeroArt") as TextureRect
		if art == "set_complete":
			play_hero_video(p, h, set_video, load(SET_VIDEO_DIR + "set_complete_badge_still.png"), SET_VIDEO_SIZE, CHROMA_KEY_MAGENTA, SET_VIDEO_EDGE)
		else:
			play_hero_video(p, h, gift_video.get(art), load(GIFT_VIDEO_DIR + art + "_opening_still.png"), GIFT_VIDEO_SIZE[art], CHROMA_KEY_GREEN)
	for slot in p.find_children("WorldArtSlot", "PanelContainer", true, false):
		if not slot.has_meta("video"):
			continue
		var r := HomeStyle.art("RegionHero")   # empty overlay over the world art: the video, then its still
		slot.add_child(r)
		play_hero_video(p, r, region_video, load(REGION_VIDEO_DIR + "new_region_scrubby_still.png"), Vector2.ZERO, CHROMA_KEY_MAGENTA)
		if r.get_child_count() == 0:
			slot.remove_child(r)
			r.free()

## SB-VIDEO-006..009, SB-POLISH-011B: one keyed VideoStreamPlayer over hero art `h` (its own texture hidden while
## it plays), then `h` holds the keyed last frame `still` at `size`. A stream that is missing or
## does not start leaves `h` exactly as built. The decoder is freed when it finishes or the
## popup closes; it never blocks the rows or the CTA (mouse ignored, no input / economy touched).
static func play_hero_video(p: BasePopup, h: TextureRect, stream: VideoStream, still: Texture2D, size: Vector2, key: Shader, edge := 0.0) -> void:
	if stream == null or still == null:
		return
	var fit := AspectRatioContainer.new()
	fit.name = "HeroVideoBox"
	fit.ratio = float(still.get_width()) / float(still.get_height())
	fit.set_anchors_preset(Control.PRESET_FULL_RECT)
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VideoStreamPlayer.new()
	v.name = "HeroVideo"
	v.expand = true
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.material = ShaderMaterial.new()
	(v.material as ShaderMaterial).shader = key
	if edge > 0.0:
		(v.material as ShaderMaterial).set_shader_parameter("edge_fade", edge)
	v.stream = stream
	fit.add_child(v)
	h.add_child(fit)
	v.play()
	if not v.is_playing() or v.get_stream_length() <= 0.0:
		h.remove_child(fit)
		fit.free()
		return
	h.custom_minimum_size = size
	h.texture = still
	h.self_modulate.a = 0.0
	var finish := func() -> void:   # captures only the hero: it lives as long as the popup
		var f := h.get_node_or_null("HeroVideoBox")
		if f != null and not f.is_queued_for_deletion():
			(f.get_child(0) as VideoStreamPlayer).stop()
			f.queue_free()
			h.self_modulate.a = 1.0
	v.finished.connect(finish)
	p.closed.connect(finish.unbind(1))

# ------------------------------------------------------------- Collection set ----

## SB-M43-068: Collection set 9/9 complete. Shows the set emblem, the set's nine canonical
## cards, 9 / 9 and the exact per-set reward (event rewards = the config row the grant used).
static func set_complete(event: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("set_complete", "reward", UiText.t("CEREMONY_SET_TITLE"), event)
	var hero := _hero(p, ART["set_complete"], Vector2(230, 230), reduced)
	if not reduced:
		hero.set_meta("video", "set_complete")   # SB-VIDEO-007: played by start_motion
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

# ----------------------------------------------------------- Master Collection ----

## SB-M43-069: all 15 sets complete. Master emblem, "All 15 sets complete", the ONE-TIME
## +2500 SB +20 Bot Parts (event rewards = the config row the exactly-once grant used).
static func master_complete(event: Dictionary, reduced: bool) -> BasePopup:
	var p := _popup("master_complete", "reward", UiText.t("CEREMONY_MASTER_TITLE"), event)
	_hero(p, ART["master_complete"], Vector2(320, 320), reduced)
	p.add_body_line(UiText.t("CEREMONY_MASTER_SETS", [int(event.get("sets", 0))]), "MasterProgress", BasePopup.ROYAL_EDGE, 38)
	p.add_body_line(UiText.t("CEREMONY_MASTER_ONCE"), "OneTime", BasePopup.INK, 26)
	_reward_rows(p, event.get("rewards", {}), 96)
	p.add_body_line(UiText.t("CEREMONY_MASTER_COMMITTED"), "CommittedNote", BasePopup.INK, 24)
	p.add_action("continue", UiText.t("CEREMONY_CONTINUE"), "primary", true)
	return p

# ---------------------------------------------------------------- Robot unlock ----

## SB-M43-070/071: a robot unlocked (Bot Parts already spent by RobotUnlockService). Canonical
## roster art / name / role / 20% meta perk and the live Bot Parts left after the unlock.
## Two CTAs: EQUIP <NAME> (the presenter routes it to the equip authority) or KEEP CURRENT.
## Null when the robot is not in the canonical roster (nothing is fabricated).
static func robot_unlock(event: Dictionary, reduced: bool):
	var id := String(event.get("robot_id", ""))
	var r := RobotRoster.entry(id)
	if r.is_empty():
		return null
	var name := String(r["name"]).to_upper()
	var p := _popup("robot_unlock", "reward", UiText.t("CEREMONY_ROBOT_TITLE"), event)
	p.context["robot_id"] = id
	_hero(p, RobotRoster.asset(id, "master"), Vector2(330, 396), reduced, ART["robot_burst"])
	p.add_body_line(name, "RobotName", BasePopup.ROYAL_EDGE, 52)
	p.add_body_line(String(r["role"]), "RobotRole", BasePopup.INK, 26)
	var perk := PanelContainer.new()
	perk.name = "Perk"
	perk.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROYAL, 3, 26, 0), UiTokens.SPACE_MD, UiTokens.SPACE_SM))
	p.get_content().add_child(perk)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	perk.add_child(ph)
	var icon := String(r.get("perk_icon", ""))
	if not icon.is_empty() and ResourceLoader.exists(icon):
		var pi := HomeStyle.art("PerkIcon")
		pi.texture = load(icon)
		pi.custom_minimum_size = Vector2(92, 92)
		ph.add_child(pi)
	var pv := VBoxContainer.new()
	pv.custom_minimum_size = Vector2(420, 0)
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_child(pv)
	var pn := BasePopup.body_label(String(r["perk_name"]), 30, BasePopup.ROYAL_EDGE)
	pn.name = "PerkName"
	pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pv.add_child(pn)
	var pt := BasePopup.body_label(String(r["perk_text"]), 26)
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
	var pl := BasePopup.body_label(UiText.t("CEREMONY_ROBOT_PARTS_LEFT", [UiText.num(int(event.get("parts_left", 0)))]), 28)
	pl.name = "Text"
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	parts.add_child(pl)
	p.add_action("equip", UiText.t("CEREMONY_ROBOT_EQUIP", [name]), "primary", true)
	p.add_action("keep", UiText.t("CEREMONY_ROBOT_KEEP"), "secondary", true)
	return p

# ---------------------------------------------------------- Gift Meter milestone ----

## SB-M43-074: a Gift Meter milestone (1 / 5 / 10 / 25 / 100 / 250 / 500 / 1000, SB-POLISH-002) reached. The rewards are
## the exact config bundle QUEUED for this occurrence; they are claimed in the Gift Bar
## (GiftMeterService.claim), never here, and the copy says so. A guaranteed-new-card fallback
## is shown as its condition, never as an extra reward.
static func gift_milestone(event: Dictionary, reduced: bool) -> BasePopup:
	var m := int(event.get("milestone", 0))
	var big := m == int(event.get("cycle_max", -1))
	var p := _popup("gift_%d" % m, "reward", UiText.t("CEREMONY_GIFT_TITLE", [UiText.num(m)]), event)
	var art := "gift_big" if big else "gift_small"
	var hero := _hero(p, ART[art], Vector2(300, 300) if big else Vector2(220, 220), reduced)
	if not reduced:
		hero.set_meta("video", art)   # SB-VIDEO-006: played by start_motion
	# SB-POLISH-002: the meter fills towards each milestone, so reaching m reads "m / m" (bar wording).
	p.add_body_line(UiText.t("CEREMONY_GIFT_MILESTONE", [UiText.num(m), UiText.num(m)]), "Milestone", BasePopup.ROYAL_EDGE, 34)
	var rewards: Dictionary = (event.get("rewards", {}) as Dictionary).duplicate()
	var fallback := int(rewards.get("guaranteed_new_fallback_sb", 0))
	rewards.erase("guaranteed_new_fallback_sb")
	_reward_rows(p, rewards, 76)
	if fallback > 0:
		p.add_body_line(UiText.t("CEREMONY_GIFT_FALLBACK", [UiText.num(fallback)]), "FallbackNote", BasePopup.INK, 22)
	p.add_body_line(UiText.t("CEREMONY_GIFT_CLAIMED" if bool(event.get("claimed", false)) else "CEREMONY_GIFT_CLAIM_IN_BAR"), "ClaimNote", BasePopup.INK, 24)
	p.add_action("continue", UiText.t("CEREMONY_CONTINUE"), "primary", true)
	return p

# ------------------------------------------------------------ feature / world ----

## SB-M43-072: the owner-accepted generic Feature Unlock master for ONE feature event
## {feature_id, name, body, icon}: CeremonyPresenter.feature_events (owner unlock table, new
## profiles) and What's New (FtueDirector). The builder refuses an event without name / icon
## rather than inventing one. Never grants.
static func feature_unlock(event: Dictionary, reduced: bool):
	var icon := String(event.get("icon", ""))
	if String(event.get("name", "")).is_empty() or icon.is_empty() or not ResourceLoader.exists(icon):
		return null
	var p := _popup("feature_unlock", "medium", UiText.t("CEREMONY_FEATURE_TITLE"), event)
	var hero := _hero(p, icon, Vector2(240, 220), reduced)
	var badge := _new_chip()
	hero.add_child(badge)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.add_body_line(String(event["name"]), "FeatureName", BasePopup.ROYAL_EDGE, 44)
	if not String(event.get("body", "")).is_empty():
		p.add_body_line(String(event["body"]), "FeatureBody", BasePopup.INK, 28)
	p.add_action("got_it", UiText.t("CEREMONY_FEATURE_GOT_IT"), "primary", true)
	return p

## SB-M43-073 (prerequisite only): the owner-accepted World Transition shell for ONE world
## registry entry {world_id, title, subtitle, art}. World ranges / unlock conditions are not
## owner-defined, so no world event exists; the builder refuses an entry without real title /
## art (never a fabricated world). Never grants, never changes progression or difficulty.
static func world_unlock(event: Dictionary, reduced: bool):
	var art := String(event.get("art", ""))
	if String(event.get("title", "")).is_empty() or art.is_empty() or not ResourceLoader.exists(art):
		return null
	var p := _popup("world_unlock", "large", String(event["title"]), event)
	var slot := PanelContainer.new()
	slot.name = "WorldArtSlot"
	slot.custom_minimum_size = Vector2(0, 520)
	slot.clip_contents = true
	slot.add_theme_stylebox_override("panel", HomeStyle.box(Color(0.125, 0.145, 0.2), BasePopup.ROYAL_EDGE, 5, 22, 0))
	p.get_content().add_child(slot)
	var a := TextureRect.new()
	a.name = "WorldArt"
	a.texture = load(art)
	a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(a)
	if not reduced:
		slot.set_meta("video", "new_region")   # SB-VIDEO-009: played by start_motion
	if not String(event.get("subtitle", "")).is_empty():
		p.add_body_line(String(event["subtitle"]), "WorldSubtitle", BasePopup.ROYAL_EDGE, 34)
	p.add_body_line(UiText.t("CEREMONY_WORLD_BODY"), "WorldBody", BasePopup.INK, 28)
	p.add_action("continue", UiText.t("CEREMONY_CONTINUE"), "primary", true)
	return p

static func _new_chip() -> PanelContainer:
	var c := PanelContainer.new()
	c.name = "NewBadge"
	var bg := Color(0.20, 0.66, 0.14)
	c.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(bg, bg.darkened(0.35), 3, 18, 0), 12, 2))
	var l := Label.new()
	l.name = "Text"
	l.text = UiText.t("PACK_CARD_NEW")
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", bg.darkened(0.5))
	c.add_child(l)
	return c
