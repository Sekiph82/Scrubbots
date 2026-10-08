extends SceneTree
## M43-C005F-PHASE1 — GameFeelFlow + Saltmire Spark canonical foundation:
##   i*: SB-M43-C005F-001 canonical plugin intake / API / license gate (REAL autoloads);
##   a*: SB-M43-C005F-002 one fail-open feedback adapter + intensity budgets;
##   r*: SB-M43-C005F-013 FULL / REDUCED matrix + live cancellation (canonical Reduced Effects);
##   b*: SB-M43-C005F-014 DO-NOT-USE boundary (static guard + plugin removal / fault injection).
## Real plugins run headless (Spark bursts process + free; GFF punch_scale tweens + restores).
## Spy backends are used only where a fault or call trace must be injected.
##
## Run: godot --headless --path . -s res://tests/m43_c005f_phase1_foundation.gd
## (a clean clone needs one `godot --headless --path . --import` first so the plugin
## class_name cache exists — standard Godot project bootstrap.)

const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

const GFF_DIR := "res://addons/game_feel_flow"
const SPARK_DIR := "res://addons/saltmire_spark"
## TASKS C005F lower bounds of the FULL particle ranges (ceilings live in the adapter).
const PARTICLE_FLOOR := {"MICRO": 0, "SMALL": 0, "REWARD": 4, "MAJOR_REWARD": 8, "WIN": 12, "MAJOR_UNLOCK": 16}
## Authorities a presentation plugin must never colonize (TASKS SB-M43-C005F-014).
const AUTHORITY_ROOTS := ["res://scripts/economy", "res://scripts/gameplay", "res://scripts/save", "res://scripts/progression",
	"res://scripts/collection", "res://scripts/settings", "res://scripts/audio", "res://scripts/haptics", "res://scripts/difficulty",
	"res://scripts/content_runtime", "res://scripts/data"]
const AUTHORITY_FILES := ["res://scripts/app/navigation_controller.gd", "res://scripts/app/app_state.gd", "res://scripts/ui/popup/modal_stack.gd",
	"res://scripts/ui/popup/base_popup.gd", "res://scripts/ui/safe_area_root.gd", "res://scripts/ui/home/home_scrubby_hero.gd"]
const PLUGIN_WORDS := ["GameFeelFlow", "\"Spark\"", "/root/Spark", "Spark.", "GFFUtil", "GFUtil", "GFFPlayer", "addons/game_feel_flow", "addons/saltmire_spark"]
## Owner DO-NOT-USE categories (TASKS SB-M43-C005F-014).
const PROHIBITED_GFF := ["camera_shake", "camera_flash", "camera_zoom", "camera_fov", "freeze_frame", "time_scale",
	"impulse", "velocity", "shake", "shake_position", "shake_rotation", "shake_scale", "flash", "particles", "gpu_particles",
	"sound", "audio_volume", "method", "signal", "event", "animator", "tween", "death", "death_explosion", "explosion",
	"explosion_small", "explosion_large", "hit_light", "hit_medium", "hit_heavy", "hit_critical"]
const PROHIBITED_CODE := ["Engine.time_scale", "time_scale", "freeze_frame", "camera_", ".paused", "Camera2D", "Camera3D",
	"RigidBody", "CharacterBody", "apply_impulse", "velocity", "change_scene", "play_global", "Spark.clear", "spark.clear", "stop_all(null)", "stop_all()",
	"effect_finished", "effect_started", ".listen(", "request_save", "grant(", "navigate", "_modals", "set_reduced"]

class Spy extends Node:
	var calls: Array = []
	var fault := false
	var presets := {"spark": {"amount": 10, "lifetime": 0.45}, "pickup": {"amount": 12, "lifetime": 0.5}, "confetti": {"amount": 40, "lifetime": 0.9}}
	func play(effect, target, params = null) -> void:
		calls.append(["play", effect, target, params])
		if fault:
			var broken = null
			broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see test log)
	func stop_all(node = null) -> void:
		calls.append(["stop_all", node])
	func get_effect_names() -> Array:
		return ["punch_scale"]
	func at(node, opts = {}) -> void:
		calls.append(["at", node, opts])
	func burst(_pos, _opts = {}) -> void:
		calls.append(["burst"])
	func clear() -> void:
		calls.append(["clear"])

