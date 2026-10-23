extends SceneTree
## SB-M22-026 step 2 — runtime on-screen size of every res://assets/ui/final/ texture on Home,
## Gameplay (5 and 6 slots), Results (won / failed), Shop and Collection at 1080x2400 and the
## 1536x2048 tablet. Real main.tscn in a SubViewport at the m49 logical size, throw-away
## user:// saves only. Physical px = logical rect x phys/logical (m49 `_logical`).
## Output JSON: {"scenarios": {scenario: {path: {max_side_px, max_w, max_h, source_w, source_h,
## size_limit, visible}}}, "loaded_mib": {scenario: MiB}, "merged": {path: max_side_px}}.
## Run: godot --headless --path . -s res://tests/tools/m22_026_texture_measure.gd -- --out=<file>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")

const F := "res://assets/ui/final/"
const MIB := 1024.0 * 1024.0
const PHYSICAL := [Vector2i(1080, 2400), Vector2i(1536, 2048)]
## robots and life (Heart popup) are extra: they draw robot poses / heart art also seen above.
const SCENARIOS := ["home", "gameplay_5slot", "gameplay_6slot", "results_won", "results_failed", "shop",
	"collection", "robots", "life"]

var _sub: SubViewport
var _root
var _scale := 1.0
var _tmp: Array = []
var _report := {}          ## scenario -> path -> entry
var _loaded := {}          ## scenario -> path -> resident bytes
var _skipped := {}         ## scenario -> reason

func _initialize() -> void:
	var out := "user://m22_026_measure.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	MainScript.boot_opening_override = 0
	for phys in PHYSICAL:
		for s in SCENARIOS:
			var key := "%s@%dx%d" % [s, phys.x, phys.y]
			_report[key] = {}
			_loaded[key] = {}
			await call("_" + s, key, phys)
			_shutdown()
	MainScript.boot_opening_override = -1
	_cleanup()
	var merged := {}
	var mib := {}
	for key in _report:
		var bytes := 0
		for p in _loaded[key]:
			bytes += int(_loaded[key][p])
		mib[key] = snappedf(bytes / MIB, 0.01)
		for p in _report[key]:
			merged[p] = maxi(int(merged.get(p, 0)), int(_report[key][p]["max_side_px"]))
		var zero: int = (_report[key] as Dictionary).values().filter(func(e): return e["max_side_px"] == 0).size()
		print("%-28s %3d textures (%d size 0)  %7.2f MiB loaded%s" % [key, _report[key].size(), zero, mib[key],
			("  SKIPPED: " + _skipped[key]) if _skipped.has(key) else ""])
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"scenarios": _report, "loaded_mib": mib, "skipped": _skipped, "merged": merged}, "\t", true))
	f.close()
	print("wrote ", out)
	print("M22-026 MEASURE: DONE (%d scenarios, %d textures)" % [_report.size(), merged.size()])
	quit(0)

# ------------------------------------------------------------------ scenarios ----

