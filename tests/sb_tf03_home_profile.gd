extends SceneTree
## SB-TF-03 (owner 2026-11-18) — Home + Profile redesign: no bottom nav / Shop & Collection tiles /
## win-streak strip; Settings icon in the top HUD; persistent 320x50 banner area (No Ads collapses
## it); see-through activity buttons (0.7x, SB-TF-13 0.98x) (Rewarded Ads, Tasks, one per active Event; SB-TF-11 moved
## Daily to Profile Login Days) in two
## columns of at most 4 that hide themselves when done; Bot Parts icon on the profile card badge;
## PLAY · LEVEL N; Profile hosts Robots / Ranks / Collection (+ new-card badge), Settings hosts
## Notifications; Hearts (+) popup hands off to the Shop.
## Real app root (main.tscn) on temp saves, injected clock + local day.
##
## Run: godot --headless --path . -s res://tests/sb_tf03_home_profile.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const HomeScreen = preload("res://scripts/ui/home/home_screen.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")

## Events service with an injected list() (phases / claimed steps the schedule cannot produce on demand).
class FakeEvents extends "res://scripts/economy/events_v02_service.gd":
	var views: Array = []
	func list() -> Array:
		return views.duplicate(true)

var EXPECTED_CASES := [
	"t01_removed_nodes", "t02_settings_button", "t03_banner_area", "t04_activity_size_glass",
	"t05_activity_columns", "t06_auto_hide", "t07_events", "t08_profile_badge_play",
	"t09_profile_destinations", "t10_new_card_badge", "t11_hearts_shop",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	preload("res://scripts/app/app_state.gd").test_unlock_all = true   # Events / Robots / Ranks on an L1 save
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _t01()
	await _t02()
	await _t03()
	await _t04()
	await _t05()
	await _t06()
	await _t07()
	await _t08()
	await _t09()
	await _t10()
	await _t11()
	UiText.locale = "en"
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _t01() -> void:
	print("[t01 no BottomNav / Nav_* / WinStreakRewardTrack / Shop + Collection tiles under Home]")
	await _boot("t01")
	var bad: Array = []
	for n in _all_nodes(_home()):
		var s := String(n.name)
		if s == "BottomNav" or s.begins_with("Nav_") or s == "WinStreakRewardTrack" or s == "Shortcut_shop" or s == "Shortcut_collection":
			bad.append(s)
	_ok(bad.is_empty(), "removed Home nodes absent %s" % str(bad))
	_ok(not _home().has_signal("nav_requested") and not _home().has_method("set_app_nav"), "nav_requested / set_app_nav plumbing gone")
	_complete("t01_removed_nodes")

func _t02() -> void:
	print("[t02 Settings icon in the top HUD between the profile card and the Scrub Bucks chip]")
	await _boot("t02")
	var h = _home()
	var b: Button = h.get_region("SettingsButton")
	var hud: Control = h.get_region("TopCurrencyHUD")
	var card: Rect2 = (h.get_region("ProfileCard") as Control).get_global_rect()
	var chip: Rect2 = (h.get_region("ScrubBucksChip") as Control).get_global_rect()
	var r := b.get_global_rect() if b != null else Rect2()
	_ok(b != null and hud.is_ancestor_of(b), "SettingsButton lives in TopCurrencyHUD")
	_ok(r.position.x >= card.end.x and r.end.x <= chip.position.x, "x between the profile card (end %.0f) and the SB chip (%.0f): %s" % [card.end.x, chip.position.x, str(r)])
	_ok(r.size.x >= 88 and r.size.y >= 88, "touch target >= 88 px (%s)" % str(r.size))
	_ok((h.get_region("SettingsIcon") as TextureRect).texture != null, "icon = the approved settings art (HOME-105 via HomeArtBinder)")
	var fired := [0]
	h.settings_requested.connect(func(): fired[0] += 1)
	b.pressed.emit()
	await _frames(2)
	_ok(fired[0] == 1 and _root.get_settings_panel().visible, "press -> settings_requested -> Settings panel")
	_root.get_settings_panel().close_panel()
	await _frames(2)
	_complete("t02_settings_button")

func _t03() -> void:
	print("[t03 AdBannerSlot = clamp(width * 50/320), bottom-anchored under PLAY; No Ads collapses it]")
	for vp in [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1620, 2160)]:
		await _boot("t03", vp)
		var h = _home()
		var ad: Control = h.get_region("AdBannerSlot")
		var play: Rect2 = (h.get_region("PlayButton") as Control).get_global_rect()
		var want := clampf(vp.x * 50.0 / 320.0, HomeScreen.AD_SLOT_MIN_H, HomeScreen.AD_SLOT_MAX_H)
		var r := ad.get_global_rect()
		_ok(absf(r.size.y - want) <= 1.0, "%s banner height %.1f == clamp(%d*50/320) %.1f" % [str(vp), r.size.y, vp.x, want])
		_ok(absf(r.end.y - vp.y) <= 1.0 and r.position.y >= play.end.y, "%s bottom-anchored (end %.0f) and below PLAY (%.0f)" % [str(vp), r.end.y, play.end.y])
	var e = _eco()
	_ok(_home().is_ad_slot_enabled() and e.ads.allowed("banner"), "banner allowed by default -> area reserved")
	var stack_end: float = (_home().get_region("BottomActionStack") as Control).get_global_rect().end.y
	e.store.grant_no_ads()
	_home().set_ad_slot_enabled(e.ads.allowed("banner"))
	await _frames(3)
	var ad2: Control = _home().get_region("AdBannerSlot")
	var stack_end2: float = (_home().get_region("BottomActionStack") as Control).get_global_rect().end.y
	_ok(not ad2.visible and not ad2.is_visible_in_tree(), "No Ads owned -> AdBannerSlot hidden")
	_ok(stack_end2 > stack_end + 50.0, "collapsed area takes zero height: PLAY stack moves down %.0f -> %.0f" % [stack_end, stack_end2])
	_complete("t03_banner_area")

