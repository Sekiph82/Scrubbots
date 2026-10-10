extends RefCounted
## HomeBadges — preload (res://scripts/ui/home/home_badges.gd).
##
## M43-C010 (SB-M43-134) — one read-only attention model for Home shortcuts and BottomNav.
## Each surface gets a single count derived from canonical state (never stored, never pushed):
##   tasks       finished-but-unclaimed orders + an openable ScrubBox
##   daily       1 while today's login reward is claimable
##   gift_bar    queued Gift Meter milestones to claim
##   robots      unlocked-but-unseen robots + 1 when the next robot can be unlocked
##   collection  owned cards not yet viewed in the album
##   events      claimable event / First-Try rewards
##   rewarded_ads 1 while the ONE sequential Rewarded Ads frontier slot is actionable right now:
##               ready_free (slot 1) or ready_ad (slots 2..5, provider available); 0 when that
##               slot is claimed / pending / ad_unavailable / sequence- or rollback-locked /
##               unavailable (M47-FAMILY-APK-TOUCH-R01 owner decision; supersedes the older R15
##               "no Home badge" wording for this indicator only). Read from
##               RewardedDailyService.slot_state(current_slot()) - never a grant or a saved flag.
## Counts clear the moment the underlying state is handled, so nothing repeats or spams.

const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

static func compute(app) -> Dictionary:
	var out := {"tasks": 0, "daily": 0, "gift_bar": 0, "robots": 0, "collection": 0, "events": 0, "rewarded_ads": 0}
	if app == null or app.economy == null or app.is_blocked:
		return out
	var e = app.economy
	var all_done := true
	for o in e.orders.orders():
		if o["done"] and not o["claimed"]:
			out["tasks"] += 1
		all_done = all_done and bool(o["done"])
	if all_done and not e.daily.all_tasks_bonus_claimed():
		out["tasks"] += 1
	out["daily"] = 0 if e.daily.claimed_today() else 1
	out["gift_bar"] = e.gift.claimable().size()
	var initial := String(RobotRoster.load_roster()["initial_robot_id"])
	for id in RobotRoster.ids():
		if id != initial and e.robots.is_unlocked(id) and not e.meta_ui.is_seen("robot_seen:" + id):
			out["robots"] += 1
	if bool(e.robots.next_robot_progress().get("can_unlock", false)) and not RobotRoster.next_locked(e.robots).is_empty():
		out["robots"] += 1
	for cid in e.collection.all_card_ids():
		if e.collection.owned(cid) > 0 and not e.meta_ui.is_seen("card:" + String(cid)):
			out["collection"] += 1
	out["events"] = e.events.claimable_count()
	if e.rewarded_daily != null:
		var rd = e.rewarded_daily
		out["rewarded_ads"] = 1 if ["ready_free", "ready_ad"].has(rd.slot_state(rd.current_slot())) else 0
	return out
