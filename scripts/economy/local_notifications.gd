extends RefCounted
## LocalNotifications — preload (res://scripts/economy/local_notifications.gd).
##
## SB-M43-172 — delivers NotificationPolicy reminders as ONE OS-scheduled local notification
## (no push server, no network). Native backend "ScrubbotsNotify" (native/): the Android plugin
## singleton or the iOS GDExtension class; none (desktop / web / headless, or a build without
## the plugin) = no-op.
##   - scheduled when the app goes to the background / closes (main.gd), cancelled on every open;
##   - only when REMINDERS is ON and the OS permission is granted (NotificationPermission);
##   - hearts: when they are full again; daily: next local day; event_ending: 24 h before the
##     end of an active event with a claimable reward. Gift needs play, so it is never predicted;
##   - the 24 h cap (policy last-sent high-water) is a lower bound, quiet hours move the time to
##     quiet_to; the earliest remaining reminder wins (same time: policy priority);
##   - a reminder whose time has passed at the next open counts as sent (policy.mark_sent).
## Economy section `local_notify`: absent = fresh; present = strict.

const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const NATIVE := "ScrubbotsNotify"
const SNAPSHOT_VERSION := 1

## schedule(title, body, seconds) / cancel_all(); tests inject a fake.
var backend = native_backend()
## Local time minus UTC in seconds (tests inject a fixed offset).
var utc_offset_fn := func() -> int:
	return int(round((Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system()) - Time.get_unix_time_from_system()) / 60.0)) * 60
var _notify: NotificationPolicy
var _permission
var _clock: Callable
var _pending_at := 0  ## fire time of the scheduled reminder, 0 = none

func _init(notify: NotificationPolicy, permission, clock: Callable = Callable()) -> void:
	_notify = notify
	_permission = permission
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())

static func native_backend():
	if Engine.has_singleton(NATIVE):
		return Engine.get_singleton(NATIVE)
	if ClassDB.class_exists(NATIVE):
		return ClassDB.instantiate(NATIVE)
	return null

## App foregrounded / started: drop the scheduled reminder (the player is here).
func on_app_open() -> void:
	if _pending_at > 0 and int(_clock.call()) >= _pending_at:
		_notify.mark_sent(_pending_at)
	_pending_at = 0
	if backend != null:
		backend.cancel_all()

## App backgrounded / closing. economy: EconomyServices; text: key -> copy. Returns the
## scheduled reminder ({category, key, at}) or {}.
func on_background(economy, blocked: bool, text: Callable) -> Dictionary:
	if backend == null:
		return {}
	backend.cancel_all()
	_pending_at = 0
	if blocked or not _notify.enabled or not _permission.granted():
		return {}
	var r := plan(economy)
	if not r.is_empty():
		var title := String(ProjectSettings.get_setting("application/config/name", ""))
		backend.schedule(title, String(text.call(r["key"])), int(r["at"]) - int(_clock.call()))
		_pending_at = int(r["at"])
	return r

## The one reminder to schedule now, or {} (categories off / nothing ahead).
func plan(economy) -> Dictionary:
	var now := int(_clock.call())
	var off := int(utc_offset_fn.call())
	var due: Array = []
	var h = economy.hearts
	if h.hearts() < h.max_hearts():
		var full: int = now + h.seconds_to_next() + (h.max_hearts() - h.hearts() - 1) * economy.config.hearts_regen_seconds()
		due.append({"category": "hearts", "key": "NOTIFY_HEARTS_FULL", "at": full})
	due.append({"category": "daily", "key": "NOTIFY_DAILY", "at": now - posmod(now + off, 86400) + 86400})
	for v in economy.events.list():
		if v["phase"] == "active" and int(v["claimable"]) > 0 and int(v["ends_in"]) > NotificationPolicy.EVENT_ENDING_S:
			due.append({"category": "event_ending", "key": "NOTIFY_EVENT_ENDING",
				"at": now + int(v["ends_in"]) - NotificationPolicy.EVENT_ENDING_S, "until": now + int(v["ends_in"])})
			break
	var best := {}
	for d in due:
		if not bool(_notify.categories.get(d["category"], false)):
			continue
		d["at"] = _outside_quiet(maxi(int(d["at"]), _notify.last_sent() + NotificationPolicy.CAP_S), off)
		if d.has("until") and int(d["at"]) >= int(d["until"]):
			continue
		if best.is_empty() or int(d["at"]) < int(best["at"]) or (int(d["at"]) == int(best["at"]) \
				and int(NotificationPolicy.PRIORITY[d["category"]]) > int(NotificationPolicy.PRIORITY[best["category"]])):
			best = d
	best.erase("until")
	return best

## ts, or the next quiet_to:00 local when ts falls in quiet hours. ponytail: fixed offset of
## today, so a DST switch before the reminder can shift it by an hour.
func _outside_quiet(ts: int, off: int) -> int:
	var local := posmod(ts + off, 86400)
	if not NotificationPolicy.in_quiet_hours(local / 3600, _notify.quiet_from, _notify.quiet_to):
		return ts
	var t := ts - local + _notify.quiet_to * 3600
	return t if t > ts else t + 86400

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "pending_at": _pending_at}

func import_snapshot(s) -> bool:
	if s == null:
		_pending_at = 0
		return true
	if typeof(s) != TYPE_DICTIONARY or int(s.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	var v = s.get("pending_at")
	if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) != floor(float(v)) or int(v) < 0:
		return false
	_pending_at = int(v)
	return true