func _t04() -> void:
	print("[t04 activity buttons: 0.98x tile (206x153, SB-TF-13), half glass alpha, legible label]")
	await _boot("t04")
	var h = _home()
	var ok := true
	for n in ["RewardedAdsButton", "Shortcut_tasks"]:
		var b: Button = h.get_region(n)
		var sb: StyleBoxFlat = b.get_theme_stylebox("normal")
		var one: bool = b.custom_minimum_size.distance_to(Vector2(206, 153)) <= 1.0 and absf(b.size.x - 206) <= 1.0 and absf(b.size.y - 153) <= 1.0 \
			and absf(sb.bg_color.a - 0.255) <= 0.02 and sb.border_color.a >= 0.8 and b.get_theme_font_size("font_size") <= 28
		ok = ok and one
		if not one:
			print("    %s size %s min %s alpha %.3f border %.2f font %d" % [n, str(b.size), str(b.custom_minimum_size), sb.bg_color.a, sb.border_color.a, b.get_theme_font_size("font_size")])
	_ok(ok, "Rewarded Ads / Tasks: 206x153 +-1, panel alpha 0.255 +-0.02, opaque border, font <= 28")
	_ok(HomeScreen.PANEL_SIZE == (Vector2(210, 156) * 0.98).round() and is_equal_approx(HomeScreen.PANEL_ALPHA, 0.51 * 0.5), "constants = 0.98 x V06 size (SB-TF-13: SB-TF-03 0.7x + 40%), 0.5 x V06 alpha")
	_complete("t04_activity_size_glass")

