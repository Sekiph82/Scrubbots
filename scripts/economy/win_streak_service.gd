extends RefCounted
## WinStreakService — preload
## (res://scripts/economy/win_streak_service.gd).
##
## Authoritative owner of the active progression Win Streak (owner decision §3).
## Increments ONLY on an authenticated first-clear progression WON. Grants the
## exact streak-SB mapping through RewardGrantService (never direct wallet
## mutation), feeds only the streak-bonus SB to GiftMeterService, and grants
## +1 Bot Part when the active streak reaches a multiple of 5.
##
## Idempotency: each level's first-clear is processed at most once
## (`_processed_levels`), and every grant/feed uses a stable per-level
## transaction id, so a duplicate/reentrant WON cannot double-advance streak,
## SB, Bot Parts, or Gift Meter progress.
##
## Reset: progression loss resets to 0; a restart AFTER real gameplay began
## counts as a loss and resets; a pre-action exit resets nothing. Replay never
## advances streak or economy.

const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

const SNAPSHOT_SCHEMA := "scrubbots.winstreak.v1"

var _reward: RewardGrantService
var _gift: GiftMeterService
var _streak: int = 0
var _processed_levels: Dictionary = {}   ## level_number -> true (first-clear processed).
var _gameplay_started: bool = false      ## transient; not persisted.

func _init(reward: RewardGrantService = null, gift: GiftMeterService = null) -> void:
	_reward = reward if reward != null else RewardGrantService.new()
	_gift = gift if gift != null else GiftMeterService.new()

func reward_service() -> RewardGrantService:
	return _reward

func gift_service() -> GiftMeterService:
	return _gift

func streak() -> int:
	return _streak

# --------------------------------------------------- attempt lifecycle ----

## Called when the first real gameplay action of an attempt occurs. Arms the
## restart-after-gameplay reset.
func on_gameplay_started() -> void:
	_gameplay_started = true

## Read-only probe: has real gameplay been armed for the current attempt?
## Used by the production host to decide whether a Retry consumes a Heart
## (post-action) or not (pre-action). Reflects the same flag on_restart consumes.
func gameplay_started() -> bool:
	return _gameplay_started

## Progression loss: always reset.
func on_progression_loss() -> void:
	_streak = 0
	_gameplay_started = false

## Restart: resets ONLY if real gameplay had begun (counts as a loss). A pre-
## action exit/restart leaves the streak intact.
func on_restart() -> void:
	if _gameplay_started:
		_streak = 0
	_gameplay_started = false

## Pre-action exit: no streak/Heart consequence.
func on_pre_action_exit() -> void:
	_gameplay_started = false

# --------------------------------------------------- streak SB mapping ----

## Owner-locked mapping, based on the active streak AFTER increment.
static func streak_sb_for(active_streak: int) -> int:
	if active_streak <= 0:
		return 0
	match active_streak:
		1: return 1
		2: return 5
		3: return 10
		4: return 25
		_: return 100

# --------------------------------------------------- process a win ----

## Process an authenticated first-clear progression WON for `level_number`.
## Returns a result dict: {applied, streak, streak_sb, bot_part, reason}.
## Duplicate/replay/invalid calls return applied=false and change nothing.
func process_first_clear_win(level_number: int, is_replay: bool = false) -> Dictionary:
	if is_replay:
		return {"applied": false, "reason": "replay", "streak": _streak}
	if level_number < 1:
		return {"applied": false, "reason": "invalid_level", "streak": _streak}
	if _processed_levels.has(level_number):
		return {"applied": false, "reason": "duplicate", "streak": _streak}

	# Tentatively advance, then grant atomically. Roll back on unexpected grant failure.
	var new_streak := _streak + 1
	var sb := streak_sb_for(new_streak)
	var sb_tx := "streak_sb:L%d" % level_number
	var granted_sb := _reward.grant(sb_tx, {EconomyWallet.SCRUB_BUCKS: sb})
	if not granted_sb and not _reward.already_applied(sb_tx):
		# Unexpected failure (e.g. unknown resource). Do not advance economics.
		return {"applied": false, "reason": "reward_failed", "streak": _streak}

	# Commit streak advance and mark processed.
	_streak = new_streak
	_processed_levels[level_number] = true
	_gameplay_started = false

	# Feed ONLY streak-bonus SB to the gift meter.
	_gift.add_streak_sb("gift:L%d" % level_number, sb)

	# Bot Part at every multiple of 5.
	var bot_part := false
	if _streak % 5 == 0:
		bot_part = _reward.grant("streak_bp5:L%d" % level_number, {EconomyWallet.BOT_PARTS: 1})

	return {
		"applied": true,
		"streak": _streak,
		"streak_sb": sb,
		"bot_part": bot_part,
		"reason": "ok",
	}

# --------------------------------------------------- snapshot / import ----

func snapshot() -> Dictionary:
	var processed: Array = _processed_levels.keys()
	processed.sort()
	return {
		"schema": SNAPSHOT_SCHEMA,
		"streak": _streak,
		"processed": processed,
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	# A missing streak section keeps the fresh default (streak 0). A present
	# section must carry the correct schema.
	if s.is_empty():
		return true
	if s.get("schema", "") != SNAPSHOT_SCHEMA:
		return false
	# Integer state must be an exact integer (int or integral float); fractional,
	# NaN or INF fails closed rather than silently truncating (M38 V02).
	var st_i = _as_exact_int(s.get("streak", null))
	if st_i == null or st_i < 0:
		return false
	var processed_raw = s.get("processed", null)
	if typeof(processed_raw) != TYPE_ARRAY:
		return false
	var new_processed: Dictionary = {}
	for v in processed_raw:
		var iv = _as_exact_int(v)
		if iv == null or iv < 1:
			return false
		if new_processed.has(iv):
			return false   # duplicate processed id => corrupt snapshot, fail closed
		new_processed[iv] = true
	# All-or-nothing apply (nothing above mutated live state).
	_streak = st_i
	_processed_levels = new_processed
	_gameplay_started = false
	return true

## Returns the exact integer value of `v`, or null if `v` is not an exact
## integer (non-numeric, fractional float, NaN or INF).
func _as_exact_int(v):
	if typeof(v) == TYPE_INT:
		return v
	if typeof(v) == TYPE_FLOAT:
		if is_nan(v) or is_inf(v) or floor(v) != v:
			return null
		return int(v)
	return null