var EXPECTED_CASES := [
	"i01_plugin_identity_versions", "i02_autoloads_exactly_once", "i03_license_attribution", "i04_no_demo_test_paid_dependency",
	"i05_capability_query_no_mutation", "i06_incompatible_or_absent_plugin_is_noop",
	"a01_single_entry_boundary_not_durable", "a02_intensity_vocabulary_budgets", "a03_real_plugins_bounded_dispatch",
	"a04_plugin_fault_never_reaches_caller", "a05_one_shot_keys", "a06_missing_plugins_noop", "a07_unbind_teardown",
	"r01_full_reduced_matrix", "r02_reduced_structurally_cheaper", "r03_live_reduced_cancels_only_owned_work",
	"r04_restore_full_no_replay", "r05_missing_plugin_both_modes", "r06_canonical_setting_reused",
	"b01_authority_static_boundary", "b02_prohibited_unreachable", "b03_adapter_code_red_lines", "b04_plugins_removed_core_paths_work",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_i01(); _i02(); _i03(); _i04(); _i05(); await _i06()
	_a01(); _a02(); await _a03(); await _a04(); await _a05(); await _a06(); await _a07()
	_r01(); await _r02(); await _r03(); await _r04(); await _r05(); await _r06()
	_b01(); _b02(); _b03(); await _b04()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _gff() -> Node:
	return get_root().get_node_or_null("GameFeelFlow")

func _spark() -> Node:
	return get_root().get_node_or_null("Spark")

func _pool() -> Node:
	return _spark().get_node_or_null(FeedbackAdapter.SPARK_POOL) if _spark() != null else null

func _live_bursts() -> int:
	var n := 0
	if _pool() != null:
		for c in _pool().get_children():
			if not c.is_queued_for_deletion():
				n += 1
	return n

func _real(reduced := false) -> Array:
	var fx := EffectsSettingsService.new()
	fx.set_reduced(reduced)
	var a := FeedbackAdapter.new()
	a.bind(self, fx)
	return [a, fx]

func _spied(reduced := false) -> Array:
	var r := _real(reduced)
	var g := Spy.new()
	var s := Spy.new()
	get_root().add_child(g)
	get_root().add_child(s)
	r[0].set_backends_for_test(g, s)
	return [r[0], r[1], g, s]

func _target() -> Control:
	var c := Control.new()
	c.size = Vector2(120, 80)
	c.position = Vector2(400, 600)
	get_root().add_child(c)
	return c

## Node2D target: the only kind GFF 1.0.0's scale target actually moves.
func _target2d() -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(500, 900)
	get_root().add_child(n)
	return n

## Max x-scale reached by `n` over `s` seconds (sampled every frame).
func _peak(n: Node2D, s: float) -> float:
	var mx := n.scale.x
	var end := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame
		mx = maxf(mx, n.scale.x)
	return mx

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _cfg(path: String) -> ConfigFile:
	var c := ConfigFile.new()
	c.load(path)
	return c

## Autoload setting -> script path (accepts res:// or the editor's uid:// form).
func _autoload_path(n: String) -> String:
	var v := String(ProjectSettings.get_setting("autoload/" + n, "")).trim_prefix("*")
	if v.begins_with("uid://"):
		var id := ResourceUID.text_to_id(v)
		return ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else ""
	return v

func _files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_files(dir + "/" + sub))
	return out

func _gd_files(dir: String) -> Array:
	return _files(dir).filter(func(p): return String(p).ends_with(".gd"))

func _code(path: String) -> String:
	var out := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var i := line.find("#")
		out += (line if i == -1 else line.substr(0, i)) + "\n"
	return out

# ------------------------------------------------------- SB-M43-C005F-001 intake ----

func _i01() -> void:
	print("[i01 installed plugin identity == audited intake (name / version / entry scripts)]")
	var g := _cfg(GFF_DIR + "/plugin.cfg")
	var s := _cfg(SPARK_DIR + "/plugin.cfg")
	_ok(g.get_value("plugin", "name", "") == "Game Feel Flow" and g.get_value("plugin", "version", "") == FeedbackAdapter.GFF_VERSION and g.get_value("plugin", "script", "") == "plugin.gd", "GameFeelFlow plugin.cfg: 'Game Feel Flow' %s, plugin.gd" % FeedbackAdapter.GFF_VERSION)
	_ok(s.get_value("plugin", "name", "") == "Saltmire Spark" and s.get_value("plugin", "version", "") == FeedbackAdapter.SPARK_VERSION and s.get_value("plugin", "script", "") == "plugin.gd", "Saltmire Spark plugin.cfg: 'Saltmire Spark' %s, plugin.gd" % FeedbackAdapter.SPARK_VERSION)
	_ok(FileAccess.file_exists(FeedbackAdapter.GFF_SCRIPT) and FileAccess.file_exists(FeedbackAdapter.SPARK_SCRIPT), "runtime entry scripts present")
	var gsrc := FileAccess.get_file_as_string(GFF_DIR + "/plugin.gd")
	var ssrc := FileAccess.get_file_as_string(SPARK_DIR + "/plugin.gd")
	_ok(gsrc.contains("AUTOLOAD_NAME = \"GameFeelFlow\"") and gsrc.contains(FeedbackAdapter.GFF_SCRIPT) and ssrc.contains("AUTOLOAD_NAME := \"Spark\"") and ssrc.contains(FeedbackAdapter.SPARK_SCRIPT), "plugin.gd registers GameFeelFlow / Spark at the audited script paths")
	_complete("i01_plugin_identity_versions")

