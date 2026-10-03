extends RefCounted
## RevealSequencer — preload (res://scripts/ui/components/reveal_sequencer.gd).
##
## M43-C005-C005 (SB-M43-063) — the one reusable production presentation sequencer for short
## ordered reward/reveal beats (Results reward rows now; the M43-C005 ceremonies next).
##
## PRESENTATION ONLY. It tweens visual properties of nodes the caller already built from
## committed truth. It knows nothing about rewards, economy, progression, save, navigation,
## ads or IAP, and `completed` is a presentation event — never a grant / claim / open /
## unlock / equip / save / advance authority.
##
## Step = {target: Object, property: String, from, to, duration: float, delay: float}
##   played strictly in order: wait `delay`, then tween `property` from -> to over `duration`.
##   `fade(target, duration, delay)` builds the common modulate:a 0 -> 1 step.
##
## play(key, steps, reduced):
##   - one-shot per key: a key that already played (running / finished / cancelled) is refused;
##   - a new key cancels any current run first; every tween callback is generation-checked
##     and the old tween is killed, so no stale callback or tween leaks into the new run;
##   - Reduced Effects, an empty sequence or a host outside the tree land the exact final
##     state immediately (same final information as the full run).
## finish(): fast-forward to the exact final state.  cancel(): stop, no completion.
## `completed(key)` fires at most once per key (natural end, finish, Reduced, empty).
## `step_started(key, index)` marks each beat of a full run (a later decoration hook only).
## Tweens are bound to the host node: freeing the host kills them. Owns no nodes.

signal completed(key: String)
signal step_started(key: String, index: int)

var _host: Node
var _key := ""
## ponytail: one small String per played key (Results adds one per show); trim if ever large.
var _played: Dictionary = {}
var _steps: Array = []
var _tween: Tween
var _gen := 0
var _step := -1
var _done := true

func _init(host: Node) -> void:
	_host = host

static func fade(target: CanvasItem, duration: float, delay := 0.0) -> Dictionary:
	return {"target": target, "property": "modulate:a", "from": 0.0, "to": 1.0, "duration": duration, "delay": delay}

## Start presentation `key`. Returns false (and changes nothing) for an empty or already-played key.
func play(key: String, steps: Array, reduced := false) -> bool:
	if key.is_empty() or _played.has(key):
		return false
	cancel()
	_played[key] = true
	_key = key
	_steps = steps.filter(func(s): return is_instance_valid(s.get("target")))
	_done = false
	for s in _steps:
		_apply(s, "from")
	if reduced or _steps.is_empty() or _host == null or not _host.is_inside_tree():
		finish()
		return true
	var gen := _gen
	_tween = _host.create_tween()
	for i in _steps.size():
		var s: Dictionary = _steps[i]
		if float(s.get("delay", 0.0)) > 0.0:
			_tween.tween_interval(float(s["delay"]))
		_tween.tween_callback(_on_step.bind(gen, i))
		_tween.tween_property(s["target"], String(s["property"]), s["to"], float(s.get("duration", 0.0)))
	_tween.tween_callback(_on_end.bind(gen))
	return true

## Fast-forward the current presentation to its exact final state (no-op when none is active).
func finish() -> void:
	if _done:
		return
	_kill()
	for s in _steps:
		_apply(s, "to")
	_step = _steps.size() - 1
	_complete()

## Stop the current presentation without completing it (route change, hidden screen, freed popup).
func cancel() -> void:
	_kill()
	_steps.clear()
	_step = -1
	_done = true

func is_running() -> bool:
	return not _done and _tween != null and _tween.is_valid() and _tween.is_running()

func is_active() -> bool:
	return not _done

func has_played(key: String) -> bool:
	return _played.has(key)

func current_key() -> String:
	return _key

## Index of the step currently playing (-1 before the first step starts).
func current_step() -> int:
	return _step

## Read-only copy of the active plan (empty once completed / cancelled).
func get_steps() -> Array:
	return _steps.duplicate(true)

func _apply(s: Dictionary, which: String) -> void:
	if s.has(which) and is_instance_valid(s.get("target")):
		(s["target"] as Object).set_indexed(NodePath(String(s["property"])), s[which])

func _kill() -> void:
	_gen += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _on_step(gen: int, i: int) -> void:
	if gen == _gen:
		_step = i
		step_started.emit(_key, i)

func _on_end(gen: int) -> void:
	if gen != _gen or _done:
		return
	_tween = null   # finishing on its own; never killed from inside its own callback
	_complete()

func _complete() -> void:
	_done = true
	_steps.clear()
	completed.emit(_key)
