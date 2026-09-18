extends SceneTree
## M28-C001 V01 — production gameplay screen responsive LAYOUT viewport harness.
##
## Hosts ONE real production GameplayScreen inside a single SubViewport and RESIZES
## that viewport (and reconfigures the board fixture) across the required matrix — a
## reliable headless mechanism that drives real container/anchor layout, does not
## touch project.godot, and additionally proves resize/re-layout re-derives geometry
## and coordinate mapping (criteria L). Every assertion reads REAL post-layout rects.
##
## Coverage:
##  - required viewport matrix + short 16:9 + tablet portrait;
##  - COMPACT/NORMAL/TALL mode record;
##  - board dominance / aspect-correct / rectangular-not-stretched;
##  - five read-only slots, 3/4/5 supply columns, exactly 3 visible rows;
##  - composition contract (no Goal/Moves, no Level rail, Scrubby low-left,
##    speech above, props right, 4 boosters, pause|ad|speed-up order,
##    speed control 1x/2x presentation states);
##  - synthetic non-zero safe-area insets, no clipping / notch overlap;
##  - board-size matrix (small/medium/hard/59x59 + two rectangular);
##  - BoardRenderer coordinate round-trip after responsive scaling.
##
## Emits deterministic metrics JSON + Markdown and attempts PNG captures under
## coordination/sessions/M28-C001/evidence/. Generated captures are TEST artifacts,
## never AI-generated art.
##
## Run:  godot --headless --path . -s res://tests/m28_gameplay_layout_smoke.gd
## Exits 0 on success, 1 on any failure.

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const EVIDENCE_DIR := "res://coordination/sessions/M28-C001/evidence"
const EPS := 1.0e-3
const TOUCH_MIN := 88.0
const VIEW_W := 24
const VIEW_H := 40

const MATRIX := [
	Vector2i(1080, 2160),
	Vector2i(1170, 2532),
	Vector2i(1290, 2796),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
	Vector2i(1080, 1920),  # shorter 16:9 portrait
	Vector2i(1536, 2048),  # tablet portrait
]

# Board-size layout fixtures (difficulty labels here are LAYOUT ONLY, not V1 authority).
const BOARD_MATRIX := [
	{"name": "small_20x20", "w": 20, "h": 20, "cols": 3},
	{"name": "medium_40x40", "w": 40, "h": 40, "cols": 4},
	{"name": "hardsize_50x50", "w": 50, "h": 50, "cols": 5},
	{"name": "very_large_59x59", "w": 59, "h": 59, "cols": 5},
	{"name": "rect_40x53", "w": 40, "h": 53, "cols": 4},
	{"name": "rect_24x40", "w": 24, "h": 40, "cols": 3},
]

var _fail := 0
var _total := 0
var _metrics: Array = []
var _sub: SubViewport
var _screen

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_DIR))
	_sub = SubViewport.new()
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub.size = MATRIX[0]
	get_root().add_child(_sub)
	_screen = GameplayScreen.new()
	_sub.add_child(_screen)
	_configure_board(VIEW_W, VIEW_H, 4)
	await _settle()

	for size in MATRIX:
		await _run_viewport_case(size)
	await _run_safe_area_case()
	for spec in BOARD_MATRIX:
		await _run_board_size_case(spec)

	_write_evidence()
	_done()

func _settle() -> void:
	await process_frame
	await process_frame
	_screen.relayout()
	await process_frame

func _configure_board(w: int, h: int, cols: int) -> void:
	var level = BoardDebugFixtures.make_level(w, h)
	var board = BoardDebugFixtures.make_board(w, h)
	var snaps := _make_snapshots(level, cols)
	_screen.configure(board, level.palette, snaps["slots"], snaps["supply"])

func _mode_name(m: int) -> String:
	match m:
		ResponsiveLayout.LayoutMode.COMPACT: return "COMPACT"
		ResponsiveLayout.LayoutMode.TALL: return "TALL"
		_: return "NORMAL"

