extends Node
## CleaningEffectsController — preload this script
## (res://scripts/gameplay/presentation/cleaning_effects_controller.gd) rather than
## relying on global class_name lookup (AL-001).
##
## M31 — PRESENTATION-ONLY cleaning effect. Listens to the authoritative M20
## committed-clear notification (CompleteClearingLoop.authenticated_clear) as a pure
## observer and spawns one short, restrained cleaning cue at the exact cleared logical
## cell. It never writes BoardState, candidates, reservations, claims, slots, supply,
## routing, target selection, scheduler/solver/terminal truth. If the effect cannot be
## shown, gameplay continues unchanged (§2 of the M31 prompt).
##
## Architecture (M31 prompt §4): effects are children of an identity-stable
## CleaningFxLayer (a Node2D created ONCE by BoardPresentation, scaled by the
## renderer's integer cell size, same board-local origin as the AgentLayer). One
## board-local unit == one cell, so an effect placed at cell center (x+0.5, y+0.5) is
## centered on that cell and rescales for free when a responsive relayout rescales the
## layer. No permanent per-cell node ever exists — an effect is created on a committed
## clear and freed when its short lifetime elapses.
##
## Pooling (§8): NOT used. The simplest bounded version (allocate one small Node2D +
## 1-2 Sprite2D per clear, free on expiry, hard cap on simultaneous instances) is
## profiled by tests/m31_scale_59_effects.gd; the cap keeps churn bounded and the
## stress evidence shows no pool is required. See CLAUDE_LOG_V01.md.

const _PUFF_TEX_PATH := "res://assets/ui/final/gameplay/effects/fx_clean_puff.png"
const _SPARKLE_TEX_PATH := "res://assets/ui/final/gameplay/effects/fx_clean_sparkle.png"

## Hard cap on simultaneously-active cleaning effects (presentation protection only —
## NEVER blocks/queues/delays a clear). Conservative mobile-friendly default justified
## by the 59x59 burst stress: real peak concurrent clears on the production stack stays
## far below this even at 2x, so the cap is a safety valve, not a normal-play limiter.
const MAX_ACTIVE_EFFECTS := 24
## Reduced-effects cap (§9): fewer simultaneous instances + a single shorter cue.
const REDUCED_MAX_ACTIVE := 8

## Short presentation lifetimes (seconds). Tuned for readability, not gameplay truth.
const NORMAL_LIFETIME := 0.30
const REDUCED_LIFETIME := 0.18

## Effect footprint in CELL units (the layer already scales by cell size).
const PUFF_SPAN := 1.4
const SPARKLE_SPAN := 0.9
## How much the cue grows over its life (soft expand while fading out).
const GROW := 0.45

var _fx_layer: Node2D = null
var _board = null
var _puff_tex: Texture2D = null
var _sparkle_tex: Texture2D = null

var _enabled: bool = true
var _reduced: bool = false

## Active effect records: {"node": Node2D, "elapsed": float, "lifetime": float,
## "sprites": Array[Sprite2D], "base": Array[Vector2]}. Never exposes gameplay refs.
var _active: Array = []
var _peak_active: int = 0
var _suppressed: int = 0

func _init() -> void:
	# Textures are optional presentation inputs; a missing/failed load must NOT break
	# gameplay — the controller simply shows fewer/no sprites (fail open).
	_puff_tex = load(_PUFF_TEX_PATH) as Texture2D
	_sparkle_tex = load(_SPARKLE_TEX_PATH) as Texture2D

## Bind the presentation FX layer + board (read-only index->position). Returns false if
## either is missing; the caller treats a false bind as "no effects", never a gameplay
## failure. Re-bindable (e.g. if presentation is rebuilt) — clears any active effects.
func bind(fx_layer: Node2D, board) -> bool:
	clear_all()
	if fx_layer == null or not is_instance_valid(fx_layer) or board == null:
		_fx_layer = null
		_board = null
		return false
	_fx_layer = fx_layer
	_board = board
	return true

func is_bound() -> bool:
	return _fx_layer != null and is_instance_valid(_fx_layer) and _board != null

# ------------------------------------------------------------ event observer --

## Connected by the host to CompleteClearingLoop.authenticated_clear. Presentation
## observer ONLY: reads target_index for placement, ignores owner/color/agent, mutates
## no gameplay truth. One committed clear -> at most one requested cue.
func _on_authenticated_clear(_owner_id: int, target_index: int, _color_id: int, _agent) -> void:
	request_effect(target_index)

