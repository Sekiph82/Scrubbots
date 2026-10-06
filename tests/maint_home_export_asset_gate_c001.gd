extends SceneTree
## MAINT-HOME-EXPORT-ASSET-GATE-C001 — export-safe Home asset gate.
## Authority: coordination/sessions/MAINT-HOME-EXPORT-ASSET-GATE-C001/OWNER_DECISION_V01.md.
## Exported packs carry imported textures + remap, not raw source PNGs. The packaged case is
## simulated deterministically through the explicit mode + project-root seam: a source root
## that does not exist (no owner file is touched) while res:// resources still resolve.
##
## Run: godot --headless --path . -s res://tests/maint_home_export_asset_gate_c001.gd

const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const AppState = preload("res://scripts/app/app_state.gd")

const STRICT := V.SOURCE_TREE_STRICT
const PACKAGED := V.PACKAGED_RUNTIME
const NO_SOURCE_ROOT := "res://__maint_no_source_tree__/"   ## never created
const SET_ID := "home_scrubby_gestures_v03"
const COUNTS := {"wave": 14, "bow": 15, "turn": 17, "full_turn": 17}

var EXPECTED_CASES := [
	"strict_real_tree", "strict_wrong_pin", "strict_source_absent", "packaged_without_source",
	"packaged_binder_binds", "packaged_animation_set", "packaged_rejections",
	"strict_tamper_dynamic", "no_generated_bypass", "auto_mode_selector", "home_live_strict",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_strict_real()
	_strict_wrong_pin()
	_strict_absent()
	_packaged_without_source()
	_packaged_binder()
	_packaged_animation()
	_packaged_rejections()
	_strict_tamper()
	_generated()
	_auto_mode()
	await _home_live()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _m() -> Dictionary:
	return V.load_manifest()

func _approved_slugs(m: Dictionary) -> Array:
	var out: Array = []
	for a in m["assets"]:
		if a["status"] == "APPROVED" and a["kind"] == "ART":
			out.append(String(a["slug"]))
	return out

func _idx(m: Dictionary, slug: String) -> int:
	for i in (m["assets"] as Array).size():
		if m["assets"][i]["slug"] == slug:
			return i
	return -1

func _errs(r: Dictionary) -> String:
	return str((r["errors"] as Array).slice(0, 2))

func _has_err(r: Dictionary, needle: String) -> bool:
	for e in r["errors"]:
		if String(e).find(needle) != -1:
			return true
	return false

# ------------------------------------------------------------------- cases ----

func _strict_real() -> void:
	print("[strict: real source tree]")
	var r: Dictionary = V.validate(_m())
	_ok(r["ok"], "default validate() == SOURCE_TREE_STRICT and the real tree passes %s" % _errs(r))
	_ok(V.validate(_m(), "res://", STRICT)["ok"], "explicit SOURCE_TREE_STRICT passes (all source pins match)")
	_ok(not V.validate(_m(), "res://", "LENIENT")["ok"], "unknown mode is rejected, never a silent default")
	_complete("strict_real_tree")

func _strict_wrong_pin() -> void:
	print("[strict: wrong pin]")
	var m := _m()
	m["assets"][_idx(m, "home_background_whispering_park")]["approved_sha256"] = "a".repeat(64)
	var r: Dictionary = V.validate(m)
	_ok(not r["ok"] and _has_err(r, "approved asset changed on disk"), "valid-format but wrong ART pin fails strict %s" % _errs(r))
	var m2 := _m()
	m2["animation_sets"][SET_ID]["gestures"]["bow"]["frames"][4]["sha256"] = "b".repeat(64)
	var r2: Dictionary = V.validate(m2)
	_ok(not r2["ok"] and _has_err(r2, "changed on disk"), "wrong animation-frame pin fails strict %s" % _errs(r2))
	_complete("strict_wrong_pin")

func _strict_absent() -> void:
	print("[strict: source absent]")
	var r: Dictionary = V.validate(_m(), NO_SOURCE_ROOT, STRICT)
	_ok(not r["ok"] and _has_err(r, "approved source missing"), "strict with no source tree fails (missing source is an error) %s" % _errs(r))
	var b = HomeArtBinder.new(null, STRICT, NO_SOURCE_ROOT)
	_ok(not b.is_manifest_valid() and b.texture("home_background_whispering_park") == null and b.animation_set(SET_ID).is_empty(), "strict binder without sources binds nothing")
	_complete("strict_source_absent")

func _packaged_without_source() -> void:
	print("[packaged: no raw source, resources resolve]")
	var r: Dictionary = V.validate(_m(), NO_SOURCE_ROOT, PACKAGED)
	_ok(r["ok"], "the SAME no-source setup validates in PACKAGED_RUNTIME because res:// resources resolve %s" % _errs(r))
	_ok(not DirAccess.dir_exists_absolute(NO_SOURCE_ROOT) and not FileAccess.file_exists(NO_SOURCE_ROOT + "assets/ui/final/characters/scrubby/scrubby_home_pose.png"), "simulated source root really has no files")
	_complete("packaged_without_source")

func _packaged_binder() -> void:
	print("[packaged binder binds approved Home art]")
	var m := _m()
	var b = HomeArtBinder.new(null, PACKAGED, NO_SOURCE_ROOT)
	_ok(b.get_mode() == PACKAGED and b.is_manifest_valid(), "binder in PACKAGED_RUNTIME, manifest valid")
	var bad: Array = []
	var n := 0
	for slug in _approved_slugs(m):
		n += 1
		if b.state(slug) != "APPROVED_BOUND" or b.texture(slug) == null:
			bad.append(slug)
	_ok(bad.is_empty() and n == 53, "all %d approved ART entries APPROVED_BOUND with a texture (R15-004: + HOME-122) %s" % [n, str(bad)])
	for slug in ["home_background_whispering_park", "scrubby_home_pose", "icon_shortcut_shop", "icon_currency_scrub_bucks"]:
		if _idx(m, slug) >= 0:
			_ok(b.texture(slug) != null, "%s binds without source bytes" % slug)
	_ok(b.state("not_a_slug") == "UNKNOWN", "unknown slug stays UNKNOWN")
	_complete("packaged_binder_binds")

func _packaged_animation() -> void:
	print("[packaged animation set]")
	var b = HomeArtBinder.new(null, PACKAGED, NO_SOURCE_ROOT)
	var s: Dictionary = b.animation_set(SET_ID)
	var counts := {}
	var nulls := 0
	for g in s.get("textures", {}):
		counts[g] = (s["textures"][g] as Array).size()
		for t in s["textures"][g]:
			nulls += int(t == null)
	_ok(counts == COUNTS and nulls == 0, "all four gesture lists load: %s" % str(counts))
	_complete("packaged_animation_set")

func _packaged_rejections() -> void:
	print("[packaged still fails closed]")
	_ok(not V.validate("not a manifest", NO_SOURCE_ROOT, PACKAGED)["ok"], "malformed manifest (not an object) rejected")
	var m0 := _m()
	m0["schema_version"] = 2
	_ok(not V.validate(m0, NO_SOURCE_ROOT, PACKAGED)["ok"], "wrong schema_version rejected")
	var m1 := _m()
	m1["assets"][_idx(m1, "home_background_whispering_park")]["status"] = "OWNER_REVIEW"
	var b1 = HomeArtBinder.new(m1, PACKAGED, NO_SOURCE_ROOT)
	_ok(b1.state("home_background_whispering_park") == "NOT_APPROVED" and b1.texture("home_background_whispering_park") == null, "unapproved ART never binds")
	var m2 := _m()
	m2["assets"][_idx(m2, "home_background_whispering_park")]["path"] = "assets/ui/home_background_outside_final.png"
	var r2: Dictionary = V.validate(m2, NO_SOURCE_ROOT, PACKAGED)
	_ok(not r2["ok"] and _has_err(r2, "under assets/ui/final/"), "approved path outside assets/ui/final/ rejected")
	var m3 := _m()
	m3["assets"][_idx(m3, "home_background_whispering_park")]["path"] = "assets/ui/final/home/background/does_not_exist.png"
	var r3: Dictionary = V.validate(m3, NO_SOURCE_ROOT, PACKAGED)
	_ok(not r3["ok"] and _has_err(r3, "packaged resource does not resolve"), "missing packaged ART resource rejected %s" % _errs(r3))
	var b3 = HomeArtBinder.new(m3, PACKAGED, NO_SOURCE_ROOT)
	_ok(not b3.is_manifest_valid() and b3.texture("scrubby_home_pose") == null, "whole manifest stays fail-closed (nothing binds)")
	var m4 := _m()
	m4["animation_sets"][SET_ID]["gestures"]["turn"]["frames"][2]["path"] = "assets/ui/final/characters/scrubby/home_animation/turn/turn_99.png"
	var r4: Dictionary = V.validate(m4, NO_SOURCE_ROOT, PACKAGED)
	_ok(not r4["ok"] and _has_err(r4, "does not resolve"), "missing packaged animation frame rejected")
	for spec in [["erase", ""], ["short", "abc"], ["upper", "A".repeat(64)], ["nonhex", "z".repeat(64)]]:
		var m5 := _m()
		var a: Dictionary = m5["assets"][_idx(m5, "home_background_whispering_park")]
		if spec[0] == "erase":
			a.erase("approved_sha256")
		else:
			a["approved_sha256"] = spec[1]
		var r5: Dictionary = V.validate(m5, NO_SOURCE_ROOT, PACKAGED)
		_ok(not r5["ok"] and _has_err(r5, "requires approved_sha256"), "approved pin %s rejected in packaged mode" % spec[0])
	var m6 := _m()
	m6["animation_sets"][SET_ID]["gestures"]["wave"]["frames"][0].erase("sha256")
	_ok(not V.validate(m6, NO_SOURCE_ROOT, PACKAGED)["ok"], "animation frame without pin rejected in packaged mode")
	var m7 := _m()
	m7["animation_sets"][SET_ID]["status"] = "CANDIDATE"
	_ok(not V.validate(m7, NO_SOURCE_ROOT, PACKAGED)["ok"], "non-APPROVED animation set rejected")
	_complete("packaged_rejections")

func _strict_tamper() -> void:
	print("[strict: tamper / dynamic recheck]")
	var m := _m()
	m["assets"][0]["approved_sha256"] = "f".repeat(64)
	var b = HomeArtBinder.new(m, STRICT)
	_ok(not b.is_manifest_valid() and b.texture("home_bg_sky") == null, "silently changed approved file (pin != bytes) -> manifest invalid, nothing binds")
	# Dynamic: diverge source identity AFTER construction; state() re-hashes every call.
	var live := _m()
	var bl = HomeArtBinder.new(live, STRICT)
	var i := _idx(live, "home_background_whispering_park")
	_ok(bl.state("home_background_whispering_park") == "APPROVED_BOUND", "strict binder binds while bytes == pin")
	live["assets"][i]["approved_sha256"] = "e".repeat(64)
	_ok(bl.state("home_background_whispering_park") == "HASH_MISMATCH" and bl.texture("home_background_whispering_park") == null, "strict state() re-hashes on every call: post-construction divergence never binds")
	var bp = HomeArtBinder.new(_m(), PACKAGED)
	_ok(bp.get_mode() == PACKAGED and bp.state("home_background_whispering_park") == "APPROVED_BOUND", "packaged binder never hashes raw source (state via ResourceLoader)")
	_complete("strict_tamper_dynamic")

func _generated() -> void:
	print("[no generated/ bypass]")
	var m := _m()
	m["assets"][_idx(m, "scrubby_home_pose")]["path"] = "assets/ui/generated/characters/scrubby_home_pose_candidate_02.png"
	_ok(not V.validate(m, NO_SOURCE_ROOT, PACKAGED)["ok"] and not HomeArtBinder.new(m, PACKAGED, NO_SOURCE_ROOT).is_manifest_valid(), "approved ART pointing into assets/ui/generated/ invalidates the manifest in packaged mode")
	var m2 := _m()
	m2["animation_sets"][SET_ID]["gestures"]["wave"]["frames"][0]["path"] = "assets/ui/generated/characters/home_animation/v03/wave/wave_01.png"
	_ok(not V.validate(m2, NO_SOURCE_ROOT, PACKAGED)["ok"], "animation frame pointing into generated/ rejected in packaged mode")
	var b = HomeArtBinder.new(null, PACKAGED, NO_SOURCE_ROOT)
	_ok(b.state("scrubby_home_pose_candidate_02") == "UNKNOWN", "generated candidates have no manifest identity to bind")
	_complete("no_generated_bypass")

func _auto_mode() -> void:
	print("[automatic mode selector]")
	var f := {"template": OS.has_feature("template"), "editor": OS.has_feature("editor"), "debug": OS.has_feature("debug"), "web": OS.has_feature("web")}
	print("  probe: Godot %s features %s default_mode %s" % [Engine.get_version_info()["string"], str(f), HomeArtBinder.default_mode()])
	_ok(not f["template"] and f["editor"] and HomeArtBinder.default_mode() == STRICT and HomeArtBinder.new().get_mode() == STRICT, "local editor/headless source run -> SOURCE_TREE_STRICT (template=false, editor=true)")
	_complete("auto_mode_selector")

func _home_live() -> void:
	print("[live Home in the source tree]")
	var p := "user://maint_home_export_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(AppState.new(p))
	for _i in range(6):
		await process_frame
	var d: Dictionary = home.get_asset_diagnostics()
	_ok(d["mode"] == STRICT and d["manifest_valid"] and (d["unbound_nodes"] as Array).is_empty() and d["hero_has_frames"] and d["animation_counts"] == COUNTS, "Home binds every mapped node + 14/15/17/17 in strict mode %s" % str(d["unbound_nodes"]))
	# The same Home with an injected packaged binder (no source root) binds identically.
	home.set_art_binder(HomeArtBinder.new(null, PACKAGED, NO_SOURCE_ROOT))
	await process_frame
	var d2: Dictionary = home.get_asset_diagnostics()
	_ok(d2["mode"] == PACKAGED and d2["manifest_valid"] and (d2["unbound_nodes"] as Array).is_empty() and d2["hero_has_frames"] and d2["animation_counts"] == COUNTS and d2["bound_nodes"] == d["bound_nodes"], "injected PACKAGED binder: same %d bound nodes, hero frames 14/15/17/17" % d2["bound_nodes"])
	sub.free()
	await process_frame
	_complete("home_live_strict")

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
	print("maint_home_export_asset_gate_c001: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
