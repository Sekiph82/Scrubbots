extends SceneTree
## SB-TF-11 (owner 2026-11-19) — the Daily login rewards moved from the Home DAILY activity button
## to Profile's "Login Days" card: no Daily button / first-Home Daily tip on Home; the card opens
## the existing daily-reward ladder (DailyService rules, facade claim, same tx ids), carries a
## claimable badge while today's reward is unclaimed (the Home profile card counts it too), and the
## claim plays the shared reward reveal. Streaks survive a relaunch (no save format change).
## Real app root (main.tscn) on temp saves, injected clock + local day.
##
## Run: godot --headless --path . -s res://tests/sb_tf11_login_days.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := [
	"t01_home_no_daily", "t02_badges", "t03_card_opens_ladder", "t04_claim_once_reveal",
	"t05_next_day_streak_relaunch", "t06_tr_card",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _path := ""
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _t01()
	await _t02()
	await _t03()
	await _t04()
	await _t05()
	await _t06()
	UiText.locale = "en"
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _t01() -> void:
	print("[t01 Home: no DAILY activity button, no first-Home Daily tip]")
	MainScript.boot_ftue_override = 1
	await _boot("t01", false)
	var h = _root.get_home()
	_ok(h.get_region("Shortcut_daily") == null and h.find_child("Shortcut_daily", true, false) == null, "no Shortcut_daily node under Home")
	var left: Array = h.get_activity_layout()["LeftShortcutColumn"]
	_ok(left.slice(0, 2) == ["RewardedAdsButton", "Shortcut_tasks"] and not left.has("Shortcut_daily"), "left column = REWARDED ADS, TASKS %s" % str(left))
	var app = _root.get_app_state()
	_ok(app.economy.ftue.is_new_profile() and not app.economy.daily.claimed_today(), "fresh profile, today's login reward unclaimed")
	_root.refresh_coachmark()
	var step := String(_root.get_coachmarks().get_step_id())
	_ok(step != "home_daily" and step == "home_tasks", "first Home tip is TASKS, never a Daily tip ('%s')" % step)
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/ftue_onboarding_v1.json"))
	_ok(not JSON.stringify(cfg).contains("shortcut:daily"), "ftue_onboarding_v1.json has no Daily shortcut step")
	_ok(_root.get_modal_stack().ids().filter(func(i): return String(i).begins_with("daily") or String(i) == "ceremony_daily").is_empty(), "no Daily popup opened by itself on Home")
	MainScript.boot_ftue_override = -1
	_complete("t01_home_no_daily")

