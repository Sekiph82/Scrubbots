extends SceneTree
## M28-C002-C002-R01 — visual remediation evidence
## (OWNER_GAMEPLAY_STATIC_SHELL_VISUAL_ACCEPTANCE_V01: S1-A S2-B S3-B S4-A S5-A S6-C + items A/B).
## Real app root / ProductionGameplayHost / GameplayScreen on real levels.
##
## Run: godot --headless --path . -s res://tests/m28_c002_c002_r01_visual.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")
const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RetireEcho = preload("res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const BAKED_TEXT := Rect2(37, 1200, 150, 117)

var EXPECTED_CASES := [
	"body_span_2_4", "route_unchanged_by_scale", "echo_proportional", "bubble_live_text",
	"short_phone_hitboxes", "ad_invisible_reserved", "accepted_styling_preserved",
	"square_only_production", "masters_unchanged", "no_accumulation",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	await _boot_main(2)
	await _body_span_2_4()
	await _route_unchanged_by_scale()
	await _echo_proportional()
	await _bubble_live_text()
	await _short_phone_hitboxes()
	await _ad_invisible_reserved()
	await _accepted_styling_preserved()
	_square_only_production()
	_masters_unchanged()
	await _no_accumulation()
	_shutdown()
	MainScript.boot_opening_override = -1
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _new_sub(size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)

func _boot_main(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_new_sub(size)
	var path := "user://m28r01_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _boot_gen(cols: int, size: Vector2i) -> void:
	_new_sub(size)
	var path := "user://m28r01_g%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var app = AppState.new(path)
	app.progression.debug_set_current_level(1)
	_host = ProductionGameplayHost.new()
	_host.app_state = app
	_host.auto_build = false
	_host.column_count = cols
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(_host)
	_host.build()
	await _settle()
	_host.get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	elif _host != null and is_instance_valid(_host):
		_host.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _screen():
	return _host.get_screen()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _clicks() -> Array:
	return SupplyPlanLoader.load_plan(_host.supply_plan_path)["plan"]["intendedColumnClicks"] if not String(_host.supply_plan_path).is_empty() else []

func _agents() -> Array:
	return _host.get_agent_layer().get_children().filter(func(a): return a is ScrubbotAgent)

## Drive with the owner plan (or greedy fronts) for `ticks` fixed runtime ticks.
func _drive(ticks: int, per_tick: Callable = Callable()) -> Array:
	var clicks := _clicks()
	var i := 0
	var trace: Array = []
	for t in range(ticks):
		if _host.get_slots().rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and _host.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(_host.get_supply().get_column_count()):
					if _host.get_input_controller().activate_front(col).get("ok", false):
						break
		_host.get_runtime().tick(0.05)
		if per_tick.is_valid():
			per_tick.call()
		var pos: Array = _agents().map(func(a): return a.position)
		trace.append([pos, _host.get_board().count_cells_by_state(0)])
		if _host.get_completion().is_terminal():
			break
	return trace

# ------------------------------------------------------------------ cases ----

func _body_span_2_4() -> void:
	print("[mini Scrubby 2.4-cell span]")
	_ok(is_equal_approx(ScrubbotVisual.BODY_SPAN_CELLS, 2.4), "ScrubbotVisual.BODY_SPAN_CELLS == 2.4 (was 1.8)")
	_drive(60)
	var spans: Array = []
	for a in _agents():
		for v in a.get_children():
			if v is ScrubbotVisual and v.has_body():
				var body: Sprite2D = v.get_child(0)
				var tex: Vector2 = body.texture.get_size()
				spans.append(maxf(tex.x, tex.y) * v._base_scale.x)
	_ok(spans.size() > 5 and spans.all(func(x): return absf(x - 2.4) < 1e-4), "every live agent body spans exactly 2.4 board cells (%d agents)" % spans.size())
	var cell: float = _screen().get_cell_size()
	_ok(spans.size() > 0 and absf(spans[0] * cell - 2.4 * cell) < 1e-3, "cell-relative: %.1f px on a %.1f px cell (no fixed pixel size)" % [2.4 * cell, cell])
	_complete("body_span_2_4")

## The visual never drives movement: identical trajectories whether bodies render at 2.4
## or are forced back to the old 1.8 look every tick.
func _route_unchanged_by_scale() -> void:
	print("[route truth unchanged by body scale]")
	await _boot_main(2)
	var trace_a: Array = _drive(400)
	await _boot_main(2)
	var shrink := func():
		for a in _agents():
			for v in a.get_children():
				if v is ScrubbotVisual and v.has_body():
					var tx: Vector2 = v.get_child(0).texture.get_size()
					v._base_scale = Vector2.ONE * (1.8 / maxf(tx.x, tx.y))   # the old 1.8-cell look
	var trace_b: Array = _drive(400, shrink)
	var same: bool = trace_a.size() == trace_b.size()
	for t in range(mini(trace_a.size(), trace_b.size())):
		same = same and trace_a[t] == trace_b[t]
	_ok(same and trace_a.size() == 400, "400 ticks: agent positions + board truth identical with 2.4 vs 1.8 bodies")
	_complete("route_unchanged_by_scale")

func _echo_proportional() -> void:
	print("[retire echo proportional]")
	_ok(is_equal_approx(RetireEcho.ECHO_SPAN_CELLS, 2.1), "ECHO_SPAN_CELLS == 2.1 (was 1.6)")
	var ratio: float = RetireEcho.ECHO_SPAN_CELLS / ScrubbotVisual.BODY_SPAN_CELLS
	_ok(absf(ratio - 1.6 / 1.8) < 0.02, "echo/live ratio %.3f keeps the previous %.3f" % [ratio, 1.6 / 1.8])
	await _boot_main(2)
	var fx = _host.get_retire_echo()
	var spans: Array = []
	var active0: int = _host.get_board().count_cells_by_state(0)
	var layer: Node2D = _host.get_screen().get_presentation().get_retire_fx_layer()
	# Sample freshly spawned echoes (scale is the base span at spawn, shrinking with age).
	_drive(900, func():
		for e in fx._active:
			if e["elapsed"] == 0.0 and is_instance_valid(e["node"]):
				var tx: Vector2 = e["node"].texture.get_size()
				spans.append(maxf(tx.x, tx.y) * e["base"].x))
	_ok(_host.get_board().count_cells_by_state(0) < active0 and fx.get_peak_active() > 0, "real authenticated clears spawned echoes (peak %d, active board %d -> %d)" % [fx.get_peak_active(), active0, _host.get_board().count_cells_by_state(0)])
	_ok(spans.size() > 5 and spans.all(func(x): return absf(x - 2.1) < 1e-4), "every spawned echo spans 2.1 cells at birth (%d sampled)" % spans.size())
	_ok(layer != null and layer.get_children().size() <= RetireEcho.MAX_ACTIVE_ECHOES, "echo layer bounded by the unchanged cap")
	_ok(is_equal_approx(RetireEcho.LIFETIME, 0.28) and RetireEcho.MAX_ACTIVE_ECHOES == 16, "echo lifetime / cap unchanged (0.28 s / 16)")
	_complete("echo_proportional")

func _bubble_live_text() -> void:
	print("[speech bubble live text]")
	for size in [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1290, 2796), Vector2i(1536, 2048), Vector2i(1440, 3200)]:
		await _boot_main(2, size)
		var s = _screen()
		var labels: Array = s.get_bubble_labels()
		var head: Label = labels[0]
		var body: Label = labels[1]
		var ok: bool = head.text == UiText.t("GP_BUBBLE_HEADLINE") and body.text == UiText.t("GP_BUBBLE_INSTRUCTION")
		ok = ok and head.is_visible_in_tree() and body.is_visible_in_tree()
		ok = ok and _near(head.get_global_rect(), s.ref_rect_to_global(Shell.rect(GameplayScreen.BUBBLE_HEADLINE_REF)), 1.5)
		ok = ok and _near(body.get_global_rect(), s.ref_rect_to_global(Shell.rect(GameplayScreen.BUBBLE_INSTRUCTION_REF)), 1.5)
		var mask: Rect2 = s.get_bubble_mask().get_global_rect()
		ok = ok and mask.encloses(head.get_global_rect()) and mask.encloses(body.get_global_rect())
		ok = ok and mask.encloses(s.ref_rect_to_global(BAKED_TEXT)) and s.bubble_text_fits()
		_ok(ok, "%dx%d: headline + instruction are live UiText, on the master transform, inside the mask, fit without clipping (font %d / %d px)" % [size.x, size.y, head.get_theme_font_size("font_size"), body.get_theme_font_size("font_size")])
		# Re-layout must be idempotent (a stale cached Label minimum once let a second pass keep
		# the unshrunk font — seen on the +1 Slot shell switch).
		var fonts := [head.get_theme_font_size("font_size"), body.get_theme_font_size("font_size")]
		for _k in range(3):
			s._layout_bubble_text()
		_ok([head.get_theme_font_size("font_size"), body.get_theme_font_size("font_size")] == fonts and s.bubble_text_fits(), "%dx%d: repeated bubble layout keeps the same fitted fonts %s" % [size.x, size.y, str(fonts)])
		_host.get_economy().boosters.add_charges("plus_one_slot", 1)
		_host.request_booster("plus_one_slot")
		await _settle()
		_ok(s.get_shell_id().begins_with("6slot") and [head.get_theme_font_size("font_size"), body.get_theme_font_size("font_size")] == fonts and s.bubble_text_fits(), "%dx%d: +1 Slot shell switch keeps the same bubble fonts %s" % [size.x, size.y, str(fonts)])
	for cols in [4, 5]:
		await _boot_gen(cols, Vector2i(1080, 2160))
		var s2 = _screen()
		_ok(s2.get_shell_id() == "5slot_%dcol" % cols and s2.bubble_text_fits() and s2.get_bubble_labels()[0].is_visible_in_tree(), "%s: bubble text fits" % s2.get_shell_id())
		_host.get_economy().boosters.add_charges("plus_one_slot", 1)
		_host.request_booster("plus_one_slot")
		await _settle()
		_ok(s2.get_shell_id() == "6slot_%dcol" % cols and s2.bubble_text_fits(), "%s: bubble text fits" % s2.get_shell_id())
	await _boot_main(2)
	_ok(not UiText.EN.values().any(func(v): return String(v).to_lower().find("same colored") != -1), "obsolete same-coloured-tile instruction not in the copy table")
	_complete("bubble_live_text")

## S2-B: at 1080x1920 the painted cells are ~83 px; invisible front hitboxes grow to 88 px,
## never overlap, never cover preview cells; visuals unchanged.
func _short_phone_hitboxes() -> void:
	print("[short-phone hitboxes]")
	for spec in [[2, 0], [0, 4], [0, 5]]:
		if spec[0] > 0:
			await _boot_main(spec[0], Vector2i(1080, 1920))
		else:
			await _boot_gen(spec[1], Vector2i(1080, 1920))
		var s = _screen()
		var sp = s.get_supply_panel()
		var id: String = s.get_shell_id()
		var ok := true
		var worst := 999.0
		var hits: Array = []
		for c in range(sp.get_column_count()):
			var tile: Rect2 = sp.get_column_row_panels(c)[0].get_global_rect()
			var hit: Rect2 = sp.get_front_hit_rect(c)
			hits.append(hit)
			worst = minf(worst, minf(hit.size.x, hit.size.y))
			ok = ok and hit.encloses(tile) and _near(tile, s.ref_rect_to_global(Shell.supply_cell(id, c, 0)), 3.0 * s.get_shell_scale() + 1.5)
			for r in [1, 2]:
				var pv: Rect2 = sp.get_column_row_panels(c)[r].get_global_rect()
				ok = ok and not hit.intersects(pv) and sp.get_column_row_panels(c)[r].mouse_filter == Control.MOUSE_FILTER_IGNORE
		for c in range(hits.size() - 1):
			ok = ok and not hits[c].intersects(hits[c + 1])
		_ok(ok and worst >= UiTokens.TOUCH_MIN - 0.01, "%s @1080x1920: painted cell ~%.0f px, invisible front hitbox >= %d px (min %.1f), no overlap, previews untouched, visuals on the baked cells" % [id, sp.get_column_row_panels(0)[0].size.x, UiTokens.TOUCH_MIN, worst])
	# A press/release in the expanded margin (outside the painted tile) activates that front.
	await _boot_main(2, Vector2i(1080, 1920))
	var sp2 = _screen().get_supply_panel()
	var hit_node: Control = sp2.get_column_row_panels(1)[0].get_node("HitArea")
	var tile2: Rect2 = sp2.get_column_row_panels(1)[0].get_global_rect()
	var margin_pt: Vector2 = Vector2(tile2.get_center().x, tile2.position.y - 1.0)
	var got := [-1]
	var cb := func(c): got[0] = c
	sp2.front_batch_activated.connect(cb)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = margin_pt
		hit_node.gui_input.emit(e)
	sp2.front_batch_activated.disconnect(cb)
	_ok(hit_node.get_global_rect().has_point(margin_pt) and not tile2.has_point(margin_pt) and got[0] == 1, "tap just outside the painted cell (inside the invisible margin) activates that front")
	_ok(hit_node.get_class() == "Control" and hit_node.get_children().is_empty() and hit_node.top_level, "hit area is an invisible plain Control (draws nothing)")
	_complete("short_phone_hitboxes")

func _ad_invisible_reserved() -> void:
	print("[AD hidden, region reserved]")
	await _boot_main(2)
	var s = _screen()
	_ok(not s.is_ad_placeholder_visible(), "no visible AD band / label")
	_ok(s.has_ad_region() and _near(s.get_ad_region_rect(), s.ref_rect_to_global(Shell.rect(Shell.AD)), 1.5), "reserved ad region kept at the bottom band (M57 anchor)")
	_ok(s.get_booster_row_rect().end.y <= s.get_ad_region_rect().position.y + 1.0, "boosters still above the reserved band")
	_complete("ad_invisible_reserved")

func _accepted_styling_preserved() -> void:
	print("[S1-A / S4-A / S5-A preserved]")
	var s = _screen()
	_ok((s.get_node("Background") as ColorRect).color == GameplayScreen.FILL, "S1-A dark navy surround")
	_ok(s.get_pause_button().get_theme_stylebox("normal") is StyleBoxEmpty and s.get_speed_label() == "2x", "S4-A native Pause glyph / live 2x text, no extra chrome")
	var sp = s.get_supply_panel()
	# C004: the front rim / ACTIVE rim are carried by the shared ColorBatchTile (was a per-panel StyleBox).
	var ftile = sp.get_column_row_panels(0)[0].get_node("Tile")
	_ok(ftile.is_active_style() and not sp.get_column_row_panels(0)[1].get_node("Tile").is_active_style() and sp.get_column_row_panels(0)[1].modulate == Color(0.62, 0.62, 0.70, 0.85), "S5-A cyan front rim, dimmed previews")
	_drive(10)
	var active_ok := false
	for v in s.get_five_slot_strip().get_slot_views():
		if v.get_state() == "ACTIVE":
			active_ok = v.get_tile().is_active_style()
	_ok(active_ok, "S5-A cyan rim on ACTIVE slots")
	_complete("accepted_styling_preserved")

func _square_only_production() -> void:
	print("[S6-C square-only production]")
	var cat = LevelCatalog.new()
	var r = cat.load_manifest()
	_ok(r.ok and cat.size() >= 10 and cat.get_entries_ordered().all(func(e): return e.width == e.height), "production catalog loads; every entry is square")
	_ok(LevelCatalog.square_shell_error(32, 32) == "" and LevelCatalog.square_shell_error(24, 40).find("square boards only") != -1, "non-square production boards are rejected with an explicit S6-C reason")
	_ok(cat.validate_all().ok, "batch revalidation passes with the square gate")
	_complete("square_only_production")

func _masters_unchanged() -> void:
	print("[six masters byte-identical]")
	var ok := true
	for id in Shell.SHA256:
		ok = ok and FileAccess.get_sha256(Shell.texture_path(id)) == Shell.SHA256[id]
	_ok(ok, "all six master PNG hashes unchanged")
	_complete("masters_unchanged")

func _no_accumulation() -> void:
	print("[no accumulation]")
	await _boot_main(2, Vector2i(1080, 1920))
	var s = _screen()
	await _settle()
	var n0 := _count(s)
	var hits0: int = s.find_children("HitArea", "", true, false).size()
	for _i in range(4):
		_host.get_economy().boosters.add_charges("plus_one_slot", 1)
		_host.request_booster("plus_one_slot")
		await _settle()
		_host.retry()
		await _settle()
	_ok(_count(s) == n0 and s.find_children("HitArea", "", true, false).size() == hits0 and hits0 == 3, "4x (+1 Slot, retry): nodes %d -> %d, HitAreas %d -> %d" % [n0, _count(s), hits0, s.find_children("HitArea", "", true, false).size()])
	_complete("no_accumulation")

# ------------------------------------------------------------------ helpers ----

func _near(a: Rect2, b: Rect2, tol: float) -> bool:
	return a.position.distance_to(b.position) <= tol and a.end.distance_to(b.end) <= tol

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

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
	print("M28-C002-C002-R01 visual remediation evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
