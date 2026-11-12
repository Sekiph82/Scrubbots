extends SceneTree
## SB-M59-010 — Settings CREDITS row + third-party notices popup on the REAL app root:
##   c01 Settings has one CREDITS button (keyed, touch >= 88, inside the frame) in the CLOSE row;
##       Vibration / Reduced Effects / Color Symbols keep their order (Reduced Effects in place)
##   c02 the row closes Settings and opens the read-only "credits" popup on the app ModalStack:
##       Godot licence == Engine.get_license_text(), Game Feel Flow / Saltmire Spark texts ==
##       their in-repo MIT LICENSE files, the engine third-party components + licence texts,
##       a scroll list taller than its viewport, one CLOSE that empties the stack
##   c03 title and section names are localized (Turkish title)
## Never boots main.tscn on the real save: temp user:// path.
##
## Run: godot --headless --path . -s res://tests/m59_credits.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const CreditsScreen = preload("res://scripts/ui/credits_screen.gd")

var EXPECTED_CASES := ["c01_settings_row", "c02_popup", "c03_localized"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	await _boot()
	await _c01()
	await _c02()
	await _c03()
	_shutdown()
	_cleanup()
	_done()

func _c01() -> void:
	print("[c01 Settings CREDITS row]")
	_root.open_settings()
	await _frames(4)
	var panel = _root.get_settings_panel()
	var b: Button = panel.get_credits_button()
	var frame: Control = panel.find_child("Frame", true, false)
	_ok(b != null and b.is_visible_in_tree() and b.name == "CreditsButton", "CreditsButton visible")
	_ok(b.text == UiText.t("CREDITS_TITLE") and b.text == "CREDITS", "keyed label %s" % b.text)
	_ok(b.size.y >= 88, "touch height %d >= 88" % int(b.size.y))
	_ok(frame.get_global_rect().grow(0.5).encloses(b.get_global_rect()), "row inside the Settings frame")
	# SB-PHONE-2026-11-12-A: the cards scroll on short screens, so the frame fits every viewport
	# (1080x1920 itself: tests/m41_settings.gd).
	var vp := Rect2(Vector2.ZERO, panel.get_viewport_rect().size).grow(-16.0)
	_ok(vp.grow(0.5).encloses(frame.get_global_rect()), "Settings frame fits %s with 16 px gutters %s" % [str(vp.size), str(frame.get_global_rect())])
	var body: Node = panel.find_child("Body", true, false)
	var cards: Node = panel.find_child("Cards", true, false)
	var at := func(n: String, parent: Node) -> int:
		var node: Node = panel.find_child(n, true, false)
		while node != null and node.get_parent() != parent:
			node = node.get_parent()
		return node.get_index() if node != null else -1
	var hap: int = at.call("HapticsToggle", cards)
	_ok(hap > 0 and at.call("ReducedEffectsToggle", cards) == hap + 1 and at.call("ColorSymbolsRow", cards) == hap + 2 and at.call("LanguageRow", cards) == hap + 3,
		"Vibration / Reduced Effects / Color Symbols / Language keep their order")
	_ok(at.call("CreditsButton", body) > at.call("SettingsScroll", body) and at.call("CreditsButton", body) == at.call("CloseButton", body) and b.get_index() == 0,
		"CREDITS shares the CLOSE row after the cards (left of CLOSE)")
	_completed["c01_settings_row"] = true

func _c02() -> void:
	print("[c02 CREDITS popup]")
	var stack = _root.get_modal_stack()
	var t0 := Time.get_ticks_msec()
	_root.get_settings_panel().get_credits_button().pressed.emit()
	await _frames(4)
	print("  open + 4 frames: %d ms" % (Time.get_ticks_msec() - t0))
	var p = stack.top()
	_ok(not _root.get_navigation().is_settings_open(), "Settings closed first")
	_ok(p != null and p.popup_id == "credits" and stack.depth() == 1, "credits popup is the one top modal")
	if p == null:
		_completed["c02_popup"] = true
		return
	_ok(p.get_title() == "CREDITS", "title %s" % p.get_title())
	_ok(_text(p, "GodotLicense") == Engine.get_license_text() and Engine.get_license_text().contains("Godot Engine contributors"), "Godot MIT notice from Engine.get_license_text()")
	for key in CreditsScreen.ADDONS:
		var src := FileAccess.get_file_as_string(CreditsScreen.ADDONS[key])
		_ok(src.begins_with("MIT License") and src.contains("Copyright (c)") and _text(p, "License_" + key) == src,
			"%s notice == %s" % [UiText.t(key), CreditsScreen.ADDONS[key]])
		_ok(_text(p, "Header_" + key) == UiText.t(key), "%s header" % key)
	var comps := _text(p, "Components")
	_ok(comps.contains("FreeType") and comps.contains("Godot Engine"), "engine third-party components listed (%d lines)" % comps.count("\n"))
	var lic_labels := 0
	for n in p.find_children("License_*", "Label", true, false):
		lic_labels += 1
	_ok(lic_labels == Engine.get_license_info().size() + CreditsScreen.ADDONS.size(), "%d licence texts (engine %d + addons %d)" % [lic_labels, Engine.get_license_info().size(), CreditsScreen.ADDONS.size()])
	var scroll: ScrollContainer = p.find_child("CreditsScroll", true, false)
	var list: Control = p.find_child("CreditsList", true, false)
	_ok(scroll != null and list.size.y > scroll.size.y, "scrollable list (%d > %d px)" % [int(list.size.y), int(scroll.size.y)])
	_ok(Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(0.5).encloses(p.get_frame_rect()), "popup frame inside the screen")
	_ok(p.get_action_ids() == ["close"], "one action: close")
	p.get_action_button("close").pressed.emit()
	await _frames(2)
	_ok(stack.depth() == 0 and not is_instance_valid(p), "CLOSE empties the stack (popup freed)")
	_completed["c02_popup"] = true

func _c03() -> void:
	print("[c03 localized]")
	UiText.locale = "tr"
	var p = CreditsScreen.open(_root.get_modal_stack())
	await _frames(2)
	_ok(p != null and p.get_title() == "EMEĞİ GEÇENLER", "Turkish title %s" % (p.get_title() if p != null else "<none>"))
	_ok(_text(p, "ComponentsHeader") == "Godot Engine üçüncü taraf bileşenleri", "Turkish components header")
	p.close()
	UiText.locale = "en"
	_completed["c03_localized"] = true

func _text(p, n: String) -> String:
	var l: Label = p.find_child(n, true, false)
	return l.text if l != null else "<missing %s>" % n

func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m59_credits_%d.save" % Time.get_ticks_usec()
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

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	UiText.locale = "en"
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

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-M59 credits evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
