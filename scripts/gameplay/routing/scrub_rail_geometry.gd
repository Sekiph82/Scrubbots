extends RefCounted
## ScrubRailGeometry — SINGLE-SOURCE Scrubbot Railroad V1 geometry
## (owner-locked `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`).
## Preload this script (AL-001); do not rely on global class_name.
##
## Pure / data-oriented. Depends on nothing but board width/height and the locked
## constants below. It is the ONE place railroad numbers live: both
## ProductionRoutingSystem (HOW / exterior travel) and ScrubRailView
## (presentation) consume this helper — the constants are never duplicated as
## magic numbers elsewhere (criteria M22-V02-033/047).
##
## Owner-locked V1 geometry for a board `W × H` (board boundary x=0..W, y=0..H):
##   - artwork-to-rail inner-edge clearance = exactly 2.0 logical cells;
##   - rail width = 1.0 logical cell;
##   - rail centreline offset = 2.5 logical cells outside each board boundary;
##   - TOP    centreline y=-2.5, x in [-2.5, W+2.5];
##   - BOTTOM centreline y=H+2.5, x in [-2.5, W+2.5];
##   - LEFT   centreline x=-2.5, y in [-2.5, H+2.5];
##   - RIGHT  centreline x=W+2.5, y in [-2.5, H+2.5];
##   - corners at the four centreline intersections.
##
## The rail is a closed rectangular loop. It is presentation/routing space only —
## never a LevelData/BoardState cell layer and never a C01..C16 artwork colour.
## Fail-closed: an invalid (non-finite / < 1) dimension yields is_valid() == false
## and inert geometry, never a fault or a non-finite coordinate.

const CLEARANCE := 2.0        # artwork-to-rail inner-edge clearance (logical cells)
const RAIL_WIDTH := 1.0       # rail visual width (logical cells)
const CENTER_OFFSET := 2.5    # CLEARANCE + RAIL_WIDTH * 0.5 outside each boundary
const EPS := 0.0001

enum Side { BOTTOM, LEFT, RIGHT, TOP }

## Deterministic equal-distance route tie-break order (owner §7): BOTTOM → LEFT →
## RIGHT → TOP. HOW-only; never affects TargetSelector WHAT-order.
const SIDE_TIEBREAK: Array = [Side.BOTTOM, Side.LEFT, Side.RIGHT, Side.TOP]

var _w: float = 0.0
var _h: float = 0.0
var _valid: bool = false

func _init(width, height) -> void:
	if not _is_finite_dim(width) or not _is_finite_dim(height):
		return
	var wf := float(width)
	var hf := float(height)
	if wf < 1.0 or hf < 1.0:
		return
	_w = wf
	_h = hf
	_valid = true

static func _is_finite_dim(v) -> bool:
	if not (v is int or v is float):
		return false
	return is_finite(float(v))

func is_valid() -> bool:
	return _valid

func clearance() -> float:
	return CLEARANCE

func rail_width() -> float:
	return RAIL_WIDTH

func center_offset() -> float:
	return CENTER_OFFSET

func top_y() -> float:
	return -CENTER_OFFSET

func bottom_y() -> float:
	return _h + CENTER_OFFSET

func left_x() -> float:
	return -CENTER_OFFSET

func right_x() -> float:
	return _w + CENTER_OFFSET

func span_min() -> float:
	return -CENTER_OFFSET

func span_max_x() -> float:
	return _w + CENTER_OFFSET

func span_max_y() -> float:
	return _h + CENTER_OFFSET

## The four corner centre points, clockwise from TL: TL, TR, BR, BL.
func corners() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left_x(), top_y()),
		Vector2(right_x(), top_y()),
		Vector2(right_x(), bottom_y()),
		Vector2(left_x(), bottom_y()),
	])

## The four centreline segments as [a, b] pairs, for presentation.
func side_segments() -> Dictionary:
	return {
		Side.TOP: [Vector2(left_x(), top_y()), Vector2(right_x(), top_y())],
		Side.BOTTOM: [Vector2(left_x(), bottom_y()), Vector2(right_x(), bottom_y())],
		Side.LEFT: [Vector2(left_x(), top_y()), Vector2(left_x(), bottom_y())],
		Side.RIGHT: [Vector2(right_x(), top_y()), Vector2(right_x(), bottom_y())],
	}

