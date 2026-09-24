extends RefCounted
## DailyService — preload
## (res://scripts/economy/daily_service.gd).
##
## Daily login (repeating 5-day cycle) + three daily tasks (SB-M39-041..044).
## Uses an injected wall clock reduced to a local CALENDAR DAY index so tests
## are deterministic. Defensive monotonic claim record: a missed calendar day
## resets the streak/cycle; a clock rollback never duplicates a claim (the
## highest-claimed day index only moves forward).
##
## Rewards route through RewardGrantService (idempotent). Daily rewards NEVER
## feed the Gift Meter (owner §4 / SB-M39-014).

const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const LOGIN_CYCLE_DAYS := 5

var _config
var _reward
var _clock: Callable                 ## returns absolute unix seconds
var _login_rewards: Dictionary = {}  ## day(1..5) -> reward dict
var _task_sb: Array = []             ## [75,100,125]
var _all_tasks_booster := 0

var _last_claim_day := -1            ## calendar-day index of last login claim (monotonic).
var _streak := 0                     ## consecutive login count.
var _tasks_claimed_day := -1         ## calendar day tasks were last claimed.
var _tasks_done: Dictionary = {}     ## task_index -> true (current day).

func _init(config, reward, clock: Callable = Callable()) -> void:
	_config = config
	_reward = reward
	_clock = clock if clock.is_valid() else Callable(self, "_default_clock")
	var d = config.daily_config()
	var lr = d.get("login_rewards", {})
	for k in lr.keys():
		_login_rewards[int(k)] = lr[k]
	_task_sb = d.get("task_sb", [75, 100, 125])
	_all_tasks_booster = int(d.get("all_tasks_random_booster_charges", 1))

func _default_clock() -> int:
	return int(Time.get_unix_time_from_system())

func _today() -> int:
	# Calendar day index (UTC day number). Deterministic under the injected clock.
	return int(_clock.call() / 86400)

func streak() -> int:
	return _streak

func cycle_day() -> int:
	# 1..5 position in the repeating cycle for the current streak.
	if _streak <= 0:
		return 0
	return ((_streak - 1) % LOGIN_CYCLE_DAYS) + 1

## Claim today's login reward. Advances/repairs the streak by calendar day:
##   - same day already claimed -> no-op;
##   - exactly next day -> streak += 1;
##   - gap (missed day) OR clock rollback -> streak resets to 1.
## Returns {ok, day, reward} or {ok:false, reason}.
func claim_login() -> Dictionary:
	var today := _today()
	if today <= _last_claim_day:
		# Same day or a rolled-back clock: never duplicate a claim.
		return {"ok": false, "reason": "already_claimed_or_rollback"}
	if _last_claim_day >= 0 and today == _last_claim_day + 1:
		_streak += 1
	else:
		_streak = 1   # first login or missed a day -> reset cycle
	_last_claim_day = today
	# New day resets task progress.
	_tasks_done = {}
	_tasks_claimed_day = -1
	var day := cycle_day()
	var reward: Dictionary = _login_rewards.get(day, {})
	var tx := "daily_login:%d" % today
	_reward.grant(tx, reward)
	return {"ok": true, "day": day, "reward": reward}

# --------------------------------------------------------------- tasks ----

func mark_task_done(task_index: int) -> void:
	if task_index < 0 or task_index >= _task_sb.size():
		return
	_tasks_done[task_index] = true

func tasks_done_count() -> int:
	return _tasks_done.size()

## Claim a completed task's SB (once per calendar day per task).
func claim_task(task_index: int) -> Dictionary:
	if task_index < 0 or task_index >= _task_sb.size():
		return {"ok": false, "reason": "invalid_task"}
	if not _tasks_done.has(task_index):
		return {"ok": false, "reason": "not_done"}
	var today := _today()
	var tx := "daily_task:%d:%d" % [today, task_index]
	var sb := int(_task_sb[task_index])
	if not _reward.grant(tx, {EconomyWallet.SCRUB_BUCKS: sb}):
		return {"ok": false, "reason": "already_claimed"}
	return {"ok": true, "sb": sb}

## Claim the all-three-tasks bonus (1 random booster charge) once per day.
func claim_all_tasks_bonus() -> Dictionary:
	if _tasks_done.size() < _task_sb.size():
		return {"ok": false, "reason": "not_all_done"}
	var today := _today()
	var tx := "daily_all_tasks:%d" % today
	if not _reward.grant(tx, {"random_booster_charges": _all_tasks_booster}):
		return {"ok": false, "reason": "already_claimed"}
	return {"ok": true, "random_booster_charges": _all_tasks_booster}

# --------------------------------------------------------------- snapshot ----

func snapshot() -> Dictionary:
	# Persist current-day task completion so relaunch continuity survives (F-M39-008):
	# which tasks are done today and which day that progress belongs to.
	var done: Array = []
	for k in _tasks_done.keys():
		done.append(k)
	done.sort()
	return {
		"last_claim_day": _last_claim_day,
		"streak": _streak,
		"tasks_done": done,
		"tasks_claimed_day": _tasks_claimed_day,
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var d = IntDomain.exact_int(s.get("last_claim_day", -1))
	var st = IntDomain.nonneg_int(s.get("streak", 0))
	if d == null or st == null:
		return false
	# Task state (optional; missing => no task progress). Indices must be exact
	# ints within the task range.
	var tasks_done_raw = s.get("tasks_done", [])
	if typeof(tasks_done_raw) != TYPE_ARRAY:
		return false
	var new_done: Dictionary = {}
	for ti in tasks_done_raw:
		var idx = IntDomain.exact_int(ti)
		if idx == null or idx < 0 or idx >= _task_sb.size():
			return false
		new_done[idx] = true
	var tcd = IntDomain.exact_int(s.get("tasks_claimed_day", -1))
	if tcd == null:
		return false
	# All-or-nothing apply.
	_last_claim_day = d
	_streak = st
	_tasks_done = new_done
	_tasks_claimed_day = tcd
	return true
