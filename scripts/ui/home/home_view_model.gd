extends RefCounted
## HomeViewModel — preload (res://scripts/ui/home/home_view_model.gd).
##
## M42 (SB-M42-015) — pure read-only projection of the canonical AppState services into
## the values the Home screen displays. It owns NO truth and caches nothing: every call
## re-reads the live services, so Home can never drift from (or duplicate) economy /
## progression state. Economy V1 semantics only — no Stars, Event Points, profile XP or
## coins exist here.

const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const WinStreakService = preload("res://scripts/economy/win_streak_service.gd")

const TRACK_POSITIONS := 5

## Returns a plain Dictionary snapshot (detached values only).
static func build(app) -> Dictionary:
	if app == null or app.economy == null:
		return {"ok": false}
	var e = app.economy
	var parts: Dictionary = e.robots.next_robot_progress()
	var gift_progress: int = e.gift.cycle_progress()
	var next_ms := -1
	for ms in GiftMeterService.MILESTONES:
		if int(ms) > gift_progress:
			next_ms = int(ms)
			break
	var streak: int = e.streak.streak()
	var track: Array = []
	for pos in range(1, TRACK_POSITIONS + 1):
		track.append({
			"position": pos,
			"sb": WinStreakService.streak_sb_for(pos),
			"reached": streak >= pos,
			"current": min(streak, TRACK_POSITIONS) == pos,
		})
	var dupes := 0
	for cid in e.collection.all_card_ids():
		dupes += int(e.exchange.exchangeable(cid))
	return {
		"ok": true,
		"blocked": bool(app.is_blocked),
		"level": int(app.progression.current_level()),
		"completed_levels": int(app.progression.completed_count()),
		"scrub_bucks": int(e.wallet.scrub_bucks()),
		"bot_parts": int(parts.get("parts", 0)),
		"bot_parts_target": int(parts.get("cost", 0)),
		"robot_can_unlock": bool(parts.get("can_unlock", false)),
		"hearts": int(e.hearts.hearts()),
		"hearts_max": int(e.hearts.max_hearts()),
		"heart_seconds_to_next": int(e.hearts.seconds_to_next()),
		"gift_progress": gift_progress,
		"gift_cycle_max": GiftMeterService.CYCLE_MAX,
		"gift_next_milestone": next_ms,
		"gift_claimable": e.gift.claimable().size(),
		"win_streak": streak,
		"win_streak_track": track,
		"daily_streak": int(e.daily.streak()),
		"daily_cycle_day": int(e.daily.cycle_day()),
		"daily_claimed_today": bool(e.daily.claimed_today()),
		"daily_next_day": int(e.daily.next_claim_cycle_day()),
		"cards_duplicates": dupes,
	}
