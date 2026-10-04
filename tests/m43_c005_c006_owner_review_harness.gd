extends SceneTree
## M43-C005-C006 (SB-M43-064) — owner review harness smoke test (review tooling only).
## Loads res://tests/tools/owner_review/standard_pack_owner_review.tscn and proves it wraps the
## real shipping StandardPackCeremony unchanged, waits in IDLE, never taps, and that its
## R / E / 1 / 2 / 3 keys only restart / switch effects / switch fixtures.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c006_owner_review_harness.gd

const SCENE := "res://tests/tools/owner_review/standard_pack_owner_review.tscn"
const HARNESS := "res://tests/tools/owner_review/standard_pack_owner_review.gd"
const CEREMONY := "res://scripts/ui/ceremony/standard_pack_ceremony.gd"
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")

## sha256 of the audited V02 production files (commit 10144f6, unchanged at 96da421).
const PRODUCTION_SHA := {
	"res://scripts/ui/ceremony/standard_pack_ceremony.gd": "f570d9bf8baa9e7d228d0dcb912fa65b610d37bfce1d09466923d2bbe797fc0e",
	"res://scripts/ui/ceremony/standard_pack_model.gd": "2db015d362fdfa2e5b2040d7e3ebcbaed59986811b2d364980082095a655f481",
	"res://scripts/ui/components/reveal_sequencer.gd": "ccfcc426db81da9ce623d262611191c0039a5f4bd21c46aa3d3decdbf9d2a5ca",
}
## Harness must not tap, inject input or carry any authority.
const FORBIDDEN := ["tap", "push_input", "parse_input_event", "InputEventMouseButton", "InputEventScreenTouch",
	"call_deferred", "Timer", "create_timer", "open_standard", "open_premium", "add_card", "grant", "claim",
	"RewardGrant", "CardPackService", "CollectionInventory", "CardsExchange", "exchange_card", "economy",
	"AppState", "save", "Save", "Navigation", "change_scene", "ProjectSettings"]
## Harness must not duplicate the opening (frames / timings / state machine / sequencing).
const NO_COPY := ["PACK_FRAMES", "FRAME_HOLD", "frame_0", "pack_opening", "RevealSequencer", "create_tween",
	"Tween", "Phase", "pack_frame", "emerge", "route", "ROUTE_S"]

var EXPECTED_CASES := ["h01_scene_loads", "h02_real_ceremony", "h03_production_unchanged", "h04_default_mixed",
	"h05_idle_waits", "h06_no_auto_tap", "h07_key_r", "h08_key_e", "h09_keys_fixtures",
	"h10_no_authority", "h11_no_duplicate_opening", "h12_project_untouched"]

var _fail := 0
var _completed: Dictionary = {}
var _h

func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load(SCENE)
	_ok(packed != null, "review scene loads")
	_h = packed.instantiate()
	get_root().add_child(_h)
	await _frames(2)
	_ok(_h.get_script().resource_path == HARNESS, "scene root runs the harness controller")
	_complete("h01_scene_loads")
	_h02_real_ceremony()
	_h03_production_unchanged()
	_h04_default_mixed()
	await _h05_idle_waits()
	_h06_no_auto_tap()
	await _h07_key_r()
	await _h08_key_e()
	await _h09_keys_fixtures()
	_h10_no_authority()
	_h11_no_duplicate_opening()
	_h12_project_untouched()
	_h.free()
	await _frames(3)
	_done()

func _h02_real_ceremony() -> void:
	print("[h02 real shipping ceremony on a real ModalStack]")
	var c = _h.get_ceremony()
	_ok(c != null and c.get_script().resource_path == CEREMONY, "ceremony is the shipping StandardPackCeremony script")
	_ok(_h.get_stack().get_script().resource_path == "res://scripts/ui/popup/modal_stack.gd" and _h.get_stack().top() == c and c.is_open(), "mounted and open on the real ModalStack")
	_complete("h02_real_ceremony")

func _h03_production_unchanged() -> void:
	print("[h03 production files unchanged]")
	for path in PRODUCTION_SHA:
		_ok(FileAccess.get_sha256(path) == PRODUCTION_SHA[path], "%s sha256 == audited V02 baseline" % path.get_file())
	_complete("h03_production_unchanged")

func _h04_default_mixed() -> void:
	print("[h04 default fixture]")
	var cards: Array = _h.get_ceremony().get_model()["cards"]
	var want: Array = Fx.mixed()["cards"]
	_ok(_h.fixture_name() == "mixed" and not _h.is_reduced(), "default = mixed, FULL effects")
	_ok(cards.map(func(c): return [c["card_id"], c["is_new"], c["copies_after"]]) == want.map(func(c): return [c["card_id"], c["is_new"], c["copies_after"]]) and cards.map(func(c): return c["is_new"]) == [true, false, true], "default cards NEW / DUPLICATE / NEW")
	_complete("h04_default_mixed")

func _h05_idle_waits() -> void:
	print("[h05 IDLE waits without input]")
	var c = _h.get_ceremony()
	await _frames(180)
	_ok(c.phase() == "IDLE" and c.frame_history().is_empty() and not c.get_sequencer().is_active(), "180 frames: still IDLE, nothing bound, no run")
	_ok(not _h.get_review_note().visible and _visible_harness_controls().is_empty(), "no harness overlay visible over the running ceremony")
	_complete("h05_idle_waits")