## Bottom-rail connector entry for a mapped slot x, clamped to the legal bottom-rail
## horizontal span only when necessary (owner §4).
func bottom_entry(x: float) -> Vector2:
	return Vector2(clampf(x, span_min(), span_max_x()), bottom_y())

## Aligned exit point on `side` for a target centre. TOP/BOTTOM share target x;
## LEFT/RIGHT share target y (owner §6).
func exit_point(side: int, target_center: Vector2) -> Vector2:
	match side:
		Side.BOTTOM:
			return Vector2(target_center.x, bottom_y())
		Side.TOP:
			return Vector2(target_center.x, top_y())
		Side.LEFT:
			return Vector2(left_x(), target_center.y)
		Side.RIGHT:
			return Vector2(right_x(), target_center.y)
	return Vector2(target_center.x, bottom_y())

func perimeter() -> float:
	return 2.0 * ((_w + 5.0) + (_h + 5.0))

## Corner arc-length coordinates (clockwise from TL): TL, TR, BR, BL.
func _corner_s() -> Array:
	var a := _w + 5.0
	var b := a + (_h + 5.0)
	var c := b + (_w + 5.0)
	return [0.0, a, b, c]

## Clockwise perimeter arc-length of a point that lies on the rail loop.
func s_of(p: Vector2) -> float:
	if absf(p.y - top_y()) < EPS:
		return clampf(p.x - left_x(), 0.0, _w + 5.0)
	if absf(p.x - right_x()) < EPS:
		return (_w + 5.0) + clampf(p.y - top_y(), 0.0, _h + 5.0)
	if absf(p.y - bottom_y()) < EPS:
		return (_w + 5.0) + (_h + 5.0) + clampf(right_x() - p.x, 0.0, _w + 5.0)
	return 2.0 * (_w + 5.0) + (_h + 5.0) + clampf(bottom_y() - p.y, 0.0, _h + 5.0)

## Point at clockwise perimeter arc-length s.
func point_at_s(s: float) -> Vector2:
	var per := perimeter()
	if per <= 0.0:
		return Vector2(left_x(), top_y())
	s = fposmod(s, per)
	var a := _w + 5.0
	var b := a + (_h + 5.0)
	var c := b + (_w + 5.0)
	if s <= a:
		return Vector2(left_x() + s, top_y())
	if s <= b:
		return Vector2(right_x(), top_y() + (s - a))
	if s <= c:
		return Vector2(right_x() - (s - b), bottom_y())
	return Vector2(left_x(), bottom_y() - (s - c))

## Shortest rail travel from point `a` to point `b` (both on the rail loop).
## Returns { "points": PackedVector2Array of the corner waypoints strictly between
## a and b along the shorter arc, in travel order, "dist": arc length }. Side
## changes therefore happen only through corners (owner §5).
func rail_path(a: Vector2, b: Vector2) -> Dictionary:
	var per := perimeter()
	var sa := s_of(a)
	var sb := s_of(b)
	var cw := fposmod(sb - sa, per)   # forward (increasing s)
	var ccw := per - cw
	var out := PackedVector2Array()
	if cw <= ccw:
		var mids: Array = []
		for cs in _corner_s():
			var rel := fposmod(cs - sa, per)
			if rel > EPS and rel < cw - EPS:
				mids.append({"r": rel, "s": cs})
		mids.sort_custom(func(x, y): return x["r"] < y["r"])
		for e in mids:
			out.append(point_at_s(e["s"]))
		return {"points": out, "dist": cw}
	else:
		var mids2: Array = []
		for cs in _corner_s():
			var rel := fposmod(sa - cs, per)
			if rel > EPS and rel < ccw - EPS:
				mids2.append({"r": rel, "s": cs})
		mids2.sort_custom(func(x, y): return x["r"] < y["r"])
		for e in mids2:
			out.append(point_at_s(e["s"]))
		return {"points": out, "dist": ccw}