func _t05() -> void:
	print("[t05 two columns, <= 4 each, <= 8 total, contiguous after a hide]")
	await _boot("t05")
	var fake = _fake_events()
	for i in range(7):
		fake.views.append(_view("ev_%d" % i, "active", false))
	await _frames(2)
	var lay: Dictionary = _home().get_activity_layout()
	var left: Array = lay["LeftShortcutColumn"]
	var right: Array = lay["RightShortcutColumn"]
	_ok(left.size() <= 4 and right.size() <= 4 and left.size() + right.size() <= 8, "with 10 eligible: left %d, right %d (<= 4 each, <= 8)" % [left.size(), right.size()])
	_ok(left.slice(0, 2) == ["RewardedAdsButton", "Shortcut_tasks"] and right.size() == 4 and right[0] == "Shortcut_event_ev_0" and left.size() == 4 and left.slice(2) == ["Shortcut_event_ev_4", "Shortcut_event_ev_5"],
		"fixed left top-down, events fill right first then the free left slots %s | %s" % [str(left), str(right)])
	_ok(_home().get_region("Shortcut_event_ev_6") == null, "events beyond 8 buttons are not shown")
	_ok(_contiguous(), "every column contiguous (gaps <= PANEL_GAP)")
	var e = _eco()
	for i in range(e.orders.orders().size()):
		e.daily.mark_task_done(i)
		e.daily.claim_task(i)
	e.daily.claim_all_tasks_bonus()
	await _frames(2)
	lay = _home().get_activity_layout()
	_ok(not (lay["LeftShortcutColumn"] as Array).has("Shortcut_tasks") and _contiguous(), "Tasks hidden -> the rest close up %s" % str(lay["LeftShortcutColumn"]))
	_complete("t05_activity_columns")

func _t06() -> void:
	print("[t06 auto-hide with injected state; next local day re-shows]")
	await _boot("t06")
	var h = _home()
	var e = _eco()
	_ok(_shown("Shortcut_tasks") and _shown("RewardedAdsButton") and h.get_region("Shortcut_daily") == null, "fresh day: Rewarded Ads, Tasks shown; no Daily button (SB-TF-11)")
	for i in range(e.orders.orders().size()):
		e.daily.mark_task_done(i)
		e.daily.claim_task(i)
	await _frames(2)
	_ok(_shown("Shortcut_tasks"), "tasks claimed, all-tasks bonus open -> Tasks still shown")
	e.daily.claim_all_tasks_bonus()
	await _frames(2)
	_ok(not _shown("Shortcut_tasks"), "all tasks + all-tasks bonus claimed -> Tasks hidden")
	var rd = e.rewarded_daily
	for slot in range(1, rd.SLOTS + 1):
		e.reward.grant(rd.tx_id(rd.today(), slot), rd.reward_for(slot))
	await _frames(2)
	_ok(not _shown("RewardedAdsButton"), "every Rewarded Ads slot granted today -> Rewarded Ads hidden")
	_day[0] += 1
	_now[0] += 86400
	h.refresh()
	await _frames(2)
	_ok(_shown("Shortcut_tasks") and _shown("RewardedAdsButton"), "next local day -> both shown again")
	_complete("t06_auto_hide")