func _h06_no_auto_tap() -> void:
	print("[h06 no auto tap in harness source]")
	var hits := _hits(_code_only(FileAccess.get_file_as_string(HARNESS)), ["tap", "push_input", "parse_input_event", "InputEventMouseButton", "InputEventScreenTouch", "call_deferred", "Timer", "create_timer"])
	_ok(hits.is_empty(), "harness never taps / injects input / schedules %s" % str(hits))
	_ok(_hits("\tceremony.tap()\n", ["tap"]) == ["tap"], "sensitivity: an injected tap() call is flagged")
	_complete("h06_no_auto_tap")

func _h07_key_r() -> void:
	print("[h07 R restarts to IDLE]")
	var old = _h.get_ceremony()
	old.tap()   # the TEST taps (the harness never does) to leave IDLE
	_ok(old.phase() == "OPENING", "test tap moved the ceremony to OPENING")
	_key(KEY_R)
	await _frames(2)
	var c = _h.get_ceremony()
	_ok(c != old and is_instance_valid(c) and c.phase() == "IDLE" and _h.get_stack().depth() == 1 and not is_instance_valid(old), "R: old ceremony closed + freed, fresh one in IDLE (depth 1)")
	_ok(_h.fixture_name() == "mixed" and not _h.is_reduced(), "R keeps fixture + effects mode")
	_complete("h07_key_r")

func _h08_key_e() -> void:
	print("[h08 E toggles Reduced Effects + restarts]")
	_key(KEY_E)
	await _frames(2)
	var c = _h.get_ceremony()
	_ok(_h.is_reduced() and c.phase() == "IDLE", "E: Reduced Effects on, restarted in IDLE")
	c.tap()
	for _i in range(600):
		if c.phase() != "OPENING":
			break
		await process_frame
	_ok(c.frame_history() == [9], "the shipping ceremony runs in Reduced mode (frame 09 only)")
	_key(KEY_E)
	await _frames(2)
	_ok(not _h.is_reduced() and _h.get_ceremony().phase() == "IDLE", "E again: FULL, IDLE")
	_complete("h08_key_e")

func _h09_keys_fixtures() -> void:
	print("[h09 1 / 2 / 3 fixtures]")
	var want := {KEY_2: ["all_new", [true, true, true]], KEY_3: ["repeat", [true, false, false]], KEY_1: ["mixed", [true, false, true]]}
	for key in want:
		_key(key)
		await _frames(2)
		var c = _h.get_ceremony()
		var states: Array = c.get_model()["cards"].map(func(x): return x["is_new"])
		_ok(_h.fixture_name() == want[key][0] and states == want[key][1] and c.phase() == "IDLE" and _h.get_stack().depth() == 1, "%s -> %s %s, IDLE" % [OS.get_keycode_string(key), want[key][0], str(states)])
	var reps: Array = Fx.repeat()["cards"].map(func(x): return x["card_id"])
	_ok(reps[0] == reps[1], "repeat fixture repeats one card (NEW then DUPLICATE)")
	_complete("h09_keys_fixtures")

func _h10_no_authority() -> void:
	print("[h10 no authority in harness / fixtures]")
	for path in [HARNESS, "res://tests/support/standard_pack_fixtures.gd"]:
		var hits := _hits(_code_only(FileAccess.get_file_as_string(path)), FORBIDDEN.filter(func(w): return not w in ["tap"]))
		_ok(hits.is_empty(), "%s: no pack/grant/inventory/exchange/save/navigation identifiers %s" % [path.get_file(), str(hits)])
	_ok(_hits("\tpacks.open_standard()\n\tinv.add_card(x)\n", FORBIDDEN).size() == 2, "sensitivity: injected authority calls flagged")
	_complete("h10_no_authority")

func _h11_no_duplicate_opening() -> void:
	print("[h11 no duplicate opening logic]")
	var hits := _hits(_code_only(FileAccess.get_file_as_string(HARNESS)), NO_COPY)
	_ok(hits.is_empty(), "harness has no frames / timings / state machine / tween of its own %s" % str(hits))
	_ok(_hits("const PACK_FRAMES := []\n", NO_COPY) == ["PACK_FRAMES"], "sensitivity: a copied frame list is flagged")
	_complete("h11_no_duplicate_opening")

func _h12_project_untouched() -> void:
	print("[h12 project startup untouched]")
	_ok(String(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/app/main.tscn", "main scene is still res://scenes/app/main.tscn")
	var autoloads := ProjectSettings.get_property_list().filter(func(p): return String(p["name"]).begins_with("autoload/")).map(func(p): return String(ProjectSettings.get_setting(p["name"])))
	_ok(not autoloads.any(func(a): return a.contains("owner_review")), "harness is not an autoload")
	_complete("h12_project_untouched")

# ------------------------------------------------------------------ helpers --

func _key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	get_root().push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	get_root().push_input(up)

func _visible_harness_controls() -> Array:
	return _h.get_children().filter(func(c): return c is Control and c.name != "Background" and c.is_visible_in_tree())

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _hits(src: String, words: Array) -> Array:
	var out: Array = []
	for w in words:
		if RegEx.create_from_string("(?<![A-Za-z_])" + w + "(?![a-z])").search(src) != null:
			out.append(w)
	return out

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

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
	print("M43-C005-C006 owner review harness smoke: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
