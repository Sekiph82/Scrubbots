extends Node2D
## ScrubRailView — reusable Scrubbot Railroad V1 presentation component.
## Preload/instantiate the scene `scenes/components/ui/gameplay/scrub_rail_view.tscn`
## (AL-001). Presentation ONLY: it consumes the single-source ScrubRailGeometry and
## owns no TargetSelector / BoardState / reservation / clearing / slot-model truth
## (criteria M22-V02-049/050).
##
## It draws in board-local cell units; the parent (shared with BoardPresentation /
## AgentLayer) applies the board cell-size scale, so the rail aligns exactly with
## the rendered board, tracks one-logical-cell rail width, and never distorts the
## board aspect ratio. Identical for every level (it never inspects level subject).
##
## M28-C002-C001 (Gameplay V02): production skin from the approved Railroad V1 art
## (`assets/ui/final/gameplay/railroad/*`): chained straight rail segments whose tube is
## exactly one logical cell wide on every centreline, glowing energy nodes at the four
## corners, and slot connectors. Connector segments are SUPPLIED by the screen from the
## same mapping the runtime route uses (SlotOriginProvider origin -> geometry
## bottom_entry), so every drawn connector is the real slot->bottom-rail travel line.
## Falls back to the procedural dark-slate/cyan track if the art cannot load.

const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")

const RAIL_COLOR := Color(0.16, 0.19, 0.25, 1.0)   # dark slate metallic track (fallback)
const RAIL_EDGE := Color(0.30, 0.35, 0.44, 1.0)    # lighter metallic edge line (fallback)
const ACCENT := Color(0.20, 0.85, 0.95, 0.90)      # restrained cyan guide energy

const RAIL_ART := "res://assets/ui/final/gameplay/railroad/rail_straight_horizontal.png"
const NODE_ART := "res://assets/ui/final/gameplay/railroad/rail_energy_node.png"
const CONNECTOR_ART := "res://assets/ui/final/gameplay/railroad/rail_slot_connector.png"
## Fraction of the straight-rail art height occupied by the tube body: the tube (not the
## end-cap flanges) is scaled to exactly RAIL_WIDTH logical cells.
const RAIL_TUBE_FRAC := 0.435
const NODE_CELLS := 2.2          # corner energy node diameter (logical cells)
const CONNECTOR_WIDTH := 0.9     # connector drawn a little lighter/thinner than the loop

static var _mip_cache: Dictionary = {}

var _geom
var _w: int = 0
var _h: int = 0
var _connectors: Array = []      # [[Vector2 origin, Vector2 bottom_entry], ...] board-local
var _rail_tex: Texture2D
var _node_tex: Texture2D
var _conn_tex: Texture2D

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_rail_tex = _mipmapped(RAIL_ART)
	_node_tex = _mipmapped(NODE_ART)
	_conn_tex = _mipmapped(CONNECTOR_ART)

## Large approved art is shown heavily downscaled; build a mipmapped copy once per path
## so it stays smooth (the approved source file is only read, never written).
static func _mipmapped(path: String) -> Texture2D:
	if _mip_cache.has(path):
		return _mip_cache[path]
	var tex := load(path) as Texture2D
	var out: Texture2D = tex
	if tex != null:
		var img := tex.get_image()
		if img != null and not img.is_empty():
			if img.is_compressed():
				img.decompress()
			img.generate_mipmaps()
			out = ImageTexture.create_from_image(img)
	_mip_cache[path] = out
	return out

## Bind the rail to a board size. Rebuilds the single-source geometry and redraws.
func configure(width: int, height: int) -> void:
	_w = width
	_h = height
	_geom = ScrubRailGeometry.new(width, height)
	queue_redraw()

func get_geometry():
	return _geom

## Slot connectors as board-local [origin, bottom_entry] pairs (one per visible slot).
func set_connectors(segments: Array) -> void:
	_connectors = segments.duplicate(true)
	queue_redraw()

func get_connectors() -> Array:
	return _connectors.duplicate(true)

func is_art_skinned() -> bool:
	return _rail_tex != null and _node_tex != null and _conn_tex != null

func _draw() -> void:
	if _geom == null or not _geom.is_valid():
		return
	for seg in _connectors:
		_draw_connector(seg[0], seg[1])
	if is_art_skinned():
		_draw_skinned()
	else:
		_draw_procedural()

func _draw_skinned() -> void:
	var segs: Dictionary = _geom.side_segments()
	for side in segs.keys():
		var ab = segs[side]
		_draw_rail_run(ab[0], ab[1])
	var d := NODE_CELLS
	for c in _geom.corners():
		draw_texture_rect(_node_tex, Rect2(c - Vector2(d, d) * 0.5, Vector2(d, d)), false)

## Straight run from a to b: whole approved segments chained end to end (their flanges
## read as couplings), stretched so an integer count exactly spans the centreline.
func _draw_rail_run(a: Vector2, b: Vector2) -> void:
	var length := a.distance_to(b)
	if length <= 0.0:
		return
	var ts: Vector2 = _rail_tex.get_size()
	var art_h: float = _geom.rail_width() / RAIL_TUBE_FRAC      # whole art height in cells
	var art_len: float = art_h * ts.x / ts.y
	var n := maxi(int(round(length / art_len)), 1)
	var seg_len := length / float(n)
	draw_set_transform(a, (b - a).angle(), Vector2.ONE)
	for i in range(n):
		draw_texture_rect(_rail_tex, Rect2(i * seg_len, -art_h * 0.5, seg_len, art_h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Connector from the slot spawn origin to its bottom-rail entry (real travel line).
func _draw_connector(origin: Vector2, entry: Vector2) -> void:
	var length := origin.distance_to(entry)
	if length <= 0.0:
		return
	if _conn_tex == null:
		draw_line(origin, entry, RAIL_COLOR, CONNECTOR_WIDTH, true)
		draw_line(origin, entry, ACCENT, CONNECTOR_WIDTH * 0.15, true)
		return
	# Art is vertical with the chevrons pointing up (slot -> rail): local +y runs from
	# the rail entry down to the slot origin.
	draw_set_transform(entry, (origin - entry).angle() - PI * 0.5, Vector2.ONE)
	draw_texture_rect(_conn_tex, Rect2(-CONNECTOR_WIDTH * 0.5, 0.0, CONNECTOR_WIDTH, length), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_procedural() -> void:
	var rw: float = _geom.rail_width()
	var segs: Dictionary = _geom.side_segments()
	# Track body (all four sides), one logical-cell wide.
	for side in segs.keys():
		var ab = segs[side]
		draw_line(ab[0], ab[1], RAIL_COLOR, rw, true)
	# Thin metallic edge highlight + restrained cyan centreline accent.
	for side in segs.keys():
		var ab = segs[side]
		draw_line(ab[0], ab[1], RAIL_EDGE, rw * 0.22, true)
		draw_line(ab[0], ab[1], ACCENT, rw * 0.10, true)
	# Rounded mechanical corners + cyan guide nodes (visual caps only).
	for c in _geom.corners():
		draw_circle(c, rw * 0.5, RAIL_COLOR)
		draw_circle(c, rw * 0.20, ACCENT)
