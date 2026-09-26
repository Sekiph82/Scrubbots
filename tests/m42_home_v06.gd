extends SceneTree
## M42 Home POLISH V06 — focused evidence (coordination/OWNER_M42_HOME_POLISH_V06.md).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home_v06.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HS = preload("res://scripts/ui/home/home_screen.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

const WORLD_PATH := "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"
const WORLD_SHA := "8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b"
## V05 audited world transforms (= V04), [size, inset top, inset bottom, scale, offset].
const WORLD_MATRIX := [
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
## V05 audited geometry at 1080x2160 (6d1708a): lower stack tops, ad height, Gift Meter
## and reward-rail rects (the latter measured relative to the track top).
const V05_PLAY_TOP := 1515.0
const V05_TRACK_TOP := 1686.0
const V05_NAV_TOP := 1822.0
const V05_AD := Rect2(0, 2016, 1080, 144)
const V05_GIFT := {"GiftMeterChassis": Rect2(98, 270, 884, 88), "GiftEmblem": Rect2(34, 248, 132, 132), "GiftCrate": Rect2(914, 248, 132, 132), "GiftMeterBar": Rect2(172, 287, 736, 54), "GiftMeter": Rect2(0, 250, 1080, 128)}
const V05_TRACK_REL := {"TrackRail": Rect2(72.4, 38, 985.6, 82), "TrackBadge": Rect2(22, 12, 112, 112), "TrackGift1": Rect2(140, 0, 181, 82), "WinStreakRewardTrack": Rect2(0, 0, 1080, 120)}
const V05_PANEL := Vector2(210, 156)
const V05_ICON_H := 110.0

var EXPECTED_CASES := [
	"world_locked", "scrubby_scale", "hero_focus_shade", "panels", "currency_pills",
	"plus_controls", "hearts_display_and_timer", "ad_and_stack", "gift_meter_locked",
	"win_streak_locked", "modals", "touch_targets", "asset_integrity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := 1790000000

func _initialize() -> void:
	await process_frame
	await _world_locked()
	var r = await _home(Vector2i(1080, 2160), "main")
	var home = r[1]
	_scrubby(home)
	_shade(home)
	_panels(home)
	_pills(home)
	_plus(home)
	_ad_stack(home)
	_gift_locked(home)
	_track_locked(home)
	r[0].free()
	await _hearts()
	await _modals()
	await _touch()
	_assets()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _home(size: Vector2i, tag: String, insets := [0, 0, 0, 0], app = null) -> Array:
	if app == null:
		var p := "user://m42_v06_%s_%d.save" % [tag, Time.get_ticks_usec()]
		_tmp.append(p)
		app = AppState.new(p)
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

func _rect(home, n: String) -> Rect2:
	return home.get_region(n).get_global_rect()

func _world_locked() -> void:
	print("[world locked]")
	for row in WORLD_MATRIX:
		var r = await _home(row[0], "lock", [0, row[1], 0, row[2]])
		var t: Dictionary = r[1].get_world_transform()
		_ok(absf(float(t["scale"]) - float(row[3])) < 0.0005 and (t["offset"] as Vector2).distance_to(row[4]) < 0.6, "%s insets %d/%d: world transform unchanged (s %.5f, off %s)" % [str(row[0]), row[1], row[2], t["scale"], str(t["offset"])])
		r[0].free()
		await process_frame
	_complete("world_locked")

func _scrubby(home) -> void:
	print("[scrubby scale]")
	var c: Dictionary = home.get_scrubby_canonical()
	var w: Dictionary = home.get_world()
	var ratio: float = float(c["k"]) / float(c["k_v04"])
	_ok(absf(ratio - 1.24) < 0.001 and HS.SCRUBBY_SCALE == 1.24, "hero scale 1.24 x V04 base fit (%.4f)" % ratio)
	_ok(absf(c["center_x"] - 540.0) < 0.01 and absf(c["feet_y"] - 1297.0) < 0.01, "centre X 540 / soles 1297 unchanged")
	var vr: Rect2 = c["visible_rect"]
	_ok(not vr.intersects(w["baked_sign_rect"]), "clears the baked sign (visible top %.1f > sign bottom %.1f)" % [vr.position.y, (w["baked_sign_rect"] as Rect2).end.y])
	var hit := false
	for b in w["helper_bot_rects"]:
		hit = hit or vr.intersects(b)
	_ok(not hit, "clears the baked helper bots (visible x %.1f..%.1f)" % [vr.position.x, vr.end.x])
	_ok(absf(_rect(home, "Art_scrubby").position.y + HS.SCRUBBY_FEET_Y * float(c["k"]) - 1297.0) < 0.5, "on screen the soles stay on y=1297")
	_complete("scrubby_scale")

func _shade(home) -> void:
	print("[hero focus shade]")
	var shade: TextureRect = home.get_region("HeroFocusShade")
	var chars: Control = home.get_region("Layer_characters")
	_ok(shade.get_parent() == chars and shade.get_index() < home.get_region("Art_scrubby").get_index() and chars.get_index() > home.get_region("WorldBackground").get_index(), "above the world, behind Scrubby")
	var tex := shade.texture as GradientTexture2D
	var g := tex.gradient
	var peak := 0.0
	var smooth := true
	for i in range(g.get_point_count()):
		peak = maxf(peak, g.get_color(i).a)
		if i > 0 and g.get_color(i).a > g.get_color(i - 1).a + 0.0001:
			smooth = false
		var col := g.get_color(i)
		if col.r > 0.1 or col.g > 0.1 or col.b > 0.15:
			smooth = false   # must be a dark navy dimmer, never a bright glow
	_ok(tex.fill == GradientTexture2D.FILL_RADIAL and peak >= 0.16 and peak <= 0.22 and g.get_color(g.get_point_count() - 1).a == 0.0 and smooth and g.get_point_count() >= 6, "native radial dark navy gradient, peak alpha %.2f, monotonic fade to 0 (no hard edge)" % peak)
	var w: Dictionary = home.get_world()
	var canon := HS.HERO_SHADE_RECT
	_ok(canon.position.y >= (w["baked_sign_rect"] as Rect2).end.y, "begins below the baked sign (%.0f >= %.0f)" % [canon.position.y, (w["baked_sign_rect"] as Rect2).end.y])
	var bots_hit := false
	for b in w["helper_bot_rects"]:
		bots_hit = bots_hit or canon.intersects(b)
	_ok(not bots_hit, "does not reach the baked helper bots")
	var c: Dictionary = home.get_scrubby_canonical()
	var torso := Vector2(c["center_x"], (c["visible_rect"] as Rect2).get_center().y)
	_ok(canon.has_point(torso) and absf(canon.get_center().x - 540.0) < 0.5, "centred behind Scrubby's torso")
	_ok(_rect(home, "HeroFocusShade").is_equal_approx(Rect2(home.world_to_screen(canon.position), canon.size * home.get_world_transform()["scale"])), "mapped with the locked world transform")
	_ok(shade.mouse_filter == Control.MOUSE_FILTER_IGNORE, "decorative, never takes input")
	_complete("hero_focus_shade")

func _panels(home) -> void:
	print("[panels]")
	var ok := true
	var geo := true
	for id in ["shop", "collection", "tasks", "daily"]:
		var b: Button = home.get_region("Shortcut_" + id)
		var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
		ok = ok and sb.bg_color.a >= 0.50 and sb.bg_color.a <= 0.52 and sb.border_width_left == 3 and sb.shadow_size == 8
		geo = geo and b.size.is_equal_approx(V05_PANEL)
	_ok(ok, "normal body alpha %.2f in 0.50..0.52, 3 px outline + restrained 8 px glow" % HS.PANEL_ALPHA)
	_ok(geo, "panel geometry unchanged (210x156)")
	for id in ["tasks", "daily"]:
		var tex: Texture2D = home.get_region("ShortcutIcon_" + id).texture
		var a := float(tex.get_width()) / float(tex.get_height())
		var v03 := Vector2(164.0 * a, 164.0) if 164.0 * a <= 206.0 else Vector2(206.0, 206.0 / a)
		_ok(home.get_region("Shortcut_" + id).get_icon_draw_size().is_equal_approx(v03), "%s icon size unchanged %s" % [id.to_upper(), str(v03)])
	_complete("panels")

func _pills(home) -> void:
	print("[currency pills]")
	for id in ["ScrubBucksChip", "HeartsChip"]:
		var chip = home.get_region(id)
		var pill: Rect2 = chip.get_global_rect()
		var icon: Rect2 = chip.icon.get_global_rect()
		_ok(pill.size.y >= 67.0 and pill.size.y <= 70.0, "%s pill %.0f px (V05 ~84 -> 67..70)" % [id, pill.size.y])
		_ok(absf(icon.size.y - V05_ICON_H) < 0.5, "%s icon unchanged (%.0f px)" % [id, icon.size.y])
		_ok(icon.position.y < pill.position.y and icon.end.y > pill.end.y, "%s icon still overhangs the thinner pill" % id)
	_ok(home.get_region("ScrubBucksChip").icon.texture.resource_path.ends_with("icon_currency_scrub_bucks.png") and home.get_region("ScrubBucksChip").value_label.text.replace(",", "") == str(home.get_app_state().economy.wallet.scrub_bucks()), "Scrub Bucks: approved banknote icon, live balance in the pill")
	_complete("currency_pills")

func _plus(home) -> void:
	print("[plus controls]")
	var app = home.get_app_state()
	var before: Dictionary = app.economy.snapshot()
	var got: Array = []
	home.scrub_bucks_purchase_requested.connect(func(): got.append("sb"))
	home.hearts_purchase_requested.connect(func(): got.append("h"))
	for spec in [["ScrubBucksChip", "ScrubBucksPlus"], ["HeartsChip", "HeartsPlus"]]:
		var pill: Rect2 = _rect(home, spec[0])
		var hit: Rect2 = _rect(home, spec[1])
		var glyph: Rect2 = _rect(home, spec[1] + "Glyph")
		var b: Button = home.get_region(spec[1])
		_ok(glyph.size.x >= 48.0 and glyph.size.x <= 58.0 and pill.encloses(glyph) and absf(glyph.get_center().y - pill.get_center().y) < 1.0, "%s glyph %.0f px inside the pill, vertically centred" % [spec[1], glyph.size.x])
		_ok(glyph.get_center().x > pill.end.x - 60.0, "%s glyph at the pill's right end" % spec[1])
		_ok(hit.size.x >= 88.0 and hit.size.y >= 88.0 and hit.get_center().distance_to(glyph.get_center()) < 1.0, "%s transparent hit target %s centred on the glyph" % [spec[1], str(hit.size)])
		var transparent := true
		for st in ["normal", "hover", "pressed"]:
			transparent = transparent and b.get_theme_stylebox(st) is StyleBoxEmpty
		_ok(transparent and b.text == "", "%s: no green circle / button body (glyph only)" % spec[1])
		b.pressed.emit()
	_ok(got == ["sb", "h"] and app.economy.snapshot() == before, "(+) emit intents only; economy unchanged")
	_complete("plus_controls")

func _hearts() -> void:
	print("[hearts display and timer]")
	var clock := func(): return _now
	var p := "user://m42_v06_hearts_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	var app = AppState.new(p, clock, LocalCalendar.offset_provider(clock, 0))
	var r = await _home(Vector2i(1080, 2160), "hearts", [0, 0, 0, 0], app)
	var home = r[1]
	var h = app.economy.hearts
	var count: Label = home.get_region("HeartsCount")
	var timer: Label = home.get_region("HeartsChip").value_label
	_ok(app.economy.config.hearts_regen_seconds() == 900, "canonical regen interval 900 s")
	_ok(count.get_parent() == home.get_region("HeartsChip").icon and count.text == "5" and count.get_theme_color("font_color") == Color(1, 1, 1) and count.get_theme_constant("outline_size") >= 10, "full: white outlined '5' on the heart icon")
	_ok(timer.text == "15:00" and timer.text.find("/") == -1, "full: pill shows static 15:00 (no N/5)")
	_now += 600
	home.refresh()
	_ok(timer.text == "15:00", "full: static, does not tick")
	h.consume()
	home.refresh()
	_ok(count.text == "4" and timer.text == "15:00" and h.seconds_to_next() == 900, "consume from full: 4 on the icon, countdown starts at 15:00")
	_now += 1
	home.refresh()
	_ok(timer.text == "14:59", "1 s later: 14:59 from HeartService")
	_now += 898
	home.refresh()
	_ok(timer.text == "00:01" and count.text == "4", "+899 s total: 00:01, no regen yet")
	_now += 1
	home.refresh()
	_ok(count.text == "5" and timer.text == "15:00", "+900 s: regenerated to 5, back to static 15:00")
	h.consume(); h.consume()
	home.refresh()
	_ok(count.text == "3" and timer.text == "15:00", "two consumed: 3, countdown from 15:00")
	_now += 900
	home.refresh()
	_ok(count.text == "4" and timer.text == "15:00", "one regen, still below max: next 15:00 interval")
	_now += 300
	home.refresh()
	_ok(timer.text == "10:00" and timer.text == "%02d:%02d" % [h.seconds_to_next() / 60, h.seconds_to_next() % 60], "display is HeartService.seconds_to_next() (10:00)")
	var props: Array = []
	for pr in home.get_script().get_script_property_list():
		props.append(String(pr["name"]))
	_ok(not props.has("_heart_timer") and not props.has("_hearts") and home._tick.wait_time == 1.0 and not home.is_processing(), "no UI-owned timer state; 1 Hz refresh, no per-frame processing")
	r[0].free()
	_complete("hearts_display_and_timer")

func _ad_stack(home) -> void:
	print("[ad and stack]")
	var ad: Control = home.get_region("AdBannerSlot")
	_ok(absf(ad.size.y - 100.0) < 0.5 and ad.size.y == ad.custom_minimum_size.y and ad.size_flags_vertical & Control.SIZE_EXPAND == 0, "ad slot 100 px, explicit, no EXPAND")
	_ok(HS.AD_SLOT_MIN_H == 72.0 and HS.AD_SLOT_MAX_H == 112.0, "responsive clamp 72..112")
	_ok(home.get_ad_mount().get_child_count() == 0 and ad.find_children("*", "Label", true, false).is_empty() and home.has_method("set_ad_slot_enabled"), "empty AdMount, collapse seam kept")
	var d := V05_AD.size.y - ad.size.y
	_ok(absf(_rect(home, "PlayButton").position.y - (V05_PLAY_TOP + d)) < 0.5 and absf(_rect(home, "WinStreakRewardTrack").position.y - (V05_TRACK_TOP + d)) < 0.5 and absf(_rect(home, "BottomNav").position.y - (V05_NAV_TOP + d)) < 0.5, "PLAY / track / nav all moved down %.0f px vs V05" % d)
	_ok(absf(_rect(home, "AdBannerSlot").end.y - 2160.0) < 0.5, "ad slot remains the bottom element")
	_complete("ad_and_stack")

func _gift_locked(home) -> void:
	print("[gift meter locked]")
	for n in V05_GIFT:
		_ok(_rect(home, n).is_equal_approx(V05_GIFT[n]), "%s geometry == V05 %s" % [n, str(V05_GIFT[n])])
	_ok(home.get_region("GiftMeterBar").caption.text == "0/1,000", "ratio-only caption unchanged")
	_complete("gift_meter_locked")

func _track_locked(home) -> void:
	print("[win streak locked]")
	var top: float = _rect(home, "WinStreakRewardTrack").position.y
	for n in V05_TRACK_REL:
		var r := _rect(home, n)
		r.position.y -= top
		_ok(r.is_equal_approx(V05_TRACK_REL[n]), "%s geometry (relative to the track) == V05" % n)
	var vals: Array = []
	for i in range(1, 6):
		vals.append(home.get_region("TrackStep%d" % i).text)
	_ok(vals == ["1", "5", "10", "25", "100"], "values unchanged")
	_complete("win_streak_locked")

func _hidden(home) -> bool:
	return not home.get_region("HomeActionLayer").is_visible_in_tree() and not home.get_region("BottomActionStack").is_visible_in_tree() and not home.get_region("ScrubBucksPlus").is_visible_in_tree() and not home.get_region("HeartsPlus").is_visible_in_tree()

func _modals() -> void:
	print("[modals]")
	var r = await _home(Vector2i(1080, 2160), "modal")
	var home = r[1]
	var before := _rect(home, "PlayButton")
	home.open_popup("daily")
	await process_frame
	_ok(_hidden(home), "Daily: action layer, stack and (+) hidden")
	home.close_top_popup()
	for _i in range(3):
		await process_frame
	_ok(not _hidden(home) and _rect(home, "PlayButton").is_equal_approx(before), "Daily closed: exact state restored")
	r[0].free()
	var path := "user://m42_v06_root_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var h2 = root.get_home()
	h2.get_region("Nav_settings").pressed.emit()
	await process_frame
	_ok(root.get_settings_panel().visible and _hidden(h2), "Settings: action layer, stack and (+) hidden")
	root.handle_back()
	await process_frame
	_ok(not _hidden(h2), "back restores Home")
	root.free()
	MainScript.boot_save_path_override = ""
	_complete("modals")

func _touch() -> void:
	print("[touch targets]")
	for row in WORLD_MATRIX:
		var r = await _home(row[0], "touch", [0, row[1], 0, row[2]])
		var home = r[1]
		var size: Vector2i = row[0]
		var safe := Rect2(Vector2(0, row[1]), Vector2(size) - Vector2(0, row[1] + row[2]))
		var bad: Array = []
		for b in home.find_children("*", "BaseButton", true, false):
			var rr: Rect2 = (b as Control).get_global_rect()
			if rr.size.x < 87.5 or rr.size.y < 87.5 or not safe.grow(0.5).encloses(rr):
				bad.append(b.name)
		var ad: Control = home.get_region("AdBannerSlot")
		if ad.size.y < 72.0 or ad.size.y > 112.0 or absf(ad.get_global_rect().end.y - safe.end.y) > 1.0:
			bad.append("ad_slot")
		var t: Dictionary = home.get_world_transform()
		if HS.PLATFORM_BOTTOM_Y * float(t["scale"]) + (t["offset"] as Vector2).y > _rect(home, "PlayButton").position.y + 0.5:
			bad.append("play_over_platform_region")
		_ok(bad.is_empty(), "%s insets %d/%d: touch >= 88 in safe area, ad 72..112 at bottom, PLAY below platform %s" % [str(size), row[1], row[2], str(bad)])
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
	print("m42_home_v06: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