func _t07() -> void:
	print("[t07 one button per active Event with unclaimed rewards; opens its details]")
	await _boot("t07")
	var e = _eco()
	var real: Array = e.events_v02.list().filter(func(v): return v["phase"] == "active")
	_ok(not real.is_empty(), "the schedule has active events at the fixture clock (%d)" % real.size())
	if not real.is_empty():
		var v: Dictionary = real[0]
		var b: Button = _home().get_region("Shortcut_event_" + String(v["id"]))
		_ok(b != null and b.visible and b.text == EventsV02Ui.title(String(v["id"])), "active event -> a button titled %s" % (b.text if b != null else "<none>"))
		var tex: Texture2D = b.icon_rect.texture if b != null else null   # SB-TF-12: the Events PNG icon (256 px)
		_ok(tex != null and tex.resource_path == EventsV02Ui.ICON % String(v["id"]) and tex.get_width() == 256, "its icon is the event's own icon %s" % (tex.resource_path if tex != null else "<none>"))
		if b != null:
			b.pressed.emit()
			await _frames(3)
			var ids: Array = _root.get_modal_stack().ids()
			var det = null
			for p in _all_nodes(_root):
				if p.get("popup_id") == "event_details":
					det = p
			_ok(ids.has("event_details") and det != null and String(det.get_meta("iid")) == String(v["iid"]), "press -> that event's details %s" % str(ids))
			_root.get_modal_stack().clear("test")
			await _frames(2)
	var fake = _fake_events()
	fake.views = [_view("upcoming_one", "upcoming", false), _view("ended_one", "claimable", false), _view("claimed_one", "active", true), _view("live_a", "active", false)]
	await _frames(2)
	var h = _home()
	_ok(h.get_region("Shortcut_event_upcoming_one") == null and h.get_region("Shortcut_event_ended_one") == null, "not active -> no button")
	_ok(h.get_region("Shortcut_event_claimed_one") == null, "active but every reward claimed -> no button")
	_ok(h.get_region("Shortcut_event_live_a") != null and (h.get_region("Shortcut_event_live_a") as Button).text == EventsV02Ui.title("live_a"), "active + unclaimed -> one button")
	fake.views.append(_view("live_b", "active", false))
	await _frames(2)
	var names: Array = (h.get_activity_layout()["RightShortcutColumn"] as Array)
	_ok(names == ["Shortcut_event_live_a", "Shortcut_event_live_b"], "two active events -> two buttons %s" % str(names))
	fake.views = []
	await _frames(2)
	_ok(h.get_region("Shortcut_event_live_a") == null and (h.get_activity_layout()["RightShortcutColumn"] as Array).is_empty(), "events end -> buttons removed")
	_complete("t07_events")

func _t08() -> void:
	print("[t08 profile badge = Bot Parts icon; PLAY · LEVEL N (EN / TR), fitted]")
	await _boot("t08")
	var h = _home()
	var app = _root.get_app_state()
	app.progression.debug_set_current_level(7)
	h.refresh()
	await _frames(2)
	var lvl = h.get_region("ProfileLevel")
	_ok(lvl == null or String(lvl.get("text")) != "7", "ProfileLevel no longer shows the level")
	var icon = h.get_region("ProfileBotPartsIcon")
	_ok(icon is TextureRect and (icon as TextureRect).texture != null and (icon as TextureRect).texture.resource_path.ends_with("bot_parts_icon.png")
		and h.get_region("ProfileRankBadge").is_ancestor_of(icon), "badge node = the Bot Parts icon inside ProfileRankBadge")
	var n := int(h.get_launch_preview()["level"])
	var play: Button = h.get_region("PlayButton")
	_ok(n == 7 and play.text == UiText.t("HOME_PLAY_LEVEL", [n]) and play.text == "PLAY · LEVEL 7", "EN PLAY text '%s'" % play.text)
	_ok(h.get_region("PlaySubtitle") == null and play.find_children("*", "Label", true, false).filter(func(l): return l.visible and l.text.contains(str(n))).is_empty(), "the level shows once: no second LEVEL line under PLAY")
	_ok(_fits(play), "EN text fits the PLAY button (font %d)" % play.get_theme_font_size("font_size"))
	for big in [123, 4321]:
		app.progression.debug_set_current_level(big)
		h.refresh()
		await _frames(1)
		_ok(_fits(play), "'%s' fits (font %d)" % [play.text, play.get_theme_font_size("font_size")])
	app.progression.debug_set_current_level(7)
	UiText.locale = "tr"
	h.refresh()
	await _frames(1)
	_ok(play.text == "OYNA · LEVEL 7" and _fits(play), "TR PLAY text '%s' fits" % play.text)
	UiText.locale = "en"
	h.refresh()
	_ok(UiText.EN.has("HOME_PLAY_LEVEL") and UiTextTr.TR.has("HOME_PLAY_LEVEL"), "HOME_PLAY_LEVEL in both EN and TR tables (full parity: m51_localization_readiness)")
	_complete("t08_profile_badge_play")

