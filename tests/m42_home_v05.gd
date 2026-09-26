extends SceneTree
## M42 Home POLISH V05 — focused evidence (coordination/OWNER_M42_HOME_POLISH_V05.md).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home_v05.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HS = preload("res://scripts/ui/home/home_screen.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

const WORLD_PATH := "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"
const WORLD_SHA := "8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b"
## V04 audited transforms (measured on a8b953e with this harness), [size, insets
## top/bottom, scale, offset].
const V04_TRANSFORMS := [
	[Vector2i(1080, 2160), 0, 0, 1.0, Vector2(0, 0)],
	[Vector2i(1080, 2160), 132, 96, 1.0, Vector2(0, 0)],
	[Vector2i(1170, 2532), 0, 0, 1.08888888888889, Vector2(-3, 0)],
	[Vector2i(1170, 2532), 132, 96, 1.08333333333333, Vector2(0, 0)],
	[Vector2i(1290, 2796), 0, 0, 1.21111111111111, Vector2(-9, 0)],
	[Vector2i(1290, 2796), 132, 96, 1.19444444444444, Vector2(0, 0)],
	[Vector2i(1080, 2400), 0, 0, 1.03287037037037, Vector2(-17.75, 0)],
	[Vector2i(1080, 2400), 132, 96, 1.0, Vector2(0, 0)],
	[Vector2i(1440, 3200), 0, 0, 1.39814814814815, Vector2(-35, 0)],
	[Vector2i(1440, 3200), 132, 96, 1.3537037037037, Vector2(-11, 0)],
	[Vector2i(1080, 1920), 0, 0, 1.0, Vector2(0, -79)],
	[Vector2i(1080, 1920), 132, 96, 0.91329479768786, Vector2(46.82081, -58.3815)],
	[Vector2i(1536, 2048), 0, 0, 1.41184971098266, Vector2(5.601156, -515.9379)],
	[Vector2i(1536, 2048), 132, 96, 1.08236994219653, Vector2(183.5202, -168.7876)],
]
## V04 audited lower-stack Y at 1080x2160 (a8b953e): PLAY top 1490, ad slot 169 px.
const V04_PLAY_TOP_1080 := 1490.0
const V04_AD_H_1080 := 169.0

