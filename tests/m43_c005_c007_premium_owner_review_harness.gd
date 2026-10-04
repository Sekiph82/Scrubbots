extends SceneTree
## M43-C005-C007 (SB-M43-065) — Premium owner review harness smoke test (review tooling only).
## Loads res://tests/tools/owner_review/premium_pack_owner_review.tscn and proves it wraps the
## real shipping PremiumPackCeremony on a real ModalStack, waits in IDLE, never taps, keeps
## card 0 Rare-or-better in every fixture, and that R / E / 1 / 2 / 3 only restart / switch.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c007_premium_owner_review_harness.gd

const SCENE := "res://tests/tools/owner_review/premium_pack_owner_review.tscn"
const HARNESS := "res://tests/tools/owner_review/premium_pack_owner_review.gd"
const CEREMONY := "res://scripts/ui/ceremony/premium_pack_ceremony.gd"
const RARE_PLUS := ["RARE", "EPIC", "LEGENDARY"]
const NO_INPUT := ["tap", "push_input", "parse_input_event", "InputEventMouseButton", "InputEventScreenTouch",
	"call_deferred", "Timer", "create_timer"]
const FORBIDDEN := ["open_standard", "open_premium", "add_card", "grant", "claim", "RewardGrant", "CardPackService",
	"CollectionInventory", "CardsExchange", "exchange_card", "economy", "AppState", "save", "Save", "Navigation",
	"change_scene", "ProjectSettings"]
const NO_COPY := ["PACK_FRAMES", "FRAME_HOLD", "FRAME09_HOLD_S", "MIN_FULL_HOLD", "frame_0", "pack_opening",
	"RevealSequencer", "create_tween", "Tween", "Phase", "pack_frame", "emerge", "route", "ROUTE_S", "ROWS", "BACKS",
	"0.22", "0.40", "0.30", "0.18"]

var EXPECTED_CASES := ["h01_scene_loads", "h02_real_ceremony", "h03_default_mixed", "h04_idle_waits",
	"h05_no_auto_tap", "h06_key_r", "h07_key_e", "h08_keys_fixtures", "h09_no_authority", "h10_no_copy",
	"h11_project_untouched"]

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
	var c = _h.get_ceremony()
	_ok(c != null and c.get_script().resource_path == CEREMONY and _h.get_stack().get_script().resource_path == "res://scripts/ui/popup/modal_stack.gd" and _h.get_stack().top() == c and c.is_open(), "real PremiumPackCeremony open on the real ModalStack")
	_complete("h02_real_ceremony")
	var states: Array = c.get_model()["cards"].map(func(x): return x["is_new"])
	_ok(_h.fixture_name() == "mixed" and not _h.is_reduced() and c.get_model()["cards"].size() == 5 and states == [true, false, true, false, true] and c.get_model()["cards"][0]["rarity"] in RARE_PLUS, "default: mixed 5 cards NEW/DUP/NEW/DUP/NEW, card 0 %s, FULL" % c.get_model()["cards"][0]["rarity"])
	_complete("h03_default_mixed")
	await _frames(180)
	_ok(c.phase() == "IDLE" and c.frame_history().is_empty() and not _h.get_review_note().visible, "180 frames: still IDLE, nothing bound, no overlay")
	_complete("h04_idle_waits")
	var src := _code_only(FileAccess.get_file_as_string(HARNESS))
	_ok(_hits(src, NO_INPUT).is_empty() and _hits("\tc.tap()\n", NO_INPUT) == ["tap"], "harness never taps / injects input (sensitivity checked)")
	_complete("h05_no_auto_tap")
	c.tap()   # the TEST taps (the harness never does)
	_key(KEY_R)
	await _frames(2)
	var c2 = _h.get_ceremony()
	_ok(c2 != c and c2.phase() == "IDLE" and _h.get_stack().depth() == 1 and not is_instance_valid(c), "R: old ceremony closed + freed, fresh one in IDLE")
	_complete("h06_key_r")
	_key(KEY_E)
	await _frames(2)
	var c3 = _h.get_ceremony()
	_ok(_h.is_reduced() and c3.phase() == "IDLE", "E: Reduced, IDLE")
	c3.tap()
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline and c3.phase() == "OPENING":
		await process_frame
	_ok(c3.frame_history() == [9], "the shipping ceremony runs Reduced (frame 09 only)")
	_key(KEY_E)
	await _frames(2)
	_ok(not _h.is_reduced() and _h.get_ceremony().phase() == "IDLE", "E again: FULL, IDLE")
	_complete("h07_key_e")
	var want := {KEY_2: ["all_new", [true, true, true, true, true]], KEY_3: ["repeat", [true, false, false, false, false]], KEY_1: ["mixed", [true, false, true, false, true]]}
	for key in want:
		_key(key)
		await _frames(2)
		var cc = _h.get_ceremony()
		var cards: Array = cc.get_model()["cards"]
		_ok(_h.fixture_name() == want[key][0] and cards.map(func(x): return x["is_new"]) == want[key][1] and cards.size() == 5 and cards[0]["rarity"] in RARE_PLUS and cc.phase() == "IDLE", "%s -> %s, 5 cards, card 0 %s, IDLE" % [OS.get_keycode_string(key), want[key][0], cards[0]["rarity"]])
	_complete("h08_keys_fixtures")
	for path in [HARNESS, "res://tests/support/premium_pack_fixtures.gd"]:
		var hits := _hits(_code_only(FileAccess.get_file_as_string(path)), FORBIDDEN)
		_ok(hits.is_empty(), "%s: no authority identifiers %s" % [path.get_file(), str(hits)])
	_complete("h09_no_authority")
	_ok(_hits(src, NO_COPY).is_empty() and _hits("const FRAME_HOLD := []\n", NO_COPY) == ["FRAME_HOLD"], "no frames / timings / layout / state machine copied (sensitivity checked)")
	_complete("h10_no_copy")
	_ok(String(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/app/main.tscn", "main scene is still res://scenes/app/main.tscn")
	var autoloads := ProjectSettings.get_property_list().filter(func(p): return String(p["name"]).begins_with("autoload/")).map(func(p): return String(ProjectSettings.get_setting(p["name"])))
	_ok(not autoloads.any(func(a): return a.contains("owner_review")), "harness is not an autoload")
	_complete("h11_project_untouched")
	_h.free()
	await _frames(3)
	_done()

func _key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	get_root().push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	get_root().push_input(up)

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
	print("M43-C005-C007 premium owner review harness smoke: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
