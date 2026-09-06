extends Node2D
## ScrubbotAgent — preload this script
## (res://scripts/gameplay/agents/scrubbot_agent.gd) rather than relying on
## global class_name lookup (AL-001 / ADR-009).
##
## M18 — the lightweight, single-in-flight visual mover for one Scrubbot. It
## CONSUMES an already-decided, already-valid successful RouteResult and walks
## that route in board-local cell coordinates. It is deliberately dumb:
##
## It does NOT
##   - select a target (M15 TargetSelector did that);
##   - reserve a target (M15 ReservationState);
##   - compute a route (M16/M17 RoutingSystem did that);
##   - mutate BoardState (ACTIVE->CLEARED is M19/M20 orchestration);
##   - release ReservationState;
##   - own scoring;
##   - carry a cell color / resource / payload back to a slot;
##   - return to its slot;
##   - dispatch another bot.
##
## Assigned color is IDENTITY / presentation metadata only (never a carried
## resource). See docs/01_GAMEPLAY_SPEC.md and CLAUDE.md §3.
##
## Coordinate space is board-local cell units (route_request.gd): the board
## top-left is Vector2(0,0), one cell is 1x1, a cell center is (x+0.5, y+0.5).
## The agent sets its own Node2D `position` in this SAME board-local space; the
## presentation/container layer (e.g. a scaled parent Node2D) maps board-local
## units to screen pixels. Screen pixels are NEVER baked into movement truth.
##
## Movement is deterministic and route-distance based (NOT per-frame point
## skipping): total travelled distance is accumulated and the position is
## resolved by walking the polyline, so any delta size — including one that
## spans several segments — lands correctly and the final point is snapped
## exactly. Movement is driven by _process(delta) once MOVING, and equally by
## an explicit advance(delta) call for deterministic headless testing.
##
## The agent owns NO child nodes, tweens or timers, so freeing it at any state
## (moving, cancelled, completed) leaves no orphan nodes (SB-M18-013).

const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

enum State {
	UNASSIGNED, ## no valid assignment yet.
	MOVING,     ## travelling along the route.
	ARRIVED,    ## reached the final route point; completion already emitted.
	CANCELLED,  ## reset/cancelled; will never move or complete again.
}

## Fires exactly once, when route traversal reaches the final point. Carries
## just enough identity for M19/M20 orchestration to act (clear the cell,
## release the reservation, score). The agent itself does none of those.
signal agent_completed(owner_id: int, target_index: int, color_id: int)

const DEFAULT_SPEED := 6.0 ## board-local cells / second.

# --- assigned identity / assignment record (read-only after assign) ----------
var owner_id: int = -1
var color_id: int = -1
var target_index: int = -1
var spawn_origin: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var speed: float = DEFAULT_SPEED

var _state: int = State.UNASSIGNED
var _route_points: PackedVector2Array = PackedVector2Array()
var _seg_len: PackedFloat32Array = PackedFloat32Array()
var _total_len: float = 0.0
var _travelled: float = 0.0
var _completed_emitted: bool = false

## Board-local positions within this tolerance are treated as equal. Route
## coordinates are small integers + 0.5, so this is generous yet safe.
const _MATCH_EPS := 0.001

# ------------------------------------------------------------- assignment ----

## Assign one in-flight movement. `request` is the RouteRequest that produced
## `route_result` (it carries the assigned target_index, spawn origin and
## target endpoint the route must match). Fails closed (returns false, stays
## UNASSIGNED) on any invalid input — an agent never partially assigns.
func assign(a_owner_id: int, a_color_id: int, request, route_result, a_speed: float = DEFAULT_SPEED) -> bool:
	if a_owner_id < 0:
		return false
	# color_id is an index into the level palette (0-based); identity only.
	if a_color_id < 0:
		return false
	if request == null or request.target_index < 0:
		return false
	if route_result == null or not route_result.success:
		return false
	# The route must answer the SAME assigned target (no retarget, ADR-024).
	if route_result.target_index != request.target_index:
		return false
	var pts: PackedVector2Array = route_result.get_points()
	if pts.size() < 2:
		return false
	if not pts[0].is_equal_approx(request.start_position):
		return false
	if not pts[pts.size() - 1].is_equal_approx(request.target_position):
		return false
	if a_speed <= 0.0:
		return false

	owner_id = a_owner_id
	color_id = a_color_id
	target_index = request.target_index
	spawn_origin = request.start_position
	target_position = request.target_position
	speed = a_speed
	_route_points = pts # already a detached duplicate (RouteResult.get_points()).
	_precompute_segments()
	_travelled = 0.0
	_completed_emitted = false
	_state = State.MOVING
	position = _route_points[0] # begins exactly at the spawn origin.
	queue_redraw()
	return true

