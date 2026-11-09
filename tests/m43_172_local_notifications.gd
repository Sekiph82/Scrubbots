extends SceneTree
## SB-M43-172 / SB-M43-171 — local reminder scheduling (LocalNotifications) with a fake native
## backend, a fake permission and an injected clock / UTC offset; lifecycle on the REAL app root:
##   n01 desktop: no native backend, no-op · n02 reminders OFF = nothing · n03 permission denied
##   = nothing · n04 earliest reminder, copy, seconds · n05 quiet hours · n06 24 h cap + priority
##   · n07 categories + event ending · n08 app open cancels / counts a passed reminder as sent ·
##   n09 persisted, strict import · n10 pause schedules, resume + cold start cancel (main.tscn) ·
##   n11 iOS permission through the native seam · n12 native sources + build wiring (static).
##
## Run: godot --headless --path . -s res://tests/m43_172_local_notifications.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const LocalNotifications = preload("res://scripts/economy/local_notifications.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const NotificationPermission = preload("res://scripts/economy/notification_permission.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## 1790000000 = 14:13:20 UTC; offset 0 below, so local == UTC.
const NOW := 1790000000
const MIDNIGHT := 1790035200
const DAY := 86400

var EXPECTED_CASES := ["n01_desktop_noop", "n02_reminders_off", "n03_permission_denied", "n04_earliest_reminder",
	"n05_quiet_hours", "n06_cap_priority", "n07_categories_event", "n08_open_cancels", "n09_persisted_strict",
	"n10_app_lifecycle", "n11_ios_permission", "n12_native_wiring"]

class FakeHearts:
	var h := 3
	var mx := 5
	var next := 300
	func hearts() -> int: return h
	func max_hearts() -> int: return mx
	func seconds_to_next() -> int: return next

class FakeConfig:
	func hearts_regen_seconds() -> int: return 900

class FakeEvents:
	var items: Array = []
	func list() -> Array: return items

class FakeEconomy:
	var hearts := FakeHearts.new()
	var config := FakeConfig.new()
	var events := FakeEvents.new()

class FakeBackend:
	var scheduled: Array = []
	var cancels := 0
	func schedule(title: String, body: String, seconds: int) -> void: scheduled.append([title, body, seconds])
	func cancel_all() -> void: cancels += 1

class FakePermission:
	var ok := true
	func granted() -> bool: return ok

class FakeNative:
	var enabled := false
	var requests := 0
	func notifications_enabled() -> bool: return enabled
	func request_authorization() -> void: requests += 1

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [NOW]
var _text := func(k): return "copy:" + String(k)

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_n01()
	_n02_n03()
	_n04()
	_n05()
	_n06()
	_n07()
	_n08()
	_n09()
	await _n10()
	_n11()
	_n12()
	_shutdown()
	_cleanup()
	_done()

## [LocalNotifications, policy (ON), permission (granted), backend]
func _make() -> Array:
	_now[0] = NOW
	var pol := NotificationPolicy.new()
	pol.enabled = true
	var perm := FakePermission.new()
	var ln := LocalNotifications.new(pol, perm, func(): return _now[0])
	ln.utc_offset_fn = func(): return 0
	var b := FakeBackend.new()
	ln.backend = b
	return [ln, pol, perm, b]

func _n01() -> void:
	print("[n01 desktop / headless: no native backend, every call is a no-op]")
	_ok(LocalNotifications.native_backend() == null, "no ScrubbotsNotify singleton / class on this host")
	var ln := LocalNotifications.new(NotificationPolicy.new(), FakePermission.new(), func(): return NOW)
	ln.on_app_open()
	_ok(ln.backend == null and ln.on_background(FakeEconomy.new(), false, _text).is_empty() and ln.snapshot()["pending_at"] == 0, "on_background schedules nothing, nothing pending")
	_complete("n01_desktop_noop")

