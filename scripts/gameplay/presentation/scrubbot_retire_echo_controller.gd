extends Node
## ScrubbotRetireEchoController — preload this script
## (res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd) rather than
## relying on global class_name lookup (AL-001).
##
## M32 — PRESENTATION-ONLY Scrubbot arrival / disappearance echo. Listens to the
## authoritative M20 committed-clear notification (CompleteClearingLoop.authenticated_clear)
## as a pure observer and spawns ONE short detached Scrubby echo at the exact cleared
## logical cell, which shrinks + fades quickly and frees itself (M32 prompt §9).
##
## It owns NO gameplay identity: no reservation, no claim, no agent ownership, emits no
## gameplay signal, mutates no BoardState/candidate/reservation/slot/supply/solver/
## terminal truth. The authoritative M20 finalize is NEVER delayed to wait for this echo
## (the echo is detached and outlives nothing gameplay). A rolled-back / rejected / reset
## clear NEVER emits authenticated_clear, so an echo is impossible on a non-committed
## clear (M32 audit §5).
##
## This mirrors the accepted M31 CleaningEffectsController observer pattern exactly, so
## it coexists with — rather than duplicates — the M31 puff/sparkle cue: the M31 cue is a
## small clean puff on the CleaningFxLayer (under agents); this echo is the vanishing bot
## silhouette on a RetireFxLayer (above agents). Neither is a reward explosion (§9/§12).
##
## Pooling: NOT used (M32 prompt §14 — pool only if profiling proves it). One small
## Sprite2D per committed clear, freed on expiry, with a hard concurrency cap as a
## presentation safety valve that NEVER blocks/queues/delays a clear.

const ScrubbotVisual = preload("res://scripts/gameplay/presentation/scrubbot_visual.gd")

## Hard cap on simultaneous echoes (presentation protection only). A suppressed echo is
## dropped deterministically and counted; it never affects gameplay.
const MAX_ACTIVE_ECHOES := 16

## Short presentation lifetime (seconds). Kept brief so the disappearance reads as a poof,
## not a celebration.
const LIFETIME := 0.28
## Echo footprint in CELL units (slightly smaller than the live travel body) and how far
## it shrinks over its life.
const ECHO_SPAN_CELLS := 1.6
const SHRINK := 0.5

var _layer: Node2D = null
var _board = null
var _enabled: bool = true

## Active echo records: {"node": Sprite2D, "elapsed": float, "base": Vector2}.
var _active: Array = []
var _peak_active: int = 0
var _suppressed: int = 0

## Bind the presentation retire layer + board (read-only index->cell position). Returns
## false if either is missing; the caller treats a false bind as "no echoes", never a
## gameplay failure. Re-bindable — clears any active echoes.
func bind(retire_layer: Node2D, board) -> bool:
	clear_all()
	if retire_layer == null or not is_instance_valid(retire_layer) or board == null:
		_layer = null
		_board = null
		return false
	_layer = retire_layer
	_board = board
	return true

func is_bound() -> bool:
	return _layer != null and is_instance_valid(_layer) and _board != null

# ------------------------------------------------------------ event observer --

## Connected by the host to CompleteClearingLoop.authenticated_clear. Presentation
## observer ONLY: reads target_index for placement, ignores owner/color/agent, mutates
## no gameplay truth. One committed clear -> at most one requested echo.
func _on_authenticated_clear(_owner_id: int, target_index: int, _color_id: int, _agent) -> void:
	request_echo(target_index)

## Core spawn path (also the direct test seam). Honours the enable toggle and the finite
## concurrency cap. Never touches gameplay state.
func request_echo(target_index: int) -> bool:
	if not _enabled:
		return false
	if not is_bound():
		return false
	var pos: Vector2i = _board.get_cell_position(target_index)
	if pos.x < 0:
		return false
	if _active.size() >= MAX_ACTIVE_ECHOES:
		_suppressed += 1
		return false
	if not _spawn(pos):
		return false
	if _active.size() > _peak_active:
		_peak_active = _active.size()
	return true

func _spawn(cell: Vector2i) -> bool:
	var tex := ScrubbotVisual._shared_texture_for_echo()
	if tex == null:
		return false  # fail open: no canonical texture -> no echo, gameplay unaffected.
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.position = Vector2(cell.x + 0.5, cell.y + 0.5)
	var longest: float = float(max(tex.get_width(), tex.get_height(), 1))
	var sc: float = ECHO_SPAN_CELLS / longest
	s.scale = Vector2(sc, sc)
	_layer.add_child(s)
	_active.append({"node": s, "elapsed": 0.0, "base": Vector2(sc, sc)})
	return true

# ------------------------------------------------------------------- aging ----

func _process(delta: float) -> void:
	age(delta)

## Advance every active echo and free any that expired. Public so tests drive aging
## deterministically without real frame timing.
func age(delta: float) -> void:
	if _active.is_empty():
		return
	var i := _active.size() - 1
	while i >= 0:
		var e: Dictionary = _active[i]
		e["elapsed"] += delta
		var p: float = clampf(e["elapsed"] / LIFETIME, 0.0, 1.0)
		var node = e["node"]
		if p >= 1.0 or node == null or not is_instance_valid(node):
			# Immediate free (signal-free leaf) keeps the active set and layer children in
			# lockstep with no one-frame ghost — matters for the retry "zero stale" guarantee.
			if node != null and is_instance_valid(node):
				node.free()
			_active.remove_at(i)
		else:
			node.modulate.a = 1.0 - p
			var shrink: float = 1.0 - SHRINK * p
			node.scale = e["base"] * shrink
		i -= 1

# ----------------------------------------------------------------- toggles ----

## Runtime presentation toggle, default ON. Disabling produces zero NEW echoes and clears
## any active echoes immediately. Never affects clears.
func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		clear_all()

func is_enabled() -> bool:
	return _enabled

# -------------------------------------------------------------- retry / reset --

## Free every active echo now (no delayed callback survives to repopulate a later state).
func clear_all() -> void:
	for e in _active:
		var node = e["node"]
		if node != null and is_instance_valid(node):
			node.free()
	_active.clear()

## M30 Retry / fresh-attempt hygiene (M32 prompt §13): remove stale echoes from the prior
## attempt and reset attempt-scoped diagnostics. Presentation-only; runs from the host's
## post-success restore seam and does NOT weaken the M30 Retry gate.
func reset_for_new_attempt() -> void:
	clear_all()
	_peak_active = 0
	_suppressed = 0

# --------------------------------------------------------------- diagnostics --

func get_active_count() -> int:
	return _active.size()

func get_peak_active() -> int:
	return _peak_active

func get_suppressed_count() -> int:
	return _suppressed
