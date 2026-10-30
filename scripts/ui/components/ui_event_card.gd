extends RefCounted
## UiEventCard — preload (res://scripts/ui/components/ui_event_card.gd).
##
## SB-M43-130-REBUILD: one reusable Weekly Cleaning Event card (scrubbots_events_master_v01),
## built from one EventService view. view["phase"] picks the state:
##   - active:   hero art (title, "Ends in" pill, "Levels cleared" pill), milestone rows, rule strip;
##   - ended:    same layout, EVENT_ENDED pill (listed only while a reward is still claimable);
##   - upcoming: collapsed, greyed hero with the "Starts in" pill only (no progress yet).
## Pure presentation: every value comes from the view. `claim` (aid, parent) -> Button supplies
## the claim button so the owning popup keeps its action gating.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const F := "res://assets/ui/final/"
const HERO := F + "events/event_weekly_hero.png"
const REWARD_ICONS := {
	"scrub_bucks": "scrub_bucks_bundle_small",
	"bot_parts": "bot_parts_bundle_small",
	"standard_card_packs": "card_pack_standard",
	"premium_card_packs": "card_pack_premium",
	"random_any_booster_charges": "booster_of_choice",
	"random_booster_charges": "booster_of_choice",
	"selected_booster_charges": "booster_of_choice",
}
const INFO_BLUE := Color(0.851, 0.906, 0.976)
const INFO_EDGE := Color(0.620, 0.745, 0.902)
const LOCK_GREY := Color(0.420, 0.459, 0.529)
const UPCOMING_TINT := Color(0.55, 0.57, 0.60)

static func build(v: Dictionary, claim: Callable) -> PanelContainer:
	var phase := String(v["phase"])
	var upcoming := phase == "upcoming"
	var card := PanelContainer.new()
	card.name = "Event_" + String(v["id"])
	card.set_meta("phase", phase)
	var edge := LOCK_GREY if upcoming else BasePopup.ROYAL_EDGE
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(LOCK_GREY.lightened(0.2) if upcoming else BasePopup.ROYAL, edge, 4, 26, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_SM))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	card.add_child(box)
	var title := HomeStyle.label(UiText.t("EVENT_WEEKLY_TITLE"), 40, HomeStyle.TEXT if upcoming else HomeStyle.SUBTITLE)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var when := ""
	match phase:
		"active":
			when = UiText.t("EVENT_ENDS_IN", [_dhm(int(v["ends_in"]))])
		"upcoming":
			when = UiText.t("EVENT_STARTS_IN", [_dhm(int(v["starts_in"]))])
		_:
			when = UiText.t("EVENT_ENDED")
	box.add_child(_hero(when, "" if upcoming else UiText.t("EVENT_PROGRESS", [UiText.num(int(v["progress"]))]), upcoming))
	if upcoming:
		return card
	for i in range(v["milestones"].size()):
		box.add_child(_row(i, v["milestones"][i], int(v["progress"]), phase, String(v["id"]), claim))
	box.add_child(_rule())
	return card

## Hero art with the native pills over it: "When" top-right, "Progress" bottom-centre.
static func _hero(when: String, progress: String, grey: bool) -> TextureRect:
	var art := HomeStyle.art("Hero")
	art.texture = load(HERO)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.clip_contents = true
	art.custom_minimum_size = Vector2(0, 200 if grey else 290)
	if grey:
		art.self_modulate = UPCOMING_TINT
	var over := VBoxContainer.new()
	over.set_anchors_preset(Control.PRESET_FULL_RECT)
	over.offset_left = UiTokens.SPACE_SM
	over.offset_top = UiTokens.SPACE_SM
	over.offset_right = -UiTokens.SPACE_SM
	over.offset_bottom = -UiTokens.SPACE_SM
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(over)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	over.add_child(top)
	top.add_child(_pill("WhenPill", "When", when, "common/icons/icon_clock.png"))
	if not progress.is_empty():
		var gap := Control.new()
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		over.add_child(gap)
		var bottom := HBoxContainer.new()
		bottom.alignment = BoxContainer.ALIGNMENT_CENTER
		over.add_child(bottom)
		bottom.add_child(_pill("ProgressPill", "Progress", progress, ""))
	return art

## Dark navy pill with an optional icon and a white label named `label_name`.
static func _pill(n: String, label_name: String, text: String, icon: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = n
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 3, 30, 4), UiTokens.SPACE_MD, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	pill.add_child(h)
	if not icon.is_empty():
		var i := HomeStyle.art("Icon")
		i.texture = load(F + icon)
		i.custom_minimum_size = Vector2(44, 44)
		h.add_child(i)
	var l := HomeStyle.label(text, 30)
	l.name = label_name
	h.add_child(l)
	return pill

