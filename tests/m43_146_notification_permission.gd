extends SceneTree
## SB-M43-146 — contextual OS notification permission on the REAL app root (main.tscn), with an
## injected fake OS permission API (NotificationPermission platform seam) and an injected clock:
##   p01 never on boot · p02 shown at the REMINDERS ON trigger · p03 Not now = no OS call + cooldown
##   p04 Allow = exactly one OS request; granted skips · p05 non-Android no-op · p06 persisted /
##   strict import · p07 no gameplay / economy effect · p08 Android preset declares the permission.
##
## Run: godot --headless --path . -s res://tests/m43_146_notification_permission.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const NotificationPermission = preload("res://scripts/economy/notification_permission.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["p01_not_on_boot", "p02_shown_at_trigger", "p03_not_now_cooldown", "p04_allow_one_request_granted_skips",
	"p05_non_android_noop", "p06_persisted_strict", "p07_no_economy_effect", "p08_android_preset_permission"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _granted := [false]
var _requests := [0]
var _granted_calls := [0]

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _p01()
	await _p02_p03()
	await _p04()
	await _p05()
	await _p06()
	await _p07()
	_p08()
	_shutdown()
	_cleanup()
	_done()

## Fake Android OS permission API on the live app's NotificationPermission.
func _fake(app, platform: String = "Android") -> void:
	var np = app.economy.notify_permission
	np.platform = platform
	np.granted_fn = func() -> bool:
		_granted_calls[0] += 1
		return _granted[0]
	np.request_fn = func() -> void: _requests[0] += 1

