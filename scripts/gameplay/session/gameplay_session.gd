extends RefCounted
## GameplaySession — preload this script
## (res://scripts/gameplay/session/gameplay_session.gd) rather than relying
## on global class_name lookup (AL-001).
##
## Headless-testable gameplay session core. Owns lifecycle state, an internally
## owned detached LevelData source copy, and current BoardState. Does not depend
## on UI, renderer, slots, routing, or scene hierarchy. The source LevelData is
## never exposed by reference — get_level_data() hands out detached snapshots so
## external mutation cannot alter reset/source truth (F-M11-STRICT-001).
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

const DEFAULT_RENDERER_SIZE := Vector2(512, 512)

var _state: int = State.UNINITIALIZED
var _level_data = null   # internally owned, detached LevelData source copy or null
var _board_state = null  # BoardState or null
var _renderer = null     # BoardRenderer or null (optional presentation binding)
var _renderer_size := DEFAULT_RENDERER_SIZE

func get_state() -> int:
	return _state

## Returns a DETACHED LevelData snapshot (or null when uninitialized). Callers
## may freely mutate the returned scalars/palette/cells; the session's internal
## source truth is never exposed and never mutated (F-M11-STRICT-001).
func get_level_data():
	return _duplicate_level_data(_level_data)

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
	# Own an internal detached copy of the source truth; build BoardState from
	# that copy so external references to the loader's LevelData cannot leak
	# into the session (F-M11-STRICT-001).
	var new_source = _duplicate_level_data(result.level_data)
	var new_board = BoardState.from_level_data(new_source)
	_level_data = new_source
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

## Bind a BoardRenderer for optional presentation. Fail-closed contract:
##   - null explicitly unbinds and returns true;
##   - a live, real BoardRenderer with a finite positive available_size binds,
##     configures immediately if a valid session exists, and returns true;
##   - any other value (scalar/junk/partial object) OR an invalid size
##     (NaN/±INF/zero/negative) is REJECTED: nothing is stored or configured,
##     a previously valid binding is preserved, and it returns false.
## (F-M11-STRICT-002/003.) Callers may ignore the return value.
func bind_renderer(renderer, available_size: Vector2 = DEFAULT_RENDERER_SIZE) -> bool:
	if renderer == null:
		_renderer = null
		return true
	if not _is_real_renderer(renderer):
		return false
	if not _is_valid_size(available_size):
		return false
	_renderer = renderer
	_renderer_size = available_size
	_configure_renderer()
	return true

func _configure_renderer() -> void:
	if _renderer == null:
		return
	# The bound renderer may have been freed externally while the session lived
	# on. Drop the stale binding and continue the session lifecycle headlessly
	# rather than calling into a freed instance (F-M11-STRICT-004).
	if not is_instance_valid(_renderer):
		_renderer = null
		return
	if _level_data == null or _board_state == null:
		return
	# Hand the renderer a DETACHED palette copy so the presentation collaborator
	# can never retain/mutate the session's internal source palette
	# (F-M11-STRICT-005). Never pass the LevelData object itself.
	_renderer.configure(_board_state, _level_data.palette.duplicate(), _renderer_size)

## True only for a live BoardRenderer (or subclass). Non-Object inputs
## (int/String/Vector2), freed instances, plain RefCounted junk, and partial
## fakes exposing configure() are all rejected. is_instance_valid() runs before
## the type check so a freed instance never reaches `is`.
func _is_real_renderer(r) -> bool:
	if typeof(r) != TYPE_OBJECT:
		return false
	if not is_instance_valid(r):
		return false
	return r is BoardRenderer

static func _is_valid_size(sz: Vector2) -> bool:
	return is_finite(sz.x) and is_finite(sz.y) and sz.x > 0.0 and sz.y > 0.0

## Build a fully detached LevelData copy (packed arrays duplicated). Returns
## null for a null source. Used for both the internal source and outward
## snapshots so neither aliases the other.
func _duplicate_level_data(src):
	if src == null:
		return null
	return LevelData.new(
		src.version, src.id, src.display_name, src.difficulty,
		src.width, src.height,
		src.palette.duplicate(), src.cells.duplicate()
	)

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
