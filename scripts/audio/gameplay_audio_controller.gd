extends Node
## GameplayAudioController — preload this script
## (res://scripts/audio/gameplay_audio_controller.gd); do not rely on global class_name (AL-001).
##
## M33 — PRESENTATION-ONLY gameplay SFX presentation. A pure observer of the already
## authoritative gameplay events:
##   - dispatch  <- ScrubbotDispatcher.assignment_dispatched (committed successful dispatch);
##   - cleaning  <- CompleteClearingLoop.authenticated_clear (committed clear);
##   - completion<- CompletionController.terminal_reached, WON only, once per attempt.
##
## It owns ONLY bounded AudioStreamPlayer voice pools + diagnostics. It NEVER selects
## targets, reserves cells, moves agents, clears cells, decides terminal state, or alters
## speed (owner audio decision + CLAUDE.md §9 boundaries). A dropped/suppressed voice never
## affects gameplay truth.
##
## Movement audio in V1 is NONE: this controller references exactly the three canonical
## one-shot SFX and creates no continuous movement stream/player/loop.
##
## Voice concurrency (SB-M33-009): fixed pools sized to a per-category cap. A request
## takes a free voice or is deterministically SUPPRESSED (never queued, never a fresh
## per-event node). Cleaning is the main density hazard; caps are conservative and tuned
## from the headless burst stress + owner F6 listening. Because a pool is fixed-size, the
## allocated player-node count and the simultaneously-active voice count can never exceed
## the cap.
##
## Speed (SB-M33 §10): 2x raises event density but each one-shot keeps normal pitch; this
## controller sets no pitch_scale and does not touch Engine.time_scale.

const SFX_BUS := "SFX"

const DISPATCH_STREAM := "res://assets/audio/sfx/dispatch.wav"
const CLEANING_STREAM := "res://assets/audio/sfx/cleaning.wav"
const COMPLETION_STREAM := "res://assets/audio/sfx/completion.wav"

# Conservative per-category voice caps (see stress evidence + F6 notes in CLAUDE_LOG_V01.md).
const DISPATCH_VOICES := 4
const CLEANING_VOICES := 8
const COMPLETION_VOICES := 1

enum Category { DISPATCH, CLEANING, COMPLETION }

## Won status token mirrored from CompletionEvaluator (avoids a runtime dependency on the
## evaluator script just to compare a StringName). Kept in sync with CompletionEvaluator.WON.
const WON := &"WON"

## One fixed voice pool per category.
class VoicePool:
	var players: Array = []          ## AudioStreamPlayer nodes (fixed count == cap).
	var busy: Array = []             ## parallel bool[]: true while a voice is playing.
	var cap: int = 0
	var requests: int = 0
	var played: int = 0
	var suppressed: int = 0
	var active: int = 0
	var peak_active: int = 0

var _pools: Dictionary = {}          ## Category -> VoicePool.
## Completion is wired to WON only, once per attempt. Reset by reset_for_new_attempt().
var _completion_played_this_attempt: bool = false
var _ready_done: bool = false

func _ready() -> void:
	if _ready_done:
		return
	_ready_done = true
	_build_pool(Category.DISPATCH, DISPATCH_STREAM, DISPATCH_VOICES)
	_build_pool(Category.CLEANING, CLEANING_STREAM, CLEANING_VOICES)
	_build_pool(Category.COMPLETION, COMPLETION_STREAM, COMPLETION_VOICES)

func _build_pool(category: int, stream_path: String, cap: int) -> void:
	var pool := VoicePool.new()
	pool.cap = cap
	var stream: AudioStream = load(stream_path)
	for i in range(cap):
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = SFX_BUS
		# One-shot: normal pitch, no loop, no autoplay. 2x never pitch-shifts these.
		p.pitch_scale = 1.0
		p.autoplay = false
		add_child(p)
		p.finished.connect(_on_voice_finished.bind(category, i))
		pool.players.append(p)
		pool.busy.append(false)
	_pools[category] = pool

# --------------------------------------------------- authoritative observers ----

## Committed successful dispatch (ScrubbotDispatcher.assignment_dispatched). One request.
func _on_assignment_dispatched(_owner_id: int, _target_index: int, _color_id: int, _agent) -> void:
	request_dispatch()

## Committed authenticated clear (CompleteClearingLoop.authenticated_clear). One request,
## subject to presentation concurrency suppression only — never delays/suppresses the clear.
func _on_authenticated_clear(_owner_id: int, _target_index: int, _color_id: int, _agent) -> void:
	request_cleaning()