func _i02() -> void:
	print("[i02 each autoload registered and alive exactly once; editor plugins enabled once]")
	_ok(_autoload_path("GameFeelFlow") == FeedbackAdapter.GFF_SCRIPT and _autoload_path("Spark") == FeedbackAdapter.SPARK_SCRIPT, "project autoloads -> audited scripts (%s, %s)" % [_autoload_path("GameFeelFlow"), _autoload_path("Spark")])
	var by_script := {FeedbackAdapter.GFF_SCRIPT: 0, FeedbackAdapter.SPARK_SCRIPT: 0}
	for c in get_root().get_children():
		var sc = c.get_script()
		if sc != null and by_script.has(sc.resource_path):
			by_script[sc.resource_path] += 1
	_ok(by_script.values() == [1, 1] and _gff() != null and _spark() != null, "exactly one live instance of each plugin singleton %s" % str(by_script))
	var enabled = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	var gn := 0
	var sn := 0
	for e in enabled:
		gn += 1 if String(e) == GFF_DIR + "/plugin.cfg" else 0
		sn += 1 if String(e) == SPARK_DIR + "/plugin.cfg" else 0
	_ok(gn == 1 and sn == 1, "editor_plugins enables each addon exactly once %s" % str(enabled))
	var ssrc := FileAccess.get_file_as_string(SPARK_DIR + "/plugin.gd")
	_ok(ssrc.contains("if not ProjectSettings.has_setting(\"autoload/\" + AUTOLOAD_NAME)"), "Spark plugin enable is guarded (no duplicate autoload on re-enable)")
	_complete("i02_autoloads_exactly_once")

func _i03() -> void:
	print("[i03 MIT license + attribution shipped with each addon]")
	var gl := FileAccess.get_file_as_string(GFF_DIR + "/LICENSE")
	var sl := FileAccess.get_file_as_string(SPARK_DIR + "/LICENSE.txt")
	_ok(gl.begins_with("MIT License") and gl.contains("Copyright (c) 2024 Game Feel Flow") and gl.contains("The above copyright notice and this permission notice shall be included"), "GameFeelFlow LICENSE: MIT, (c) 2024 Game Feel Flow")
	_ok(sl.begins_with("MIT License") and sl.contains("Copyright (c) 2026 Saltmire") and sl.contains("The above copyright notice and this permission notice shall be included"), "Saltmire Spark LICENSE.txt: MIT, (c) 2026 Saltmire")
	_ok(FileAccess.file_exists(GFF_DIR + "/README.md") and FileAccess.file_exists(SPARK_DIR + "/README.md"), "README attribution entry points retained")
	_complete("i03_license_attribution")

func _i04() -> void:
	print("[i04 no demo / test / GdUnit / Pro / paid Impact payload or dependency]")
	var all: Array = _files(GFF_DIR) + _files(SPARK_DIR)
	var bad: Array = all.filter(func(p): var s := String(p).to_lower(); return s.contains("/examples/") or s.contains("/demo/") or s.contains("/test") or s.contains("gdunit"))
	_ok(bad.is_empty(), "no examples/demo/test files in the canonical addons %s" % str(bad))
	_ok(not DirAccess.dir_exists_absolute("res://addons/game_feel_flow_pro") and not DirAccess.dir_exists_absolute("res://addons/saltmire_impact") and not DirAccess.dir_exists_absolute("res://addons/gdUnit4"), "no GameFeelFlow Pro / Saltmire Impact / GdUnit addon present")
	var deps: Array = []
	for p in all.filter(func(p): return String(p).ends_with(".gd")):
		var code := _code(p)
		for w in ["gdUnit", "GdUnit", "saltmire_impact", "examples/", "res://demo"]:
			if code.contains(w):
				deps.append("%s:%s" % [String(p).get_file(), w])
		if code.contains("game_feel_flow_pro") and not code.contains("FileAccess.file_exists"):
			deps.append("%s:unguarded pro" % String(p).get_file())
	_ok(deps.is_empty(), "runtime code has no GdUnit / Impact / demo reference; Pro lookups are file_exists-guarded optional %s" % str(deps))
	_complete("i04_no_demo_test_paid_dependency")

