extends Node2D
## RouteDebugOverlay — preload this script
## (res://scripts/debug/route_debug_overlay.gd) rather than relying on global
## class_name lookup (AL-001).
##
## M16 — GENERIC, debug-only visualization of any RouteResult. It knows nothing
## about the routing algorithm: it consumes a RouteResult ONLY and draws what
## the result says. It never computes a route, never retargets, never mutates
## BoardState, and is not production gameplay UI (ADR-024).
##
## Board-local route coordinates are scaled to pixels for display only, with an
## optional caller-supplied cell_pixels/origin — that mapping is diagnostic and
## has no bearing on the resolution-independent route data.

const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

## Diagnostic-only board-local -> pixel mapping (does not affect route data).
var cell_pixels: float = 24.0
var pixel_origin: Vector2 = Vector2(40, 40)
var polyline_color: Color = Color(0.2, 0.8, 1.0)
var start_color: Color = Color(0.3, 1.0, 0.4)
var end_color: Color = Color(1.0, 0.5, 0.2)
var failure_color: Color = Color(1.0, 0.3, 0.3)
var marker_radius: float = 5.0

var _model: Dictionary = build_draw_model(null)

## Build the pure draw-state description of a RouteResult. Static and side-effect
## free so it is directly testable headlessly (no live CanvasItem draw context).
## For a successful route it exposes the polyline, start and end markers; for a
## failure it exposes success=false plus the stable failure reason to display.
static func build_draw_model(result) -> Dictionary:
	if result == null or not result.success:
		var reason: StringName = &"NO_RESULT"
		if result != null:
			reason = result.failure_reason
		return {
			"success": false,
			"failure_reason": reason,
			"target_index": (result.target_index if result != null else -1),
			"polyline": PackedVector2Array(),
			"start": null,
			"end": null,
		}
	var pts: PackedVector2Array = result.get_points()
	return {
		"success": true,
		"failure_reason": RouteResult.FailureReason.NONE,
		"target_index": result.target_index,
		"polyline": pts,
		"start": pts[0],
		"end": pts[pts.size() - 1],
	}

## Set the route to visualize and request a redraw. Consumes RouteResult only.
func set_route(result) -> void:
	_model = build_draw_model(result)
	queue_redraw()

## Current draw model (for tests / inspection).
func get_draw_model() -> Dictionary:
	return _model.duplicate()

func _to_px(p: Vector2) -> Vector2:
	return pixel_origin + p * cell_pixels

func _draw() -> void:
	if not _model.get("success", false):
		draw_string(ThemeDB.fallback_font, Vector2(10, 20),
			"NO ROUTE: %s" % String(_model.get("failure_reason", &"?")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, failure_color)
		return
	var poly: PackedVector2Array = _model["polyline"]
	var px := PackedVector2Array()
	for p in poly:
		px.append(_to_px(p))
	if px.size() >= 2:
		draw_polyline(px, polyline_color, 2.0)
	draw_circle(_to_px(_model["start"]), marker_radius, start_color)
	draw_circle(_to_px(_model["end"]), marker_radius, end_color)