func _n02_n03() -> void:
	print("[n02 reminders OFF / n03 permission denied / blocked save: nothing scheduled]")
	var m := _make()
	m[1].enabled = false
	_ok(m[0].on_background(FakeEconomy.new(), false, _text).is_empty() and m[3].scheduled.is_empty() and m[3].cancels == 1, "reminders OFF: old reminder cancelled, none scheduled")
	_complete("n02_reminders_off")
	m = _make()
	m[2].ok = false
	_ok(m[0].on_background(FakeEconomy.new(), false, _text).is_empty() and m[3].scheduled.is_empty(), "permission denied: none scheduled")
	m = _make()
	_ok(m[0].on_background(FakeEconomy.new(), true, _text).is_empty() and m[3].scheduled.is_empty(), "blocked (future-schema) save: none scheduled")
	_complete("n03_permission_denied")

func _n04() -> void:
	print("[n04 earliest reminder: hearts full before the next daily reward]")
	var m := _make()
	var e := FakeEconomy.new()
	var r: Dictionary = m[0].on_background(e, false, _text)
	_ok(r.get("category") == "hearts" and int(r["at"]) == NOW + 300 + 900, "3/5 hearts, 300 s + 1 x 900 s -> hearts at now+1200 (%s)" % str(r))
	_ok(m[3].scheduled == [[String(ProjectSettings.get_setting("application/config/name")), "copy:NOTIFY_HEARTS_FULL", 1200]], "one OS schedule: app title, policy copy key, seconds %s" % str(m[3].scheduled))
	_ok(UiText.t("NOTIFY_HEARTS_FULL") != "NOTIFY_HEARTS_FULL", "copy key has English text")
	e.hearts.h = 5
	r = m[0].plan(e)
	_ok(r.get("category") == "daily" and int(r["at"]) == MIDNIGHT + 8 * 3600, "hearts full: daily at the next local day, moved out of 22-08 quiet hours to 08:00 (%s)" % str(r))
	m[0].utc_offset_fn = func(): return 3 * 3600
	r = m[0].plan(e)
	_ok(int(r["at"]) == MIDNIGHT - 3 * 3600 + 8 * 3600, "UTC+3: next local day starts 3 h earlier in UTC (%s)" % str(r))
	_complete("n04_earliest_reminder")

func _n05() -> void:
	print("[n05 quiet hours on the local clock]")
	var m := _make()
	m[1].quiet_from = 14
	m[1].quiet_to = 16
	var r: Dictionary = m[0].plan(FakeEconomy.new())
	_ok(r.get("category") == "hearts" and int(r["at"]) == MIDNIGHT - DAY + 16 * 3600, "hearts at 14:33 inside 14-16 -> 16:00 (%s)" % str(r))
	m[1].quiet_from = 14
	m[1].quiet_to = 14
	_ok(int(m[0].plan(FakeEconomy.new())["at"]) == NOW + 1200, "from == to: no quiet hours")
	_complete("n05_quiet_hours")

func _n06() -> void:
	print("[n06 24 h cap is a lower bound; same time -> policy priority]")
	var m := _make()
	m[1].mark_sent(NOW - 3600)
	var r: Dictionary = m[0].plan(FakeEconomy.new())
	_ok(int(r["at"]) == NOW - 3600 + DAY and r["category"] == "daily", "sent 1 h ago: earliest at last_sent + 24 h; hearts vs daily tie -> daily (priority 3 > 1) (%s)" % str(r))
	_complete("n06_cap_priority")

func _n07() -> void:
	print("[n07 per-category toggles; event ending 24 h before its end]")
	var m := _make()
	var e := FakeEconomy.new()
	m[1].set_category("hearts", false)
	_ok(m[0].plan(e).get("category") == "daily", "hearts off -> daily")
	m[1].set_category("daily", false)
	_ok(m[0].plan(e).is_empty(), "hearts + daily off, no event -> nothing")
	e.events.items = [{"phase": "active", "ends_in": 3 * DAY, "claimable": 1}]
	var r: Dictionary = m[0].plan(e)
	_ok(r.get("category") == "event_ending" and int(r["at"]) == NOW + 2 * DAY and not r.has("until"), "event ends in 3 d with a claimable reward -> reminder 24 h before the end (%s)" % str(r))
	e.events.items = [{"phase": "active", "ends_in": 3 * DAY, "claimable": 0}]
	_ok(m[0].plan(e).is_empty(), "nothing claimable -> no event reminder")
	e.events.items = [{"phase": "active", "ends_in": DAY + 3600, "claimable": 1}]
	m[1].mark_sent(NOW - 3600)
	m[1].quiet_from = 13
	m[1].quiet_to = 16
	_ok(m[0].plan(e).is_empty(), "cap + quiet hours push it past the event end -> dropped")
	m[1].set_category("event_ending", false)
	m[1].quiet_from = 22
	m[1].quiet_to = 8
	_ok(m[0].plan(e).is_empty(), "event_ending off -> nothing")
	_complete("n07_categories_event")

