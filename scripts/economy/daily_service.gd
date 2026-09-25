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
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")

const LOGIN_CYCLE_DAYS := 5

var _config
var _reward
## Wall-clock provider: returns absolute unix seconds.
var _clock: Callable
## Local calendar-day provider: returns the LocalCalendar civil-day ordinal
## (consecutive across month/year/leap). Owner-required LOCAL date semantics — NOT unix_seconds/86400 UTC-day
## (M39 V03, F-M39-V02-009). Tests inject this to cross local midnight
## deterministically; production defaults to LocalCalendar.system_provider().
var _local_day_provider: Callable
var _login_rewards: Dictionary = {}  ## day(1..5) -> reward dict
var _task_sb: Array = []             ## [75,100,125]
var _all_tasks_booster := 0

var _last_claim_day := -1            ## local calendar-day key of last login claim.
var _last_claim_ts := 0              ## wall-clock seconds of last login claim.
var _highest_seen_ts := 0            ## defensive monotonic clock high-water mark.
var _streak := 0                     ## consecutive login count.
var _tasks_claimed_day := -1         ## local calendar day tasks were last claimed.
var _tasks_day := -1                 ## local calendar day _tasks_done belongs to.
var _tasks_done: Dictionary = {}     ## task_index -> true (current day).

func _init(config, reward, clock: Callable = Callable(), local_day: Callable = Callable()) -> void:
	_config = config
	_reward = reward
	_clock = clock if clock.is_valid() else Callable(self, "_default_clock")
	# M39 V04 (F-M39-V03-002): production (no injected clock) uses the OS LOCAL
	# calendar date; never unix-seconds/86400. An injected test clock without an
	# injected provider derives its date at UTC offset 0 (deterministic tests).
	if local_day.is_valid():
		_local_day_provider = local_day
	elif clock.is_valid():
		_local_day_provider = LocalCalendar.offset_provider(_clock, 0)
	else:
		_local_day_provider = LocalCalendar.system_provider()
	var d = config.daily_config()
	var lr = d.get("login_rewards", {})
	for k in lr.keys():
		_login_rewards[int(k)] = lr[k]
	_task_sb = d.get("task_sb", [75, 100, 125])
	_all_tasks_booster = int(d.get("all_tasks_random_booster_charges", 1))

func _default_clock() -> int:
	return int(Time.get_unix_time_from_system())

func _today() -> int:
	# Owner-required LOCAL calendar-day key (F-M39-V02-009). Tests inject this
	# so a synthetic day cross does not require moving 86400 unix seconds.
	return int(_local_day_provider.call())

## Reset task state whenever the local day differs from the day _tasks_done
## belongs to. Prevents prior-day completion from leaking into a new day even
## when no login claim has run first (F-M39-V02-015).
func _sync_tasks_to_today() -> void:
	var today := _today()
	# Forward-only (M39 V04): a clock/local-day rollback never rewrites the task
	# day or wipes progress; task claims refuse while today < _tasks_day.
	if today > _tasks_day:
		_tasks_done = {}
		_tasks_day = today
		_tasks_claimed_day = -1

func streak() -> int:
	return _streak

func cycle_day() -> int:
	# 1..5 position in the repeating cycle for the current streak.
	if _streak <= 0:
		return 0
	return ((_streak - 1) % LOGIN_CYCLE_DAYS) + 1

## M42 (SB-M42-024) read-only presentation queries. They never mutate state.
## True when today's LOCAL-day login reward was already claimed.
func claimed_today() -> bool:
	return _last_claim_day >= 0 and _today() <= _last_claim_day

## Cycle day (1..5) a claim made today would grant (streak continues only when the last
## claim was exactly yesterday, mirroring claim_login()).
func next_claim_cycle_day() -> int:
	var today := _today()
	var next_streak := (_streak + 1) if (_last_claim_day >= 0 and today == _last_claim_day + 1) else 1
	if claimed_today():
		next_streak = _streak
	return ((max(next_streak, 1) - 1) % LOGIN_CYCLE_DAYS) + 1

## Configured login reward bundle for cycle day 1..5 (detached copy).
func login_reward_for(day: int) -> Dictionary:
	var r = _login_rewards.get(day, {})
	return (r as Dictionary).duplicate() if typeof(r) == TYPE_DICTIONARY else {}