func _i05() -> void:
	print("[i05 harmless capability query through the adapter: real API answers, nothing mutated]")
	var r := _real()
	var bursts0 := _live_bursts()
	var cap: Dictionary = r[0].capabilities()
	_ok(cap["gff"] and cap["spark"], "both real plugins pass the compatibility contract")
	_ok((cap["gff_effects"] as Array).has("punch_scale") and (cap["gff_effects"] as Array).has("camera_shake") and not (cap["gff_effects"] as Array).has("elastic"), "installed GFF 1.0.0 effects: punch_scale present; camera_shake exists but is unreachable; no 'elastic'")
	_ok(["spark", "hit", "explode", "pickup", "dust", "confetti"].all(func(p): return (cap["spark_presets"] as Array).has(p)), "installed Spark presets %s" % str(cap["spark_presets"]))
	_ok(_live_bursts() == bursts0 and r[0].owned_count() == 0 and r[0].dispatch_log().is_empty(), "query created no burst / effect / log entry")
	_complete("i05_capability_query_no_mutation")

func _i06() -> void:
	print("[i06 incompatible / partially initialized / absent plugin is treated as absent]")
	var real_g := _gff()
	get_root().remove_child(real_g)
	var impostor := Node.new()
	impostor.name = "GameFeelFlow"
	get_root().add_child(impostor)
	var r := _real()
	_ok(not r[0].capabilities()["gff"] and r[0].capabilities()["spark"], "an impostor GameFeelFlow node (wrong script / API) is not used")
	var t := _target()
	_ok(r[0].play("REWARD", t), "play still accepted (Spark-only, GFF absent)")
	await _frames(2)
	_ok(is_equal_approx(t.scale.x, 1.0), "no GFF motion from the impostor")
	get_root().remove_child(impostor)
	impostor.free()
	get_root().add_child(real_g)
	r[0].cancel_all()
	await _frames(2)
	t.free()
	_ok(r[0].capabilities()["gff"], "real GameFeelFlow restored and usable again")
	_complete("i06_incompatible_or_absent_plugin_is_noop")

# ------------------------------------------------------- SB-M43-C005F-002 adapter ----

func _a01() -> void:
	print("[a01 one production entry boundary; adapter is ephemeral presentation, never saved]")
	var hits: Array = []
	for p in _gd_files("res://scripts"):
		if String(p).ends_with("feel/feedback_adapter.gd"):
			continue
		var code := _code(p)
		for w in PLUGIN_WORDS:
			if code.contains(w):
				hits.append("%s:%s" % [String(p).get_file(), w])
	_ok(hits.is_empty(), "no shipping script outside the adapter references either plugin %s" % str(hits))
	var main := _code("res://scripts/app/main.gd")
	var users: Array = _gd_files("res://scripts").filter(func(p): return _code(p).contains("FeedbackAdapter.new()"))
	_ok(users == ["res://scripts/app/main.gd"] and main.count("FeedbackAdapter.new()") == 1 and main.contains("feel.unbind()"), "exactly one adapter, created and torn down by the app root %s" % str(users))
	var durable: Array = []
	for p in ["res://scripts/app/app_state.gd", "res://scripts/save/save_service.gd", "res://scripts/economy/economy_services.gd"]:
		if _code(p).contains("FeedbackAdapter") or _code(p).contains("feedback_adapter") or _code(p).contains("\"feel\""):
			durable.append(p)
	_ok(durable.is_empty(), "AppState / SaveService / EconomyServices never hold or persist the adapter %s" % str(durable))
	_complete("a01_single_entry_boundary_not_durable")