func _t09() -> void:
	print("[t09 Profile: Robots / Ranks / Collection; Notifications moved to Settings]")
	await _boot("t09")
	(_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var p = _top()
	_ok(_top_id() == "profile" and p.get_action_button("notifications") == null, "Profile open, no Notifications action")
	_ok(_dest_unfit(p).is_empty(), "EN ROBOTS / RANKS / COLLECTION labels fit their buttons (clear of the badge) %s" % str(_dest_unfit(p)))
	var opened := {}
	for id in ["robots", "ranks", "collection"]:
		var b: Button = p.get_action_button(id)
		_ok(b != null and b.size.y >= 88, "Profile %s button (>= 88 px)" % id)
		_tap(id)
		await _frames(2)
		opened[id] = _top_id()
		_top().close()
		await _frames(2)
	_ok(opened == {"robots": "robots", "ranks": "ranks", "collection": "collection"} and _top_id() == "profile", "they open Robots / Ranks / Collection album %s" % str(opened))
	_root.get_modal_stack().clear("test")
	await _frames(2)
	UiText.locale = "tr"
	(_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(3)
	var tr_p = _top()
	_ok(tr_p.get_action_button("collection").text == UiText.caps(UiText.t("PROFILE_COLLECTION")) and _dest_unfit(tr_p).is_empty(), "TR %s labels fit their buttons %s" % [str(DEST_IDS.map(func(i): return tr_p.get_action_button(i).text)), str(_dest_unfit(tr_p))])
	UiText.locale = "en"
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_root.open_settings()
	await _frames(2)
	var nb: Button = _root.get_settings_panel().get_notifications_button()
	_ok(nb != null and nb.text == UiText.t("NOTIFY_TITLE"), "Settings has a NOTIFICATIONS entry")
	nb.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "notifications" and not _root.get_settings_panel().visible, "it opens the notifications popup")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t09_profile_destinations")

func _t10() -> void:
	print("[t10 new-card badge on the Profile Collection button and the Home profile card]")
	await _boot("t10")
	var e = _eco()
	var h = _home()
	var app = _root.get_app_state()
	var cid := String(e.collection.all_card_ids()[0])
	e.collection.add_card(cid)
	h.refresh()
	await _frames(2)
	var bd := HomeBadges.compute(app)
	var rest := int(bd["achievements"]) + int(bd["robots"]) + int(bd["daily"])   # SB-TF-11: + today's login reward
	var pb: Label = h.get_region("ProfileBadge")
	_ok(int(bd["collection"]) == 1 and pb.visible and pb.text == str(rest + 1), "Home profile card badge counts the new card (%s)" % pb.text)
	(h.get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var badge: Label = _top().get_action_button("collection").get_node("CollectionBadge")
	_ok(badge.visible and badge.text == "1", "Profile COLLECTION button badge 1")
	_ok(_dest_unfit(_top()).is_empty() and _top().get_action_button("collection").get_global_rect().encloses(badge.get_global_rect()), "with the badge shown every label still fits, badge inside the button %s" % str(_dest_unfit(_top())))
	_tap("collection")
	await _frames(2)
	_ok(_top_id() == "collection", "album open")
	CollectionScreen.open_set(_root.get_modal_stack(), app, e.collection.card_set(cid))
	await _frames(2)
	_root.get_modal_stack().top().close()
	await _frames(2)
	_top().close()   # album
	await _frames(2)
	_ok(_top_id() == "profile" and not badge.visible, "card viewed in the album -> Profile Collection badge cleared")
	_root.get_modal_stack().clear("test")
	h.refresh()
	await _frames(2)
	bd = HomeBadges.compute(app)
	_ok(int(bd["collection"]) == 0 and pb.text == ("" if rest == 0 else str(rest)), "Home profile card badge no longer counts it ('%s')" % pb.text)
	_complete("t10_new_card_badge")

func _t11() -> void:
	print("[t11 Hearts (+) -> MORE IN SHOP; Scrub Bucks popup unchanged; no other Home path to the Shop]")
	await _boot("t11")
	var h = _home()
	(h.get_region("HeartsPlus") as Button).pressed.emit()
	await _frames(2)
	var sb: Button = _top().get_action_button("shop") if _top() != null else null
	_ok(_top_id() == "life" and sb != null and sb.text == UiText.t("SB_POPUP_MORE") and sb.text == "MORE IN SHOP", "Hearts popup has a shop action 'MORE IN SHOP'")
	_tap("shop")
	await _frames(2)
	_ok(_top_id() == "shop" and String(_top().context.get("source", "")) == "home_heart_plus", "it opens the Shop (source home_heart_plus)")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	(h.get_region("ScrubBucksPlus") as Button).pressed.emit()
	await _frames(2)
	_ok(_top_id() == "scrub_bucks" and _top().get_action_button("shop") != null and _top().get_action_button("shop").text == UiText.t("SB_POPUP_MORE"), "Scrub Bucks popup keeps MORE IN SHOP")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	var reached: Array = []
	for n in _all_nodes(h):
		if not (n is Button) or ["ScrubBucksPlus", "HeartsPlus", "PlayButton"].has(String(n.name)) or not (n as Button).is_visible_in_tree():
			continue
		(n as Button).pressed.emit()
		await _frames(2)
		if _root.get_modal_stack().ids().has("shop"):
			reached.append(String(n.name))
		_root.get_modal_stack().clear("test")
		if _root.get_settings_panel().visible:
			_root.get_settings_panel().close_panel()
		await _frames(2)
	_ok(reached.is_empty(), "no other Home button reaches the Shop %s" % str(reached))
	_complete("t11_hearts_shop")

# ---------------------------------------------------------------- helpers ----

const DEST_IDS := ["robots", "ranks", "collection"]
## Profile destination buttons whose label (at its font) is wider than the room beside the badge.
func _dest_unfit(p) -> Array:
	var bad: Array = []
	for id in DEST_IDS:
		var b: Button = p.get_action_button(id)
		var w: float = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		if w > ProfileScreens.destination_text_width(b) + 0.5:
			bad.append("%s %.0f>%.0f" % [b.text, w, ProfileScreens.destination_text_width(b)])
	return bad

func _view(id: String, phase: String, all_claimed: bool) -> Dictionary:
	return {"iid": id + ":1", "id": id, "phase": phase, "claimable": 0,
		"steps": [{"rid": "m0", "claimed": all_claimed}, {"rid": "m1", "claimed": all_claimed}]}

func _fake_events():
	var f := FakeEvents.new(func(): return _now[0])
	_eco().events_v02 = f
	return f

func _shown(n: String) -> bool:
	var b = _home().get_region(n)
	return b != null and (b as Control).visible

func _contiguous() -> bool:
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var bs: Array = (_home().get_region(side) as Node).get_children().filter(func(b): return (b as Control).visible)
		for i in range(1, bs.size()):
			var gap: float = (bs[i] as Control).get_global_rect().position.y - (bs[i - 1] as Control).get_global_rect().end.y
			if gap < 0.0 or gap > HomeScreen.PANEL_GAP + 1:
				print("    gap %.1f in %s" % [gap, side])
				return false
	return true

func _fits(b: Button) -> bool:
	var avail: float = b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x - 2.0 * b.get_theme_constant("outline_size")
	return b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x <= avail + 0.5 and absf(b.size.x - HomeScreen.PLAY_SIZE.x) <= 1.0

func _all_nodes(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out

func _boot(tag: String, size := Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://sb_tf03_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")   # FTUE / ceremonies never sit over the cases
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _home():
	return _root.get_home()

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

## Frames after a home.refresh() (the Home 1 s live tick, so injected state shows at once).
func _frames(n: int) -> void:
	if _root != null and is_instance_valid(_root) and _root.get_home() != null:
		_root.get_home().refresh()
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-TF-03 home/profile evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