var EXPECTED_CASES := [
	"world_lock_matrix", "world_fixed_when_ad_changes", "scrubby_hero", "panels_glass",
	"currency_widgets", "gift_meter", "reward_rail", "ad_slot", "bottom_stack",
	"stack_reflow", "modals_hide_stack", "touch_targets", "asset_integrity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _world_lock()
	var r = await _home(Vector2i(1080, 2160), "main")
	var home = r[1]
	await _world_fixed(home)
	_scrubby(home)
	_panels(home)
	_currency(home)
	_gift(home)
	_rail(home)
	_ad(home)
	_stack(home)
	await _reflow(home)
	await _modals(home)
	r[0].free()
	await _touch()
	_assets()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _home(size: Vector2i, tag: String, insets := [0, 0, 0, 0]) -> Array:
	var p := "user://m42_v05_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var app = AppState.new(p)
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	home.get_region("SafeAreaRoot").set_synthetic_insets(insets[0], insets[1], insets[2], insets[3])
	for _i in range(8):
		await process_frame
	return [sub, home]

func _world_lock() -> void:
	print("[world lock matrix]")
	for row in V04_TRANSFORMS:
		var r = await _home(row[0], "lock", [0, row[1], 0, row[2]])
		var t: Dictionary = r[1].get_world_transform()
		var ok: bool = absf(float(t["scale"]) - float(row[3])) < 0.0005 and (t["offset"] as Vector2).distance_to(row[4]) < 0.6
		_ok(ok, "%s insets %d/%d: world transform == V04 (s %.5f vs %.5f, off %s vs %s)" % [str(row[0]), row[1], row[2], t["scale"], row[3], str(t["offset"]), str(row[4])])
		r[0].free()
		await process_frame
	_complete("world_lock_matrix")

func _world_fixed(home) -> void:
	print("[world fixed when ad changes]")
	var wb: Control = home.get_region("WorldBackground")
	var before: Rect2 = wb.get_global_rect()
	var feet_before: float = home.get_region("Art_scrubby").get_global_rect().position.y
	_ok(home.get_world_transform()["scale"] == 1.0 and home.get_world_transform()["offset"] == Vector2.ZERO, "1080x2160: scale 1.0000, offset (0,0)")
	home.set_ad_slot_enabled(false)
	for _i in range(4):
		await process_frame
	_ok(wb.get_global_rect().is_equal_approx(before) and absf(home.get_region("Art_scrubby").get_global_rect().position.y - feet_before) < 0.01, "ad slot collapsed: HOME-120 rect and Scrubby unchanged")
	home.get_region("AdBannerSlot").custom_minimum_size.y = 96.0
	home.set_ad_slot_enabled(true)
	home.get_region("AdBannerSlot").custom_minimum_size.y = 96.0
	for _i in range(3):
		await process_frame
	_ok(wb.get_global_rect().is_equal_approx(before), "ad slot at a different height: HOME-120 rect unchanged")
	home.set_ad_slot_enabled(true)   # re-applies the real reservation
	for _i in range(3):
		await process_frame
	_complete("world_fixed_when_ad_changes")

func _scrubby(home) -> void:
	print("[scrubby hero]")
	var c: Dictionary = home.get_scrubby_canonical()
	var w: Dictionary = home.get_world()
	_ok(absf(c["center_x"] - 540.0) < 0.01 and absf(c["feet_y"] - 1297.0) < 0.01, "centre X 540 / soles Y 1297 unchanged (%.2f, %.2f)" % [c["center_x"], c["feet_y"]])
	_ok(absf(float(c["k"]) / float(c["k_v04"]) - 1.15) < 0.001 and HS.SCRUBBY_V05_SCALE == 1.15, "visible scale 1.15 x V04 (k %.5f vs %.5f)" % [c["k"], c["k_v04"]])
	var vr: Rect2 = c["visible_rect"]
	_ok(not vr.intersects(w["baked_sign_rect"]), "clears the baked sign (top %.1f > sign bottom %.1f)" % [vr.position.y, (w["baked_sign_rect"] as Rect2).end.y])
	var hit := false
	for b in w["helper_bot_rects"]:
		hit = hit or vr.intersects(b)
	_ok(not hit, "clears the baked helper bots")
	var sc: TextureRect = home.get_region("Art_scrubby")
	_ok(absf(sc.position.y + HS.SCRUBBY_FEET_Y * float(c["k"]) - 1297.0) < 0.5, "on screen the soles stay on y=1297")
	_complete("scrubby_hero")

func _panels(home) -> void:
	print("[panels glass]")
	var names: Array = []
	for n in home.find_children("Shortcut_*", "Button", true, false):
		names.append(String(n.name))
	names.sort()
	_ok(names == ["Shortcut_collection", "Shortcut_daily", "Shortcut_shop", "Shortcut_tasks"], "four panels only %s" % str(names))
	var ok := true
	for id in ["shop", "collection", "tasks", "daily"]:
		var sb := home.get_region("Shortcut_" + id).get_theme_stylebox("normal") as StyleBoxFlat
		ok = ok and sb.bg_color.a >= 0.40 and sb.bg_color.a <= 0.48 and sb.border_width_left >= 2 and sb.border_width_left <= 3 and sb.border_color.a >= 0.7
	_ok(ok, "glass body alpha %.2f in 0.40..0.48, outline %d px visible" % [HS.PANEL_ALPHA, HS.PANEL_BORDER])
	var d := {}
	for id in ["shop", "collection", "tasks", "daily"]:
		var tex: Texture2D = home.get_region("ShortcutIcon_" + id).texture
		var a := float(tex.get_width()) / float(tex.get_height())
		var box := Vector2(206, 164)
		d[id] = [home.get_region("Shortcut_" + id).get_icon_draw_size(), Vector2(box.y * a, box.y) if box.y * a <= box.x else Vector2(box.x, box.x / a)]
	_ok(d["tasks"][0].is_equal_approx(d["tasks"][1]) and d["daily"][0].is_equal_approx(d["daily"][1]), "TASKS / DAILY exact V04 (= V03) icon size")
	_ok(d["shop"][0].x > d["shop"][1].x * 1.15 and d["collection"][0].x > d["collection"][1].x * 1.15, "SHOP / COLLECTION keep the V04 enlargement")
	var vp: Vector2 = home.get_viewport_rect().size
	var margin_ok := true
	for id in ["shop", "collection", "tasks", "daily"]:
		var r: Rect2 = home.get_region("Shortcut_" + id).get_global_rect()
		margin_ok = margin_ok and r.position.x >= 20.0 and vp.x - r.end.x >= 20.0
	_ok(margin_ok, "outer screen margin preserved")
	_complete("panels_glass")

func _currency(home) -> void:
	print("[currency widgets]")
	for spec in [["ScrubBucksChip", "ScrubBucksPlus"], ["HeartsChip", "HeartsPlus"]]:
		var chip = home.get_region(spec[0])
		var plus: Button = home.get_region(spec[1])
		var icon: Rect2 = chip.icon.get_global_rect()
		var pill: Rect2 = chip.get_global_rect()
		var pr: Rect2 = plus.get_global_rect()
		_ok(icon.size.y >= 110.0 and icon.size.y <= 122.0, "%s icon %.0f px tall (110..122)" % [spec[0], icon.size.y])
		_ok(pill.size.y >= 82.0 and pill.size.y <= 94.0, "%s pill %.0f px tall (82..94)" % [spec[0], pill.size.y])
		_ok(icon.position.y < pill.position.y and icon.end.y > pill.end.y and icon.position.x < pill.position.x, "%s icon overhangs the pill (top, bottom, left)" % spec[0])
		_ok(chip.icon_slot.get_parent().get_index() > -1 and chip.icon.get_parent() == chip.icon_slot, "%s icon drawn above the pill body" % spec[0])
		var sb := plus.get_theme_stylebox("normal") as StyleBoxFlat
		_ok(pr.size.x >= 88.0 and pr.size.y >= 88.0 and absf(pr.size.x - pr.size.y) < 1.0 and sb.corner_radius_top_left >= int(pr.size.x / 2) - 1, "%s circular (+) %s" % [spec[1], str(pr.size)])
		_ok(pr.position.x < pill.end.x and pr.end.x > pill.end.x and plus.get_index() > chip.get_index(), "%s (+) attached over the pill's right end, drawn in front" % spec[1])
	var sbw: Rect2 = home.get_region("ScrubBucksWidget").get_global_rect()
	var hw: Rect2 = home.get_region("HeartsWidget").get_global_rect()
	var sb_icon: Rect2 = home.get_region("ScrubBucksChip").icon.get_global_rect()
	var h_icon: Rect2 = home.get_region("HeartsChip").icon.get_global_rect()
	_ok(not sbw.intersects(hw) and not sb_icon.intersects(h_icon) and not home.get_region("ProfileCard").get_global_rect().intersects(sb_icon) and not home.get_region("ProfileCard").get_global_rect().intersects(h_icon), "widgets/icons do not overlap each other or the profile card")
	_ok(home.get_region("ScrubBucksChip").value_label.get_theme_font_size("font_size") >= 44, "large live value text")
	var app = home.get_app_state()
	var before: Dictionary = app.economy.snapshot()
	var got: Array = []
	home.scrub_bucks_purchase_requested.connect(func(): got.append("sb"))
	home.hearts_purchase_requested.connect(func(): got.append("h"))
	home.get_region("ScrubBucksPlus").pressed.emit()
	home.get_region("HeartsPlus").pressed.emit()
	_ok(got == ["sb", "h"] and app.economy.snapshot() == before, "(+) emit intents only; economy unchanged")
	_complete("currency_widgets")

func _gift(home) -> void:
	print("[gift meter]")
	var meter = home.get_region("GiftMeterBar")
	var chassis: Control = home.get_region("GiftMeterChassis")
	var emblem: Control = home.get_region("GiftEmblem")
	var crate: Control = home.get_region("GiftCrate")
	_ok(meter.caption.text == "0/1,000", "ratio only (%s)" % meter.caption.text)
	_ok(meter.get_parent() == chassis and (meter.bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color == HomeStyle.GOLD and meter.bar.size.y >= 50.0, "gold inset bar inside the navy chassis (%.0f px)" % meter.bar.size.y)
	var cr: Rect2 = chassis.get_global_rect()
	_ok(cr.size.y >= 80.0 and (chassis.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top >= 3, "substantial chassis with a cyan edge (%.0f px)" % cr.size.y)
	var er: Rect2 = emblem.get_global_rect()
	var kr: Rect2 = crate.get_global_rect()
	_ok(er.size.y > 112.0 and kr.size.y > 112.0, "emblem / crate larger than V04 (112)")
	_ok(er.position.x < cr.position.x and er.end.x > cr.position.x and kr.end.x > cr.end.x and kr.position.x < cr.end.x and er.size.y > cr.size.y, "emblem / crate overhang both chassis ends")
	_ok(emblem.get_index() > chassis.get_index() and crate.get_index() > chassis.get_index(), "emblem / crate above the chassis in z-order")
	_ok(meter.bar.get_global_rect().position.x >= er.end.x - 1.0 and meter.bar.get_global_rect().end.x <= kr.position.x + 1.0, "gold fill never hidden under emblem / crate")
	var bad := false
	for l in home.get_region("GiftMeter").find_children("*", "Label", true, false):
		var t := String(l.text).to_upper()
		bad = bad or t.find("NEXT") != -1 or t.find(":") != -1 or t.find("EVENT") != -1 or t.find("D") != -1 and t.find("H") != -1
	_ok(not bad, "no NEXT GIFT / timer / Event Points copy")
	_complete("gift_meter")

func _rail(home) -> void:
	print("[reward rail]")
	var track: Control = home.get_region("WinStreakRewardTrack")
	var rail: Rect2 = home.get_region("TrackRail").get_global_rect()
	_ok(track.size.y <= 130.0 and rail.size.y <= 90.0, "shallow rail (track %.0f, rail %.0f)" % [track.size.y, rail.size.y])
	var over := true
	for i in range(1, 6):
		over = over and home.get_region("TrackGift%d" % i).get_global_rect().position.y < rail.position.y
	_ok(over, "gifts overhang the rail top")
	var badge: Rect2 = home.get_region("TrackBadge").get_global_rect()
	_ok(badge.position.x < rail.position.x and home.get_region("TrackBadge").get_index() > home.get_region("TrackRail").get_index(), "streak badge in front, overhanging the rail's left end")
	var vals: Array = []
	for i in range(1, 6):
		vals.append(home.get_region("TrackStep%d" % i).text)
	_ok(vals == ["1", "5", "10", "25", "100"], "values exactly 1/5/10/25/100")
	var bad: Array = []
	for l in track.find_children("*", "Label", true, false):
		var t := String(l.text)
		if t.find("+") != -1 or t.to_upper().find("WIN") != -1:
			bad.append(t)
	var sb_path := "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png"
	for n in track.find_children("*", "TextureRect", true, false):
		if (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path == sb_path:
			bad.append("sb_icon")
	_ok(bad.is_empty(), "no '+', WIN or per-step SB icon %s" % str(bad))
	_ok(home.get_region("TrackGlow1").visible == false and home.get_region("TrackGlow5").visible == false, "no glow when no step is current (fresh save)")
	var app = home.get_app_state()
	app.economy.streak.process_first_clear_win(1)
	app.economy.streak.process_first_clear_win(2)
	home.refresh()
	_ok(home.get_region("TrackGlow2").visible and not home.get_region("TrackGlow1").visible and home.get_region("TrackStep2").get_theme_color("font_color") == HomeStyle.GOLD, "current step: glow + gold value")
	_ok(home.get_region("TrackGift1").modulate.a == 1.0 and home.get_region("TrackGift4").modulate.a < 1.0 and home.get_region("TrackGift4").modulate.a >= 0.7, "reached full, future dimmed but readable")
	_complete("reward_rail")

func _ad(home) -> void:
	print("[ad slot]")
	var ad: Control = home.get_region("AdBannerSlot")
	_ok(absf(ad.size.y - 144.0) < 1.0, "ad slot 144 px at 1080x2160 (%.0f)" % ad.size.y)
	_ok(ad.size_flags_vertical & Control.SIZE_EXPAND == 0 and ad.size.y == ad.custom_minimum_size.y, "fixed reservation, no vertical EXPAND")
	_ok(home.get_ad_mount().get_child_count() == 0 and ad.find_children("*", "Label", true, false).is_empty(), "empty AdMount, no fake ad content")
	_complete("ad_slot")

func _stack(home) -> void:
	print("[bottom stack]")
	var names: Array = []
	for c in home.get_region("BottomActionStack").get_children():
		names.append(String(c.name))
	_ok(names == ["PlayButton", "WinStreakRewardTrack", "BottomNav"], "stack = PLAY -> track -> nav %s" % str(names))
	var stack: Rect2 = home.get_region("BottomActionStack").get_global_rect()
	var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
	var sep: int = home.get_region("HomeLayout").get_theme_constant("separation")
	_ok(home.get_region("PlayButton").get_global_rect().end.y <= home.get_region("WinStreakRewardTrack").get_global_rect().position.y and home.get_region("WinStreakRewardTrack").get_global_rect().end.y <= home.get_region("BottomNav").get_global_rect().position.y and absf(ad.position.y - stack.end.y - sep) < 1.0, "nav sits directly above the ad slot (one layout gap)")
	_ok(home.get_region("StatusLabel").get_parent() == home.get_region("PlayButton"), "status pill attached to PLAY (no extra row)")
	var play_top: float = home.get_region("PlayButton").get_global_rect().position.y
	_ok(absf(play_top - (V04_PLAY_TOP_1080 + (V04_AD_H_1080 - 144.0))) < 1.0, "1080x2160: PLAY moved down by exactly the released ad height (%.0f = V04 %.0f + %.0f)" % [play_top, V04_PLAY_TOP_1080, V04_AD_H_1080 - 144.0])
	_complete("bottom_stack")

func _reflow(home) -> void:
	print("[stack reflow]")
	var names := ["PlayButton", "WinStreakRewardTrack", "BottomNav"]
	var before := {}
	for n in names:
		before[n] = home.get_region(n).get_global_rect().position.y
	var world_before: Rect2 = home.get_region("WorldBackground").get_global_rect()
	var ad_h: float = home.get_region("AdBannerSlot").size.y
	home.set_ad_slot_enabled(false)
	for _i in range(4):
		await process_frame
	var moved := true
	for n in names:
		moved = moved and absf(home.get_region(n).get_global_rect().position.y - before[n] - (ad_h + home.get_region("HomeLayout").get_theme_constant("separation"))) < 1.0
	_ok(moved, "released ad space lowers PLAY, track and nav by the same amount")
	_ok(home.get_region("WorldBackground").get_global_rect().is_equal_approx(world_before), "HOME-120 does not move")
	home.set_ad_slot_enabled(true)
	for _i in range(4):
		await process_frame
	var back := true
	for n in names:
		back = back and absf(home.get_region(n).get_global_rect().position.y - before[n]) < 1.0
	_ok(back, "re-enabled: exact positions restored")
	_complete("stack_reflow")

func _hidden(home) -> bool:
	return not home.get_region("BottomActionStack").is_visible_in_tree() and not home.get_region("HomeActionLayer").is_visible_in_tree() and not home.get_region("ScrubBucksPlus").is_visible_in_tree() and not home.get_region("HeartsPlus").is_visible_in_tree()

func _modals(home) -> void:
	print("[modals hide stack]")
	var before: Rect2 = home.get_region("PlayButton").get_global_rect()
	home.open_popup("daily")
	await process_frame
	_ok(_hidden(home), "Daily: bottom stack + action layer + (+) hidden")
	home.close_top_popup()
	for _i in range(3):
		await process_frame
	_ok(not _hidden(home) and home.get_region("PlayButton").get_global_rect().is_equal_approx(before), "Daily closed: exact stack restored")
	var path := "user://m42_v05_root_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var h2 = root.get_home()
	h2.get_region("Nav_settings").pressed.emit()
	await process_frame
	_ok(root.get_settings_panel().visible and _hidden(h2), "Settings: bottom stack + action layer + (+) hidden")
	root.handle_back()
	await process_frame
	_ok(not _hidden(h2), "back closes Settings and restores the stack")
	root.free()
	MainScript.boot_save_path_override = ""
	_complete("modals_hide_stack")

func _touch() -> void:
	print("[touch targets]")
	for size in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		for insets in [[0, 0, 0, 0], [0, 132, 0, 96]]:
			var r = await _home(size, "touch", insets)
			var home = r[1]
			var safe := Rect2(Vector2(insets[0], insets[1]), Vector2(size) - Vector2(insets[0] + insets[2], insets[1] + insets[3]))
			var bad: Array = []
			for b in home.find_children("*", "BaseButton", true, false):
				var rr: Rect2 = (b as Control).get_global_rect()
				if rr.size.x < 87.5 or rr.size.y < 87.5 or not safe.grow(0.5).encloses(rr):
					bad.append(b.name)
			var t: Dictionary = home.get_world_transform()
			var play: Rect2 = home.get_region("PlayButton").get_global_rect()
			if HS.PLATFORM_BOTTOM_Y * float(t["scale"]) + (t["offset"] as Vector2).y > play.position.y + 0.5:
				bad.append("play_over_platform_region")
			var ad: Control = home.get_region("AdBannerSlot")
			if ad.size.y < 96.0 or ad.size.y > 160.0 or absf(ad.get_global_rect().end.y - safe.end.y) > 1.0:
				bad.append("ad_slot")
			_ok(bad.is_empty(), "%s insets=%s: buttons >= 88 in safe area, PLAY below the platform region, ad 96..160 at the bottom %s" % [str(size), str(insets), str(bad)])
			r[0].free()
			await process_frame
	_complete("touch_targets")

func _assets() -> void:
	print("[asset integrity]")
	_ok(FileAccess.get_sha256(WORLD_PATH) == WORLD_SHA, "HOME-120 bytes unchanged")
	var bad: Array = []
	var n := 0
	for a in V.load_manifest()["assets"]:
		if a["status"] == "APPROVED" and a.has("path"):
			n += 1
			if FileAccess.get_sha256("res://" + String(a["path"])) != String(a["approved_sha256"]):
				bad.append(a["id"])
	_ok(n == 51 and bad.is_empty(), "all 51 approved entries match their pins %s" % str(bad))
	_complete("asset_integrity")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fail += 1
		print("  FAIL: ", msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: ", missing)
	print("m42_home_v05: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