func _a02() -> void:
	print("[a02 MICRO..MAJOR_UNLOCK vocabulary, particle + duration budgets]")
	_ok(FeedbackAdapter.INTENTS == ["MICRO", "SMALL", "REWARD", "MAJOR_REWARD", "WIN", "MAJOR_UNLOCK"], "intensity ladder MICRO -> SMALL -> REWARD -> MAJOR_REWARD -> WIN -> MAJOR_UNLOCK")
	_ok(FeedbackAdapter.PARTICLE_CEILING == {"MICRO": 0, "SMALL": 4, "REWARD": 8, "MAJOR_REWARD": 14, "WIN": 18, "MAJOR_UNLOCK": 24}, "particle ceilings == TASKS (0 / 4 / 8 / 14 / 18 / 24)")
	var ok := true
	var prev_d := 0.0
	for i in FeedbackAdapter.INTENTS:
		var p: Dictionary = FeedbackAdapter.FULL[i]
		var amt := int(p["amount"])
		var d := float(FeedbackAdapter.DURATION_CEILING_S[i])
		ok = ok and amt >= int(PARTICLE_FLOOR[i]) and amt <= int(FeedbackAdapter.PARTICLE_CEILING[i])
		ok = ok and d >= prev_d and d <= 1.3 and float(p["gff_duration"]) < d and float(p["gff_intensity"]) <= 0.25
		ok = ok and (String(p["gff"]).is_empty() or FeedbackAdapter.GFF_ALLOWED.has(p["gff"])) and (String(p["spark"]).is_empty() or FeedbackAdapter.SPARK_ALLOWED.has(p["spark"]))
		prev_d = d
	_ok(ok, "every FULL tier inside its TASKS particle range, non-decreasing duration ceilings <= 1.3 s, punch shorter than its ceiling, allow-listed names only")
	_complete("a02_intensity_vocabulary_budgets")

func _a03() -> void:
	print("[a03 REAL plugins: WIN dispatch is deferred, capped and expires inside its ceiling]")
	var r := _real()
	var a = r[0]
	var t := _target2d()
	var bursts0 := _live_bursts()
	var order: Array = []
	_ok(a.play("WIN", t, "a03:win"), "WIN accepted")
	order.append(_live_bursts() - bursts0)
	_ok(order == [0], "no plugin work inside the caller's frame")
	await _frames(1)
	var em: Node = _pool().get_child(_pool().get_child_count() - 1)
	_ok(_live_bursts() == bursts0 + 1 and (em.get("_parts") as Array).size() == 18 and float(em.get("_max_life")) <= float(FeedbackAdapter.DURATION_CEILING_S["WIN"]), "one Spark burst, 18 particles (WIN ceiling), max life %.2f s <= 1.1 s" % float(em.get("_max_life")))
	var peak: float = await _peak(t, 0.3)
	_ok(peak > 1.02 and peak <= 1.15, "GFF punch_scale visibly but restrainedly moves the Node2D target (peak %.3f <= 1.15)" % peak)
	var ui := _target()
	var b1 := _live_bursts()
	a.play("REWARD", ui)
	await _frames(2)
	_ok(_live_bursts() == b1 + 1 and is_equal_approx(ui.scale.x, 1.0), "Control (UI) target: Spark burst only; GFF scale is never applied to Controls")
	await _wait(float(FeedbackAdapter.DURATION_CEILING_S["WIN"]) + 0.3)
	_ok(_live_bursts() == bursts0 and a.owned_count() == 0 and is_equal_approx(t.scale.x, 1.0), "after the ceiling: bursts freed, nothing owned, target restored to scale 1")
	t.free()
	ui.free()
	_complete("a03_real_plugins_bounded_dispatch")

func _a04() -> void:
	print("[a04 a plugin that throws can never reach or block the caller]")
	var r := _spied()
	var a = r[0]
	r[2].fault = true
	var t := _target2d()
	var steps: Array = []
	print("  EXPECTED_FAULT_INJECTION: the next SCRIPT ERROR ('explode' on null) is deliberately raised inside a spy plugin")
	steps.append(a.play("REWARD", t))
	steps.append("caller_continued")
	await _frames(2)
	_ok(steps == [true, "caller_continued"] and r[2].calls.size() == 1, "caller returned and continued; the fault happened later inside the adapter dispatch")
	r[2].fault = false
	_ok(a.play("REWARD", t) and true, "adapter still accepts work after a plugin fault")
	await _frames(1)
	_ok(r[2].calls.size() == 2 and r[3].calls.size() == 2, "later dispatch reaches both backends normally")
	a.cancel_all()
	t.free()
	r[2].free()
	r[3].free()
	_complete("a04_plugin_fault_never_reaches_caller")

