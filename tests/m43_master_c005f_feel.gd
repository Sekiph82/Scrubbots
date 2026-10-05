extends SceneTree
## M43 master — Lane C005F presentation feel (SB-M43-C005F-002 adapter, SB-M43-C005F-014 boundary).
## Spy backends stand in for GameFeelFlow / Spark (the canonical plugin intake is owner-gated).
##
## Run: godot --headless --path . -s res://tests/m43_master_c005f_feel.gd

const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")

## Owner DO-NOT-USE categories (TASKS SB-M43-C005F-014).
const PROHIBITED := ["camera_shake", "camera_flash", "camera_zoom", "camera_offset", "camera_fov", "freeze_frame",
	"time_scale", "impulse", "velocity", "shake", "shake_position", "shake_rotation", "shake_scale", "flash", "death",
	"death_explosion", "explosion", "explosion_small", "explosion_large", "hit_light", "hit_medium", "hit_heavy", "hit_critical"]

class Spy extends Node:
	var calls: Array = []
	var presets := {"spark": {"amount": 10}, "pickup": {"amount": 12}, "confetti": {"amount": 40}}
	func play(effect, target, _params = null) -> void:
		calls.append(["play", effect, target])
	func play_combo(combo, target, _params = null) -> void:
		calls.append(["play_combo", combo, target])
	func stop_all(node = null) -> void:
		calls.append(["stop_all", node])
	func at(node, opts = {}) -> void:
		calls.append(["at", node, opts])
	func clear() -> void:
		calls.append(["clear"])

var EXPECTED_CASES := ["f01_tier_table", "f02_dispatch_after_caller", "f03_one_shot_key", "f04_missing_plugins_noop",
	"f05_reduced_live_cancel", "f06_allowlist_excludes_prohibited", "f07_single_adapter_no_call_sites"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_f01()
	await _f02()
	await _f03()
	await _f04()
	await _f05()
	_f06()
	_f07()
	_done()

func _adapter(reduced := false) -> Array:
	var fx := EffectsSettingsService.new()
	fx.set_reduced(reduced)
	var a := FeedbackAdapter.new()
	a.bind(self, fx)
	var g := Spy.new()
	var s := Spy.new()
	get_root().add_child(g)
	get_root().add_child(s)
	a.set_backends_for_test(g, s)
	return [a, g, s, fx]

func _target() -> Control:
	var c := Control.new()
	get_root().add_child(c)
	return c

func _f01() -> void:
	print("[f01 MICRO..MAJOR_UNLOCK table within owner ceilings; Reduced = nothing]")
	var ok := true
	for i in FeedbackAdapter.INTENTS:
		ok = ok and int(FeedbackAdapter.FULL[i]["amount"]) <= int(FeedbackAdapter.PARTICLE_CEILING[i])
		ok = ok and FeedbackAdapter.REDUCED[i]["amount"] == 0 and String(FeedbackAdapter.REDUCED[i]["gff"]).is_empty()
	_ok(ok and FeedbackAdapter.PARTICLE_CEILING == {"MICRO": 0, "SMALL": 4, "REWARD": 8, "MAJOR_REWARD": 14, "WIN": 18, "MAJOR_UNLOCK": 24}, "FULL within ceilings; ceilings == TASKS; REDUCED no particles, no plugin motion")
	_ok(FeedbackAdapter.INTENTS == ["MICRO", "SMALL", "REWARD", "MAJOR_REWARD", "WIN", "MAJOR_UNLOCK"], "intensity ladder order preserved")
	_complete("f01_tier_table")

func _f02() -> void:
	print("[f02 REWARD dispatch is deferred: the caller always finishes first]")
	var r := _adapter()
	var a = r[0]
	var t := _target()
	var order: Array = []
	_ok(a.play("REWARD", t), "accepted")
	order.append("caller_continued")
	order.append(r[1].calls.size() + r[2].calls.size())
	await process_frame
	_ok(order == ["caller_continued", 0], "no plugin call ran inside the caller's frame")
	_ok(r[1].calls == [["play_combo", "ui_notification", t]] and r[2].calls.size() == 1 and r[2].calls[0][2]["amount"] == 8, "GFF ui_notification + Spark pickup capped at 8")
	_free(r, t)
	_complete("f02_dispatch_after_caller")

func _f03() -> void:
	print("[f03 one-shot key never plays twice]")
	var r := _adapter()
	var t := _target()
	_ok(r[0].play("WIN", t, "results:attempt:3:WON") and not r[0].play("WIN", t, "results:attempt:3:WON") and r[0].play("WIN", t, "results:attempt:4:WON"), "same key refused; a new key plays")
	await process_frame
	_ok(r[1].calls.size() == 2 and r[0].dispatch_log().size() == 2, "exactly two dispatches")
	_free(r, t)
	_complete("f03_one_shot_key")

func _f04() -> void:
	print("[f04 plugins absent: silent no-op, never blocks]")
	var a := FeedbackAdapter.new()
	a.bind(self, null)
	a.set_backends_for_test(null, null)
	var t := _target()
	_ok(a.play("MAJOR_UNLOCK", t) and not a.play("BOGUS", t) and not a.play("SMALL", null), "absent plugins accepted as no-op; bad intent / target refused")
	a.cancel_all()
	await process_frame
	_ok(true, "cancel_all with absent plugins is harmless")
	t.free()
	_complete("f04_missing_plugins_noop")

func _f05() -> void:
	print("[f05 live Reduced toggle cancels decorative work; Reduced dispatches nothing]")
	var r := _adapter(false)
	var t := _target()
	r[3].set_reduced(true)
	await process_frame
	_ok(r[1].calls.has(["stop_all", null]) and r[2].calls.has(["clear"]), "toggle -> GFF stop_all + Spark clear")
	var n1: int = r[1].calls.size() + r[2].calls.size()
	r[0].play("MAJOR_REWARD", t)
	await process_frame
	_ok(r[1].calls.size() + r[2].calls.size() == n1, "Reduced: no plugin call for MAJOR_REWARD")
	r[3].set_reduced(false)
	await process_frame
	_ok(r[1].calls.size() + r[2].calls.size() == n1, "returning to FULL replays nothing")
	_free(r, t)
	_complete("f05_reduced_live_cancel")

func _f06() -> void:
	print("[f06 allow-list excludes every DO-NOT-USE category]")
	var names: Array = []
	for i in FeedbackAdapter.INTENTS:
		names.append(FeedbackAdapter.FULL[i]["gff"])
	_ok(FeedbackAdapter.GFF_ALLOWED.all(func(n): return not PROHIBITED.has(n)) and names.all(func(n): return n == "" or FeedbackAdapter.GFF_ALLOWED.has(n)), "allowed GFF names never prohibited; table uses allowed names only")
	_complete("f06_allowlist_excludes_prohibited")

func _f07() -> void:
	print("[f07 one adapter at the app root, no plugin access anywhere else]")
	var hits: Array = []
	for path in _gd_files("res://scripts"):
		var src := FileAccess.get_file_as_string(path)
		if path.ends_with("feedback_adapter.gd"):
			continue
		if src.contains("GameFeelFlow") or src.contains("\"Spark\"") or src.contains("/root/Spark"):
			hits.append(path)
	var main := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_ok(hits.is_empty() and main.count("FeedbackAdapter.new()") == 1, "plugin names appear only in the adapter; one instance %s" % str(hits))
	_complete("f07_single_adapter_no_call_sites")

func _gd_files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_gd_files(dir + "/" + sub))
	return out

func _free(r: Array, t: Node) -> void:
	r[1].free()
	r[2].free()
	t.free()

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
	print("M43 master C005F feel evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