## Detached authentic snapshots for a level with `columns` supply columns.
func _make_snapshots(level, columns: int) -> Dictionary:
	var supply = BatchSupplyGenerator.generate(level, columns, 3, 4242)
	var supply_snap: Array = supply.player_snapshot() if supply != null else []
	# Five slots: mix of EMPTY / ACTIVE(in-flight) / WAITING to exercise every state.
	var s_active = SlotBatchState.make_occupied("m28_a", 0, 6, 0)
	s_active.apply_commit()  # committed 1 -> in-flight presentation
	var s_wait = SlotBatchState.make_occupied("m28_w", 1, 4, 1)
	s_wait.set_state(SlotBatchState.WAITING)
	var slot_snap: Array = [
		s_active.to_dict(),
		s_wait.to_dict(),
		SlotBatchState.make_empty().to_dict(),
		SlotBatchState.make_occupied("m28_c", 2, 3, 2).to_dict(),
		SlotBatchState.make_empty().to_dict(),
	]
	return {"slots": slot_snap, "supply": supply_snap}

func _run_viewport_case(size: Vector2i) -> void:
	_sub.size = size
	await _settle()
	var screen = _screen
	var tag := str(size)

	_ok(_sub.size == size, "%s: subviewport at requested size" % tag)
	var view_rect := Rect2(Vector2.ZERO, Vector2(size))
	var safe: Rect2 = screen.get_safe_rect()
	_ok(view_rect.encloses(safe) or _rect_approx_inside(safe, view_rect), "%s: safe rect inside viewport" % tag)

	var board_region: Rect2 = screen.get_board_region_rect()
	var batch: Rect2 = screen.get_batch_region_rect()
	var booster: Rect2 = screen.get_booster_row_rect()
	var bottom: Rect2 = screen.get_bottom_row_rect()
	var board_rect: Rect2 = screen.get_board_rect()

	# Board dominance: board region is the largest band, larger than every other.
	_ok(board_region.get_area() > batch.get_area(), "%s: board region > batch region" % tag)
	_ok(board_region.get_area() > booster.get_area(), "%s: board region > booster row" % tag)
	_ok(board_region.get_area() > bottom.get_area(), "%s: board region > bottom row" % tag)
	# Board aspect preserved (rectangular 24x40 not stretched to square).
	var aspect: float = board_rect.size.x / max(board_rect.size.y, 1.0)
	_ok(absf(aspect - float(VIEW_W) / float(VIEW_H)) < 0.02, "%s: board aspect preserved (%.4f)" % [tag, aspect])
	_ok(_rect_approx_inside(board_rect, board_region), "%s: rendered board inside its region" % tag)

	# Five read-only slots.
	var strip = screen.get_five_slot_strip()
	_ok(strip.get_slot_count() == 5, "%s: exactly five slot views" % tag)
	_ok(not (strip is Button), "%s: five-slot strip is not a Button" % tag)
	var slot_views: Array = strip.get_slot_views()
	var slots_no_button := true
	for v in slot_views:
		if v is Button or v.has_signal("slot_activated"):
			slots_no_button = false
	_ok(slots_no_button, "%s: no slot view is a Button / emits slot_activated" % tag)

	# Supply: 4 columns, exactly 3 visible rows each, hidden depth not exposed.
	var supply = screen.get_supply_panel()
	_ok(supply.get_column_count() == 4, "%s: supply shows 4 columns" % tag)
	_ok(supply.get_visible_row_count() == 3, "%s: supply exactly 3 visible rows" % tag)
	var rows_ok := true
	for c in range(supply.get_column_count()):
		if supply.get_column_row_panels(c).size() != 3:
			rows_ok = false
	_ok(rows_ok, "%s: every supply column renders exactly 3 row panels" % tag)

	# Composition contract.
	_ok(not screen.has_goal_moves_panel(), "%s: Goal/Moves panel absent" % tag)
	_ok(not screen.has_level_lock_rail(), "%s: Level/lock rail absent" % tag)
	_ok(screen.get_booster_count() == 4, "%s: exactly four boosters" % tag)

	var pause: Rect2 = screen.get_pause_rect()
	var ad: Rect2 = screen.get_ad_placeholder_rect()
	var speed: Rect2 = screen.get_speed_control_rect()
	_ok(pause.position.x < ad.position.x and ad.position.x < speed.position.x,
		"%s: bottom order pause < ad < speed-up" % tag)
	_ok(pause.size.x >= TOUCH_MIN and pause.size.y >= TOUCH_MIN, "%s: pause >= TOUCH_MIN" % tag)
	_ok(speed.size.x >= TOUCH_MIN and speed.size.y >= TOUCH_MIN, "%s: speed control >= TOUCH_MIN" % tag)
	# Speed control 1x/2x presentation states (distinct/readable); default new session = 1x.
	_ok(screen.get_speed_state() == "1x", "%s: speed control defaults to 1x" % tag)
	screen.set_speed_2x(true)
	_ok(screen.get_speed_state() == "2x", "%s: speed control presents 2x state" % tag)
	screen.set_speed_2x(false)
	_ok(screen.get_speed_state() == "1x", "%s: speed control returns to 1x state" % tag)

	var scrubby: Rect2 = screen.get_scrubby_anchor_rect()
	var speech: Rect2 = screen.get_speech_anchor_rect()
	var props: Rect2 = screen.get_props_anchor_rect()
	_ok(speech.position.y < scrubby.position.y, "%s: speech anchor above Scrubby" % tag)
	_ok(scrubby.position.x <= batch.position.x + batch.size.x * 0.5, "%s: Scrubby anchored left" % tag)
	_ok(scrubby.get_center().y > batch.get_center().y, "%s: Scrubby anchored low in batch region" % tag)
	_ok(props.get_center().x > screen.get_supply_panel_rect().get_center().x, "%s: cleaning props anchored right" % tag)

	# No clipping: every essential region inside the safe rect.
	var essentials := {
		"board": board_rect, "five_slots": screen.get_five_slot_strip_rect(),
		"supply": screen.get_supply_panel_rect(), "boosters": booster,
		"pause": pause, "speed": speed, "ad": ad}
	var clip_ok := true
	for k in essentials.keys():
		if not _rect_approx_inside(essentials[k], safe):
			clip_ok = false
	_ok(clip_ok, "%s: no essential region clips outside safe rect" % tag)

	# Coordinate round-trip after responsive scaling.
	var rt := _coordinate_roundtrip(screen, VIEW_W, VIEW_H)
	_ok(rt["max_err"] < EPS, "%s: coord round-trip max err %.6f < eps" % [tag, rt["max_err"]])

	# Attempt a PNG capture (test artifact; blank in pure headless is acceptable).
	var png_saved: bool = await _try_capture("viewport_%dx%d.png" % [size.x, size.y])

	_metrics.append({
		"kind": "viewport", "viewport": [size.x, size.y],
		"mode": _mode_name(screen.get_layout_mode()),
		"safe_rect": _r(safe), "board_region": _r(board_region), "board_rect": _r(board_rect),
		"board_logical": [VIEW_W, VIEW_H], "cell_size": screen.get_cell_size(),
		"batch_region": _r(batch), "five_slot_rect": _r(screen.get_five_slot_strip_rect()),
		"supply_rect": _r(screen.get_supply_panel_rect()), "supply_columns": supply.get_column_count(),
		"supply_visible_rows": supply.get_visible_row_count(),
		"booster_row": _r(booster), "booster_count": screen.get_booster_count(),
		"bottom_row": _r(bottom), "pause": _r(pause), "ad": _r(ad), "speed": _r(speed),
		"scrubby_anchor": _r(scrubby), "speech_anchor": _r(speech), "props_anchor": _r(props),
		"coord_roundtrip_max_err": rt["max_err"], "coord_samples": rt["samples"],
		"clip_ok": clip_ok, "png_saved": png_saved,
	})

