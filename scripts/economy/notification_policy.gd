extends RefCounted
## NotificationPolicy — preload (res://scripts/economy/notification_policy.gd).
##
## M43-C012 / C012R (SB-M43-145/147/148/149, R12-004..006) — the ONE decision authority for
## proactive (retention) notifications. Platform delivery is not wired: Godot ships no local
## notification API, so a native plugin / platform decision is required (SB-M43-146 BLOCKED);
## this authority decides WHAT may be sent and keeps the player's preferences.
##   - opt-in: global OFF by default; per-category toggles (hearts, daily, event_ending, gift);
##   - quiet hours on the player's local clock (default 22:00-08:00);
##   - priority + dedup: simultaneous candidates collapse into ONE message (highest priority);
##   - cap: at most one proactive push per rolling 24 h (sent log persisted);
##   - stale suppression: every candidate is re-derived from current state, so consumed /
##     already-claimed prompts are never produced; copy is factual (no false expiry claims);
##   - deep links only to known destinations; anything else falls back to "home".
## Economy section `notifications`: absent = defaults; present = strict.

const CATEGORIES := ["hearts", "daily", "event_ending", "gift"]
## Higher first: a reward that can actually expire beats routine reminders.
const PRIORITY := {"event_ending": 4, "daily": 3, "gift": 2, "hearts": 1}
const DESTINATIONS := ["home", "daily", "tasks", "gift_bar", "events", "shop", "collection", "robots", "profile"]
const CAP_S := 86400
const EVENT_ENDING_S := 24 * 3600
const SNAPSHOT_VERSION := 1

var enabled := false
var categories := {"hearts": true, "daily": true, "event_ending": true, "gift": true}
var quiet_from := 22
var quiet_to := 8
var _last_sent := 0

static func deep_link(dest: String) -> String:
	return dest if DESTINATIONS.has(dest) else "home"

static func in_quiet_hours(hour: int, start: int, end: int) -> bool:
	if start == end:
		return false
	return (hour >= start or hour < end) if start > end else (hour >= start and hour < end)

## Current candidates from LIVE state (stale prompts can never appear). app: AppState.
static func candidates(app) -> Array:
	var e = app.economy
	var out: Array = []
	if e.hearts.hearts() >= e.hearts.max_hearts():
		out.append({"category": "hearts", "key": "NOTIFY_HEARTS_FULL", "link": "home"})
	if not e.daily.claimed_today():
		out.append({"category": "daily", "key": "NOTIFY_DAILY", "link": "daily"})
	if e.gift.claimable().size() > 0:
		out.append({"category": "gift", "key": "NOTIFY_GIFT", "link": "gift_bar"})
	for v in e.events.list():
		if v["phase"] == "active" and int(v["ends_in"]) <= EVENT_ENDING_S and int(v["claimable"]) > 0:
			out.append({"category": "event_ending", "key": "NOTIFY_EVENT_ENDING", "link": "events"})
			break
	return out

## The single message to send now, or {} (opt-out, category off, quiet hours, cap, nothing).
func decide(app, now_ts: int, local_hour: int) -> Dictionary:
	if not enabled or app == null or app.is_blocked:
		return {}
	if in_quiet_hours(local_hour, quiet_from, quiet_to):
		return {}
	if _last_sent > 0 and now_ts - _last_sent < CAP_S and now_ts >= _last_sent:
		return {}
	var best := {}
	for c in candidates(app):
		if not bool(categories.get(c["category"], false)):
			continue
		if best.is_empty() or int(PRIORITY[c["category"]]) > int(PRIORITY[best["category"]]):
			best = c
	if not best.is_empty():
		best["link"] = deep_link(String(best["link"]))
	return best

func mark_sent(now_ts: int) -> void:
	_last_sent = maxi(_last_sent, now_ts)

func set_category(cat: String, on: bool) -> bool:
	if not CATEGORIES.has(cat):
		return false
	categories[cat] = on
	return true

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "enabled": enabled, "categories": categories.duplicate(),
		"quiet_from": quiet_from, "quiet_to": quiet_to, "last_sent": _last_sent}

func import_snapshot(s) -> bool:
	if s == null:
		enabled = false
		categories = {"hearts": true, "daily": true, "event_ending": true, "gift": true}
		quiet_from = 22
		quiet_to = 8
		_last_sent = 0
		return true
	if typeof(s) != TYPE_DICTIONARY or int(s.get("version", -1)) != SNAPSHOT_VERSION or typeof(s.get("enabled")) != TYPE_BOOL or typeof(s.get("categories")) != TYPE_DICTIONARY:
		return false
	var cats := {}
	for c in CATEGORIES:
		if typeof(s["categories"].get(c)) != TYPE_BOOL:
			return false
		cats[c] = s["categories"][c]
	if s["categories"].size() != CATEGORIES.size():
		return false
	for k in ["quiet_from", "quiet_to", "last_sent"]:
		var v = s.get(k)
		if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) != floor(float(v)) or int(v) < 0:
			return false
	if int(s["quiet_from"]) > 23 or int(s["quiet_to"]) > 23:
		return false
	enabled = s["enabled"]
	categories = cats
	quiet_from = int(s["quiet_from"])
	quiet_to = int(s["quiet_to"])
	_last_sent = int(s["last_sent"])
	return true
