extends SceneTree
## M23-C001 V01 — Batch Supply Engine evidence (real Hazard Bot + rectangular + 59x59).
## Gameplay-domain only; loads the real checked-in level through the real LevelLoader,
## generates a deterministic candidate supply, and prints/asserts a compact
## structured trace: dimensions, palette, per-color source vs generated totals
## (exact conservation), seed/config, per-column front + visible preview, and a
## hidden-depth proof (deeper-than-preview entries are not in the player preview).
##
## Run: godot --headless --path . -s res://tests/m23_v01_batch_supply_evidence.gd
## Exits 0 on success, 1 on any failure.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")

const LEVEL_PATH := "res://data/levels/m21_level_001_hazard_bot.json"
const SEED := 20260917
const COLUMNS := 3
const PREVIEW := 3

var _fail := 0

func _initialize() -> void:
	var res = LevelLoader.load_from_path(LEVEL_PATH)
	if not res.is_ok():
		_ok(false, "real Hazard Bot level loads through LevelLoader")
		_done(); return
	var lvl = res.level_data
	print("M23_LEVEL id=%s dims=%dx%d palette_size=%d cell_count=%d" % [lvl.id, lvl.width, lvl.height, lvl.palette.size(), lvl.get_cell_count()])

	var src := BatchSupplyGenerator.color_totals(lvl)
	print("M23_SOURCE_TOTALS %s (sum=%d)" % [str(src), _sum(src)])

	var e = BatchSupplyGenerator.generate(lvl, COLUMNS, PREVIEW, SEED)
	_ok(e != null, "generation succeeds for Hazard Bot (3 columns, preview 3)")
	if e == null:
		_done(); return
	print("M23_CONFIG seed=%d columns=%d preview_depth=%d" % [e.get_seed(), e.get_column_count(), e.get_preview_depth()])

	# Generated per-color totals + exact conservation.
	var snap = e.debug_snapshot()
	var gen := {}
	for c in range(snap["columns"].size()):
		var ids := []
		for d in snap["columns"][c]:
			ids.append("%s(c%d:%d)" % [d["batch_id"], d["color_id"], d["robot_count"]])
			gen[d["color_id"]] = int(gen.get(d["color_id"], 0)) + int(d["robot_count"])
		print("M23_COLUMN %d depth=%d batches=%s" % [c, snap["columns"][c].size(), str(ids)])
	print("M23_GENERATED_TOTALS %s (sum=%d)" % [str(gen), _sum(gen)])

	var conserved := true
	for c in src.keys():
		if int(gen.get(c, 0)) != int(src[c]):
			conserved = false
	_ok(conserved, "exact per-color conservation source==generated")
	_ok(_sum(gen) == lvl.get_cell_count(), "total generated quota == cell count (400)")

	# Per-column front + visible preview; hidden-depth proof.
	var any_hidden := false
	for c in range(COLUMNS):
		var front = e.get_front(c)
		var preview = e.get_preview(c)
		var remaining = e.get_remaining(c)
		var front_id = "none" if front == null else front.get_batch_id()
		print("M23_FRONT col=%d front=%s preview_len=%d remaining=%d" % [c, front_id, preview.size(), remaining])
		_ok(preview.size() <= PREVIEW, "col %d visible preview <= preview depth" % c)
		if remaining > PREVIEW:
			any_hidden = true
			# player_snapshot must expose only the preview slice, never the hidden tail.
			var ps = e.player_snapshot()[c]
			_ok(ps["preview"].size() == PREVIEW and ps["remaining"] == remaining, "col %d hidden entries not leaked (preview=%d, remaining=%d)" % [c, ps["preview"].size(), remaining])
			# Prove a specific deep batch id is NOT in the player preview.
			var deep_id = snap["columns"][c][PREVIEW]["batch_id"]
			var leaked := false
			for d in ps["preview"]:
				if d["batch_id"] == deep_id:
					leaked = true
			_ok(not leaked, "col %d deep batch %s hidden from player preview" % [c, deep_id])
	_ok(any_hidden, "at least one column has hidden depth beyond preview (proof is meaningful)")

	# Determinism: same seed -> identical layout.
	var e2 = BatchSupplyGenerator.generate(lvl, COLUMNS, PREVIEW, SEED)
	_ok(str(e2.debug_snapshot()) == str(snap), "same seed reproduces identical Hazard Bot layout")

	_done()

func _sum(d: Dictionary) -> int:
	var s := 0
	for k in d.keys():
		s += int(d[k])
	return s

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M23 V01 batch supply evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
