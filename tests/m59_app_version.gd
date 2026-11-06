extends SceneTree
## SB-M59-004/005 — app version + build number shown in Settings from the ONE version source
## (res://data/config/app_version.json; CI stamps build + channel, see docs/RELEASE_BUILDS.md).
## Real SettingsPanel scene on an isolated AppState save. The static workflow / preset side is
## tools/check_release_versioning.py (python -I).
##
## Run: godot --headless --path . -s res://tests/m59_app_version.gd

const AppState = preload("res://scripts/app/app_state.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["v01_source", "v02_channel_suffix", "v03_settings_label", "v04_pseudo_keyed"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _src: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_src = JSON.parse_string(FileAccess.get_file_as_string(SettingsPanel.APP_VERSION_PATH))
	_v01_source()
	_v02_channel_suffix()
	await _v03_settings_label()
	await _v04_pseudo_keyed()
	_cleanup()
	_done()

func _v01_source() -> void:
	print("[v01 version source: semantic version, repo state build 0 / debug]")
	var re := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	_ok(re.search(String(_src.get("version", ""))) != null, "version %s is MAJOR.MINOR.PATCH" % str(_src.get("version")))
	_ok(int(_src.get("build", -1)) == 0 and _src.get("channel") == "debug", "committed build 0 / channel debug (CI stamps both)")
	_complete("v01_source")

func _v02_channel_suffix() -> void:
	print("[v02 debug builds carry -debug, release does not]")
	var v := String(_src["version"])
	_ok(SettingsPanel.version_text() == "VERSION %s-debug · BUILD 0" % v, "repo source -> %s" % SettingsPanel.version_text())
	_ok(SettingsPanel.version_text({"version": "1.2.3", "build": 77, "channel": "debug"}) == "VERSION 1.2.3-debug · BUILD 77", "debug channel suffix")
	_ok(SettingsPanel.version_text({"version": "1.2.3", "build": 77, "channel": "release"}) == "VERSION 1.2.3 · BUILD 77", "release channel has no suffix")
	_complete("v02_channel_suffix")

func _v03_settings_label() -> void:
	print("[v03 Settings shows the version label]")
	var panel = await _open_panel("label")
	var lbl: Label = panel.find_child("VersionLabel", true, false)
	_ok(lbl != null and lbl.is_visible_in_tree(), "VersionLabel present and visible")
	if lbl != null:
		_ok(lbl.text == SettingsPanel.version_text(), "label text '%s' from the version source" % lbl.text)
		_ok(lbl.get_theme_font_size("font_size") >= 30, "label font >= 30")
		var frame: Control = panel.find_child("Frame", true, false)
		_ok(frame.get_global_rect().grow(0.5).encloses(lbl.get_global_rect()), "label inside the Settings frame")
	panel.get_parent().free()
	_complete("v03_settings_label")

func _v04_pseudo_keyed() -> void:
	print("[v04 label is keyed (pseudo-locale brackets it)]")
	UiText.pseudo = true
	var panel = await _open_panel("pseudo")
	var lbl: Label = panel.find_child("VersionLabel", true, false)
	_ok(lbl != null and lbl.text.begins_with("["), "pseudo label %s" % (lbl.text if lbl != null else "<none>"))
	UiText.pseudo = false
	panel.get_parent().free()
	_complete("v04_pseudo_keyed")

func _open_panel(tag: String):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	root.add_child(sub)
	var panel = SettingsPanelScene.instantiate()
	sub.add_child(panel)
	panel.bind(AppState.new(_uniq(tag)))
	await process_frame
	await process_frame
	return panel

func _uniq(tag: String) -> String:
	var p := "user://m59_app_version_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
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
	print("SB-M59 app version evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
