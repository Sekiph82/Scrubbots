extends SceneTree
## SB-PHONE-2026-11-12-C — owner phone test 2026-11-12 copy/state fixes, real app root
## (main.tscn) with injected clock + local calendar day and a temp save:
##   h  Hearts at max show no countdown: Home HUD pill reads FULL / DOLU, the Life popup hides
##      its timer pill; below max both show HeartService.seconds_to_next();
##   c  Collection album set names + rarity abbreviations, and the set detail title, follow the
##      language (TR set names from UiText DATA, S/N/E/EF vs C/R/E/L);
##   r  Robots: Scrubby's perk is player-facing copy (EN + TR), no developer wording;
##   d  one login-streak truth: Daily header, claim popup, Profile tile and Home Daily popup all
##      read DailyService.display_streak(); a missed day already reads 1 before the claim.
##
## Run: godot --headless --path . -s res://tests/sb_phone_2026_11_12_c_copy_state.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := [
	"h01_hud_full_no_timer", "h02_life_popup_full_no_timer",
	"c01_album_set_names_rarity_en_tr", "c02_set_detail_title_tr",
	"r01_scrubby_player_copy",
	"d01_missed_day_display_before_claim", "d02_streak_one_truth_after_claim", "d03_continued_streak_matches_today",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	AppState.test_unlock_all = true
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _h()
	await _c()
	await _r()
	await _d()
	UiText.locale = "en"
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _h() -> void:
	print("[h Hearts at max: no countdown in HUD or Life popup]")
	await _boot("h")
	var h = _eco().hearts
	var home = _root.get_home()
	var pill: Label = home.get_region("HeartsChip").value_label
	h.import_snapshot({"hearts": h.max_hearts(), "anchor": _now[0]})
	for lang in [["en", "FULL"], ["tr", "DOLU"]]:
		UiText.locale = lang[0]
		home.refresh()
		_ok(pill.text == lang[1] and pill.text.find(":") == -1, "%s full: HUD pill '%s', no timer" % [lang[0], pill.text])
	_now[0] += 600
	home.refresh()
	_ok(pill.text == "DOLU", "full + 600 s: still DOLU, nothing ticks")
	UiText.locale = "en"
	h.consume()
	home.refresh()
	_ok(pill.text == "15:00" and h.seconds_to_next() == 900, "below max: HUD shows the regen countdown 15:00")
	_now[0] += 61
	home.refresh()
	_ok(pill.text == "13:59", "below max: countdown follows HeartService (13:59)")
	_complete("h01_hud_full_no_timer")
	_now[0] += 900
	_ok(h.hearts() == h.max_hearts(), "regenerated back to max")
	UiText.locale = "tr"
	var p = _root.open_life("test")
	await _frames(2)
	var tp: Control = p.find_child("TimerPill", true, false)
	_ok(_txt(p, "TimerTitle") == "Canlar dolu!" and not tp.visible and _txt(p, "TimerValue") == "", "TR popup full: 'Canlar dolu!', timer pill hidden")
	p.close("test")
	await _frames(1)
	UiText.locale = "en"
	h.consume()
	p = _root.open_life("test")
	await _frames(2)
	tp = p.find_child("TimerPill", true, false)
	_ok(tp.visible and _txt(p, "TimerValue") == "15:00" and _txt(p, "TimerTitle") == UiText.t("LIFE_NEXT_IN"), "EN popup below max: pill visible, 15:00")
	p.close("test")
	await _frames(1)
	_complete("h02_life_popup_full_no_timer")

func _c() -> void:
	print("[c Collection set names + rarity abbreviations follow the language]")
	await _boot("c")
	var app = _root.get_app_state()
	var stack = _root.get_modal_stack()
	UiText.locale = "en"
	var p = CollectionScreen.open_album(stack, app)
	await _frames(2)
	var s1 = p.find_child("Set_1", true, false)
	_ok(_lbl(s1, "Title") == "Set 1 · Meet the Scrubbots", "EN title '%s'" % _lbl(s1, "Title"))
	_ok(_lbl(s1, "Burden").begins_with("C ") and _lbl(s1, "Burden").contains(" · L "), "EN burden '%s'" % _lbl(s1, "Burden"))
	p.close("test")
	await _frames(1)
	UiText.locale = "tr"
	p = CollectionScreen.open_album(stack, app)
	await _frames(2)
	var bad: Array = []
	for n in range(1, 16):
		var want := "Set %d · %s" % [n, UiText.data("SET_NAME_%d" % n, "?")]
		if _lbl(p.find_child("Set_%d" % n, true, false), "Title") != want or want.ends_with("?"):
			bad.append(n)
	s1 = p.find_child("Set_1", true, false)
	_ok(bad.is_empty() and _lbl(s1, "Title") == "Set 1 · Scrubbot'larla Tanış" and _lbl(p.find_child("Set_6", true, false), "Title") == "Set 6 · Banyo Karmaşası", "TR: all 15 set titles translated %s" % str(bad))
	var burden := _lbl(s1, "Burden")
	_ok(burden.begins_with("S ") and burden.contains(" · N ") and burden.contains(" · E ") and burden.contains(" · EF ") and not burden.contains("C ") and not burden.contains("L "), "TR burden '%s'" % burden)
	_complete("c01_album_set_names_rarity_en_tr")
	var d = CollectionScreen.open_set(stack, app, 2)
	await _frames(2)
	_ok(d.get_title() == "Set 2 · Temizlik Ekibi", "TR set detail title '%s'" % d.get_title())
	stack.clear("test")
	await _frames(1)
	UiText.locale = "en"
	_complete("c02_set_detail_title_tr")