## Core spawn path (also the direct test seam). Honours enable toggle and the finite
## concurrency cap; a suppressed cue increments the diagnostic counter and is dropped
## deterministically. Never touches gameplay state.
func request_effect(target_index: int) -> bool:
	if not _enabled:
		return false
	if not is_bound():
		return false
	var pos: Vector2i = _board.get_cell_position(target_index)
	if pos.x < 0:
		return false
	if _active.size() >= _effective_cap():
		_suppressed += 1
		return false
	_spawn(pos)
	if _active.size() > _peak_active:
		_peak_active = _active.size()
	return true

func _spawn(cell: Vector2i) -> void:
	var container := Node2D.new()
	container.position = Vector2(cell.x + 0.5, cell.y + 0.5)
	# FX reads over the cleared (transparent) cell; the layer sits under the AgentLayer
	# so a moving Scrubbot is never hidden by the cue (§5 z-order).
	_fx_layer.add_child(container)

	var sprites: Array = []
	var base: Array = []
	_add_sprite(container, _puff_tex, PUFF_SPAN, sprites, base)
	if not _reduced:
		_add_sprite(container, _sparkle_tex, SPARKLE_SPAN, sprites, base)

	_active.append({
		"node": container,
		"elapsed": 0.0,
		"lifetime": REDUCED_LIFETIME if _reduced else NORMAL_LIFETIME,
		"sprites": sprites,
		"base": base,
	})

func _add_sprite(container: Node2D, tex: Texture2D, span_cells: float, sprites: Array, base: Array) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	var tw: float = float(max(tex.get_width(), 1))
	var sc: float = span_cells / tw
	s.scale = Vector2(sc, sc)
	container.add_child(s)
	sprites.append(s)
	base.append(Vector2(sc, sc))

# ------------------------------------------------------------------- aging ----

func _process(delta: float) -> void:
	age(delta)

## Advance every active effect by `delta` and free any that expired. Public so tests can
## drive aging deterministically without depending on real frame timing.
func age(delta: float) -> void:
	if _active.is_empty():
		return
	var i := _active.size() - 1
	while i >= 0:
		var e: Dictionary = _active[i]
		e["elapsed"] += delta
		var p: float = clampf(e["elapsed"] / e["lifetime"], 0.0, 1.0)
		var node = e["node"]
		if p >= 1.0 or node == null or not is_instance_valid(node):
			# Immediate free (not queue_free): an effect container is a signal-free leaf, so
			# freeing it now keeps the active set and the layer's child set in lockstep with
			# no one-frame ghost — important for the retry/toggle "zero stale" guarantees.
			if node != null and is_instance_valid(node):
				node.free()
			_active.remove_at(i)
		else:
			var alpha: float = 1.0 - p
			var grow: float = 1.0 + GROW * p
			var sprites: Array = e["sprites"]
			var base: Array = e["base"]
			for si in range(sprites.size()):
				var sp = sprites[si]
				if sp != null and is_instance_valid(sp):
					sp.modulate.a = alpha
					sp.scale = base[si] * grow
		i -= 1

# ----------------------------------------------------------------- toggles ----

## Runtime presentation toggle, default ON (§6). Disabling produces zero NEW cues and,
## deterministically, clears any currently-active cues immediately. Never affects clears.
func set_effects_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		clear_all()

func is_effects_enabled() -> bool:
	return _enabled

## Reduced-effects presentation seam (§9): one shorter cue + a lower concurrency cap.
## Changes presentation cost/density only; never how many cells clear or when.
func set_reduced_effects(on: bool) -> void:
	_reduced = on

func is_reduced_effects() -> bool:
	return _reduced

func _effective_cap() -> int:
	return REDUCED_MAX_ACTIVE if _reduced else MAX_ACTIVE_EFFECTS

# -------------------------------------------------------------- retry / reset --

## Free every active cue now (no delayed callback survives to repopulate a later state).
func clear_all() -> void:
	for e in _active:
		var node = e["node"]
		if node != null and is_instance_valid(node):
			node.free()
	_active.clear()

## M30 Retry / fresh-attempt hygiene (§10): remove stale cues from the previous attempt
## and reset the attempt-scoped diagnostic counters. Presentation-only; invoked from the
## host's post-success restore seam. Does NOT weaken the M30 Retry gate.
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
