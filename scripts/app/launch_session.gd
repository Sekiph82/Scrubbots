extends RefCounted
## LaunchSession — preload (res://scripts/app/launch_session.gd).
##
## M42 (SB-M42-031) — implements OWNER_M42_OPENING_PLAYBACK_FREQUENCY_DECISION_V01:
## the opening cinematic plays once per cold/native app launch. State lives in a static
## (process-lifetime) variable only:
##   - a true native restart = new process = fresh state -> may play again;
##   - internal navigation, Retry, returning from screens, re-creating the app root and
##     background/foreground resume all run in the SAME process -> never replay.
## This is launch-session state; it is NEVER written to the save, gameplay or economy.

static var _opening_consumed := false

## True exactly once per process: the caller that gets true plays the opening.
static func try_consume_opening() -> bool:
	if _opening_consumed:
		return false
	_opening_consumed = true
	return true

static func opening_consumed() -> bool:
	return _opening_consumed

## Test-only: simulate a new native process (cold launch). Never called by production.
static func debug_reset_for_new_process() -> void:
	_opening_consumed = false