func _open_notifications():
	var p = ProfileScreens.open_notifications(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	return p

func _press(p, id: String) -> void:
	p.rearm()
	p.get_action_button(id).pressed.emit()
	await _frames(2)

func _top_id() -> String:
	var t = _root.get_modal_stack().top()
	return "" if t == null else String(t.popup_id)

func _p01() -> void:
	print("[p01 never asked on boot (fresh save, Android fake, reminders OFF and ON)]")
	await _boot("p01")
	var a = _root.get_app_state()
	_fake(a)
	await _frames(4)
	_ok(_top_id() != "notification_permission" and _requests[0] == 0, "fresh boot: no explainer, no OS request (top '%s')" % _top_id())
	a.economy.notify.enabled = true
	a.request_save()
	var path: String = MainScript.boot_save_path_override
	_root.flush_lifecycle("test")
	_shutdown()
	await _reboot(path)
	a = _root.get_app_state()
	_ok(a.economy.notify.enabled and _top_id() != "notification_permission" and _requests[0] == 0, "relaunch with reminders ON: still nothing on boot")
	var src := FileAccess.get_file_as_string("res://scripts/ui/profile/profile_screens.gd")
	_ok(src.count("open_notification_permission(") == 2, "explainer opened from exactly one call site (the REMINDERS ON toggle)")
	for f in ["res://scripts/app/main.gd", "res://scripts/ui/home/home_screen.gd", "res://scripts/app/app_state.gd"]:
		_ok(not FileAccess.get_file_as_string(f).contains("notify_permission"), "%s never touches the permission flow" % f)
	_complete("p01_not_on_boot")

func _p02_p03() -> void:
	print("[p02 the REMINDERS ON toggle shows the native explainer before any OS prompt]")
	await _boot("p02")
	var a = _root.get_app_state()
	_fake(a)
	var p = await _open_notifications()
	_ok(p.find_child("Platform", true, false) == null, "Android: no 'cannot ask' line")
	await _press(p, "notify_all")
	var x = _root.get_modal_stack().top()
	_ok(a.economy.notify.enabled and _top_id() == "notification_permission", "toggle ON -> explainer on top")
	_ok(_requests[0] == 0, "explainer shown, OS not asked yet")
	_ok(x.get_title() == UiText.t("NOTIFY_PERMISSION_TITLE") and x.find_child("Explain", true, false).text == UiText.t("NOTIFY_PERMISSION_BODY"), "keyed title / benefit copy")
	_ok(x.get_action_button("allow").text == UiText.t("NOTIFY_PERMISSION_ALLOW") and x.get_action_button("not_now").text == UiText.t("NOTIFY_PERMISSION_NOT_NOW"), "Allow / Not now buttons")
	_complete("p02_shown_at_trigger")

	print("[p03 Not now: no OS call, cooldown from data, back counts as Not now]")
	await _press(x, "not_now")
	_ok(_requests[0] == 0 and _top_id() == "notifications", "Not now -> no OS request, back on Notifications")
	_ok(a.economy.notify.enabled, "reminder preference itself stays ON")
	var d = JSON.parse_string(FileAccess.get_file_as_string(NotificationPermission.PATH))
	var cd: int = int(d["decline_cooldown_days"]) * 86400
	_ok(a.economy.notify_permission.cooldown_s == cd, "cooldown from notification_permission_v1.json (%d days)" % int(d["decline_cooldown_days"]))
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notifications" and _requests[0] == 0, "OFF -> ON inside the cooldown: no explainer")
	_now[0] += cd - 1
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notifications", "cooldown - 1 s: still nothing")
	_now[0] += 1
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notification_permission", "cooldown elapsed: explainer again")
	_ok(_root.get_modal_stack().top().request_back() and _requests[0] == 0 and _top_id() == "notifications", "back / dismiss = Not now (no OS call)")
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notifications", "dismiss also starts the cooldown")
	var two := _write_json("cfg", {"schema": NotificationPermission.SCHEMA, "decline_cooldown_days": 2})
	_ok(NotificationPermission.new(Callable(), two).cooldown_s == 2 * 86400 and NotificationPermission.new(Callable(), "res://missing.json").cooldown_s == 7 * 86400, "cooldown is data-driven")
	_complete("p03_not_now_cooldown")

func _p04() -> void:
	print("[p04 Allow: exactly one OS request; granted state skips the explainer]")
	await _boot("p04")
	var a = _root.get_app_state()
	_fake(a)
	_requests[0] = 0
	var p = await _open_notifications()
	await _press(p, "notify_all")
	var x = _root.get_modal_stack().top()
	x.get_action_button("allow").pressed.emit()
	x.get_action_button("allow").pressed.emit()
	await _frames(2)
	_ok(_requests[0] == 1, "Allow (double tap) -> one OS request (got %d)" % _requests[0])
	_granted[0] = true
	_now[0] += 30 * 86400
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notifications" and _requests[0] == 1, "granted -> never explained / requested again")
	_granted[0] = false
	await _press(p, "notify_all")
	await _press(p, "notify_all")
	_ok(_top_id() == "notification_permission", "OS denied after Allow: re-explained only after the cooldown (30 d later)")
	_root.get_modal_stack().top().request_back()
	await _frames(2)
	_complete("p04_allow_one_request_granted_skips")

func _p05() -> void:
	print("[p05 iOS / desktop: no-op (iOS needs a native plugin, SB-M43-171)]")
	for plat in ["iOS", "Windows", "macOS", "Linux", "Web"]:
		await _boot("p05" + plat)
		var a = _root.get_app_state()
		_fake(a, plat)
		_requests[0] = 0
		_granted_calls[0] = 0
		var p = await _open_notifications()
		_ok(p.find_child("Platform", true, false) != null, "%s: 'cannot ask yet' line shown" % plat)
		await _press(p, "notify_all")
		_ok(a.economy.notify.enabled and _top_id() == "notifications" and _requests[0] == 0 and _granted_calls[0] == 0, "%s: toggle ON -> no explainer, no OS API call" % plat)
	var real := NotificationPermission.new()
	_ok(real.platform == OS.get_name() and not real.should_explain(), "real seam on this desktop host: unsupported, never explains")
	_complete("p05_non_android_noop")

func _p06() -> void:
	print("[p06 asked / declined persisted across relaunch; strict import]")
	await _boot("p06")
	var a = _root.get_app_state()
	_fake(a)
	_granted[0] = false
	var p = await _open_notifications()
	await _press(p, "notify_all")
	await _press(_root.get_modal_stack().top(), "not_now")
	var snap: Dictionary = a.economy.notify_permission.snapshot()
	_ok(int(snap["declined_at"]) == _now[0] and int(snap["asked_at"]) == 0, "declined_at recorded %s" % str(snap))
	var path: String = MainScript.boot_save_path_override
	_root.flush_lifecycle("test")
	_shutdown()
	await _reboot(path)
	a = _root.get_app_state()
	_fake(a)
	_ok(a.economy.notify_permission.snapshot() == snap and not a.economy.notify_permission.should_explain(), "relaunch: declined state + cooldown survive")
	var np := NotificationPermission.new()
	_ok(np.import_snapshot(null) and np.snapshot() == {"version": 1, "asked_at": 0, "declined_at": 0}, "absent section = fresh")
	for bad in [{"version": 2, "asked_at": 0, "declined_at": 0}, {"version": 1, "asked_at": -1, "declined_at": 0}, {"version": 1, "asked_at": 0}, {"version": 1, "asked_at": 1.5, "declined_at": 0}, "x"]:
		_ok(not np.import_snapshot(bad), "rejects %s" % str(bad))
	_complete("p06_persisted_strict")

func _p07() -> void:
	print("[p07 no gameplay / economy effect]")
	await _boot("p07")
	var a = _root.get_app_state()
	_fake(a)
	var before: Dictionary = a.economy.snapshot()
	var p = await _open_notifications()
	await _press(p, "notify_all")
	await _press(_root.get_modal_stack().top(), "allow")
	var after: Dictionary = a.economy.snapshot()
	var changed: Array = []
	for k in before:
		if JSON.stringify(before[k]) != JSON.stringify(after[k]):
			changed.append(k)
	changed.sort()
	_ok(changed == ["notifications", "notify_permission"], "only the reminder preference + permission state changed %s" % str(changed))
	var src := FileAccess.get_file_as_string("res://scripts/economy/notification_permission.gd")
	_ok(not src.contains("wallet") and not src.contains("reward") and not src.contains("hearts"), "permission script touches no economy service")
	_complete("p07_no_economy_effect")

func _p08() -> void:
	print("[p08 Android export preset declares POST_NOTIFICATIONS]")
	var cfg := FileAccess.get_file_as_string("res://.github/android/export_presets_family_first10.cfg")
	_ok(cfg.contains("permissions/post_notifications=true"), "permissions/post_notifications=true")
	_complete("p08_android_preset_permission")

# ----------------------------------------------------------------- helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	await _reboot(_tmp_path(tag))

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
	var path := "user://m43_146_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	return path

func _write_json(tag: String, d: Dictionary) -> String:
	var path := "user://m43_146_%s_%d.json" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
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
	print("SB-M43-146 notification permission: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
