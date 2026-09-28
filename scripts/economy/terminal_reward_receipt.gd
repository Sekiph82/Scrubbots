extends RefCounted
## TerminalRewardReceipt — preload (res://scripts/economy/terminal_reward_receipt.gd).
##
## M43-C001A (SB-M43-001/003/004/007/010/012/013) — the read-only receipt of what ONE
## gameplay terminal actually committed. The production host captures authoritative
## service state immediately before its terminal economy transaction and again after
## the commit + save; the receipt is built ONLY from that before/after truth plus the
## committed service results (FirstClearTransaction / WinStreakService / GiftMeterService).
##
## It never grants, never recomputes rewards from config and never calls
## RewardGrantService. Results presents it; a presentation refresh cannot mutate it.
##
## reveal_queue is a deterministic, data-only order for a later owner-approved
## celebration (SB-M43-010): only committed, non-zero entries appear, in owner order
## first-clear SB -> Win Streak SB -> Bot Parts -> Gift Meter -> Collection cards.
## Presentation (or Reduced Effects) may show them instantly; nothing waits on it.
##
## follow_ups lists downstream ceremony handoffs (SB-M43-012/013) ONLY for events whose
## committed state changed in this terminal: newly queued Gift Meter milestones (claimed
## later in the Gift Bar), and robot / Collection set / Master Collection changes. There
## is no feature/world authority yet, so those are never emitted.

const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")

const SCHEMA := "scrubbots.results_receipt.v1"

const REVEAL_FIRST_CLEAR_SB := "first_clear_sb"
const REVEAL_WIN_STREAK_SB := "win_streak_sb"
const REVEAL_BOT_PARTS := "bot_parts"
const REVEAL_GIFT_METER := "gift_meter"
const REVEAL_COLLECTION_CARDS := "collection_cards"

## Authoritative state probe. Read-only.
static func capture(progression, economy) -> Dictionary:
	var queue_ids: Array = []
	for occ in economy.gift.gift_bar_queue():
		queue_ids.append(String(occ.get("id", "")))
	var cards := 0
	for n in economy.collection.snapshot().get("owned", {}).values():
		cards += int(n)
	return {
		"frontier": int(progression.current_level()) if progression != null else 0,
		"scrub_bucks": economy.wallet.scrub_bucks(),
		"bot_parts": economy.wallet.bot_parts(),
		"streak": economy.streak.streak(),
		"hearts": economy.hearts.hearts(),
		"gift_cycle_progress": economy.gift.cycle_progress(),
		"gift_cycles_completed": economy.gift.cycles_completed(),
		"gift_queue_ids": queue_ids,
		"cards_owned": cards,
		"sets_completed": economy.collection.completed_set_count(),
		"master_claimed": bool(economy.collection.snapshot().get("master_claimed", false)),
		"robots_unlocked": economy.robots.unlocked_count(),
	}

