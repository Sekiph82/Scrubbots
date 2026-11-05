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
##   achievements completed achievements whose reward is not claimed yet (SB-POLISH-007; drawn
##               on the Home profile card, which opens Profile -> Achievements)
##   rewarded_ads 1 while the ONE sequential Rewarded Ads frontier slot is actionable right now:
##               ready_free (slot 1) or ready_ad (slots 2..5, provider available); 0 when that
##               slot is claimed / pending / ad_unavailable / sequence- or rollback-locked /
##               unavailable (M47-FAMILY-APK-TOUCH-R01 owner decision; supersedes the older R15
##               "no Home badge" wording for this indicator only). Read from
##               RewardedDailyService.slot_state(current_slot()) - never a grant or a saved flag.
## Counts clear the moment the underlying state is handled, so nothing repeats or spams.
##
## SB-M44-013 — new_features(app): gated Home entries a NEW (fresh FTUE) profile has unlocked
## but not yet visited (meta_ui key "feature_visited:<feature>"). Established profiles never
## show NEW. Home draws it as a "NEW" pill; a numeric count on the same entry wins.

const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")

## SB-M44-031: Home entry -> feature id in the owner unlock table (AppState.feature_unlocked).
## Gift Bar and Hearts unlock at L1 and are never gated here.
const GATED_ENTRIES := {"shop": "shop", "collection": "collection", "tasks": "tasks", "daily": "daily",
	"robots": "robots", "events": "events", "leaderboard": "ranks"}

static func visited_key(feature_id: String) -> String:
	return "feature_visited:" + feature_id

static func new_features(app) -> Array:
	if app == null or app.economy == null or app.is_blocked or not app.economy.ftue.is_new_profile():
		return []
	# SB-M44-032: an entry open from L1 was never "newly unlocked", so it never shows NEW.
	return GATED_ENTRIES.keys().filter(func(id): return app.feature_unlock_level(GATED_ENTRIES[id]) > 1 and app.feature_unlocked(GATED_ENTRIES[id]) \
		and not app.economy.meta_ui.is_seen(visited_key(GATED_ENTRIES[id])))

static func compute(app) -> Dictionary:
	var out := {"tasks": 0, "daily": 0, "gift_bar": 0, "robots": 0, "collection": 0, "events": 0, "rewarded_ads": 0, "achievements": 0}
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
	out["achievements"] = Achievements.claimable_count(app)
	if e.rewarded_daily != null:
		var rd = e.rewarded_daily
		out["rewarded_ads"] = 1 if ["ready_free", "ready_ad"].has(rd.slot_state(rd.current_slot())) else 0
	return out