func _n08() -> void:
	print("[n08 app open cancels; a reminder whose time passed counts as sent]")
	var m := _make()
	m[0].on_background(FakeEconomy.new(), false, _text)
	var at := int(m[0].snapshot()["pending_at"])
	_now[0] = at - 1
	m[0].on_app_open()
	_ok(m[3].cancels == 2 and m[1].last_sent() == 0 and m[0].snapshot()["pending_at"] == 0, "open before it fired: cancelled, cap untouched")
	m[0].on_background(FakeEconomy.new(), false, _text)
	at = int(m[0].snapshot()["pending_at"])
	_now[0] = at + 50
	m[0].on_app_open()
	_ok(m[1].last_sent() == at and m[0].snapshot()["pending_at"] == 0, "open after it fired: cap high-water = its fire time")
	_complete("n08_open_cancels")

func _n09() -> void:
	print("[n09 snapshot / strict import]")
	var m := _make()
	m[0].on_background(FakeEconomy.new(), false, _text)
	var snap: Dictionary = m[0].snapshot()
	var other: Array = _make()
	_ok(other[0].import_snapshot(snap) and other[0].snapshot() == snap and int(snap["pending_at"]) == NOW + 1200, "round trip %s" % str(snap))
	_ok(other[0].import_snapshot(null) and other[0].snapshot() == {"version": 1, "pending_at": 0}, "absent section = fresh")
	for bad in [{"version": 2, "pending_at": 0}, {"version": 1, "pending_at": -1}, {"version": 1}, {"version": 1, "pending_at": 1.5}, "x"]:
		_ok(not other[0].import_snapshot(bad), "rejects %s" % str(bad))
	_complete("n09_persisted_strict")

func _n10() -> void:
	print("[n10 real app root: pause schedules + saves, resume cancels, cold start counts a fired one]")
	_now[0] = NOW
	var path := _tmp_path("n10")
	await _reboot(path)
	var a = _root.get_app_state()
	var ln = a.economy.local_notify
	var b := FakeBackend.new()
	ln.backend = b
	ln.utc_offset_fn = func(): return 0
	a.economy.notify_permission.platform = "Android"
	a.economy.notify_permission.granted_fn = func() -> bool: return true
	_root.notification(NOTIFICATION_APPLICATION_PAUSED)
	_ok(b.scheduled.is_empty(), "reminders OFF (default): pause schedules nothing")
	a.economy.notify.enabled = true
	_root.notification(NOTIFICATION_APPLICATION_PAUSED)
	_ok(b.scheduled.size() == 1 and b.scheduled[0][1] == UiText.t("NOTIFY_DAILY"), "reminders ON + granted: pause schedules one reminder with its copy %s" % str(b.scheduled))
	var at := int(ln.snapshot()["pending_at"])
	_ok(at > NOW, "pending reminder recorded (%d)" % at)
	var c := b.cancels
	_root.notification(NOTIFICATION_APPLICATION_RESUMED)
	_ok(b.cancels == c + 1 and ln.snapshot()["pending_at"] == 0, "resume cancels it")
	_root.notification(NOTIFICATION_APPLICATION_PAUSED)
	_shutdown()
	_now[0] = at + 60
	await _reboot(path)
	a = _root.get_app_state()
	_ok(a.economy.notify.last_sent() == at and a.economy.local_notify.snapshot()["pending_at"] == 0, "cold start after it fired: saved pending -> counted as sent (cap), cleared")
	_complete("n10_app_lifecycle")

