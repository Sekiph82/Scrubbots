extends Control
## HomeScrubbyHero — preload (res://scripts/ui/home/home_scrubby_hero.gd).
##
## M42-C003 V03 (SB-M42-035): the single presentation-only Home hero animation component
## (coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md, ASSET_PRODUCTION_SPEC_V03.md).
##
## Owns: idle micro-motion, the gesture scheduler, frame swapping, lifecycle/modal gates and
## the Reduced Effects response. HomeScreen owns layout and passes the accepted M42-C002
## HOME-026 rect (SCRUBBY_SCALE 1.612) via set_base(); this component never computes world
## layout, never takes input and never touches AppState truth (it only reads
## AppState.effects).
##
## Geometry: HOME-026 (`Art_scrubby`, a sibling TextureRect) keeps its accepted rect. Gesture
## frames share one larger canvas + one animation pivot (the planted sole midpoint); the
## gesture TextureRect is sized canvas x texels_per_pixel x k (k = screen px per HOME texel)
## and placed so pivot lands on the HOME screen soles point. Frame swaps only change the
## texture, never the rect, so they cannot jitter.
##
## Idle: restrained squash/stretch of Art_scrubby about its soles, a pure function of the
## idle phase -> exactly identity at phase 0 and whenever disabled. It is a render-only
## canvas_item vertex shader, so Art_scrubby's accepted rect/transform never changes.
## During a gesture HOME-026 is faded (self_modulate.a = 0), not hidden or moved.
## Scheduler: idle interval uniform 6..12 s, then one gesture by weight (Wave 35 / Turn 30 /
## Bow 25 / Full Turn 10) excluding the previous one; never stacked; the next interval starts
## only after the gesture returned to HOME-026. No Timer/Tween/signal is created per cycle.

const WEIGHTS := {"wave": 35, "turn": 30, "bow": 25, "full_turn": 10}
const INTERVAL_MIN := 6.0
const INTERVAL_MAX := 12.0
const IDLE_PERIOD := 2.6      ## seconds per breath
const IDLE_SQUASH := 0.006    ## +-0.6% height (x counter-scaled by half) about the soles
const IDLE_SHADER := """shader_type canvas_item;
uniform vec2 pivot = vec2(0.0);
uniform vec2 squash = vec2(1.0);
void vertex() { VERTEX = pivot + (VERTEX - pivot) * squash; }
"""

var _home_rect: TextureRect          ## Art_scrubby (HOME-026), owned by HomeScreen
var _gesture_rect: TextureRect       ## Art_scrubby_gesture (frames)
var _set: Dictionary = {}            ## binder animation_set() result ({} = static fallback)
var _effects = null                  ## AppState.effects (EffectsSettingsService)
var _rng := RandomNumberGenerator.new()
var _k := 0.0                        ## screen px per HOME texel (from set_base)
var _idle_mat := ShaderMaterial.new()

var _gesture := ""                   ## "" = idle
var _gesture_t := 0.0
var _last := ""
var _wait := 0.0
var _idle_t := 0.0
var _modal := false
var _focused := true
var _paused := false
var _was_open := false               ## gates open on the previous step (resume detection)
var _counts := {}                    ## gesture -> times started (tests/evidence)

func _init() -> void:
	name = "HomeScrubbyHero"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gesture_rect = TextureRect.new()
	_gesture_rect.name = "Art_scrubby_gesture"
	_gesture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gesture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gesture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_gesture_rect.visible = false
	add_child(_gesture_rect)
	_rng.seed = 0x5C2B
	_wait = _next_interval()
	var sh := Shader.new()
	sh.code = IDLE_SHADER
	_idle_mat.shader = sh

func _exit_tree() -> void:
	_disconnect_effects()

# ------------------------------------------------------------------ binding ----

## HOME-026 node (its rect stays owned by HomeScreen layout).
func set_home_rect(rect: TextureRect) -> void:
	_home_rect = rect
	_home_rect.material = _idle_mat

## Binder animation_set() result; {} keeps the static HOME-026 fallback.
func set_frames(anim_set: Dictionary) -> void:
	_set = anim_set if anim_set.has("textures") else {}
	_end_gesture()

func has_frames() -> bool:
	return not _set.is_empty()

## Canonical Reduced Effects (AppState.effects); live via its changed(reduced) signal.
func bind_effects(effects) -> void:
	if effects == _effects:
		return
	_disconnect_effects()
	_effects = effects
	if _effects != null and _effects.has_signal("changed"):
		_effects.changed.connect(_on_reduced_changed)
	if is_reduced():
		_end_gesture()

func _disconnect_effects() -> void:
	if _effects != null and _effects.has_signal("changed") and _effects.changed.is_connected(_on_reduced_changed):
		_effects.changed.disconnect(_on_reduced_changed)
	_effects = null

func _on_reduced_changed(reduced: bool) -> void:
	if reduced:
		_end_gesture()

func is_reduced() -> bool:
	return _effects != null and _effects.is_reduced()

## Deterministic seam for tests/evidence.
func set_rng_seed(seed: int) -> void:
	_rng.seed = seed
	_wait = _next_interval()

