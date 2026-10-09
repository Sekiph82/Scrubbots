extends RefCounted
## PackRouteProbe — TEST-ONLY (M43-C005F-PHASE3-QA-R01). Deterministic mid-route geometry probe
## for the shipping Standard / Premium pack CardView, replacing frame-sampled observation
## (a loaded headless scheduler can step a card from route 0 straight to route 1).
##
## probe(): drives the PRODUCTION CardView `route` setter to a strictly intermediate value,
## reads the resulting face centre / visibility, then restores route 0.0 (route < 1 never emits
## `arrived`, so the real routing that follows is untouched). No shipping code is changed.
## mid_ok(): the travel predicate; it rejects a card stuck at its slot, a card jumped to its
## destination, and a card heading to the OTHER destination (sensitivity proven by callers).

const PROBE_ROUTE := 0.5
const EPS := 2.0   ## px tolerance (layer space)

## {ok, slot, dest, mid, visible, restored} for one CardView at AWAIT_ROUTE.
static func probe(cv) -> Dictionary:
	var start: Vector2 = cv.face_center()
	var out := {"slot": cv.slot_point(), "dest": cv.destination_point(), "start": start}
	cv.route = PROBE_ROUTE
	out["mid"] = cv.face_center()
	out["visible"] = cv.is_visible_in_tree() and cv.modulate.a > 0.5
	cv.route = 0.0
	out["restored"] = cv.face_center().distance_to(start) < 0.01 and cv.route == 0.0
	return out

## True when `mid` lies strictly between `slot` and `own` on that segment (not at either end),
## is closer to `own` than the start, and is NOT on the slot -> `other` path.
static func mid_ok(slot: Vector2, start: Vector2, own: Vector2, other: Vector2, mid: Vector2) -> bool:
	var seg := own - slot
	if seg.length() <= EPS:
		return false
	var f := (mid - slot).dot(seg) / seg.length_squared()
	var on_own := _perp(slot, own, mid) <= EPS
	var strictly_between := f > 0.05 and f < 0.95 and mid.distance_to(slot) > EPS and mid.distance_to(own) > EPS
	var closer := mid.distance_to(own) < start.distance_to(own)
	var wrong := other.distance_to(own) > EPS and _perp(slot, other, mid) <= EPS and _perp(slot, own, other) > EPS
	return on_own and strictly_between and closer and not wrong

## Synthetic mis-routes the predicate must reject (sensitivity): stuck at the slot, jumped to the
## destination, and the same travel aimed at the other destination.
static func rejects_misroutes(slot: Vector2, start: Vector2, own: Vector2, other: Vector2) -> bool:
	var t := 1.0 - (1.0 - PROBE_ROUTE) * (1.0 - PROBE_ROUTE)
	return not mid_ok(slot, start, own, other, slot) \
		and not mid_ok(slot, start, own, other, own) \
		and (other.distance_to(own) <= EPS or not mid_ok(slot, start, own, other, slot.lerp(other, t)))

static func _perp(a: Vector2, b: Vector2, p: Vector2) -> float:
	var d := b - a
	if d.length() <= 0.0001:
		return p.distance_to(a)
	return absf(d.cross(p - a)) / d.length()