## M30 terminal latch (CompletionController.terminal_reached). Plays only on WON, exactly
## once per attempt; LOST/ERROR play nothing.
func _on_terminal_reached(status, _detail) -> void:
	if status != WON:
		return
	if _completion_played_this_attempt:
		return
	_completion_played_this_attempt = true
	_request(Category.COMPLETION)

# ------------------------------------------------------------- direct seams ----
# Isolated presentation test seams (F6 buttons + headless tests). They exercise the SAME
# bounded voice path as the authoritative observers.

func request_dispatch() -> bool:
	return _request(Category.DISPATCH)

func request_cleaning() -> bool:
	return _request(Category.CLEANING)

func request_completion() -> bool:
	return _request(Category.COMPLETION)

## Retry / fresh-attempt seam (SB-M33 §11): re-arm the once-per-attempt completion latch AND
## free the single completion channel (its sound belongs to the finished attempt) so a later
## fresh WON reliably plays completion again. Touches no gameplay state and no volume settings.
func reset_for_new_attempt() -> void:
	_completion_played_this_attempt = false
	_release_category(Category.COMPLETION)

## Free every voice in one category and stop its players (used on a fresh attempt so a stale
## completion sound never blocks the next attempt's completion). Presentation-only.
func _release_category(category: int) -> void:
	var pool: VoicePool = _pools.get(category)
	if pool == null:
		return
	for i in range(pool.busy.size()):
		pool.busy[i] = false
		var p: AudioStreamPlayer = pool.players[i]
		if p.playing:
			p.stop()
	pool.active = 0

# --------------------------------------------------------------- voice core ----

## Take a free voice for `category` and play it, or deterministically suppress. Returns true
## if a voice played. Never queues, never allocates a new node.
func _request(category: int) -> bool:
	var pool: VoicePool = _pools.get(category)
	if pool == null:
		return false
	pool.requests += 1
	var idx := _free_voice(pool)
	if idx < 0:
		pool.suppressed += 1
		return false
	pool.busy[idx] = true
	pool.active += 1
	if pool.active > pool.peak_active:
		pool.peak_active = pool.active
	pool.played += 1
	var p: AudioStreamPlayer = pool.players[idx]
	p.play()
	return true

func _free_voice(pool: VoicePool) -> int:
	for i in range(pool.busy.size()):
		if not pool.busy[i]:
			return i
	return -1

func _on_voice_finished(category: int, idx: int) -> void:
	var pool: VoicePool = _pools.get(category)
	if pool == null or idx < 0 or idx >= pool.busy.size():
		return
	if pool.busy[idx]:
		pool.busy[idx] = false
		pool.active -= 1

# ------------------------------------------------------------- diagnostics ----

## Presentation diagnostics only. Returns {requests, played, suppressed, active, peak, cap}.
func get_diagnostics(category: int) -> Dictionary:
	var pool: VoicePool = _pools.get(category)
	if pool == null:
		return {}
	return {
		"requests": pool.requests,
		"played": pool.played,
		"suppressed": pool.suppressed,
		"active": pool.active,
		"peak": pool.peak_active,
		"cap": pool.cap,
	}

func get_voice_cap(category: int) -> int:
	var pool: VoicePool = _pools.get(category)
	return pool.cap if pool != null else 0

## Total allocated AudioStreamPlayer nodes (proves the pool never grows under stress).
func get_allocated_voice_count() -> int:
	var n := 0
	for c in _pools:
		n += (_pools[c] as VoicePool).players.size()
	return n

func get_active_voice_count(category: int) -> int:
	var pool: VoicePool = _pools.get(category)
	return pool.active if pool != null else 0

## The exact canonical streams referenced — used by tests to prove no movement stream and
## exactly the three owner-locked one-shots.
func get_stream_paths() -> Array:
	return [DISPATCH_STREAM, CLEANING_STREAM, COMPLETION_STREAM]

func completion_played_this_attempt() -> bool:
	return _completion_played_this_attempt

# --------------------------------------------------------- test-only seams ----

## Test-only: free every busy voice deterministically (headless, without waiting for the
## dummy audio driver's `finished`). Never used by production wiring.
func debug_release_all() -> void:
	for c in _pools:
		var pool: VoicePool = _pools[c]
		for i in range(pool.busy.size()):
			pool.busy[i] = false
		pool.active = 0
