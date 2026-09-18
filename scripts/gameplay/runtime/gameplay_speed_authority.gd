extends RefCounted
## GameplaySpeedAuthority — M29 owner-locked production gameplay-speed authority.
## Preload this script (res://scripts/gameplay/runtime/gameplay_speed_authority.gd);
## do not rely on global class_name (AL-001).
##
## Owner rule: coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md. V1 supports EXACTLY two
## speeds — 1x and 2x. This authority is the single source of truth for the current
## gameplay speed FACTOR and the derived scheduler cadence interval. It is a plain
## gameplay-domain value object: NO Godot Node, NO Engine.time_scale, NO global
## application timing. The runtime controller reads factor()/cadence_interval() and
## scales ITS OWN scheduler clock + agent travel; unrelated app/UI/monetization clocks
## are never touched (owner rule §4).
##
## 2x means temporal playback only: factor 2.0 halves cadence_interval() and doubles
## the travel delta the runtime feeds agents. It changes NO gameplay truth (ordering,
## accounting, targets, routes, reservations, clear identity) — that lives entirely in
## the accepted M23–M27/M19/M20 engines, which this object never touches.
##
## A new level / full reset restores 1x (owner rule §6). Pause is tracked by the
## runtime controller, not here: pause overrides speed but preserves the selected
## speed across resume (owner rule §5).

signal speed_changed(factor: float)

const FACTOR_1X := 1.0
const FACTOR_2X := 2.0
const DEFAULT_BASE_INTERVAL := 0.5   # seconds between scheduler steps at 1x

var _base_interval: float = DEFAULT_BASE_INTERVAL
var _is_2x: bool = false

## `base_interval` is the deterministic 1x cadence period (seconds/step). Must be a
## finite positive number; a malformed value falls back to the default.
func _init(base_interval: float = DEFAULT_BASE_INTERVAL) -> void:
	if is_finite(base_interval) and base_interval > 0.0:
		_base_interval = base_interval

## Current temporal factor: 1.0 at 1x, 2.0 at 2x.
func factor() -> float:
	return FACTOR_2X if _is_2x else FACTOR_1X

func is_2x() -> bool:
	return _is_2x

func base_interval() -> float:
	return _base_interval

## Scheduler cadence period at the current speed: base at 1x, EXACTLY half at 2x.
func cadence_interval() -> float:
	return _base_interval / factor()

## Set the speed state explicitly. Emits speed_changed only on an actual change, so a
## redundant set (e.g. an idempotent auto-2x while already 2x) is a no-op side-effect.
func set_2x(value: bool) -> void:
	if value == _is_2x:
		return
	_is_2x = value
	speed_changed.emit(factor())

## Manual 1x <-> 2x toggle (bottom-right control). Returns the new state.
func toggle() -> bool:
	set_2x(not _is_2x)
	return _is_2x

## Full reset / new level: restore 1x. Emits speed_changed only if it was 2x, so a
## stale callback from a prior 2x session cannot silently re-emit on a fresh 1x one.
func reset() -> void:
	set_2x(false)