## Claim today's login reward. Advances/repairs the streak by LOCAL calendar day
## (M39 V03, F-M39-V02-009/015):
##   - same day already claimed -> no-op;
##   - clock rollback below highest-seen ts -> fail closed;
##   - exactly next day (numeric next, tolerant of jumps > 1 as "missed") -> +1 or reset;
##   - login mutation is ATOMIC with the reward grant: if the RewardGrantService
##     grant fails and is not already-applied, NOTHING mutates (day/ts/streak/
##     tasks all untouched).
func claim_login() -> Dictionary:
	var today := _today()
	var now := int(_clock.call())
	if today <= _last_claim_day:
		return {"ok": false, "reason": "already_claimed_or_rollback"}
	if now < _highest_seen_ts:
		return {"ok": false, "reason": "clock_rollback"}
	# Compute the tentative next state without committing.
	var new_streak := (_streak + 1) if (_last_claim_day >= 0 and today == _last_claim_day + 1) else 1
	var new_cycle_day := ((new_streak - 1) % LOGIN_CYCLE_DAYS) + 1
	var reward: Dictionary = _login_rewards.get(new_cycle_day, {})
	var tx := "daily_login:%d" % today
	# Grant is atomic with the state transition (F-M39-V02-015). Idempotency: a
	# reward already applied for this tx id is treated as a successful commit so
	# a mid-flight crash+relaunch cannot leave state ahead of the reward.
	var granted = _reward.grant(tx, reward)
	if not granted and not _reward.already_applied(tx):
		return {"ok": false, "reason": "grant_failed"}
	# Commit local-day + streak + timestamps.
	_streak = new_streak
	_last_claim_day = today
	_last_claim_ts = now
	_highest_seen_ts = max(_highest_seen_ts, now)
	# A fresh day resets task progress — but never wipes tasks already done
	# earlier TODAY before the login claim.
	if _tasks_day != today:
		_tasks_done = {}
		_tasks_day = today
		_tasks_claimed_day = -1
	return {"ok": true, "day": new_cycle_day, "reward": reward}

# --------------------------------------------------------------- tasks ----

func mark_task_done(task_index: int) -> void:
	_sync_tasks_to_today()   # prior-day completion cannot leak into today
	if task_index < 0 or task_index >= _task_sb.size():
		return
	_tasks_done[task_index] = true

func tasks_done_count() -> int:
	_sync_tasks_to_today()
	return _tasks_done.size()

## Claim a completed task's SB (once per LOCAL calendar day per task).
func claim_task(task_index: int) -> Dictionary:
	_sync_tasks_to_today()
	if task_index < 0 or task_index >= _task_sb.size():
		return {"ok": false, "reason": "invalid_task"}
	if _today() < _tasks_day:
		return {"ok": false, "reason": "clock_rollback"}
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
	_sync_tasks_to_today()
	if _today() < _tasks_day:
		return {"ok": false, "reason": "clock_rollback"}
	if _tasks_done.size() < _task_sb.size():
		return {"ok": false, "reason": "not_all_done"}
	var today := _today()
	var tx := "daily_all_tasks:%d" % today
	if not _reward.grant(tx, {"random_booster_charges": _all_tasks_booster}):
		return {"ok": false, "reason": "already_claimed"}
	return {"ok": true, "random_booster_charges": _all_tasks_booster}

# --------------------------------------------------------------- snapshot ----

func snapshot() -> Dictionary:
	# Owner-required daily persisted state (M39 V03, F-M39-V02-009/015):
	# local-day key + last-claim timestamp + highest-seen timestamp (defensive
	# monotonic rollback guard) + task local-day + current task completion.
	var done: Array = []
	for k in _tasks_done.keys():
		done.append(k)
	done.sort()
	return {
		"last_claim_day": _last_claim_day,
		"last_claim_ts": _last_claim_ts,
		"highest_seen_ts": _highest_seen_ts,
		"streak": _streak,
		"tasks_day": _tasks_day,
		"tasks_done": done,
		"tasks_claimed_day": _tasks_claimed_day,
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var d = IntDomain.exact_int(s.get("last_claim_day", -1))
	var st = IntDomain.nonneg_int(s.get("streak", 0))
	var lts = IntDomain.nonneg_int(s.get("last_claim_ts", 0))
	var hts = IntDomain.nonneg_int(s.get("highest_seen_ts", 0))
	if d == null or st == null or lts == null or hts == null:
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
	var td = IntDomain.exact_int(s.get("tasks_day", -1))
	if tcd == null or td == null:
		return false
	# All-or-nothing apply.
	_last_claim_day = d
	_last_claim_ts = lts
	_highest_seen_ts = hts
	_streak = st
	_tasks_done = new_done
	_tasks_claimed_day = tcd
	_tasks_day = td
	return true
