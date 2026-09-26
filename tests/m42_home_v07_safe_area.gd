extends SceneTree
## M42 Home POLISH V07 — desktop safe-area policy
## (coordination/OWNER_M42_HOME_POLISH_V07_DESKTOP_SAFE_AREA.md).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home_v07_safe_area.gd

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const SafeAreaRootScript = preload("res://scripts/ui/safe_area_root.gd")
const SafeAreaRootScene = preload("res://scenes/components/ui/common/safe_area_root.tscn")
const HS = preload("res://scripts/ui/home/home_screen.gd")

## V06 audited world transforms (= V05 = V04), [size, inset top, inset bottom, scale, offset].
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

var EXPECTED_CASES := [
	"platform_policy", "probe_conversion", "synthetic_overrides_desktop", "desktop_runtime_zero",
	"home_canonical_ad", "home_683_width_ad", "world_matrix_unchanged", "synthetic_matrix_valid",
	"v06_constants_unchanged",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_policy()
	_probe()
	await _synthetic()
	await _desktop_zero()
	await _home_canonical()
	await _home_683()
	await _world_matrix()
	await _synthetic_matrix()
	_constants()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _policy() -> void:
	print("[platform policy]")
	for os_name in ["Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
		_ok(not SafeAreaRootScript.uses_runtime_display_safe_area(os_name), "%s: desktop -> no runtime display safe area" % os_name)
	for os_name in ["Android", "iOS", "Web"]:
		_ok(SafeAreaRootScript.uses_runtime_display_safe_area(os_name), "%s: runtime display safe area probed" % os_name)
	_complete("platform_policy")

func _probe() -> void:
	print("[probe conversion]")
	_ok(SafeAreaRootScript.margins_from_probe(Rect2i(0, 0, 0, 0), Vector2i(1920, 1080), Vector2(683, 1366)) == [0, 0, 0, 0], "empty probe -> zero margins")
	_ok(SafeAreaRootScript.margins_from_probe(Rect2i(0, 0, -5, 100), Vector2i(1920, 1080), Vector2(683, 1366)) == [0, 0, 0, 0], "invalid probe -> zero margins")
	# A genuine mobile probe (notch + home indicator) still converts exactly as before.
	_ok(SafeAreaRootScript.margins_from_probe(Rect2i(0, 132, 1080, 2172), Vector2i(1080, 2400), Vector2(1080, 2400)) == [0, 132, 0, 96], "mobile probe -> [0,132,0,96] (unchanged conversion)")
	# What the old code did with a Windows work area (1366 screen, 48 px taskbar): a false
	# bottom inset. The desktop policy now never feeds this probe into margins.
	var fake := SafeAreaRootScript.margins_from_probe(Rect2i(0, 0, 768, 1318), Vector2i(768, 1366), Vector2(683, 1366))
	_ok(fake[3] > 0, "sanity: a desktop work-area probe WOULD produce a false bottom inset (%d px) if it were used" % fake[3])
	_complete("probe_conversion")

func _root(size: Vector2i) -> Array:
	var sub := SubViewport.new()
	sub.size = size
	get_root().add_child(sub)
	var root = SafeAreaRootScene.instantiate()
	sub.add_child(root)
	await process_frame
	await process_frame
	return [sub, root]

func _synthetic() -> void:
	print("[synthetic overrides desktop]")
	var r = await _root(Vector2i(683, 1366))
	var root = r[1]
	root.set_synthetic_insets(3, 132, 7, 96)
	_ok(root.get_applied_margins() == [3, 132, 7, 96], "synthetic insets applied exactly on %s (%s)" % [OS.get_name(), str(root.get_applied_margins())])
	root.set_synthetic_insets(-4, 10, 0, -2)
	_ok(root.get_applied_margins() == [0, 10, 0, 0], "synthetic negatives still clamp to 0 (unchanged seam)")
	root.clear_synthetic_insets()
	var want: Array = [0, 0, 0, 0] if not SafeAreaRootScript.uses_runtime_display_safe_area(OS.get_name()) else SafeAreaRootScript.margins_from_probe(DisplayServer.get_display_safe_area(), DisplayServer.screen_get_size(), Vector2(683, 1366))
	_ok(root.get_applied_margins() == want, "cleared synthetic -> platform policy (%s)" % str(root.get_applied_margins()))
	r[0].free()
	_complete("synthetic_overrides_desktop")

func _desktop_zero() -> void:
	print("[desktop runtime zero]")
	var r = await _root(Vector2i(683, 1366))
	var desktop := not SafeAreaRootScript.uses_runtime_display_safe_area(OS.get_name())
	_ok(desktop, "this test host is a desktop platform (%s)" % OS.get_name())
	_ok(r[1].get_applied_margins() == [0, 0, 0, 0], "desktop runtime margins are zero regardless of the display probe (probe %s, screen %s)" % [str(DisplayServer.get_display_safe_area()), str(DisplayServer.screen_get_size())])
	r[0].free()
	_complete("desktop_runtime_zero")

func _home(size: Vector2i, tag: String, insets = null) -> Array:
	var p := "user://m42_v07_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(AppState.new(p))
	if insets != null:
		home.get_region("SafeAreaRoot").set_synthetic_insets(insets[0], insets[1], insets[2], insets[3])
	for _i in range(8):
		await process_frame
	return [sub, home]

func _home_canonical() -> void:
	print("[home canonical ad]")
	# No synthetic insets: the real desktop policy is in effect.
	var r = await _home(Vector2i(1080, 2160), "canon")
	var home = r[1]
	var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
	_ok(home.get_region("SafeAreaRoot").get_applied_margins() == [0, 0, 0, 0], "desktop policy: zero margins")
	_ok(absf(ad.size.y - 100.0) < 0.5 and absf(ad.end.y - 2160.0) < 0.5, "1080x2160: AdBannerSlot 100 px at the screen bottom (%s)" % str(ad))
	r[0].free()
	_complete("home_canonical_ad")

func _home_683() -> void:
	print("[home 683 width ad]")
	var r = await _home(Vector2i(683, 1366), "w683")
	var home = r[1]
	var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
	var nav: Rect2 = home.get_region("BottomNav").get_global_rect()
	_ok(home.get_region("SafeAreaRoot").get_applied_margins()[3] == 0, "683x1366: bottom safe inset 0")
	_ok(absf(ad.size.y - 72.0) < 0.5, "683x1366: width-clamped ad reservation 72 px (%.1f)" % ad.size.y)
	_ok(nav.end.y <= ad.position.y + 0.5 and (home.get_region("AdBannerSlot").get_theme_stylebox("panel") as StyleBoxFlat).expand_margin_bottom > 0.0, "nav directly above the ad slot; inset painting kept for real mobile insets")
	# Note: a 683-px LOGICAL viewport is narrower than the V06 Home minimum layout width
	# (V06 targets the 1080-wide logical canvas; in the real app the 683x1366 window is
	# scaled by stretch mode canvas_items to a 1080x2160 logical viewport). This case only
	# proves the width-clamped reservation, as required.
	r[0].free()
	_complete("home_683_width_ad")

func _world_matrix() -> void:
	print("[world matrix unchanged]")
	for row in WORLD_MATRIX:
		var r = await _home(row[0], "wm", [0, row[1], 0, row[2]])
		var t: Dictionary = r[1].get_world_transform()
		_ok(absf(float(t["scale"]) - float(row[3])) < 0.0005 and (t["offset"] as Vector2).distance_to(row[4]) < 0.6, "%s insets %d/%d: world transform unchanged" % [str(row[0]), row[1], row[2]])
		r[0].free()
		await process_frame
	_complete("world_matrix_unchanged")

func _synthetic_matrix() -> void:
	print("[synthetic matrix valid]")
	for size in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		var r = await _home(size, "sm", [0, 132, 0, 96])
		var home = r[1]
		var safe := Rect2(Vector2(0, 132), Vector2(size) - Vector2(0, 228))
		var bad: Array = []
		if home.get_region("SafeAreaRoot").get_applied_margins() != [0, 132, 0, 96]:
			bad.append("margins")
		for b in home.find_children("*", "BaseButton", true, false):
			var rr: Rect2 = (b as Control).get_global_rect()
			if not safe.grow(0.5).encloses(rr) or rr.size.x < 87.5 or rr.size.y < 87.5:
				bad.append(b.name)
		var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
		if absf(ad.end.y - safe.end.y) > 0.5:
			bad.append("ad_not_at_safe_bottom")
		var sb := home.get_region("AdBannerSlot").get_theme_stylebox("panel") as StyleBoxFlat
		if sb.expand_margin_bottom < 96.0:
			bad.append("ad_does_not_paint_through_inset")
		_ok(bad.is_empty(), "%s synthetic [0,132,0,96]: margins applied, touch >= 88 inside safe area, ad at safe bottom and painting through the inset %s" % [str(size), str(bad)])
		r[0].free()
		await process_frame
	_complete("synthetic_matrix_valid")

func _constants() -> void:
	print("[v06 constants unchanged]")
	_ok(is_equal_approx(HS.AD_SLOT_RATIO, 100.0 / 1080.0) and HS.AD_SLOT_MIN_H == 72.0 and HS.AD_SLOT_MAX_H == 112.0, "ad reservation rule unchanged (100 px @1080, clamp 72..112)")
	_ok(HS.SCRUBBY_SCALE == 1.24 and HS.PANEL_ALPHA == 0.51 and HS.CURRENCY_PILL_H == 68.0, "V06 hero / panel / pill constants unchanged")
	_complete("v06_constants_unchanged")

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
	print("m42_home_v07_safe_area: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
