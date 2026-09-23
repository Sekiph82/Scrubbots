extends RefCounted
## GiftMeterService — preload
## (res://scripts/economy/gift_meter_service.gd).
##
## M38 minimal canonical seam. Gift Meter progress comes from Win Streak SB ONLY
## (owner decision §4). Base level SB, Daily, Gift rewards, exchange, refunds and
## purchases must NEVER call `add_streak_sb`.
##
## Responsibilities in M38:
##   - accumulate streak-bonus SB into a 0..cycle_max cycle with rollover;
##   - detect newly-crossed milestones (10/50/250/500/1000) exactly once and
##     queue their ids into a Gift Bar queue;
##   - be idempotent per transaction id so a duplicate/reentrant streak callback
##     cannot advance progress or re-queue a milestone twice.
##
## Full milestone reward payout (booster charges, card packs, guaranteed-new
## card) is M39 behavior layered on top of this queue; M38 does not fabricate
## those subsystems.

const CYCLE_MAX := 1000
const MILESTONES := [10, 50, 250, 500, 1000]

var _cycle_progress: int = 0          ## progress within current cycle [0, CYCLE_MAX).
var _total_progress: int = 0          ## lifetime streak SB fed in.
var _cycles_completed: int = 0
## Milestone id occurrences queued for Gift Bar. Each entry is
## {"cycle": int, "milestone": int}. M39 consumes/claims these.
var _gift_bar_queue: Array = []
var _applied_tx: Dictionary = {}      ## tx_id -> true (idempotency).

## Feed streak-bonus SB. `tx_id` makes it idempotent. Returns the list of
## milestone occurrences newly queued by THIS call (empty if duplicate/no cross).
func add_streak_sb(tx_id: String, amount: int) -> Array:
	if tx_id.is_empty() or amount <= 0:
		return []
	if _applied_tx.has(tx_id):
		return []
	_applied_tx[tx_id] = true
	_total_progress += amount

	var newly: Array = []
	var remaining := amount
	while remaining > 0:
		var before := _cycle_progress
		var room := CYCLE_MAX - before
		var step: int = min(remaining, room)
		var after := before + step
		# Milestones crossed in this segment of the CURRENT cycle.
		for m in MILESTONES:
			if before < m and after >= m:
				var occ := {
					"id": "gift_ms:c%d:m%d" % [_cycles_completed, m],
					"cycle": _cycles_completed,
					"milestone": m,
					"claimed": false,
				}
				_gift_bar_queue.append(occ)
				newly.append(occ)
		_cycle_progress = after
		remaining -= step
		if _cycle_progress >= CYCLE_MAX:
			# Complete the cycle, rollover.
			_cycles_completed += 1
			_cycle_progress = 0
	return newly

func cycle_progress() -> int:
	return _cycle_progress

func total_progress() -> int:
	return _total_progress

func cycles_completed() -> int:
	return _cycles_completed

func gift_bar_queue() -> Array:
	return _gift_bar_queue.duplicate(true)

## Unclaimed queued milestone occurrences (Gift Bar surface). Never auto-consumed.
func claimable() -> Array:
	var out: Array = []
	for occ in _gift_bar_queue:
		if not occ.get("claimed", false):
			out.append(occ.duplicate())
	return out

## Claim one queued milestone occurrence by its stable id, granting the
## config-defined rewards through the reward service. Idempotent: the reward
## grant uses the occurrence id as its transaction id, and the occurrence is
## marked claimed. Returns {ok, rewards} or {ok:false}.
func claim(occurrence_id: String, reward_service, config) -> Dictionary:
	for occ in _gift_bar_queue:
		if occ.get("id", "") == occurrence_id:
			if occ.get("claimed", false):
				return {"ok": false, "reason": "already_claimed"}
			var rewards: Dictionary = config.gift_meter_milestone(int(occ["milestone"]))
			var applied = reward_service.grant(occurrence_id, rewards)
			if not applied and not reward_service.already_applied(occurrence_id):
				return {"ok": false, "reason": "grant_failed"}
			occ["claimed"] = true
			return {"ok": true, "rewards": rewards}
	return {"ok": false, "reason": "not_found"}

## Total Bot Parts a full 0->1000 cycle grants (proof helper for SB-M39-012).
func full_cycle_bot_parts(config) -> int:
	var total := 0
	for m in MILESTONES:
		total += int(config.gift_meter_milestone(m).get("bot_parts", 0))
	return total

func snapshot() -> Dictionary:
	return {
		"cycle_progress": _cycle_progress,
		"total_progress": _total_progress,
		"cycles_completed": _cycles_completed,
		"gift_bar_queue": _gift_bar_queue.duplicate(true),
		"applied": _applied_tx.keys(),
	}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var cp = s.get("cycle_progress", null)
	var tp = s.get("total_progress", null)
	var cc = s.get("cycles_completed", null)
	if not _is_nonneg_int(cp) or not _is_nonneg_int(tp) or not _is_nonneg_int(cc):
		return false
	if int(cp) >= CYCLE_MAX:
		return false
	var q = s.get("gift_bar_queue", [])
	if typeof(q) != TYPE_ARRAY:
		return false
	var applied = s.get("applied", [])
	if typeof(applied) != TYPE_ARRAY:
		return false
	_cycle_progress = int(cp)
	_total_progress = int(tp)
	_cycles_completed = int(cc)
	_gift_bar_queue = q.duplicate(true)
	_applied_tx = {}
	for tx in applied:
		_applied_tx[String(tx)] = true
	return true

func _is_nonneg_int(v) -> bool:
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return false
	return int(v) >= 0