func _a05() -> void:
	print("[a05 one-shot event keys]")
	var r := _spied()
	var t := _target2d()
	_ok(r[0].play("WIN", t, "results:attempt:3:WON") and not r[0].play("WIN", t, "results:attempt:3:WON") and r[0].play("WIN", t, "results:attempt:4:WON"), "same key refused; a new key plays")
	_ok(r[0].play("SMALL", t) and r[0].play("SMALL", t), "keyless requests are not deduplicated")
	await _frames(1)
	_ok(r[2].calls.filter(func(c): return c[0] == "play").size() == 4 and r[0].dispatch_log().size() == 4, "exactly four dispatches")
	r[0].cancel_all()
	t.free()
	r[2].free()
	r[3].free()
	_complete("a05_one_shot_keys")

func _a06() -> void:
	print("[a06 plugins absent: silent no-op; bad intent / target refused]")
	var a := FeedbackAdapter.new()
	a.bind(self, null)
	a.set_backends_for_test(null, null)
	var t := _target()
	_ok(a.play("MAJOR_UNLOCK", t) and not a.play("BOGUS", t) and not a.play("SMALL", null), "absent plugins accepted as no-op; bad intent / null target refused")
	await _frames(2)
	a.cancel_all()
	_ok(a.capabilities() == {"gff": false, "spark": false, "gff_effects": [], "spark_presets": []}, "capabilities report both absent")
	await _wait(float(FeedbackAdapter.DURATION_CEILING_S["MAJOR_UNLOCK"]) + 0.1)
	_ok(a.owned_count() == 0, "nothing lingers")
	t.free()
	_complete("a06_missing_plugins_noop")

func _a07() -> void:
	print("[a07 unbind cancels owned work and drops the settings subscription]")
	var r := _real()
	var t := _target2d()
	r[0].play("MAJOR_REWARD", t)
	await _frames(1)
	_ok(r[0].owned_count() == 1 and r[1].changed.is_connected(r[0]._on_effects_changed), "one owned dispatch; subscribed to EffectsSettingsService.changed")
	r[0].unbind()
	await _frames(2)
	_ok(r[0].owned_count() == 0 and not r[1].changed.is_connected(r[0]._on_effects_changed) and is_equal_approx(t.scale.x, 1.0), "unbind: nothing owned, unsubscribed, target restored")
	t.free()
	_complete("a07_unbind_teardown")

# ------------------------------------------------------- SB-M43-C005F-013 matrix ----

func _r01() -> void:
	print("[r01 deterministic FULL / REDUCED matrix]")
	var r := _real(false)
	var full_ok := true
	var red_ok := true
	for i in FeedbackAdapter.INTENTS:
		full_ok = full_ok and r[0].plan(i) == FeedbackAdapter.FULL[i]
	r[1].set_reduced(true)
	for i in FeedbackAdapter.INTENTS:
		var p: Dictionary = r[0].plan(i)
		red_ok = red_ok and String(p["gff"]).is_empty() and String(p["spark"]).is_empty() and int(p["amount"]) == 0
	_ok(full_ok, "FULL rows served while Reduced Effects is OFF")
	_ok(red_ok, "REDUCED: every tier -> no motion, no flash, no particles / confetti, no camera / screen work")
	_ok(r[0].plan("BOGUS").is_empty(), "unknown intent has no row")
	print("  matrix: " + str(FeedbackAdapter.INTENTS.map(func(i): return "%s FULL=%s/%s/%d REDUCED=none" % [i, FeedbackAdapter.FULL[i]["gff"], FeedbackAdapter.FULL[i]["spark"], FeedbackAdapter.FULL[i]["amount"]])))
	_complete("r01_full_reduced_matrix")

func _r02() -> void:
	print("[r02 REDUCED is structurally cheaper than FULL (real plugins, every tier)]")
	var full := _real(false)
	var red := _real(true)
	var tf := _target2d()
	var tr := _target2d()
	var b0 := _live_bursts()
	var full_particles := 0
	for i in FeedbackAdapter.INTENTS:
		full[0].play(i, tf)
		red[0].play(i, tr)
	await _frames(1)
	for c in _pool().get_children():
		if not c.is_queued_for_deletion():
			full_particles += (c.get("_parts") as Array).size()
	_ok(full[0].owned_count() == 6 and _live_bursts() - b0 == 5 and full_particles == 4 + 8 + 14 + 18 + 24, "FULL: 6 owned dispatches, 5 bursts, %d particles" % full_particles)
	await _frames(2)
	_ok(red[0].owned_count() == 0 and red[0].dispatch_log().size() == 6 and is_equal_approx(tr.scale.x, 1.0), "REDUCED: 6 requests logged, 0 plugin dispatches, 0 particles, target never moved")
	full[0].cancel_all()
	await _frames(2)
	tf.free()
	tr.free()
	_complete("r02_reduced_structurally_cheaper")