func _r() -> void:
	print("[r Robots: Scrubby perk is player-facing copy]")
	var r: Dictionary = RobotRoster.entry("scrubby")
	UiText.locale = "en"
	var en := RobotsScreen.perk_line(r)
	UiText.locale = "tr"
	var tr := RobotsScreen.perk_line(r)
	var tr_role := UiText.data("ROBOT_ROLE_SCRUBBY", "")
	UiText.locale = "en"
	_ok(en == "Team Leader: Scrubby gives no bonus; he leads the whole team.", "EN '%s'" % en)
	_ok(tr == "Takım Lideri: Scrubby bonus vermez; tüm takımı yönetir.", "TR '%s'" % tr)
	var dev := ["modifier", "reference", "neutral", "economy", "franchise", "endgame", "değiştirici", "referans", "tarafsız", "ekonomi", "endüstriyel"]
	var leaks: Array = []
	for rr in RobotRoster.load_roster()["robots"]:
		var id := String(rr["id"]).to_upper()
		var texts := [String(rr["role"]), String(rr["perk_name"]), String(rr["perk_text"])]
		UiText.locale = "tr"
		texts.append_array([UiText.data("ROBOT_ROLE_" + id, ""), UiText.data("ROBOT_PERK_NAME_" + id, ""), UiText.data("ROBOT_PERK_TEXT_" + id, "")])
		UiText.locale = "en"
		for t in texts:
			for w in dev:
				if String(t).to_lower().contains(w):
					leaks.append("%s:%s" % [id, w])
	_ok(leaks.is_empty() and tr_role == "Lider. Güler yüzlü, dengeli ve hep iyimser.", "no developer wording in any robot role/perk (EN+TR) %s" % str(leaks))
	_ok(RobotRoster.entry("scrubby")["perk_modifiers"].is_empty(), "Scrubby still has no perk modifier (truth unchanged)")
	_complete("r01_scrubby_player_copy")

func _d() -> void:
	print("[d one login-streak truth; missed day reads 1 before the claim]")
	await _boot("d")
	var app = _root.get_app_state()
	var d = _eco().daily
	for _i in range(3):
		app.actions.claim_daily_login()
		_day[0] += 1
		_now[0] += 86400
	_day[0] -= 1
	_now[0] -= 86400
	_ok(d.streak() == 3 and d.display_streak() == 3 and d.claimed_today(), "three consecutive claims: streak 3")
	_day[0] += 3   # two whole days missed
	_now[0] += 86400 * 3
	_ok(d.streak() == 3 and d.display_streak() == 1 and d.next_claim_cycle_day() == 1, "missed days: stored 3, displayed 1 = today's D1")
	var p = DailyScreens.open_daily(_root.get_modal_stack(), app)
	await _frames(2)
	_ok(_txt_in(p, "StreakRow", "Streak") == UiText.t("DAILY_CONSECUTIVE", ["1"]) and _states(p)[0] == "today", "Daily header 1 while D1 is TODAY (was 3)")
	_ok(_profile_login_days() == "1", "Profile Login Days 1 before the claim")
	_root.get_modal_stack().clear("test")
	await _frames(1)
	_complete("d01_missed_day_display_before_claim")
	var res: Dictionary = app.actions.claim_daily_login()
	_ok(res.get("ok", false) and int(res["day"]) == 1 and d.streak() == 1 and d.display_streak() == 1, "claim: D1, streak 1")
	var rp = DailyScreens.open_daily_reward(_root.get_modal_stack(), app, res)
	await _frames(1)
	_ok(_txt(rp, "Streak") == UiText.t("DAILY_CONSECUTIVE", ["1"]), "claim popup reads 1")
	_root.get_modal_stack().clear("test")
	await _frames(1)
	_ok(_profile_login_days() == "1" and int(_root.get_home().get_view_model()["daily_streak"]) == 1, "Profile and Home view model read 1")
	_complete("d02_streak_one_truth_after_claim")
	_day[0] += 1
	_now[0] += 86400
	p = DailyScreens.open_daily(_root.get_modal_stack(), app)
	await _frames(2)
	_ok(d.display_streak() == 2 and _states(p)[1] == "today" and _txt_in(p, "StreakRow", "Streak") == UiText.t("DAILY_CONSECUTIVE", ["2"]), "next day: header 2 with D2 TODAY")
	_root.get_modal_stack().clear("test")
	await _frames(1)
	_complete("d03_continued_streak_matches_today")

# ------------------------------------------------------------------ helpers ----

func _profile_login_days() -> String:
	var p = ProfileScreens.open_profile(_root.get_modal_stack(), _root.get_app_state())
	var v := _lbl(p.find_child("LoginDays", true, false), "Value")
	p.close("test")
	return v

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://sbphone1112c_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")
	await _frames(1)

func _states(p) -> Array:
	var out: Array = []
	for day in range(1, 6):
		out.append(String(p.find_child("Day_%d" % day, true, false).get_meta("state")))
	return out

func _eco():
	return _root.get_app_state().economy

func _lbl(node, n: String) -> String:
	var l = node.find_child(n, true, false) if node != null else null
	return l.text if l is Label else ""

func _txt(p, n: String) -> String:
	return _lbl(p, n)

func _txt_in(p, parent: String, n: String) -> String:
	return _lbl(p.find_child(parent, true, false), n)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	AppState.test_unlock_all = false
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
	print("SB-PHONE-2026-11-12-C copy/state evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
