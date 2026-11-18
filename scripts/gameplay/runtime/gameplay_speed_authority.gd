extends RefCounted
## GameplaySpeedAuthority — M29 owner-locked production gameplay-speed authority.
## Preload this script (res://scripts/gameplay/runtime/gameplay_speed_authority.gd);
## do not rely on global class_name (AL-001).
##
## Owner rule: coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md. Speeds: 1x, the paid/manual
## 2x, and the free automatic endgame 3x (SB-TF-02, owner 2026-11-18: once the last Supply
## batch is in the slots). This authority is the single source of truth for the current
## gameplay speed FACTOR and the derived scheduler cadence interval. It is a plain
## gameplay-domain value object: NO Godot Node, NO Engine.time_scale, NO global
## application timing. The runtime controller reads factor()/cadence_interval() and
## scales ITS OWN scheduler clock + agent travel; unrelated app/UI/monetization clocks
## are never touched (owner rule §4).
##
## 2x / 3x mean temporal playback only: factor 2.0 (3.0) halves (thirds) cadence_interval()
## and doubles (triples) the travel delta the runtime feeds agents. It changes NO gameplay truth (ordering,
## accounting, targets, routes, reservations, clear identity) — that lives entirely in
## the accepted M23–M27/M19/M20 engines, which this object never touches.
##
## A new level / full reset restores 1x (owner rule §6) at THIS authority. The production
## host then applies the owner's timed-2x cross-level default on top of that reset
## (coordination/OWNER_TIMED_2X_CROSS_LEVEL_RUNTIME_V01.md): while a timed entitlement still
## has wall-clock time left, a newly built / restarted attempt is set to 2x by the host
## (ProductionGameplayHost._apply_default_speed); this object stays entitlement-agnostic.
## Pause is tracked by the
## runtime controller, not here: pause overrides speed but preserves the selected
## speed across resume (owner rule §5).

signal speed_changed(factor: float)

const FACTOR_1X := 1.0
const FACTOR_2X := 2.0
## Free automatic endgame speed-up (SB-TF-02): distinct from the paid/manual 2x.
const FACTOR_AUTO_3X := 3.0
## Seconds between scheduler waves at 1x: exactly 1/3 s (M29-C002 owner tempo retune;
## historical baseline was 0.5 s). 2x = 1/6 s. Kept as an exact quotient, never 0.33.
const DEFAULT_BASE_INTERVAL := 1.0 / 3.0

var _base_interval: float = DEFAULT_BASE_INTERVAL
var _is_2x: bool = false
var _is_auto_3x: bool = false

## `base_interval` is the deterministic 1x cadence period (seconds/step). Must be a
## finite positive number; a malformed value falls back to the default.
func _init(base_interval: float = DEFAULT_BASE_INTERVAL) -> void:
	if is_finite(base_interval) and base_interval > 0.0:
		_base_interval = base_interval

## Current temporal factor: 1.0 at 1x, 2.0 at paid/manual 2x, 3.0 in the free auto mode
## (auto wins when both are set).
func factor() -> float:
	if _is_auto_3x:
		return FACTOR_AUTO_3X
	return FACTOR_2X if _is_2x else FACTOR_1X

## The paid/manual 2x state (not the free auto 3x).
func is_2x() -> bool:
	return _is_2x

func is_auto_3x() -> bool:
	return _is_auto_3x

func base_interval() -> float:
	return _base_interval

## Scheduler cadence period at the current speed: base at 1x, EXACTLY half at 2x, a third
## in the auto 3x mode.
func cadence_interval() -> float:
	return _base_interval / factor()

## Set the paid/manual 2x state explicitly; this also leaves the free auto 3x mode. Emits
## speed_changed only on an actual factor change, so a redundant set is a no-op side-effect.
func set_2x(value: bool) -> void:
	_set_state(value, false)

## Free automatic endgame speed-up (authoritative M23-exhausted): 3x over whatever 2x state
## is held; idempotent.
func set_auto_3x(value: bool) -> void:
	_set_state(_is_2x, value)

func _set_state(two: bool, auto3: bool) -> void:
	var before := factor()
	_is_2x = two
	_is_auto_3x = auto3
	if factor() != before:
		speed_changed.emit(factor())

## Raw temporal toggle seam. M29 uses this for deterministic/debug evidence. Economy V1
## shipping UI must gate a manual request through SpeedEntitlementService before calling
## this seam; the authoritative M23-exhausted auto 3x calls set_auto_3x(true) for free.
## Any speed-up (2x or auto 3x) toggles back to 1x, 1x toggles to 2x. Returns is_2x().
func toggle() -> bool:
	set_2x(factor() == FACTOR_1X)
	return _is_2x

## Full reset / new level: restore 1x. Emits speed_changed only if it was faster, so a
## stale callback from a prior 2x session cannot silently re-emit on a fresh 1x one.
func reset() -> void:
	set_2x(false)
