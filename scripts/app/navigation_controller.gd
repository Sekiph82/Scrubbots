extends RefCounted
## NavigationController — preload
## (res://scripts/app/navigation_controller.gd).
##
## M42 (SB-M42-001) — the ONE app-root-owned navigation authority. Owned by the
## real app root (scripts/app/main.gd) next to the canonical AppState. It holds only
## presentation-route state (which screen is shown, whether the Settings overlay is
## open, the current gameplay attempt id and its terminal latch). It never owns or
## mutates gameplay/save/economy/progression/settings truth.
##
## Routes (closed set — there is NO Level Select route, SB-M42-005):
##   BOOT -> OPENING | HOME
##   OPENING -> HOME
##   HOME -> GAMEPLAY
##   GAMEPLAY -> RESULTS           (authoritative terminal only, once per attempt)
##   GAMEPLAY -> HOME              (pre-action exit only; caller proves it)
##   RESULTS -> HOME | GAMEPLAY    (continue next frontier / retry)
## Settings is an overlay flag, openable only from HOME.
##
## Every transition is deterministic: an illegal edge, an unknown route, a re-entrant
## request (issued from inside a route_changed handler) or a same-route request is
## rejected and changes nothing. Each accepted transition gets a monotonically
## increasing transition id.

signal route_changed(from_route: int, to_route: int, payload: Dictionary)
signal settings_changed(open: bool)

enum Route { BOOT, OPENING, HOME, GAMEPLAY, RESULTS }

const _EDGES := {
	Route.BOOT: [Route.OPENING, Route.HOME],
	Route.OPENING: [Route.HOME],
	Route.HOME: [Route.GAMEPLAY],
	Route.GAMEPLAY: [Route.RESULTS, Route.HOME],
	Route.RESULTS: [Route.HOME, Route.GAMEPLAY],
}

var _route: int = Route.BOOT
var _settings_open := false
var _in_transition := false
var _transition_id := 0
var _attempt_id := 0
var _terminal_latched := false
var _last_payload: Dictionary = {}

func current() -> int:
	return _route

func route_name(r: int = -1) -> String:
	var v := _route if r < 0 else r
	for k in Route:
		if Route[k] == v:
			return k
	return "UNKNOWN"

func transition_id() -> int:
	return _transition_id

func attempt_id() -> int:
	return _attempt_id

func is_settings_open() -> bool:
	return _settings_open

func last_payload() -> Dictionary:
	return _last_payload.duplicate(true)

func can_go(to: int) -> bool:
	return not _in_transition and _EDGES.has(_route) and (_EDGES[_route] as Array).has(to)

## Request a route change. Returns true only when the transition was accepted.
## Entering GAMEPLAY starts a new attempt (new attempt id, terminal latch re-armed).
## Leaving HOME closes the Settings overlay.
func go(to: int, payload: Dictionary = {}) -> bool:
	if typeof(to) != TYPE_INT or not can_go(to):
		return false
	_in_transition = true
	var from := _route
	_route = to
	_transition_id += 1
	_last_payload = payload.duplicate(true)
	if to == Route.GAMEPLAY:
		_attempt_id += 1
		_terminal_latched = false
	if from == Route.HOME and _settings_open:
		_settings_open = false
		settings_changed.emit(false)
	route_changed.emit(from, to, _last_payload.duplicate(true))
	_in_transition = false
	return true

## Authoritative gameplay terminal -> RESULTS, exactly once per attempt. A stale
## attempt id, a repeated terminal callback or a call outside GAMEPLAY is rejected.
func on_gameplay_terminal(attempt: int, status: StringName, level: int) -> bool:
	if _route != Route.GAMEPLAY or attempt != _attempt_id or _terminal_latched:
		return false
	if not can_go(Route.RESULTS):
		return false
	_terminal_latched = true
	return go(Route.RESULTS, {"status": String(status), "level": level, "attempt": attempt})

## RESULTS -> GAMEPLAY for a Retry of the SAME attempt host: re-arms the terminal
## latch under a new attempt id (the host itself performs the transaction-safe retry).
func resume_gameplay_after_retry() -> bool:
	return go(Route.GAMEPLAY, {"retry": true})

func open_settings() -> bool:
	if _in_transition or _route != Route.HOME or _settings_open:
		return false
	_settings_open = true
	settings_changed.emit(true)
	return true

func close_settings() -> bool:
	if not _settings_open:
		return false
	_settings_open = false
	settings_changed.emit(false)
	return true

## Deterministic back (SB-M42-009). Returns the action taken:
##   "close_settings" | "home" | "none".
## GAMEPLAY back is never a free exit: only an explicitly proven pre-action exit may
## return HOME (Economy V1: exit before first real action = no Heart loss); after the
## first action, mid-level exit has no owner-defined economy rule, so back does nothing.
func back(pre_action_exit_allowed: bool = false) -> String:
	if _in_transition:
		return "none"
	if _settings_open:
		close_settings()
		return "close_settings"
	match _route:
		Route.RESULTS:
			return "home" if go(Route.HOME, {"via": "back"}) else "none"
		Route.GAMEPLAY:
			if pre_action_exit_allowed and go(Route.HOME, {"via": "back_pre_action"}):
				return "home"
			return "none"
	return "none"