func _run_safe_area_case() -> void:
	var size := Vector2i(1080, 2160)
	var insets := {"left": 48, "top": 96, "right": 48, "bottom": 132}
	_sub.size = size
	_screen.set_synthetic_safe_insets(insets["left"], insets["top"], insets["right"], insets["bottom"])
	await _settle()

	var inner := Rect2(Vector2(insets["left"], insets["top"]),
		Vector2(size.x - insets["left"] - insets["right"], size.y - insets["top"] - insets["bottom"]))
	var essentials := [_screen.get_board_rect(), _screen.get_five_slot_strip_rect(),
		_screen.get_supply_panel_rect(), _screen.get_booster_row_rect(),
		_screen.get_pause_rect(), _screen.get_speed_control_rect()]
	var contained := true
	for r in essentials:
		if not _rect_approx_inside(r, inner):
			contained = false
	_ok(contained, "safe-area: all essential regions inside non-zero inner safe rect (no notch overlap)")
	await _try_capture("safe_area_insets_1080x2160.png")
	_metrics.append({"kind": "safe_area", "viewport": [size.x, size.y], "insets": insets,
		"inner_safe": _r(inner), "essentials_contained": contained})
	_screen.set_synthetic_safe_insets(0, 0, 0, 0)

func _run_board_size_case(spec: Dictionary) -> void:
	var size := Vector2i(1080, 2160)
	var w: int = spec["w"]
	var h: int = spec["h"]
	_sub.size = size
	_configure_board(w, h, spec["cols"])
	await _settle()
	var screen = _screen
	var tag: String = spec["name"]

	var board_rect: Rect2 = screen.get_board_rect()
	var board_region: Rect2 = screen.get_board_region_rect()
	var batch: Rect2 = screen.get_batch_region_rect()
	# Aspect preserved / rectangular not stretched.
	var want := float(w) / float(h)
	var got: float = board_rect.size.x / max(board_rect.size.y, 1.0)
	_ok(absf(got - want) < 0.02, "%s: aspect preserved want %.4f got %.4f" % [tag, want, got])
	_ok(_rect_approx_inside(board_rect, board_region), "%s: board inside region" % tag)
	_ok(board_region.get_area() > batch.get_area(), "%s: board region dominant" % tag)
	# Protected batch region never collapses below minimum.
	_ok(batch.size.y >= float(UiTokens.BATCH_REGION_MIN_HEIGHT) - 1.0,
		"%s: batch region >= protected minimum (%.0f)" % [tag, batch.size.y])
	_ok(screen.get_supply_panel_rect().size.x >= float(UiTokens.SUPPLY_PANEL_MIN_WIDTH) - 1.0,
		"%s: supply >= protected width" % tag)
	_ok(screen.get_supply_panel().get_column_count() == spec["cols"], "%s: supply columns == %d" % [tag, spec["cols"]])

	var rt := _coordinate_roundtrip(screen, w, h)
	_ok(rt["max_err"] < EPS, "%s: coord round-trip max err %.6f" % [tag, rt["max_err"]])
	await _try_capture("board_%s.png" % tag)

	_metrics.append({"kind": "board_size", "name": tag, "viewport": [size.x, size.y],
		"board_logical": [w, h], "cell_size": screen.get_cell_size(),
		"board_rect": _r(board_rect), "board_region": _r(board_region),
		"batch_region": _r(batch), "supply_columns": screen.get_supply_panel().get_column_count(),
		"coord_roundtrip_max_err": rt["max_err"]})

