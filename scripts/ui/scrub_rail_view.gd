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
## board aspect ratio. Consistent dark-slate metallic track with restrained cyan
## guide nodes and rounded mechanical corners, identical for every level (it never
## inspects level subject/theme). Zero generated assets — pure procedural 2D — so
## it is trivially reskinnable later without touching routing/target truth.

const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")

const RAIL_COLOR := Color(0.16, 0.19, 0.25, 1.0)   # dark slate metallic track
const RAIL_EDGE := Color(0.30, 0.35, 0.44, 1.0)    # lighter metallic edge line
const ACCENT := Color(0.20, 0.85, 0.95, 0.90)      # restrained cyan guide energy

var _geom
var _w: int = 0
var _h: int = 0

## Bind the rail to a board size. Rebuilds the single-source geometry and redraws.
func configure(width: int, height: int) -> void:
	_w = width
	_h = height
	_geom = ScrubRailGeometry.new(width, height)
	queue_redraw()

func get_geometry():
	return _geom

func _draw() -> void:
	if _geom == null or not _geom.is_valid():
		return
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
	# Rounded mechanical corners + cyan guide nodes (motion path stays inside the
	# railroad envelope; these are visual caps only).
	for c in _geom.corners():
		draw_circle(c, rw * 0.5, RAIL_COLOR)
		draw_circle(c, rw * 0.20, ACCENT)