func _t02() -> void:
	print("[t02 claimable badge on the Profile Login Days card and the Home profile card]")
	await _boot("t02")
	var h = _root.get_home()
	var app = _root.get_app_state()
	var bd := HomeBadges.compute(app)
	var rest := int(bd["achievements"]) + int(bd["robots"]) + int(bd["collection"])
	var pb: Label = h.get_region("ProfileBadge")
	_ok(int(bd["daily"]) == 1 and pb.visible and pb.text == str(rest + 1), "Home profile card badge counts today's login reward ('%s', rest %d)" % [pb.text, rest])
	(h.get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var tile: Control = _top().find_child("LoginDays", true, false)
	var badge: Label = tile.find_child("LoginDaysBadge", true, false) if tile != null else null
	_ok(_top_id() == "profile" and badge != null and badge.visible and badge.text == "1", "Profile Login Days card badge '1' while unclaimed")
	_ok(tile.get_global_rect().encloses(badge.get_global_rect()), "badge inside the card")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t02_badges")

func _t03() -> void:
	print("[t03 tapping the Login Days card opens the existing daily ladder (one popup on a double tap)]")
	await _boot("t03")
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var b: Button = _top().find_child("LoginDaysButton", true, false)
	_ok(b != null and not b.disabled and b.size.y >= 88 and b.size.x >= 88, "LoginDaysButton covers the card (%s), >= 88 px" % (str(b.size) if b != null else "<none>"))
	_ok(b != null and b.accessibility_name == "Login Days, DAILY REWARDS" and not b.accessibility_description.is_empty(), "the card button has a screen-reader name '%s'" % (b.accessibility_name if b != null else ""))
	b.pressed.emit()
	b.pressed.emit()
	await _frames(2)
	var ids: Array = _root.get_modal_stack().ids()
	_ok(_top_id() == "daily_login" and ids.count("daily_login") == 1 and ids == ["profile", "daily_login"], "Login Days -> the Daily ladder over Profile, once %s" % str(ids))
	var days: Control = _top().find_child("Days", true, false)
	_ok(days != null and days.get_child_count() == 5, "D1..D5 ladder cards")
	_top().close()
	await _frames(2)
	_ok(_top_id() == "profile", "closing the ladder returns to Profile")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t03_card_opens_ladder")

func _t04() -> void:
	print("[t04 claim from the ladder: Day 1 once, shared reveal, badge clears]")
	await _boot("t04")
	var app = _root.get_app_state()
	var e = app.economy
	var sb0: int = e.wallet.scrub_bucks()
	var want := int(e.daily.login_reward_for(1).get("scrub_bucks", 0))
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var profile = _top()
	(profile.find_child("LoginDaysButton", true, false) as Button).pressed.emit()
	await _frames(2)
	var ladder = _top()
	var log0: int = _root.reveal_log.size()
	_tap("claim")
	await _frames(2)
	_ok(e.daily.claimed_today() and e.wallet.scrub_bucks() == sb0 + want and want == 100, "Day 1 claimed: +%d SB (%d -> %d)" % [want, sb0, e.wallet.scrub_bucks()])
	var rev: Array = _root.reveal_log.slice(log0)
	_ok(rev.size() == 1 and rev[0][0] == "daily" and String(rev[0][1]).begins_with("claim_daily_login:"), "one shared reward reveal, source daily %s" % str(rev))
	_ok(_top_id() == "ceremony_daily", "the existing Day N confirmation follows the claim")
	_top().close()
	await _frames(2)
	_ok(_top() == ladder and ladder.get_action_button("claim").disabled, "ladder CLAIM now blocked")
	_ok(not app.actions.claim_daily_login()["ok"] and e.wallet.scrub_bucks() == sb0 + want, "second claim the same day refused, no second grant")
	ladder.close()
	await _frames(2)
	var tile: Control = profile.find_child("LoginDays", true, false)
	var badge: Label = tile.find_child("LoginDaysBadge", true, false)
	_ok(_top() == profile and not badge.visible, "back on Profile: Login Days badge cleared")
	_ok((tile.find_child("Value", true, false) as Label).text == UiText.num(int(e.daily.display_streak())) and int(e.daily.display_streak()) == 1, "card value = the live consecutive-login count (1)")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_ok(int(HomeBadges.compute(app)["daily"]) == 0 and (_root.get_home().get_region("ProfileBadge") as Label).text == _rest_text(app), "Home profile card no longer counts it")
	_complete("t04_claim_once_reveal")

func _t05() -> void:
	print("[t05 next local day: badge returns, Day 2 continues the streak; streak survives a relaunch]")
	_day[0] += 1
	_now[0] += 86400
	await _boot("t05", true, true)
	var e = _root.get_app_state().economy
	_ok(not e.daily.claimed_today() and e.daily.next_claim_cycle_day() == 2 and int(e.daily.display_streak()) == 2, "relaunch on the next day: yesterday's streak kept, today unclaimed, Day 2 next")
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var profile = _top()
	var badge: Label = profile.find_child("LoginDaysBadge", true, false)
	_ok(badge.visible, "next day -> Login Days badge back")
	(profile.find_child("LoginDaysButton", true, false) as Button).pressed.emit()
	await _frames(2)
	var sb0: int = e.wallet.scrub_bucks()
	_tap("claim")
	await _frames(2)
	_ok(int(e.daily.display_streak()) == 2 and e.wallet.scrub_bucks() == sb0, "Day 2 = 1 Standard Card Pack (no SB), streak 2")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_relaunch()
	await _frames(4)
	_root.get_modal_stack().clear("test")
	e = _root.get_app_state().economy
	_ok(int(e.daily.display_streak()) == 2 and e.daily.claimed_today(), "relaunch: streak 2 and today's claim persisted")
	_complete("t05_next_day_streak_relaunch")

func _t06() -> void:
	print("[t06 TR: Login Days card caption + ladder]")
	_day[0] += 1
	_now[0] += 86400
	UiText.locale = "tr"
	await _boot("t06")
	(_root.get_home().get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var tile: Control = _top().find_child("LoginDays", true, false)
	_ok((tile.find_child("Caption", true, false) as Label).text == "Giriş Günü" and (tile.find_child("LoginDaysBadge", true, false) as Label).visible, "TR card 'Giriş Günü' with its badge")
	(tile.find_child("LoginDaysButton", true, false) as Button).pressed.emit()
	await _frames(2)
	_ok(_top_id() == "daily_login" and _top().get_action_button("claim").text == UiText.t("POPUP_CLAIM"), "TR ladder opens with its CLAIM")
	UiText.locale = "en"
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t06_tr_card")

# ---------------------------------------------------------------- helpers ----

func _rest_text(app) -> String:
	var bd := HomeBadges.compute(app)
	var n := int(bd["achievements"]) + int(bd["robots"]) + int(bd["collection"]) + int(bd["daily"])
	return str(n) if n > 0 else ""

## A new temp save, or the last one when `reuse` (relaunch). `clear`: drop FTUE / ceremonies.
func _boot(tag: String, clear := true, reuse := false) -> void:
	_shutdown()
	if not reuse or _path.is_empty():
		_path = "user://sb_tf11_%s_%d.save" % [tag, Time.get_ticks_usec()]
		_tmp.append(_path)
	_start()
	await _frames(4)
	if clear:
		_root.get_modal_stack().clear("test")
		await _frames(2)

func _relaunch() -> void:
	_shutdown()
	_start()

func _start() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _path
	_root = MainScene.instantiate()
	_sub.add_child(_root)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

## Frames after a home.refresh() (the Home 1 s live tick, so injected state shows at once).
func _frames(n: int) -> void:
	if _root != null and is_instance_valid(_root) and _root.get_home() != null:
		_root.get_home().refresh()
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
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
	print("SB-TF-11 login days evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