## Round-trip: logical cell center -> global -> board-local, compared to the
## expected board-local cell-unit center (x+0.5, y+0.5). Corners + center + fixed
## deterministic interior cells.
func _coordinate_roundtrip(screen, w: int, h: int) -> Dictionary:
	var cells: Array = [
		Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1),
		Vector2i(w / 2, h / 2), Vector2i(w / 3, h / 4), Vector2i(w - 2, h / 2), Vector2i(1, h - 2)]
	var max_err := 0.0
	for c in cells:
		var g: Vector2 = screen.cell_center_to_global(c.x, c.y)
		var back: Vector2 = screen.global_to_board_local(g)
		var expected := Vector2(c.x + 0.5, c.y + 0.5)
		max_err = maxf(max_err, back.distance_to(expected))
	return {"max_err": max_err, "samples": cells.size()}

func _try_capture(filename: String) -> bool:
	await process_frame
	var tex := _sub.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.get_width() == 0:
		return false
	var path := "%s/%s" % [EVIDENCE_DIR, filename]
	return img.save_png(path) == OK

func _rect_approx_inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 1.0 \
		and inner.position.y >= outer.position.y - 1.0 \
		and inner.end.x <= outer.end.x + 1.0 \
		and inner.end.y <= outer.end.y + 1.0

