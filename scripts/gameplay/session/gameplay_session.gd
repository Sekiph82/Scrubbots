extends RefCounted
## GameplaySession — preload this script
## (res://scripts/gameplay/session/gameplay_session.gd) rather than relying
## on global class_name lookup (AL-001).
##
## Headless-testable gameplay session core. Owns lifecycle state, immutable
## LevelData reference, and current BoardState. Does not depend on UI,
## renderer, slots, routing, or scene hierarchy.
##
## Lifecycle transition table:
##   UNINITIALIZED -> READY        (load_level succeeds)
##   READY         -> ACTIVE       (start)
##   ACTIVE        -> PAUSED       (pause)
##   PAUSED        -> ACTIVE       (resume)
##   ACTIVE        -> COMPLETED    (complete)
##   READY|ACTIVE|PAUSED|COMPLETED -> READY (reset)
##
## Completion is an explicit external transition only — no automatic
## win/lose/timer/move/cleared-count detection. The eventual win-condition
## system will call complete() when appropriate.
##
## NOTE: State.ACTIVE below is a SESSION-LIFECYCLE state (the level is being
## played) and is unrelated to BoardState.CellState.ACTIVE (an artwork pixel
## still present). They are deliberately distinct concepts.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")

enum State {
	UNINITIALIZED = 0,
	READY = 1,
	ACTIVE = 2,
	PAUSED = 3,
	COMPLETED = 4,
}

var _state: int = State.UNINITIALIZED
var _level_data = null   # LevelData or null
var _board_state = null  # BoardState or null
var _renderer = null     # BoardRenderer or null (optional presentation binding)
var _renderer_size := Vector2(512, 512)

func get_state() -> int:
	return _state

func get_level_data():
	return _level_data

func get_board_state():
	return _board_state

## Load a Level Data V1 JSON file. On success: creates fresh BoardState,
## stores immutable LevelData, enters READY, configures bound renderer.
## On failure: returns error; any previously valid session is preserved.
## Replacement semantics: a new level replaces the prior session only
## after full validation and fresh BoardState creation succeed.
func load_level(path: String) -> Dictionary:
	var result = LevelLoader.load_from_path(path)
	if not result.is_ok():
		return {"ok": false, "error": "load_failed", "message": _join_errors(result.errors)}
	var new_level = result.level_data
	var new_board = BoardState.from_level_data(new_level)
	_level_data = new_level
	_board_state = new_board
	_state = State.READY
	_configure_renderer()
	return {"ok": true, "error": "", "message": ""}

func start() -> Dictionary:
	if _state != State.READY:
		return _invalid_transition("start", "READY")
	_state = State.ACTIVE
	return _ok()

func pause() -> Dictionary:
	if _state != State.ACTIVE:
		return _invalid_transition("pause", "ACTIVE")
	_state = State.PAUSED
	return _ok()

func resume() -> Dictionary:
	if _state != State.PAUSED:
		return _invalid_transition("resume", "PAUSED")
	_state = State.ACTIVE
	return _ok()

func complete() -> Dictionary:
	if _state != State.ACTIVE:
		return _invalid_transition("complete", "ACTIVE")
	_state = State.COMPLETED
	return _ok()

## Reset: recreate BoardState from immutable LevelData. All cells ACTIVE,
## dimensions/palette preserved. Returns to READY.
func reset() -> Dictionary:
	if _state == State.UNINITIALIZED:
		return _invalid_transition("reset", "READY|ACTIVE|PAUSED|COMPLETED")
	_board_state = BoardState.from_level_data(_level_data)
	_state = State.READY
	_configure_renderer()
	return _ok()

## Bind a BoardRenderer for optional presentation. The renderer is
## configured immediately if a valid session exists. Pass null to unbind.
func bind_renderer(renderer, available_size: Vector2 = Vector2(512, 512)) -> void:
	_renderer = renderer
	_renderer_size = available_size
	_configure_renderer()

func _configure_renderer() -> void:
	if _renderer == null or _level_data == null or _board_state == null:
		return
	_renderer.configure(_board_state, _level_data.palette, _renderer_size)

func _ok() -> Dictionary:
	return {"ok": true, "error": "", "message": ""}

func _invalid_transition(action: String, required: String) -> Dictionary:
	var current := _state_name(_state)
	return {
		"ok": false,
		"error": "invalid_transition",
		"message": "%s requires %s, current state is %s" % [action, required, current],
	}

static func _state_name(s: int) -> String:
	match s:
		State.UNINITIALIZED: return "UNINITIALIZED"
		State.READY: return "READY"
		State.ACTIVE: return "ACTIVE"
		State.PAUSED: return "PAUSED"
		State.COMPLETED: return "COMPLETED"
	return "UNKNOWN"

static func _join_errors(errors: Array[String]) -> String:
	return "; ".join(errors)
