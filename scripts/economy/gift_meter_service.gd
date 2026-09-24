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

const IntDomain = preload("res://scripts/economy/int_domain.gd")

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
	# Missing fields default to a fresh cycle (safe default); present-but-invalid
	# (fractional/NaN/INF/negative) fields fail closed.
	var cp = IntDomain.nonneg_int(s.get("cycle_progress", 0))
	var tp = IntDomain.nonneg_int(s.get("total_progress", 0))
	var cc = IntDomain.nonneg_int(s.get("cycles_completed", 0))
	if cp == null or tp == null or cc == null:
		return false
	if int(cp) >= CYCLE_MAX:
		return false
	# Coherence: total_progress must equal cycles_completed*CYCLE_MAX + cycle_progress.
	if int(tp) != int(cc) * CYCLE_MAX + int(cp):
		return false
	var q = s.get("gift_bar_queue", [])
	if typeof(q) != TYPE_ARRAY:
		return false
	# Canonical queue occurrence shape (M39 V03, F-M39-V02-012). Every entry must
	# be a dict with id (non-empty unique string) / cycle (nonneg int) / milestone
	# (in {10,50,250,500,1000}) / claimed (bool). Malformed entries fail closed.
	var seen_ids := {}
	var new_queue: Array = []
	for e in q:
		if typeof(e) != TYPE_DICTIONARY:
			return false
		var eid = e.get("id", null)
		if typeof(eid) != TYPE_STRING or String(eid).is_empty() or seen_ids.has(eid):
			return false
		seen_ids[eid] = true
		var cyc = IntDomain.nonneg_int(e.get("cycle", null))
		var mile = IntDomain.exact_int(e.get("milestone", null))
		var claimed = e.get("claimed", null)
		if cyc == null or mile == null or typeof(claimed) != TYPE_BOOL:
			return false
		if not MILESTONES.has(mile):
			return false
		new_queue.append({"id": String(eid), "cycle": cyc, "milestone": mile, "claimed": claimed})
	var applied = s.get("applied", [])
	if typeof(applied) != TYPE_ARRAY:
		return false
	# Applied tx ids must be non-empty unique strings.
	var new_applied := {}
	for tx in applied:
		if typeof(tx) != TYPE_STRING:
			return false
		var tid := String(tx)
		if tid.is_empty() or new_applied.has(tid):
			return false
		new_applied[tid] = true
	# All-or-nothing apply (nothing above mutated live state).
	_cycle_progress = int(cp)
	_total_progress = int(tp)
	_cycles_completed = int(cc)
	_gift_bar_queue = new_queue
	_applied_tx = new_applied
	return true