func _r(rect: Rect2) -> Array:
	return [snappedf(rect.position.x, 0.01), snappedf(rect.position.y, 0.01),
		snappedf(rect.size.x, 0.01), snappedf(rect.size.y, 0.01)]

func _write_evidence() -> void:
	var payload := {"milestone": "M28-C001 V01", "eps": EPS, "touch_min": TOUCH_MIN,
		"total_checks": _total, "failures": _fail, "metrics": _metrics}
	var f := FileAccess.open("%s/viewport_metrics.json" % EVIDENCE_DIR, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()
	var md := FileAccess.open("%s/viewport_metrics.md" % EVIDENCE_DIR, FileAccess.WRITE)
	if md != null:
		md.store_string(_markdown(payload))
		md.close()

func _markdown(payload: Dictionary) -> String:
	var out := "# M28-C001 V01 — Viewport Layout Evidence\n\n"
	out += "Generated by `tests/m28_gameplay_layout_smoke.gd` (deterministic; test artifacts only).\n\n"
	out += "Total checks: %d — Failures: %d\n\n" % [payload["total_checks"], payload["failures"]]
	out += "## Viewport matrix\n\n"
	out += "| viewport | mode | board region | board rect | cell | batch h | boosters | coord err | png |\n"
	out += "|---|---|---|---|---|---|---|---|---|\n"
	for m in _metrics:
		if m.get("kind") != "viewport":
			continue
		out += "| %s | %s | %s | %s | %.1f | %.0f | %d | %.6f | %s |\n" % [
			str(m["viewport"]), m["mode"], str(m["board_region"]), str(m["board_rect"]),
			m["cell_size"], m["batch_region"][3], m["booster_count"],
			m["coord_roundtrip_max_err"], str(m["png_saved"])]
	out += "\n## Board-size matrix (layout fixtures only)\n\n"
	out += "| fixture | logical | cell | board rect | board region | batch h | cols | coord err |\n"
	out += "|---|---|---|---|---|---|---|---|\n"
	for m in _metrics:
		if m.get("kind") != "board_size":
			continue
		out += "| %s | %s | %.1f | %s | %s | %.0f | %d | %.6f |\n" % [
			m["name"], str(m["board_logical"]), m["cell_size"], str(m["board_rect"]),
			str(m["board_region"]), m["batch_region"][3], m["supply_columns"],
			m["coord_roundtrip_max_err"]]
	for m in _metrics:
		if m.get("kind") == "safe_area":
			out += "\n## Synthetic safe-area insets\n\n"
			out += "insets=%s inner_safe=%s essentials_contained=%s\n" % [
				str(m["insets"]), str(m["inner_safe"]), str(m["essentials_contained"])]
	return out

func _ok(cond: bool, msg: String) -> void:
	_total += 1
	if cond:
		print("PASS: %s" % msg)
	else:
		_fail += 1
		print("FAIL: %s" % msg)

func _done() -> void:
	if _screen != null:
		_screen.free()
	if _sub != null:
		_sub.free()
	print("==== M28 layout smoke: %d checks, %d failures ====" % [_total, _fail])
	quit(1 if _fail > 0 else 0)