func _precompute_segments() -> void:
	_seg_len = PackedFloat32Array()
	_total_len = 0.0
	for i in range(_route_points.size() - 1):
		var d := _route_points[i].distance_to(_route_points[i + 1])
		_seg_len.append(d)
		_total_len += d

# --------------------------------------------------------------- movement ----

func _process(delta: float) -> void:
	if _state == State.MOVING:
		advance(delta)

## Advance movement by `delta` seconds. No-op unless MOVING (so a cancelled or
## completed agent never moves again). Deterministic: accumulates route-distance
## and resolves the position from the polyline, so large deltas cross multiple
## segments correctly and arrival snaps exactly to the final point.
func advance(delta: float) -> void:
	if _state != State.MOVING:
		return
	if delta <= 0.0:
		return # zero (or negative) delta does not move.
	_travelled += speed * delta
	if _travelled >= _total_len:
		_travelled = _total_len
		position = _route_points[_route_points.size() - 1] # exact endpoint snap.
		_state = State.ARRIVED
		queue_redraw()
		if not _completed_emitted:
			_completed_emitted = true
			agent_completed.emit(owner_id, target_index, color_id)
		return
	position = _position_at(_travelled)
	queue_redraw()

## Board-local position at cumulative distance `dist` along the route polyline.
func _position_at(dist: float) -> Vector2:
	if _route_points.size() < 2:
		return position
	if dist <= 0.0:
		return _route_points[0]
	var remaining := dist
	for i in range(_seg_len.size()):
		var seg := _seg_len[i]
		if remaining <= seg or i == _seg_len.size() - 1:
			if seg <= 0.0:
				return _route_points[i + 1]
			var t: float = clampf(remaining / seg, 0.0, 1.0)
			return _route_points[i].lerp(_route_points[i + 1], t)
		remaining -= seg
	return _route_points[_route_points.size() - 1]

# ----------------------------------------------------------------- cancel ----

## Cancel/reset. Movement stops immediately; no arrival/completion signal will
## fire afterwards; the agent can then be freed safely. Idempotent — calling it
## repeatedly (or after completion) is safe and never re-emits anything.
func cancel() -> void:
	if _state == State.CANCELLED:
		return
	_state = State.CANCELLED
	queue_redraw()

# ------------------------------------------------------------- read-only -----

func get_state() -> int:
	return _state

func is_moving() -> bool:
	return _state == State.MOVING

func has_arrived() -> bool:
	return _state == State.ARRIVED

func is_cancelled() -> bool:
	return _state == State.CANCELLED

## Detached copy of the assigned route — callers can never mutate agent truth.
func get_route_points() -> PackedVector2Array:
	return _route_points.duplicate()

func get_local_position() -> Vector2:
	return position

func get_route_length() -> float:
	return _total_len

func get_progress() -> float:
	if _total_len <= 0.0:
		return 1.0
	return clampf(_travelled / _total_len, 0.0, 1.0)

# ------------------------------------------------------------------ debug -----

## Minimal debug marker in board-local space (radius ~0.3 cell). A scaled parent
## container magnifies it to screen size; the agent bakes no pixels. Colour is a
## deterministic debug hue from color_id (identity presentation only — the agent
## carries no resource). No child node is created for this.
func _draw() -> void:
	var hue: float = fposmod(float(maxi(color_id, 0)) * 0.13, 1.0)
	var c := Color.from_hsv(hue, 0.55, 0.95)
	if _state == State.CANCELLED:
		c = Color(0.5, 0.5, 0.5, 0.6)
	draw_circle(Vector2.ZERO, 0.3, c)
