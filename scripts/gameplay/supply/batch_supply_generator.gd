extends RefCounted
## BatchSupplyGenerator — M23 deterministic candidate-supply generator. Preload this
## script (res://scripts/gameplay/supply/batch_supply_generator.gd). Gameplay-domain
## only (no UI/board/routing). Derives per-color logical-cell totals from
## LevelData.cells using the existing integer palette IDs, partitions each positive
## total into positive integer batches, distributes them across the configured
## 3/4/5 FIFO columns, and returns a loaded BatchSupplyEngine.
##
## Deterministic for identical (LevelData, column_count, preview_depth, seed): a
## private RNG seeded explicitly (no wall clock, no global RNG). Conservation-exact
## (OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01 §4/§6). Candidates only — M23 does not
## prove solvability (that is M27). Fails closed (returns null) on malformed input.

const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

## Upper bound on batches per color — keeps generation bounded/legal.
const MAX_BATCHES_PER_COLOR := 8

## Deterministic per-color cell totals from LevelData.cells, or {} if the source is
## malformed/foreign (M23 V02, F-M23-V01-STRICT-004). Fails closed BEFORE touching any
## field so a foreign RefCounted/object never raises an uncaught script error. Requires:
## the exact LevelData domain type, positive coherent dimensions, a non-empty palette,
## a packed-int cell array whose length equals get_cell_count(), and every cell palette
## id within range.
static func color_totals(level) -> Dictionary:
	if not (level is LevelData):
		return {}
	if typeof(level.width) != TYPE_INT or typeof(level.height) != TYPE_INT \
			or level.width <= 0 or level.height <= 0:
		return {}
	if typeof(level.palette) != TYPE_PACKED_STRING_ARRAY:
		return {}
	var palette_size: int = level.palette.size()
	if palette_size <= 0:
		return {}
	var cells = level.cells
	if typeof(cells) != TYPE_PACKED_INT32_ARRAY or cells.size() == 0:
		return {}
	if cells.size() != level.get_cell_count():
		return {}
	var totals: Dictionary = {}
	for c in cells:
		if c < 0 or c >= palette_size:
			return {}
		totals[c] = int(totals.get(c, 0)) + 1
	return totals

## Generate a loaded BatchSupplyEngine, or null on any invalid input.
static func generate(level, column_count, preview_depth, seed: int) -> RefCounted:
	var engine = BatchSupplyEngine.create(column_count, preview_depth)
	if engine == null:
		return null
	var totals := color_totals(level)
	if totals.is_empty():
		return null
	var palette_size: int = level.palette.size()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var flat: Array = []  # deterministic append order
	var gidx: int = 0
	var colors := totals.keys()
	colors.sort()  # ascending color id -> deterministic RNG consumption order
	for color in colors:
		var total: int = totals[color]
		var kmax: int = mini(total, MAX_BATCHES_PER_COLOR)
		var k: int = 1 + int(rng.randi() % kmax)
		for p in _partition(total, k):
			var b = ColorBatch.make("B%05d" % gidx, color, p, palette_size)
			if b == null:
				return null
			flat.append(b)
			gidx += 1

	# Distribute across columns in deterministic append order (round-robin).
	var cols: Array = []
	for _i in range(column_count):
		cols.append([])
	for i in range(flat.size()):
		cols[i % column_count].append(flat[i])

	# Atomic candidate commit: queue + seed + palette size become the initial truth
	# together, so reset() restores all three (F-M23-V01-STRICT-003).
	if not engine.load_candidate(cols, seed, palette_size):
		return null
	return engine

## Split T into k positive integers summing exactly to T (base + remainder-front).
## Requires 1 <= k <= T so every part is >= 1; conservation is exact.
static func _partition(total: int, k: int) -> Array:
	var parts: Array = []
	var base: int = total / k
	var rem: int = total % k
	for i in range(k):
		parts.append(base + (1 if i < rem else 0))
	return parts
