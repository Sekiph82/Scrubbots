extends RefCounted
## NotificationPermission — preload (res://scripts/economy/notification_permission.gd).
##
## SB-M43-146 — contextual OS notification permission. Never asked on boot: the only trigger is
## the player turning REMINDERS ON (NotificationPolicy opt-in, OFF by default), where a native
## explainer popup says why before the OS dialog. "Not now" never calls the OS and starts a
## data-driven cooldown (data/config/notification_permission_v1.json); "Allow" makes exactly one
## OS request. Android only (Godot built-in OS.request_permission, POST_NOTIFICATIONS, API 33+).
## TODO(iOS): UNUserNotificationCenter authorization needs a native plugin (TASKS SB-M43-171);
## until then iOS / desktop are a no-op. No gameplay / economy effect.
## Economy section `notify_permission`: absent = fresh; present = strict.

const PATH := "res://data/config/notification_permission_v1.json"
const SCHEMA := "scrubbots.notification_permission.v1"
const PERMISSION := "android.permission.POST_NOTIFICATIONS"
const SNAPSHOT_VERSION := 1

var cooldown_s := 7 * 86400
## Platform seam (tests swap these for a fake OS permission API).
var platform := OS.get_name()
var granted_fn := func() -> bool: return OS.get_granted_permissions().has(PERMISSION)
var request_fn := func() -> void: OS.request_permission(PERMISSION)
var _clock: Callable
var _asked_at := 0       ## last "Allow" (OS request made) ts, 0 = never
var _declined_at := 0    ## last "Not now" ts, 0 = never

func _init(clock: Callable = Callable(), path: String = PATH) -> void:
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(d) == TYPE_DICTIONARY and d.get("schema") == SCHEMA:
			cooldown_s = maxi(1, int(d.get("decline_cooldown_days", 7))) * 86400

func supported() -> bool:
	return platform == "Android"

func granted() -> bool:
	return supported() and bool(granted_fn.call())

## True when the explainer should show now: Android, not granted, outside the cooldown after
## the last "Not now" / "Allow" (an OS-level denial is never re-asked inside it either).
func should_explain() -> bool:
	if not supported() or granted():
		return false
	var last := maxi(_asked_at, _declined_at)
	return last == 0 or int(_clock.call()) - last >= cooldown_s

func decline() -> void:
	_declined_at = int(_clock.call())

func allow() -> void:
	_asked_at = int(_clock.call())
	request_fn.call()

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "asked_at": _asked_at, "declined_at": _declined_at}

func import_snapshot(s) -> bool:
	if s == null:
		_asked_at = 0
		_declined_at = 0
		return true
	if typeof(s) != TYPE_DICTIONARY or int(s.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	for k in ["asked_at", "declined_at"]:
		var v = s.get(k)
		if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) != floor(float(v)) or int(v) < 0:
			return false
	_asked_at = int(s["asked_at"])
	_declined_at = int(s["declined_at"])
	return true
