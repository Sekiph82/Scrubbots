extends RefCounted
## WeeklyRanks — preload (res://scripts/progression/weekly_ranks.gd).
##
## SB-M43-131 (owner 2026-10-22): the RANKS weekly table counts the levels the player completed
## this week; the week resets Monday 00:00 UTC. Only committed campaign wins count (the gameplay
## host's first-clear WON): losses, disabled-level skips, boosters, Scrub Bucks and purchases
## add nothing. Clock-rollback safe: a win dated before the stored week is not counted and
## never rewrites it. Local only (no server); other players are not compared.
## Economy section `ranks`: absent = nothing counted; present = strict.

const SNAPSHOT_VERSION := 1
const WEEK_S := 7 * 86400
## 1970-01-05 00:00 UTC, the first Monday after the Unix epoch (a Thursday).
const MONDAY_EPOCH := 4 * 86400

var _clock: Callable
var _week := 0       ## Monday 00:00 UTC (unix s) of the counted week; 0 = nothing counted yet
var _count := 0

func _init(clock: Callable = Callable()) -> void:
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())

func now() -> int:
	return int(_clock.call())

## Monday 00:00 UTC (unix s) of the week holding `ts`.
static func week_start(ts: int) -> int:
	return ts - posmod(ts - MONDAY_EPOCH, WEEK_S)

## A committed campaign win. Returns true when it was counted (false = clock rolled back
## before the stored week).
func on_level_won() -> bool:
	var w := week_start(now())
	if w < _week:
		return false
	if w > _week:
		_week = w
		_count = 0
	_count += 1
	return true

## Levels completed in the current UTC week (0 after a reset or while the clock is behind).
func weekly_count() -> int:
	return _count if week_start(now()) == _week else 0

## Current week window: {start, end} unix s, end = next Monday 00:00 UTC (exclusive).
func window() -> Dictionary:
	var w := week_start(now())
	return {"start": w, "end": w + WEEK_S}

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "week_start": _week, "count": _count}

func import_snapshot(s) -> bool:
	if s == null:
		_week = 0
		_count = 0
		return true
	if typeof(s) != TYPE_DICTIONARY or s.size() != 3 or not _is_int(s.get("version")) or int(s["version"]) != SNAPSHOT_VERSION \
		or not _is_int(s.get("week_start")) or not _is_int(s.get("count")):
		return false
	var w := int(s["week_start"])
	var c := int(s["count"])
	if c < 0 or w < 0 or (w == 0) != (c == 0) or (w > 0 and week_start(w) != w):
		return false   # a counted week must be a Monday 00:00 UTC; "never counted" has no count
	_week = w
	_count = c
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