func _r03() -> void:
	print("[r03 live FULL -> REDUCED cancels only adapter-owned work, restores targets]")
	var r := _real(false)
	var t := _target2d()
	var other := _target()
	r[0].play("MAJOR_UNLOCK", t, "r03")
	await _frames(1)
	var peak: float = await _peak(t, 0.08)
	_spark().at(other, "spark")   # someone else's burst (stands in for non-adapter plugin state)
	await _frames(1)
	var foreign: Node = _pool().get_child(_pool().get_child_count() - 1)
	var b_before := _live_bursts()
	_ok(r[0].owned_count() == 1 and b_before >= 2 and peak > 1.02, "mid-celebration: owned dispatch, bursts alive, target punched (peak %.3f)" % peak)
	r[1].set_reduced(true)   # live accessibility toggle (canonical setting)
	await _frames(3)
	_ok(r[0].owned_count() == 0 and is_equal_approx(t.scale.x, 1.0), "toggle: nothing owned, punched target restored to scale 1")
	_ok(is_instance_valid(foreign) and not foreign.is_queued_for_deletion() and _live_bursts() == 1, "only the adapter's burst was freed; the foreign burst is untouched (no global Spark.clear)")
	r[1].set_reduced(false)
	other.free()
	t.free()
	await _wait(0.6)
	_complete("r03_live_reduced_cancels_only_owned_work")

func _r04() -> void:
	print("[r04 REDUCED -> FULL never replays a consumed event]")
	var r := _real(true)
	var t := _target2d()
	var b0 := _live_bursts()
	_ok(r[0].play("WIN", t, "results:attempt:9:WON"), "WIN under REDUCED consumes its key (static truth only)")
	r[1].set_reduced(false)
	await _frames(2)
	_ok(not r[0].play("WIN", t, "results:attempt:9:WON") and r[0].owned_count() == 0 and _live_bursts() == b0 and is_equal_approx(t.scale.x, 1.0), "back in FULL: same key refused, nothing plays retroactively")
	t.free()
	_complete("r04_restore_full_no_replay")

func _r05() -> void:
	print("[r05 missing plugins are safe in FULL and REDUCED]")
	for mode in [false, true]:
		var r := _real(mode)
		r[0].set_backends_for_test(null, null)
		var t := _target()
		var ok := true
		for i in FeedbackAdapter.INTENTS:
			ok = ok and r[0].play(i, t, "r05:%s:%s" % [str(mode), i])
		r[1].set_reduced(not mode)
		r[0].cancel_all()
		await _frames(2)
		_ok(ok and is_equal_approx(t.scale.x, 1.0), "%s: every tier accepted as a no-op, toggle + cancel harmless" % ("REDUCED" if mode else "FULL"))
		t.free()
	_complete("r05_missing_plugin_both_modes")

