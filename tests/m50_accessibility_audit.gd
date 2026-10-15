extends SceneTree
## M50 Accessibility (SB-M50-001/003/004/006/007/009/011, evidence) — measurements with the
## developer tool res://tools/accessibility_audit.gd against REAL production constants, the
## production level catalog and the real gameplay screen. Thresholds that are product
## decisions (colour-blind assist) are REPORTED, not invented as pass/fail rules.
##
## Run: godot --headless --path . -s res://tests/m50_accessibility_audit.gd

const A = preload("res://tools/accessibility_audit.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

const WCAG_AA := 4.5

var EXPECTED_CASES := ["a01_math_reference_values", "a02_ui_text_contrast", "a03_level_cvd_report", "a04_non_colour_cues_live"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_a01()
	_a02()
	_a03()
	await _a04()
	_done()

func _a01() -> void:
	print("[a01 reference values: WCAG contrast, Lab, CVD simulation]")
	_ok(absf(A.contrast_ratio(Color.BLACK, Color.WHITE) - 21.0) < 0.01 and absf(A.contrast_ratio(Color(0.3, 0.6, 0.2), Color(0.3, 0.6, 0.2)) - 1.0) < 1e-6, "contrast black/white = 21, identical = 1")
	var lab: Vector3 = A.to_lab(Color.WHITE)
	_ok(absf(lab.x - 100.0) < 0.1 and absf(lab.y) < 0.5 and absf(lab.z) < 0.5, "white -> L* 100, a* b* ~ 0 (%s)" % str(lab))
	var red := Color("#FF4500")
	_ok(A.simulate(red, "normal") == red and A.delta_e(red, red) == 0.0, "normal vision is identity; dE(x,x) = 0")
	var grey := Color(0.5, 0.5, 0.5)
	var grey_ok := true
	for k in ["protan", "deutan", "tritan"]:
		grey_ok = grey_ok and A.delta_e(A.simulate(grey, k), grey) < 1.5
	_ok(grey_ok, "neutral grey ~unchanged by every CVD matrix")
	_ok(A.delta_e(A.simulate(Color(1, 0, 0), "protan"), A.simulate(Color(0, 0.5, 0), "protan")) < A.delta_e(Color(1, 0, 0), Color(0, 0.5, 0)), "protanopia reduces red/green separation")
	var red_lab: Vector3 = A.to_lab(Color(1, 0, 0))
	_ok(red_lab.distance_to(Vector3(53.24, 80.09, 67.20)) < 0.2, "sRGB red -> Lab (53.24, 80.09, 67.20) reference (%s)" % str(red_lab))
	# Sharma, Wu & Dalal (2005) CIEDE2000 published test pairs.
	var sharma := [[Vector3(50, 2.6772, -79.7751), Vector3(50, 0, -82.7485), 2.0425], [Vector3(50, 0, 0), Vector3(50, -1, 2), 2.3669],
		[Vector3(50, 2.5, 0), Vector3(73, 25, -18), 27.1492], [Vector3(50, 2.5, 0), Vector3(50, 3.1736, 0.5854), 1.0000]]
	var s_ok := true
	for s in sharma:
		s_ok = s_ok and absf(A.ciede2000(s[0], s[1]) - float(s[2])) < 0.0005
	_ok(s_ok, "CIEDE2000 matches 4 published Sharma test pairs")
	_complete("a01_math_reference_values")

func _a02() -> void:
	print("[a02 text contrast of production colour constants (WCAG AA 4.5)]")
	var pairs := [
		["popup body INK on cream ROW card", BasePopup.INK, BasePopup.ROW],
		["white title on ROYAL plaque", Color.WHITE, BasePopup.ROYAL],
		["white label on CARD shortcut", HomeStyle.TEXT, HomeStyle.CARD],
		["white on NAVY dock", HomeStyle.TEXT, HomeStyle.NAVY],
		["SUBTITLE yellow on PANEL", HomeStyle.SUBTITLE, HomeStyle.PANEL],
		["INK on GOLD", BasePopup.INK, HomeStyle.GOLD],
	]
	for p in pairs:
		var r: float = A.contrast_ratio(p[1], p[2])
		_ok(r >= WCAG_AA, "%s: %.2f:1" % [p[0], r])
	# M50 decision B (owner 2026-10-15): the hero PLAY label is NAVY text on the unchanged green
	# (tests/m50_color_symbols.gd s07 checks the live button states). Other green buttons keep white.
	var navy: float = A.contrast_ratio(HomeStyle.NAVY, HomeStyle.GREEN)
	_ok(navy >= WCAG_AA, "hero PLAY label: NAVY on GREEN %.2f:1" % navy)
	print("    note: white label on other green buttons (popup / results primary) stays %.2f:1 fill + navy outline" % A.contrast_ratio(HomeStyle.TEXT, HomeStyle.GREEN))
	_ok(UiTokens.FONT_BODY >= 28 and UiTokens.FONT_BUTTON >= 30 and UiTokens.TOUCH_MIN >= 88, "type / touch tokens: body %d, button %d, touch %d" % [UiTokens.FONT_BODY, UiTokens.FONT_BUTTON, UiTokens.TOUCH_MIN])
	_complete("a02_ui_text_contrast")

func _a03() -> void:
	print("[a03 production levels: closest colour pair under normal / protan / deutan / tritan vision]")
	var cat = LevelCatalog.new()
	_ok(cat.load_manifest().ok, "catalog loads")
	var rows := 0
	var normal_ok := true
	for e in cat.get_entries_ordered():
		var lv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(e.level_path))
		var cols: Array = (lv["palette"] as Array).map(func(h): return Color(String(h)))
		var rep: Dictionary = A.palette_report(cols)
		var parts: Array = []
		for k in A.KINDS:
			var r: Dictionary = rep[k]
			parts.append("%s dE76 %.1f (%s/%s) dE00 %.1f (%s/%s)" % [k, float(r["min"]), lv["palette"][int(r["a"])], lv["palette"][int(r["b"])],
				float(r["min00"]), lv["palette"][int(r["a00"])], lv["palette"][int(r["b00"])]])
		print("    L%d %s %d colours | %s" % [int(e.order), String(e.id), cols.size(), " | ".join(parts)])
		normal_ok = normal_ok and is_finite(float(rep["normal"]["min"])) and float(rep["normal"]["min"]) >= 10.0
		rows += 1
	_ok(rows >= 10 and normal_ok, "%d levels measured; every level's closest pair >= dE76 10 under normal vision (builder sanity floor, not an owner threshold)" % rows)
	print("    FINDING (owner decision, SB-M50-002/003): CVD minima above (severity 1.0 = full dichromacy; CIE76 understates, see dE00); colour identity has no non-colour cue on tiles")
	_complete("a03_level_cvd_report")

func _a04() -> void:
	print("[a04 live non-colour cues on the real gameplay screen]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var path := "user://m50_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	for _i in range(6):
		await process_frame
	root.play_current_frontier()
	for _i in range(6):
		await process_frame
	var host = root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var panel = host.get_screen().get_supply_panel()
	var snap: Array = host.get_supply().player_snapshot()
	var counts_ok := true
	var checked := 0
	for c in range(panel.get_column_count()):
		var front = snap[c].get("front", null) if c < snap.size() else null
		if front is Dictionary:
			checked += 1
			counts_ok = counts_ok and panel.get_row_count_text(c, 0) == str(int(front.get("robot_count", -1)))
	_ok(counts_ok and checked > 0, "every supply front (%d checked) shows its live robot count as text (quantity is not colour-only)" % checked)
	var badges_ok := true
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		var b: Button = host.get_screen().get_booster_button(id)
		badges_ok = badges_ok and b.get_node("Icon") is TextureRect and (b.get_node("Icon") as TextureRect).texture != null
	_ok(badges_ok, "each booster is identified by its own icon art, not colour")
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	_complete("a04_non_colour_cues_live")

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
	print("M50 accessibility audit evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