## Accepted HOME-026 screen rect (parent-local) for the current layout.
func set_base(home_pos: Vector2, home_size: Vector2, home_tex_size: Vector2) -> void:
	_k = home_size.x / home_tex_size.x if home_tex_size.x > 0.0 else 0.0
	_idle_mat.set_shader_parameter("pivot", _home_root() * _k)
	if has_frames():
		var d := float(_set["home_texels_per_anim_pixel"])
		var canvas := Vector2(_set["canvas"][0], _set["canvas"][1])
		var pivot := Vector2(_set["pivot"][0], _set["pivot"][1])
		_gesture_rect.size = canvas * d * _k
		_gesture_rect.position = get_pivot_screen(home_pos) - pivot * d * _k
	_apply_idle()

func _home_root() -> Vector2:
	if has_frames():
		return Vector2(_set["home_root_texels"][0], _set["home_root_texels"][1])
	return Vector2.ZERO

## HOME-026 screen soles point (parent-local) = the animation pivot's screen point.
func get_pivot_screen(home_pos: Vector2 = Vector2.INF) -> Vector2:
	var pos: Vector2 = home_pos if home_pos != Vector2.INF else (_home_rect.position if _home_rect != null else Vector2.ZERO)
	return pos + _home_root() * _k

# ---------------------------------------------------------------- lifecycle ----

## HomeScreen modal state (popups / settings overlay): no new gesture while true.
func set_modal(active: bool) -> void:
	_modal = active

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
		NOTIFICATION_APPLICATION_PAUSED:
			_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			_paused = false

## Large motion allowed at all (Reduced Effects off, Home visible, app focused/running).
func motion_allowed() -> bool:
	return has_frames() and not is_reduced() and is_visible_in_tree() and _focused and not _paused

## A NEW gesture may start (also requires no modal).
func can_start_gesture() -> bool:
	return motion_allowed() and not _modal

func _process(delta: float) -> void:
	step(delta)

## One deterministic tick (tests drive this with set_process(false)).
func step(dt: float) -> void:
	var open := can_start_gesture()
	if not motion_allowed():
		_end_gesture()        # hidden / backgrounded / Reduced Effects: inert, static HOME-026
		_idle_t = 0.0
		_apply_idle()
		_was_open = false
		return
	if open and not _was_open:
		_wait = _next_interval()   # resume: fresh 6..12 s, no catch-up burst
	_was_open = open
	if _gesture != "":
		_gesture_t += dt     # a running gesture may finish under a modal (no snap)
		var frames: Array = _set["textures"][_gesture]
		var i := int(floor(_gesture_t * float(_set["fps"])))
		if i >= frames.size():
			_end_gesture()
			_wait = _next_interval()
		else:
			_gesture_rect.texture = frames[i]
		return
	_idle_t = fmod(_idle_t + dt, IDLE_PERIOD)
	_apply_idle()
	if not open:
		return
	_wait -= dt
	if _wait <= 0.0:
		start_gesture(pick_gesture())

func pick_gesture() -> String:
	var total := 0
	for g in WEIGHTS:
		if g != _last and has_frames() and (_set["textures"] as Dictionary).has(g):
			total += int(WEIGHTS[g])
	var r := _rng.randi_range(1, total)
	for g in WEIGHTS:
		if g == _last or not (_set["textures"] as Dictionary).has(g):
			continue
		r -= int(WEIGHTS[g])
		if r <= 0:
			return g
	return ""

## Start one gesture now (scheduler; tests/evidence seam). Refused while one is running.
func start_gesture(g: String) -> bool:
	if _gesture != "" or not has_frames() or not (_set["textures"] as Dictionary).has(g) or not can_start_gesture():
		return false
	_gesture = g
	_gesture_t = 0.0
	_last = g
	_counts[g] = int(_counts.get(g, 0)) + 1
	_idle_t = 0.0
	_apply_idle()
	_gesture_rect.texture = _set["textures"][g][0]
	_gesture_rect.visible = true
	if _home_rect != null:
		_home_rect.self_modulate.a = 0.0
	return true

func _end_gesture() -> void:
	_gesture = ""
	_gesture_t = 0.0
	_gesture_rect.visible = false
	_gesture_rect.texture = null
	if _home_rect != null:
		_home_rect.self_modulate.a = 1.0

func _apply_idle() -> void:
	_idle_mat.set_shader_parameter("squash", get_idle_squash())

## Current idle squash (identity when reduced, gesturing, or at phase 0).
func get_idle_squash() -> Vector2:
	var s := 0.0 if is_reduced() or _gesture != "" else IDLE_SQUASH * sin(TAU * _idle_t / IDLE_PERIOD)
	return Vector2(1.0 - s * 0.5, 1.0 + s)

func get_idle_material() -> ShaderMaterial:
	return _idle_mat

func _next_interval() -> float:
	return _rng.randf_range(INTERVAL_MIN, INTERVAL_MAX)

# ------------------------------------------------------------ test accessors ----

func get_state() -> Dictionary:
	return {"gesture": _gesture, "gesture_t": _gesture_t, "last": _last, "wait": _wait,
		"idle_t": _idle_t, "modal": _modal, "focused": _focused, "paused": _paused,
		"counts": _counts.duplicate()}

func get_gesture_rect() -> TextureRect:
	return _gesture_rect

func get_frame_index() -> int:
	if _gesture == "":
		return -1
	return int(floor(_gesture_t * float(_set["fps"])))

func get_set() -> Dictionary:
	return _set

func gesture_duration(g: String) -> float:
	return float((_set["textures"][g] as Array).size()) / float(_set["fps"])