func _home(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_walk(key)
	var hero = _root.get_home().get_region("HomeScrubbyHero")
	hero.set_process(false)
	var anim: Dictionary = hero.get_set()
	for g in anim.get("textures", {}):
		if not hero.start_gesture(g):
			_skipped[key] = "gesture %s did not start" % g
			continue
		var dt := 1.0 / float(anim["fps"])
		hero.step(dt * 0.5)   # mid-frame sampling, so float steps never skip a frame index
		for _i in (anim["textures"][g] as Array).size():
			await process_frame
			_walk(key)
			hero.step(dt)
		hero.step(1.0)

func _gameplay_5slot(key: String, phys: Vector2i) -> void:
	await _play(key, phys)
	_walk(key)

func _gameplay_6slot(key: String, phys: Vector2i) -> void:
	var h = await _play(key, phys)
	if not h.activate_plus_one_slot():
		_skipped[key] = "activate_plus_one_slot refused"
	await _frames(4)
	_walk(key)

func _results_won(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"WON")

func _results_failed(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"LOST")

func _results(key: String, phys: Vector2i, status: StringName) -> void:
	var h = await _play(key, phys)
	h.get_completion().terminal_reached.emit(status, {})
	var res = _root.get_results_screen()
	res.finish_reveal()
	await _frames(8)
	if _root.get_navigation().route_name() != "RESULTS":
		_skipped[key] = "route %s, not RESULTS" % _root.get_navigation().route_name()
	_walk(key)

func _shop(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_root.get_acquisition().open_shop({"source": "measure"})
	await _frames(6)
	_walk(key)

## Album, set detail, card detail of every owned card (and one not found) and Cards Exchange:
## each card seen anywhere is also seen at its largest (detail) size.
func _collection(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	var app = _root.get_app_state()
	var owned := ["s2_c0", "s2_c4", "s2_c8", "s3_c1"]
	for k in range(9):
		owned.append("s1_c%d" % k)
	for cid in owned:
		app.economy.collection.add_card(cid)
	var st = _root.get_modal_stack()
	CollectionScreen.open_album(st, app)
	await _frames(6)
	_walk(key)
	for n in [1, 2, 3]:
		CollectionScreen.open_set(st, app, n)
		await _frames(6)
		_walk(key)
		st.top().close("measure")
	for cid in owned + ["s2_c1"]:
		CollectionScreen.open_card(st, app, cid)
		await _frames(4)
		_walk(key)
		st.top().close("measure")
	await _frames(2)
	CollectionScreen.open_exchange(st, app)
	await _frames(6)
	_walk(key)

func _robots(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	RobotsScreen.open(_root.get_modal_stack(), _root.get_app_state(), _root.ceremonies)
	await _frames(6)
	_walk(key)

func _life(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_root.get_acquisition().open_life("measure")
	await _frames(6)
	_walk(key)

# ------------------------------------------------------------------ measure ----

func _walk(key: String) -> void:
	var stack: Array = [_sub]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children(true))
		var texs: Array = []
		var sz := Vector2.ZERO
		if n is TextureRect or n is NinePatchRect:
			texs = [n.texture]
			sz = (n as Control).get_global_rect().size
		elif n is TextureButton:
			texs = [n.texture_normal, n.texture_pressed, n.texture_hover, n.texture_disabled, n.texture_focused]
			sz = (n as Control).get_global_rect().size
		elif n is Sprite2D and n.texture != null:
			texs = [n.texture]
			sz = n.texture.get_size() * (n as Sprite2D).get_global_transform().get_scale().abs()
		for t in texs:
			_record(key, t, sz.abs() * _scale, (n as CanvasItem).is_visible_in_tree())

func _record(key: String, t: Texture2D, sz: Vector2, shown: bool) -> void:
	if t is AtlasTexture:
		t = (t as AtlasTexture).atlas
	if t == null or not t.resource_path.begins_with(F):
		return
	var p := t.resource_path.trim_prefix(F)
	_loaded[key][p] = t.get_width() * t.get_height() * 4
	var e: Dictionary = _report[key].get(p, {})
	if e.is_empty():
		var src := _png_size(t.resource_path)
		e = {"max_side_px": 0, "max_w": 0, "max_h": 0, "source_w": src.x, "source_h": src.y,
			"size_limit": _size_limit(t.resource_path), "visible": false}
		_report[key][p] = e
	e["visible"] = e["visible"] or shown
	if sz.x <= 0.0 or sz.y <= 0.0:
		return   # loaded, size 0
	e["max_w"] = maxi(e["max_w"], ceili(sz.x))
	e["max_h"] = maxi(e["max_h"], ceili(sz.y))
	e["max_side_px"] = maxi(e["max_w"], e["max_h"])

## Source PNG dimensions from the IHDR header (big-endian width/height at bytes 16..23).
static func _png_size(path: String) -> Vector2i:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	f.big_endian = true
	f.seek(16)
	var w := f.get_32()
	return Vector2i(w, f.get_32())

static func _size_limit(path: String) -> int:
	var c := ConfigFile.new()
	if c.load(path + ".import") != OK:
		return 0
	return int(c.get_value("params", "process/size_limit", 0))

# ------------------------------------------------------------------ fixture ----

func _boot(tag: String, phys: Vector2i) -> void:
	_shutdown()
	var lv := _logical(phys)
	_scale = float(phys.x) / float(lv.x)
	_sub = SubViewport.new()
	_sub.size = lv
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m22_026_measure_%s_%d.save" % [tag.replace("@", "_"), Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _play(key: String, phys: Vector2i):
	await _boot(key, phys)
	_root.get_modal_stack().clear("measure")
	_root.play_current_frontier()
	await _frames(6)
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	return h

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

## Same as tests/m49_responsive_matrix.gd `_logical`.
static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
