extends Node
## GameplayAudioController — preload this script
## (res://scripts/audio/gameplay_audio_controller.gd); do not rely on global class_name (AL-001).
##
## M33 — PRESENTATION-ONLY gameplay SFX presentation. A pure observer of the already
## authoritative gameplay events (owner audio decision V02, 2026-09-24):
##   - dispatch  -> NONE. No sound is played on ScrubbotDispatcher.assignment_dispatched.
##   - cleaning  <- CompleteClearingLoop.authenticated_clear (committed clear). Source sound is
##                  the owner-approved `dispatch.wav`, played as a SHORT BOUNDED transient.
##   - completion<- CompletionController.terminal_reached, WON only, once per attempt.
##
## It owns ONLY bounded AudioStreamPlayer voice pools + diagnostics. It NEVER selects
## targets, reserves cells, moves agents, clears cells, decides terminal state, or alters
## speed (owner audio decision + CLAUDE.md §9 boundaries). A dropped/suppressed voice never
## affects gameplay truth, and the clear is never delayed to wait for a sound.
##
## Movement audio in V1 is NONE: this controller references exactly two canonical one-shot
## streams and creates no continuous movement stream/player/loop. Background music lives in
## the separate MusicController on the Music bus.
##
## Cleaning tail bound (V02): the pixel is CLEARED at the committed clear and its visual cue
## (M31 cleaning FX 0.30 s, M32 retire echo 0.28 s) is gone shortly after. A cleaning voice
## is therefore hard-stopped at CLEANING_MAX_SEC after it starts, with a short linear fade over
## the last CLEANING_FADE_SEC so the cut does not click. No cleaning voice can sound longer
## than CLEANING_MAX_SEC regardless of the source file length.
##
## Voice concurrency (SB-M33-009): fixed pools sized to a per-category cap. A request takes a
## free voice or is deterministically SUPPRESSED (never queued, never a fresh per-event node).
## V02 lowers the cleaning cap for a cleaner mix; owner F6 re-listening judges the result.
##
## Speed (SB-M33 §10): 2x raises event density but each one-shot keeps normal pitch; this
## controller sets no pitch_scale and does not touch Engine.time_scale.

const SFX_BUS := "SFX"

## V02: cleaning reuses the approved dispatch.wav sonic identity. cleaning.wav is preserved on
## disk but no longer referenced by runtime.
const CLEANING_STREAM := "res://assets/audio/sfx/dispatch.wav"
const COMPLETION_STREAM := "res://assets/audio/sfx/completion.wav"

## V02 conservative cleaning mix (V01 was 8 voices of a 1.86 s file).
const CLEANING_VOICES := 3
const COMPLETION_VOICES := 1
## Hard audible bound of one cleaning voice (seconds) — below the 0.28 s retire echo.
const CLEANING_MAX_SEC := 0.24
## Linear fade-out at the end of the bound so the cutoff does not click.
const CLEANING_FADE_SEC := 0.06
## Base level of a cleaning voice; tunable during owner F6 re-listening.
const CLEANING_VOLUME_DB := -3.0
## Silence floor for the fade.
const FADE_FLOOR_DB := -60.0

enum Category { CLEANING, COMPLETION }

## Won status token mirrored from CompletionEvaluator (avoids a runtime dependency on the
## evaluator script just to compare a StringName). Kept in sync with CompletionEvaluator.WON.
const WON := &"WON"

## One fixed voice pool per category.
class VoicePool:
	var players: Array = []          ## AudioStreamPlayer nodes (fixed count == cap).
	var busy: Array = []             ## parallel bool[]: true while a voice is playing.
	var age: Array = []              ## parallel float[]: seconds since the voice started.
	var max_sec: float = -1.0        ## >0: hard audible bound per voice; <=0: natural end.
	var base_db: float = 0.0
	var cap: int = 0
	var requests: int = 0
	var played: int = 0
	var suppressed: int = 0
	var cut: int = 0                 ## voices stopped by the tail bound.
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
	_build_pool(Category.CLEANING, CLEANING_STREAM, CLEANING_VOICES, CLEANING_MAX_SEC, CLEANING_VOLUME_DB)
	_build_pool(Category.COMPLETION, COMPLETION_STREAM, COMPLETION_VOICES, -1.0, 0.0)

func _build_pool(category: int, stream_path: String, cap: int, max_sec: float, base_db: float) -> void:
	var pool := VoicePool.new()
	pool.cap = cap
	pool.max_sec = max_sec
	pool.base_db = base_db
	var stream: AudioStream = load(stream_path)
	for i in range(cap):
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = SFX_BUS
		# One-shot: normal pitch, no loop, no autoplay. 2x never pitch-shifts these.
		p.pitch_scale = 1.0
		p.volume_db = base_db
		p.autoplay = false
		add_child(p)
		p.finished.connect(_on_voice_finished.bind(category, i))
		pool.players.append(p)
		pool.busy.append(false)
		pool.age.append(0.0)
	_pools[category] = pool

# --------------------------------------------------- authoritative observers ----

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

func request_cleaning() -> bool:
	return _request(Category.CLEANING)

func request_completion() -> bool:
	return _request(Category.COMPLETION)