func _n11() -> void:
	print("[n11 iOS permission through the native ScrubbotsNotify seam]")
	var np := NotificationPermission.new(func(): return NOW)
	np.platform = "iOS"
	_ok(not np.supported() and not np.should_explain(), "iOS without the native class: unsupported, no explainer")
	var f := FakeNative.new()
	np.native = f
	_ok(np.supported() and not np.granted() and np.should_explain(), "iOS with it: supported, not determined -> explainer")
	np.allow()
	_ok(f.requests == 1, "Allow -> exactly one requestAuthorization")
	f.enabled = true
	_ok(np.granted() and not np.should_explain(), "authorized -> granted, never explained again")
	np.platform = "Android"
	f.enabled = false
	_ok(not np.granted(), "Android with the plugin: granted = areNotificationsEnabled")
	_complete("n11_ios_permission")

func _n12() -> void:
	print("[n12 native sources + build wiring (static)]")
	var java := FileAccess.get_file_as_string("res://native/android/scrubbots_notify/src/com/scrubbots/notify/ScrubbotsNotifyPlugin.java")
	_ok(java.contains("\"ScrubbotsNotify\"") and java.contains("setAndAllowWhileIdle") and not java.contains("setExact"), "Android plugin: name ScrubbotsNotify, inexact idle alarm")
	for m in ["notifications_enabled", "schedule", "cancel_all"]:
		_ok(java.contains("public boolean " + m) or java.contains("public void " + m), "Android exposes " + m)
	var man := FileAccess.get_file_as_string("res://native/android/scrubbots_notify/AndroidManifest.xml")
	_ok(man.contains("org.godotengine.plugin.v2.ScrubbotsNotify") and man.contains("android:exported=\"false\"") and man.contains("android:targetSdkVersion") and not man.contains("uses-permission"), "AAR manifest: v2 plugin, private receiver, uses-sdk, no permission")
	var objc := FileAccess.get_file_as_string("res://native/ios/scrubbots_notify/scrubbots_notify.m")
	var gdext := FileAccess.get_file_as_string("res://native/ios/scrubbots_notify/scrubbots_notify.gdextension")
	_ok(gdext.contains("entry_symbol = \"scrubbots_notify_init\"") and objc.contains("scrubbots_notify_init(") and objc.contains("\"ScrubbotsNotify\""), "iOS GDExtension entry symbol + class name match")
	for m in ["notifications_enabled", "request_authorization", "schedule", "cancel_all"]:
		_ok(objc.contains("add_method(\"%s\"" % m), "iOS exposes " + m)
	_ok(FileAccess.file_exists("res://native/.gdignore"), "native/ is ignored by the Godot import")
	var preset := FileAccess.get_file_as_string("res://.github/android/export_presets_family_first10.cfg")
	_ok(preset.contains("gradle_build/use_gradle_build=false"), "family preset: Gradle build stays OFF by default (flag)")
	var plugin := FileAccess.get_file_as_string("res://addons/scrubbots_notify/plugin.gd")
	_ok(plugin.contains("gradle_build/use_gradle_build") and plugin.contains("scrubbots_notify/android/scrubbots_notify.aar"), "export plugin adds the AAR only with the Gradle build")
	_ok(not FileAccess.get_file_as_string("res://project.godot").contains("scrubbots_notify"), "project.godot does not enable it (the workflow does, per input)")
	var aw := FileAccess.get_file_as_string("res://.github/workflows/android-family-first10.yml")
	_ok(aw.contains("local_notifications:") and aw.contains("build_aar.py") and aw.contains("--install-android-build-template") and aw.contains("use_gradle_build=true") and aw.contains("addons/scrubbots_notify/plugin.cfg"), "Android workflow: input builds the AAR, enables Gradle + the plugin")
	var iw := FileAccess.get_file_as_string("res://.github/workflows/ios-ipa.yml")
	_ok(iw.contains("local_notifications:") and iw.contains("--dump-gdextension-interface") and iw.contains("scrubbots_notify.m") and iw.contains("APP_NAME: Scrubbots"), "iOS workflow: input builds the GDExtension; fixed Scrubbots basename kept")
	_complete("n12_native_wiring")

# ----------------------------------------------------------------- helpers ----

func _reboot(path: String) -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _tmp_path(tag: String) -> String:
	var path := "user://m43_172_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-M43-172 local notifications: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