## Cream milestone row: reward icon, "N levels" + reward text, and its real state on the right.
static func _row(i: int, m: Dictionary, progress: int, phase: String, id: String, claim: Callable) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = "Milestone_%d" % i
	row.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 3, 22, 0), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	row.add_child(h)
	var icon := HomeStyle.art("Icon")
	icon.texture = load(F + "rewards/%s.png" % reward_icon(m["reward"]))
	icon.custom_minimum_size = Vector2(84, 84)
	h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var lv := UiText.t("EVENT_MILESTONE_LEVEL_ONE") if int(m["target"]) == 1 else UiText.t("EVENT_MILESTONE_LEVELS", [UiText.num(int(m["target"]))])
	var t := _text(lv, 32, BasePopup.INK)
	t.name = "Text"
	col.add_child(t)
	var r := _text(UiText.reward_text(m["reward"]), 22, BasePopup.ROYAL)
	r.name = "Reward"
	col.add_child(r)
	var right := HBoxContainer.new()
	right.custom_minimum_size = Vector2(270, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(right)
	if m["claimed"]:
		var pill := PanelContainer.new()
		pill.name = "Done"
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(HomeStyle.GREEN, HomeStyle.GREEN_EDGE, 3, 30, 4, 2), UiTokens.SPACE_SM, UiTokens.SPACE_XS))
		right.add_child(pill)
		var ph := HBoxContainer.new()
		ph.add_theme_constant_override("separation", UiTokens.SPACE_XS)
		pill.add_child(ph)
		var chk := HomeStyle.art("Check")
		chk.texture = load(F + "common/icons/icon_check.png")
		chk.custom_minimum_size = Vector2(36, 36)
		ph.add_child(chk)
		var s := HomeStyle.label(UiText.t("ACH_DONE"), 24, HomeStyle.TEXT, 6)
		s.name = "State"
		ph.add_child(s)
	elif m["claimable"]:
		var b: Button = claim.call("ev:%s:%d" % [id, i], right)
		b.text = UiText.t("POPUP_CLAIM")
	elif phase == "active":
		var target := int(m["target"])
		var bar := ProgressBar.new()
		bar.name = "Progress_%d" % i
		bar.show_percentage = false
		bar.max_value = target
		bar.value = mini(progress, target)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		HomeStyle.style_meter(bar, HomeStyle.GLOW, 48)
		right.add_child(bar)
		var cap := HomeStyle.label(UiText.t("HOME_RATIO", [UiText.num(mini(progress, target)), UiText.num(target)]), 26, HomeStyle.TEXT, 6)
		cap.name = "State"
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cap.set_anchors_preset(Control.PRESET_FULL_RECT)
		bar.add_child(cap)
	else:
		var lock := PanelContainer.new()
		lock.name = "Locked"
		lock.custom_minimum_size = Vector2(150, 64)
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.add_theme_stylebox_override("panel", HomeStyle.box(LOCK_GREY, LOCK_GREY.darkened(0.4), 3, 30, 4, 2))
		right.add_child(lock)
		var li := HomeStyle.art("Icon")
		li.texture = load(F + "common/icons/icon_lock.png")
		lock.add_child(li)
	return row

## Light-blue info strip: (i) icon + EVENT_RULE.
static func _rule() -> PanelContainer:
	var strip := PanelContainer.new()
	strip.name = "Rule"
	strip.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(INFO_BLUE, INFO_EDGE, 2, 18, 0), UiTokens.SPACE_MD, UiTokens.SPACE_XS))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	strip.add_child(h)
	var i := HomeStyle.art("Icon")
	i.texture = load(F + "common/icons/icon_info.png")
	i.custom_minimum_size = Vector2(52, 52)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(i)
	var l := BasePopup.body_label(UiText.t("EVENT_RULE"), 22)
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return strip

## Reward art for one reward dict: a single known key -> its bundle; several keys / other -> gift box.
static func reward_icon(reward: Dictionary) -> String:
	if reward.size() != 1:
		return "gift_box"
	return String(REWARD_ICONS.get(reward.keys()[0], "gift_box"))

static func _text(text: String, size: int, color: Color) -> Label:
	var l := BasePopup.body_label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l

static func _dhm(sec: int) -> String:
	return UiText.t("TIME_DHM", [sec / 86400, (sec % 86400) / 3600, (sec % 3600) / 60])