## Retry / fresh-attempt seam (SB-M33 §11, V02 criterion 7): re-arm the once-per-attempt
## completion latch AND stop every cleaning/completion voice (their sound belongs to the
## finished attempt) so no stale tail carries into the fresh attempt. Touches no gameplay
## state and no volume settings.
func reset_for_new_attempt() -> void:
	_completion_played_this_attempt = false
	_release_category(Category.CLEANING)
	_release_category(Category.COMPLETION)

## Free every voice in one category and stop its players. Presentation-only.
func _release_category(category: int) -> void:
	var pool: VoicePool = _pools.get(category)
	if pool == null:
		return
	for i in range(pool.busy.size()):
		_stop_voice(pool, i)

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
	pool.age[idx] = 0.0
	pool.active += 1
	if pool.active > pool.peak_active:
		pool.peak_active = pool.active
	pool.played += 1
	var p: AudioStreamPlayer = pool.players[idx]
	p.volume_db = pool.base_db
	p.play()
	return true

func _free_voice(pool: VoicePool) -> int:
	for i in range(pool.busy.size()):
		if not pool.busy[i]:
			return i
	return -1

func _stop_voice(pool: VoicePool, idx: int) -> void:
	var p: AudioStreamPlayer = pool.players[idx]
	if p.playing:
		p.stop()
	p.volume_db = pool.base_db
	if pool.busy[idx]:
		pool.busy[idx] = false
		pool.active -= 1
	pool.age[idx] = 0.0

func _on_voice_finished(category: int, idx: int) -> void:
	var pool: VoicePool = _pools.get(category)
	if pool == null or idx < 0 or idx >= pool.busy.size():
		return
	if pool.busy[idx]:
		pool.busy[idx] = false
		pool.active -= 1
		pool.age[idx] = 0.0

func _process(delta: float) -> void:
	advance_voices(delta)

## Age every bounded voice by `delta` seconds: fade over the last CLEANING_FADE_SEC and
## hard-stop at the pool's max_sec. Driven by _process in production; tests call it directly
## for deterministic time. Non-finite/negative delta is ignored.
func advance_voices(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	for c in _pools:
		var pool: VoicePool = _pools[c]
		if pool.max_sec <= 0.0:
			continue
		for i in range(pool.busy.size()):
			if not pool.busy[i]:
				continue
			pool.age[i] += delta
			var remaining: float = pool.max_sec - pool.age[i]
			if remaining <= 0.0:
				pool.cut += 1
				_stop_voice(pool, i)
				continue
			var p: AudioStreamPlayer = pool.players[i]
			if remaining < CLEANING_FADE_SEC:
				var k: float = remaining / CLEANING_FADE_SEC
				p.volume_db = maxf(FADE_FLOOR_DB, pool.base_db + linear_to_db(maxf(k, 0.001)))

# ------------------------------------------------------------- diagnostics ----

## Presentation diagnostics only. Returns {requests, played, suppressed, cut, active, peak, cap}.
func get_diagnostics(category: int) -> Dictionary:
	var pool: VoicePool = _pools.get(category)
	if pool == null:
		return {}
	return {
		"requests": pool.requests,
		"played": pool.played,
		"suppressed": pool.suppressed,
		"cut": pool.cut,
		"active": pool.active,
		"peak": pool.peak_active,
		"cap": pool.cap,
	}

func get_voice_cap(category: int) -> int:
	var pool: VoicePool = _pools.get(category)
	return pool.cap if pool != null else 0

## Hard audible bound of one voice in `category` (<=0 means natural end).
func get_voice_max_sec(category: int) -> float:
	var pool: VoicePool = _pools.get(category)
	return pool.max_sec if pool != null else -1.0

## Oldest age of any currently busy voice in `category` (0 when none).
func get_max_voice_age(category: int) -> float:
	var pool: VoicePool = _pools.get(category)
	var m := 0.0
	if pool != null:
		for i in range(pool.busy.size()):
			if pool.busy[i]:
				m = maxf(m, pool.age[i])
	return m

## Total allocated AudioStreamPlayer nodes (proves the pool never grows under stress).
func get_allocated_voice_count() -> int:
	var n := 0
	for c in _pools:
		n += (_pools[c] as VoicePool).players.size()
	return n

func get_active_voice_count(category: int) -> int:
	var pool: VoicePool = _pools.get(category)
	return pool.active if pool != null else 0

## The exact canonical streams referenced — used by tests to prove no movement stream, no
## dispatch sound and the owner-locked V02 mapping.
func get_stream_paths() -> Array:
	return [CLEANING_STREAM, COMPLETION_STREAM]

## Stream resource path actually loaded on a category's players (tests prove dispatch.wav
## backs cleaning on the live nodes, not just in a constant).
func get_category_stream_path(category: int) -> String:
	var pool: VoicePool = _pools.get(category)
	if pool == null or pool.players.is_empty():
		return ""
	var s: AudioStream = (pool.players[0] as AudioStreamPlayer).stream
	return s.resource_path if s != null else ""

func completion_played_this_attempt() -> bool:
	return _completion_played_this_attempt

# --------------------------------------------------------- test-only seams ----

## Test-only: free every busy voice deterministically (headless, without waiting for the
## dummy audio driver's `finished`). Never used by production wiring.
func debug_release_all() -> void:
	for c in _pools:
		var pool: VoicePool = _pools[c]
		for i in range(pool.busy.size()):
			_stop_voice(pool, i)
