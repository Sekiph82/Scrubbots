extends Node
## HapticsController — preload this script
## (res://scripts/haptics/haptics_controller.gd); do not rely on global class_name (AL-001).
##
## M34 — PRESENTATION-ONLY vibration presentation. Pure observer of the same
## authoritative gameplay events M33 audio observes:
##   - cleaning   <- CompleteClearingLoop.authenticated_clear (committed clear);
##   - completion <- CompletionController.terminal_reached, WON only, once per attempt.
##
## Fail-open: an unsupported platform, a disabled toggle or a throttled request
## MUST NEVER block gameplay. The controller owns only:
##   - a boolean enabled seam (SB-M34-004);
##   - a deterministic anti-spam window with diagnostics (SB-M34-005);
##   - the once-per-attempt completion latch (SB-M34-003).
##
## Platform research (SB-M34-001) is recorded in docs/12_HAPTICS_PLATFORM_RESEARCH.md.
## In V1 the platform seam is Input.vibrate_handheld(ms), which is a no-op on
## desktop/headless and does not distinguish patterns. Every runtime call goes
## through _platform_vibrate() so tests can inject a fake platform and count
## calls without a real device.

const CLEAN_MS := 20                 ## short cleaning tick; conservative.
const COMPLETION_MS := 220           ## longer completion buzz; distinct from cleaning.
const CLEAN_THROTTLE_MS := 60        ## min interval between cleaning vibrations.

## Won status token mirrored from CompletionEvaluator (avoids a hard load-time
## dependency on the evaluator script just to compare a StringName).
const WON := &"WON"

enum Category { CLEANING, COMPLETION }

var _enabled: bool = true
var _completion_played_this_attempt: bool = false
var _last_clean_ms: int = -100000
var _requests_clean: int = 0
var _played_clean: int = 0
var _suppressed_clean: int = 0
var _requests_completion: int = 0
var _played_completion: int = 0
var _suppressed_completion: int = 0
## Test seam: swap out Input.vibrate_handheld with a counter. Signature is
## (duration_ms: int, category: int) -> void.
var _platform_sink: Callable = Callable()
var _platform_calls: int = 0
var _platform_total_ms: int = 0

# --------------------------------------------------------------- toggle ----

func set_enabled(v: bool) -> void:
	_enabled = v

func is_enabled() -> bool:
	return _enabled

# --------------------------------------------------- authoritative observers ----

## Committed authenticated clear (CompleteClearingLoop.authenticated_clear).
func _on_authenticated_clear(_owner_id: int, _target_index: int, _color_id: int, _agent) -> void:
	request_cleaning()

## M30 terminal latch (CompletionController.terminal_reached). Vibrates only on
## WON, exactly once per attempt; LOST/ERROR play nothing.
func _on_terminal_reached(status, _detail) -> void:
	if status != WON:
		return
	if _completion_played_this_attempt:
		return
	_completion_played_this_attempt = true
	request_completion()

# ---------------------------------------------------------- direct seams ----

func request_cleaning() -> bool:
	_requests_clean += 1
	if not _enabled:
		_suppressed_clean += 1
		return false
	var now := Time.get_ticks_msec()
	if now - _last_clean_ms < CLEAN_THROTTLE_MS:
		_suppressed_clean += 1
		return false
	_last_clean_ms = now
	_played_clean += 1
	_platform_vibrate(CLEAN_MS, Category.CLEANING)
	return true

func request_completion() -> bool:
	_requests_completion += 1
	if not _enabled:
		_suppressed_completion += 1
		return false
	_played_completion += 1
	_platform_vibrate(COMPLETION_MS, Category.COMPLETION)
	return true

## Retry / fresh-attempt seam: re-arm the once-per-attempt completion latch and
## clear the anti-spam window (the previous attempt owns its throttling).
func reset_for_new_attempt() -> void:
	_completion_played_this_attempt = false
	_last_clean_ms = -100000

# ------------------------------------------------------------ platform ----

func _platform_vibrate(duration_ms: int, category: int) -> void:
	_platform_calls += 1
	_platform_total_ms += duration_ms
	if _platform_sink.is_valid():
		_platform_sink.call(duration_ms, category)
		return
	# Real device path: Godot 4.7.2 exposes Input.vibrate_handheld(ms) on Android/iOS;
	# no-op on desktop/headless. Fail-open by design.
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(duration_ms)

## Test seam. Passing an invalid Callable restores the default platform path.
func set_platform_sink(sink: Callable) -> void:
	_platform_sink = sink

# ------------------------------------------------------------ diagnostics ----

func get_diagnostics(category: int) -> Dictionary:
	if category == Category.CLEANING:
		return {
			"requests": _requests_clean,
			"played": _played_clean,
			"suppressed": _suppressed_clean,
		}
	if category == Category.COMPLETION:
		return {
			"requests": _requests_completion,
			"played": _played_completion,
			"suppressed": _suppressed_completion,
		}
	return {}

func completion_played_this_attempt() -> bool:
	return _completion_played_this_attempt

func get_platform_call_count() -> int:
	return _platform_calls

func get_platform_total_ms() -> int:
	return _platform_total_ms

func get_throttle_ms() -> int:
	return CLEAN_THROTTLE_MS