## Build the receipt. status: "WON" | "LOST"; commit: FirstClearTransaction result
## (WON only); save: the terminal save-boundary result.
static func build(status: String, level: int, pre: Dictionary, post: Dictionary,
		commit: Dictionary, save: Dictionary) -> Dictionary:
	var won := status == "WON"
	var committed: bool = won and bool(commit.get("ok", false))
	var fc: Dictionary = commit.get("first_clear", {}) if committed else {}
	var st: Dictionary = commit.get("streak", {}) if committed else {}
	var first_sb := int(fc.get("scrub_bucks", 0))
	var first_bp := int(fc.get("bot_parts", 0))
	var streak_sb := int(st.get("streak_sb", 0))
	var streak_bp := 1 if bool(st.get("bot_part", false)) else 0
	var sb_delta: int = post["scrub_bucks"] - pre["scrub_bucks"]
	var bp_delta: int = post["bot_parts"] - pre["bot_parts"]
	var cards_delta: int = post["cards_owned"] - pre["cards_owned"]
	var newly: Array = []
	for occ in st.get("gift_milestones", []):
		newly.append((occ as Dictionary).duplicate())
	var reason := "ok" if committed else String(commit.get("reason", "no_commit")) if won else "lost"
	var r := {
		"schema": SCHEMA,
		"status": status,
		"level": level,
		"first_clear": committed,
		# forward-only law: a WON that was not the frontier grants nothing (replay/stale).
		"already_cleared": won and String(commit.get("reason", "")) == "not_frontier",
		"commit_reason": reason,
		"commit_stage": String(commit.get("stage", "")),
		"difficulty": String(commit.get("difficulty", "")),
		"rewards": {
			"first_clear_sb": first_sb,
			"first_clear_bot_parts": first_bp,
			"win_streak_sb": streak_sb,
			"win_streak_bot_parts": streak_bp,
		},
		"wallet_delta": {"scrub_bucks": sb_delta, "bot_parts": bp_delta},
		# Committed components must explain the whole wallet change (no hidden grant).
		"reconciled": sb_delta == first_sb + streak_sb and bp_delta == first_bp + streak_bp,
		"streak": {"before": pre["streak"], "after": post["streak"]},
		"hearts": {"before": pre["hearts"], "after": post["hearts"]},
		"frontier": {"before": pre["frontier"], "after": post["frontier"]},
		"gift_meter": {
			"before": pre["gift_cycle_progress"], "after": post["gift_cycle_progress"],
			"cycles_before": pre["gift_cycles_completed"], "cycles_after": post["gift_cycles_completed"],
			"cycle_max": GiftMeterService.CYCLE_MAX, "newly_queued": newly,
		},
		"cards_delta": cards_delta,
		"saved": bool(save.get("ok", false)),
		"reveal_queue": [],
		"follow_ups": [],
	}
	var q: Array = r["reveal_queue"]
	if first_sb > 0:
		q.append({"kind": REVEAL_FIRST_CLEAR_SB, "amount": first_sb})
	if streak_sb > 0:
		q.append({"kind": REVEAL_WIN_STREAK_SB, "amount": streak_sb, "streak": post["streak"]})
	if first_bp + streak_bp > 0:
		q.append({"kind": REVEAL_BOT_PARTS, "amount": first_bp + streak_bp})
	if post["gift_cycle_progress"] != pre["gift_cycle_progress"] or post["gift_cycles_completed"] != pre["gift_cycles_completed"]:
		q.append({"kind": REVEAL_GIFT_METER, "from": pre["gift_cycle_progress"],
			"to": post["gift_cycle_progress"], "cycle_max": GiftMeterService.CYCLE_MAX,
			"milestones": newly.map(func(o): return int(o["milestone"]))})
	if cards_delta > 0:
		q.append({"kind": REVEAL_COLLECTION_CARDS, "amount": cards_delta})
	for i in range(q.size()):
		q[i]["seq"] = i
	var f: Array = r["follow_ups"]
	for occ in newly:
		# Only a milestone the Gift queue really holds is handed off (claim = Gift Bar).
		if (post["gift_queue_ids"] as Array).has(occ["id"]) and not (pre["gift_queue_ids"] as Array).has(occ["id"]):
			f.append({"kind": "gift_milestone", "occurrence_id": occ["id"],
				"milestone": occ["milestone"], "cycle": occ["cycle"], "claim_surface": "gift_bar"})
	if post["robots_unlocked"] > pre["robots_unlocked"]:
		f.append({"kind": "robot_unlock", "count": post["robots_unlocked"] - pre["robots_unlocked"]})
	if post["sets_completed"] > pre["sets_completed"]:
		f.append({"kind": "collection_set_complete", "count": post["sets_completed"] - pre["sets_completed"]})
	if post["master_claimed"] and not pre["master_claimed"]:
		f.append({"kind": "master_collection_complete"})
	r.make_read_only()
	return r