func _r06() -> void:
	print("[r06 the app's adapter follows the ONE canonical Reduced Effects setting]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var path := "user://c005f_p1_r06_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(4)
	var fx = root.get_app_state().effects
	_ok(root.feel != null and not root.feel.reduced() and root.feel.capabilities()["gff"] and root.feel.capabilities()["spark"], "app root adapter bound; both real plugins usable")
	fx.set_reduced(true)
	_ok(root.feel.reduced() and String(root.feel.plan("WIN")["spark"]).is_empty(), "toggling app_state.effects (Settings authority) switches the adapter to REDUCED")
	fx.set_reduced(false)
	var src := _code("res://scripts/ui/feel/feedback_adapter.gd")
	_ok(not src.contains("ConfigFile") and not src.contains("user://") and not src.contains("set_reduced"), "adapter owns no setting / file of its own")
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	_complete("r06_canonical_setting_reused")

# ------------------------------------------------------- SB-M43-C005F-014 boundary ----

func _b01() -> void:
	print("[b01 no authority script references a plugin or the feel adapter]")
	var files: Array = AUTHORITY_FILES.duplicate()
	for root in AUTHORITY_ROOTS:
		files.append_array(_gd_files(root))
	var hits: Array = []
	for p in files:
		var code := _code(p)
		for w in PLUGIN_WORDS + ["FeedbackAdapter", "feedback_adapter", ".feel"]:
			if code.contains(w):
				hits.append("%s:%s" % [String(p).get_file(), w])
	_ok(files.size() > 60 and hits.is_empty(), "%d authority scripts (economy / gameplay / save / progression / collection / settings / audio / haptics / difficulty / content_runtime / data / navigation / AppState / ModalStack / BasePopup / SafeArea / Scrubby hero): clean %s" % [files.size(), str(hits)])
	_complete("b01_authority_static_boundary")

func _b02() -> void:
	print("[b02 DO-NOT-USE categories are unreachable through the adapter]")
	var reach: Array = FeedbackAdapter.GFF_ALLOWED.duplicate()
	for i in FeedbackAdapter.INTENTS:
		for row in [FeedbackAdapter.FULL[i], FeedbackAdapter.REDUCED[i]]:
			if not String(row["gff"]).is_empty():
				reach.append(row["gff"])
	_ok(reach.all(func(n): return not PROHIBITED_GFF.has(n)) and FeedbackAdapter.SPARK_ALLOWED.all(func(p): return ["spark", "pickup", "confetti"].has(p)), "reachable GFF names %s never prohibited; Spark presets spark/pickup/confetti only" % str(reach))
	var punch = _gff().get_effect("punch_scale")
	_ok(punch != null and int(punch.get("loop_count")) == 0 and bool(punch.get("restore_after_play")) and String(punch.target.get_script().resource_path).ends_with("gff_scale_target.gd"), "installed punch_scale: element scale target, no loop, restores after play")
	var installed: Array = _gff().get_effect_names()
	_ok(["camera_shake", "camera_flash", "freeze_frame", "time_scale", "impulse", "velocity"].all(func(n): return installed.has(n)), "prohibited effects exist in the install (so the allow-list, not absence, is what blocks them)")
	_complete("b02_prohibited_unreachable")

func _b03() -> void:
	print("[b03 adapter code red lines: no time / pause / camera / physics / scene / authority callbacks]")
	var code := _code("res://scripts/ui/feel/feedback_adapter.gd")
	var bad: Array = PROHIBITED_CODE.filter(func(w): return code.contains(w))
	_ok(bad.is_empty(), "adapter code free of prohibited calls %s" % str(bad))
	_ok(code.count(".connect(") == 2 and code.contains("_effects.changed.connect(") and code.contains(".timeout.connect(_expire"), "only connects: settings `changed` + its own expiry timer (no plugin callback)")
	_ok(not code.contains("= gff.play") and not code.contains("= spark.at") and not code.contains("return gff") and not code.contains("await gff"), "plugin results never read: Spark / GFF cannot decide clear / reward / success")
	_ok(code.contains("em.queue_free()") and code.count("queue_free") == 1 and code.contains("Callable(gff, \"stop_all\").call_deferred(target)"), "only adapter-spawned Spark bursts are freed; GFF stop is targeted")
	_complete("b03_adapter_code_red_lines")

func _b04() -> void:
	print("[b04 plugin autoloads removed: Home -> gameplay -> WON -> Results -> save still work]")
	var removed: Array = []
	for n in ["GameFeelFlow", "Spark"]:
		var node := get_root().get_node_or_null(n)
		if node != null:
			get_root().remove_child(node)
			removed.append(node)
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var path := "user://c005f_p1_b04_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(4)
	_ok(root.get_navigation().route_name() == "HOME" and not root.feel.capabilities()["gff"], "boot to HOME with no plugin autoloads")
	var r: Dictionary = root.play_current_frontier()
	await _frames(4)
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await _frames(4)
	var rc: Dictionary = h.get_terminal_receipt()
	_ok(r.get("ok", false) and root.get_navigation().route_name() == "RESULTS" and bool(rc.get("first_clear", false)) and bool(rc.get("saved", false)), "launch, WON commit + save, Results all work without plugins")
	_ok(root.feel.play("WIN", root.get_results_screen(), "b04") and root.feel.play("MAJOR_UNLOCK", root.get_results_screen()), "adapter calls stay harmless no-ops")
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for node in removed:
		get_root().add_child(node)
	_ok(_gff() != null and _spark() != null, "plugins restored")
	_complete("b04_plugins_removed_core_paths_work")

# ------------------------------------------------------------------- infra -----

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
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

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += missing.size()
		print("  FAIL: cases not completed %s" % str(missing))
	print("M43-C005F-PHASE1 foundation: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
