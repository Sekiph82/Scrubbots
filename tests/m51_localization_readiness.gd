extends SceneTree
## M51 Localization readiness (SB-M51-001..004, 009 evidence) — the UiText pseudo-locale
## (developer mode, never enabled by the shipping app) against the REAL app root:
##   l01 pseudo-locale properties · l02 key convention / non-empty English table
##   l03 Settings is fully keyed (asserted: no visible untranslated literal; frame contained)
##   l04 multi-surface scan: untranslated visible literals + text leaving the screen under ~35%
##       expansion, REPORTED as findings (Home, Tasks, Daily, Help, Shop, gameplay HUD, Results).
##
## Run: godot --headless --path . -s res://tests/m51_localization_readiness.gd

const UiText = preload("res://scripts/ui/ui_text.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

## Non-language glyphs that are not translatable copy.
const GLYPHS := ["X", "?", "II", "2x", "2X", "+", "-"]

var EXPECTED_CASES := ["l01_pseudo_properties", "l02_key_convention", "l03_settings_fully_keyed", "l04_surface_scan_report"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	_l01()
	_l02()
	UiText.pseudo = true
	await _l03()
	await _l04()
	UiText.pseudo = false
	_shutdown()
	_cleanup()
	_done()

func _l01() -> void:
	print("[l01 pseudo-locale: bracketed, accented, >= 35% longer, digits / symbols kept, off by default]")
	_ok(not UiText.pseudo and UiText.t("SETTINGS_TITLE") == "SETTINGS", "off by default; English unchanged")
	var src := "Win 3 levels (100%)"
	var p := UiText.pseudo_text(src)
	_ok(p.begins_with("[") and p.ends_with("]") and p.contains("3") and p.contains("100%") and p.contains("Wíñ") and p.length() >= int(src.length() * 1.35) + 2, "'%s' -> '%s'" % [src, p])
	_ok(UiText.pseudo_text("") == "" and UiText.pseudo_text(src) == p, "empty stays empty; deterministic")
	UiText.pseudo = true
	var with_args := UiText.t("TASK_WIN_N", ["3"])
	UiText.pseudo = false
	_ok(with_args.begins_with("[") and with_args.contains("3") and not with_args.contains("%s"), "formatting happens before pseudo: '%s'" % with_args)
	_complete("l01_pseudo_properties")

func _l02() -> void:
	print("[l02 key convention: UPPER_SNAKE keys (REWARD_<resource id> keeps the lowercase canonical id), non-empty English]")
	var re := RegEx.new()
	re.compile("^([A-Z0-9]+(_[A-Z0-9]+)*|REWARD_[a-z0-9_]+)$")
	var bad_keys: Array = []
	var empty: Array = []
	for k in UiText.EN:
		if re.search(String(k)) == null:
			bad_keys.append(k)
		if String(UiText.EN[k]).is_empty():
			empty.append(k)
	_ok(bad_keys.is_empty(), "%d keys, all UPPER_SNAKE %s" % [UiText.EN.size(), str(bad_keys)])
	_ok(empty == ["FTUE_L2_BOOSTERS_BODY"], "only the documented runtime-built body is empty %s" % str(empty))
	_complete("l02_key_convention")

func _l03() -> void:
	print("[l03 Settings under pseudo-locale: every visible text keyed, frame inside the viewport]")
	await _boot("l03", Vector2i(1080, 2160))
	_root.open_settings()
	await _frames(4)
	var panel = _root.get_settings_panel()
	var left := _untranslated(panel)
	var frame: Control = panel.find_child("Frame", true, false)
	var fr := Rect2(frame.global_position, frame.size)
	_ok(left.is_empty(), "no untranslated literal left in Settings %s" % str(left))
	_ok(Rect2(Vector2.ZERO, Vector2(1080, 2160)).grow(0.5).encloses(fr), "Settings frame still inside the screen with ~35%% longer copy %s" % str(fr))
	_complete("l03_settings_fully_keyed")

func _l04() -> void:
	print("[l04 surface scan under pseudo-locale (findings, not pass/fail)]")
	await _boot("l04", Vector2i(1080, 2160))
	var stack = _root.get_modal_stack()
	var surfaces := 0
	var report := func(name: String, node) -> void:
		var lits := _untranslated(node)
		var off := _offscreen(node)
		print("    %s: untranslated %d %s | off-screen %d %s" % [name, lits.size(), str(lits.slice(0, 8)), off.size(), str(off.slice(0, 5))])
	report.call("Home", _root.get_home())
	surfaces += 1
	for d in ["tasks", "daily", "shop"]:
		stack.clear("test")
		await _frames(1)
		_root.open_deep_link(d)
		await _frames(4)
		if stack.top() != null:
			report.call(d, stack.top())
			surfaces += 1
	stack.clear("test")
	await _frames(1)
	var hp = HelpTipsScreen.open(stack, _root.get_app_state())
	await _frames(4)
	if hp != null:
		report.call("help_tips", hp)
		surfaces += 1
	stack.clear("test")
	await _frames(1)
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	if host != null:
		host.get_runtime().set_process(false)
		report.call("gameplay_hud", host.get_screen())
		surfaces += 1
	var res = _root.get_results_screen()
	res.visible = true
	res.show_model(_root._results_model({"status": "WON", "level": 1, "attempt": 1}))
	await _frames(6)
	report.call("results_won", res)
	surfaces += 1
	_ok(surfaces >= 7, "%d player surfaces scanned (findings above feed SB-M51-001/009 and SB-M49-022/027)" % surfaces)
	_complete("l04_surface_scan_report")

# ------------------------------------------------------------------ helpers ----

## Visible Label / Button texts with letters that do not carry the pseudo brackets.
func _untranslated(node) -> Array:
	var out: Array = []
	for n in (node as Node).find_children("*", "", true, false):
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var txt := ""
		if n is Label:
			txt = (n as Label).text
		elif n is Button:
			txt = (n as Button).text
		else:
			continue
		txt = txt.strip_edges()
		if txt.is_empty() or GLYPHS.has(txt) or not _has_letter(txt) or txt.begins_with("["):
			continue
		out.append("%s='%s'" % [n.name, txt.left(40)])
	return out

## Visible text controls whose rect leaves the viewport.
func _offscreen(node) -> Array:
	var vp := Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(1.0)
	var out: Array = []
	for n in (node as Node).find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
			var r: Rect2 = (n as Control).get_global_rect()
			if r.has_area() and not vp.encloses(r):
				out.append("%s %s" % [n.name, str(r)])
	return out

static func _has_letter(s: String) -> bool:
	for ch in s:
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
			return true
	return false

func _boot(tag: String, size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m51_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	UiText.pseudo = false
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
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
	print("M51 localization readiness evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
