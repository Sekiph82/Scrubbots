extends SceneTree
## M51 Localization readiness (SB-M51-001..004, 009 evidence) — the UiText pseudo-locale
## (developer mode, never enabled by the shipping app) against the REAL app root:
##   l01 pseudo-locale properties · l02 key convention / non-empty English table
##   l03 Settings is fully keyed (asserted: no visible untranslated literal; frame contained)
##   l04 multi-surface scan: untranslated visible literals + text leaving the screen under ~40%
##       expansion, REPORTED as findings (Home, Tasks, Daily, Help, Shop, gameplay HUD, Results).
##   l05 Turkish table (SB-M51-005/006): every EN key has a non-empty TR entry with the same
##       %s / %d placeholders in the same order (English-only _ONE plural forms excepted), no
##       stray TR keys, every achievement / robot / Collection set has its TR data copy
##   l06 plurals (SB-M51-008): EN one/other for Hearts, Bot Parts, cards, days, ranks, gifts /
##       rewards through UiText.tn and the real Results rows; TR keeps one form
##   l07 language choice (SB-M51-005): saved choice > device > English; strict save field;
##       Settings LANGUAGE row (one extra card, Reduced Effects in place) switches + persists,
##       and a reboot on that save builds Home / Settings in Turkish
##   l08 static guard (SB-M51-001/007): no hard-coded user text (text = "...", multi-word
##       literals) and no hand-formatted currency in scripts/ui, scripts/app, scenes; every
##       literal UiText key exists.
##
## Run: godot --headless --path . -s res://tests/m51_localization_readiness.gd

const UiText = preload("res://scripts/ui/ui_text.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")

## l08: the only literals the text-property / multi-word scan may meet (non-language glyphs),
## as "<file>|<literal>".
const GUARD_ALLOW := ["scripts/ui/gameplay_screen.gd|II"]
const GUARD_DIRS := ["res://scripts/ui", "res://scripts/app", "res://scenes"]

## Non-language glyphs that are not translatable copy.
const GLYPHS := ["X", "?", "II", "2x", "2X", "+", "-"]

var EXPECTED_CASES := ["l01_pseudo_properties", "l02_key_convention", "l03_settings_fully_keyed", "l04_surface_scan_report",
	"l05_turkish_table", "l06_plurals", "l07_language_choice", "l08_hardcoded_text_guard"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	_l01()
	_l02()
	UiText.pseudo = true
	await _l03()
	await _l04()
	UiText.pseudo = false
	_l05()
	_l06()
	await _l07()
	_l08()
	_shutdown()
	_cleanup()
	_done()

func _l01() -> void:
	print("[l01 pseudo-locale: bracketed, accented, >= 35% longer, digits / symbols kept, off by default]")
	_ok(not UiText.pseudo and UiText.t("SETTINGS_TITLE") == "SETTINGS", "off by default; English unchanged")
	var src := "Win 3 levels (100%)"
	var p := UiText.pseudo_text(src)
	_ok(p.begins_with("[") and p.ends_with("]") and p.contains("3") and p.contains("100%") and p.contains("Wíñ") and p.length() >= int(src.length() * 1.35) + 2, "'%s' -> '%s'" % [src, p])
	_ok(UiText.pseudo_text("") == "" and UiText.pseudo_text(src) == p, "empty stays empty; deterministic")
	UiText.pseudo = true
	var with_args := UiText.t("TASK_WIN_N", ["3"])
	UiText.pseudo = false
	_ok(with_args.begins_with("[") and with_args.contains("3") and not with_args.contains("%s"), "formatting happens before pseudo: '%s'" % with_args)
	_complete("l01_pseudo_properties")

func _l02() -> void:
	print("[l02 key convention: UPPER_SNAKE keys (REWARD_<resource id> keeps the lowercase canonical id), non-empty English]")
	var re := RegEx.new()
	re.compile("^([A-Z0-9]+(_[A-Z0-9]+)*|REWARD_[a-z0-9_]+)$")
	var bad_keys: Array = []
	var empty: Array = []
	for k in UiText.EN:
		if re.search(String(k)) == null:
			bad_keys.append(k)
		if String(UiText.EN[k]).is_empty():
			empty.append(k)
	_ok(bad_keys.is_empty(), "%d keys, all UPPER_SNAKE %s" % [UiText.EN.size(), str(bad_keys)])
	_ok(empty == ["FTUE_BOOSTER_INTRO_BODY"], "only the documented runtime-built body is empty %s" % str(empty))
	_complete("l02_key_convention")

func _l03() -> void:
	print("[l03 Settings under pseudo-locale: every visible text keyed, frame inside the viewport]")
	await _boot("l03", Vector2i(1080, 2160))
	_root.open_settings()
	await _frames(4)
	var panel = _root.get_settings_panel()
	var left := _untranslated(panel)
	var frame: Control = panel.find_child("Frame", true, false)
	var fr := Rect2(frame.global_position, frame.size)
	_ok(left.is_empty(), "no untranslated literal left in Settings %s" % str(left))
	_ok(Rect2(Vector2.ZERO, Vector2(1080, 2160)).grow(0.5).encloses(fr), "Settings frame still inside the screen with ~40%% longer copy %s" % str(fr))
	_complete("l03_settings_fully_keyed")

func _l04() -> void:
	print("[l04 surface scan under pseudo-locale (findings, not pass/fail)]")
	await _boot("l04", Vector2i(1080, 2160))
	var stack = _root.get_modal_stack()
	var surfaces := 0
	var report := func(name: String, node) -> void:
		var lits := _untranslated(node)
		var off := _offscreen(node)
		print("    %s: untranslated %d %s | off-screen %d %s" % [name, lits.size(), str(lits.slice(0, 8)), off.size(), str(off.slice(0, 5))])
	report.call("Home", _root.get_home())
	surfaces += 1
	for d in ["tasks", "daily", "shop"]:
		stack.clear("test")
		await _frames(1)
		_root.open_deep_link(d)
		await _frames(4)
		if stack.top() != null:
			report.call(d, stack.top())
			surfaces += 1
	stack.clear("test")
	await _frames(1)
	var hp = HelpTipsScreen.open(stack, _root.get_app_state())
	await _frames(4)
	if hp != null:
		report.call("help_tips", hp)
		surfaces += 1
	stack.clear("test")
	await _frames(1)
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	if host != null:
		host.get_runtime().set_process(false)
		report.call("gameplay_hud", host.get_screen())
		surfaces += 1
	var res = _root.get_results_screen()
	res.visible = true
	res.show_model(_root._results_model({"status": "WON", "level": 1, "attempt": 1}))
	await _frames(6)
	report.call("results_won", res)
	surfaces += 1
	_ok(surfaces >= 7, "%d player surfaces scanned (findings above feed SB-M51-001/009 and SB-M49-022/027)" % surfaces)
	_complete("l04_surface_scan_report")

func _l05() -> void:
	print("[l05 Turkish table: every key, same placeholders, non-empty; data copy complete]")
	var missing: Array = []
	var bad_ph: Array = []
	var empty: Array = []
	var one_in_tr: Array = []
	for k in UiText.EN:
		var base := String(k).trim_suffix("_ONE")
		if String(k).ends_with("_ONE") and UiText.EN.has(base):   # an English-only plural form
			if _ph(UiText.EN[k]) != _ph(UiText.EN[base]):
				bad_ph.append(k)
			if UiTextTr.TR.has(k):
				one_in_tr.append(k)
			continue
		if not UiTextTr.TR.has(k):
			missing.append(k)
			continue
		if _ph(UiText.EN[k]) != _ph(UiTextTr.TR[k]):
			bad_ph.append(k)
		if String(UiTextTr.TR[k]).is_empty() and k != "FTUE_BOOSTER_INTRO_BODY":
			empty.append(k)
	var stray: Array = UiTextTr.TR.keys().filter(func(k): return not UiText.EN.has(k))
	_ok(missing.is_empty(), "every EN key has a TR entry (%d TR keys) %s" % [UiTextTr.TR.size(), str(missing)])
	_ok(bad_ph.is_empty(), "placeholders match in count and order (EN vs TR, _ONE vs base) %s" % str(bad_ph))
	_ok(empty.is_empty() and stray.is_empty() and one_in_tr.is_empty(), "no empty TR copy %s, no stray TR keys %s, no TR _ONE forms %s" % [str(empty), str(stray), str(one_in_tr)])
	var need: Array = []
	var ach = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/achievements_v2.json"))
	for a in ach["achievements"]:
		need.append("ACH_NAME_" + String(a["id"]).to_upper())
		need.append("ACH_DESC_" + String(a["id"]).to_upper())
	for id in RobotRoster.ids():
		for f in ["ROBOT_ROLE_", "ROBOT_PERK_NAME_", "ROBOT_PERK_TEXT_"]:
			need.append(f + String(id).to_upper())
	for n in range(1, 16):
		need.append("SET_NAME_%d" % n)
	for w in JSON.parse_string(FileAccess.get_file_as_string("res://data/config/worlds_v1.json"))["worlds"]:
		need.append("WORLD_NAME_%d" % int(w["number"]))
	var lacking: Array = need.filter(func(k): return not UiTextTr.DATA.has(k) or String(UiTextTr.DATA[k]).is_empty())
	_ok(lacking.is_empty() and UiTextTr.DATA.size() == need.size(), "%d data copy entries (achievements, robots, sets, worlds) all translated %s" % [need.size(), str(lacking)])
	UiText.locale = "tr"
	var tr_ok := UiText.t("HOME_PLAY") == "OYNA" and UiText.num(1234567) == "1.234.567" and UiText.data("ACH_NAME_CLEAN_START", "Clean Start") == "Temiz Başlangıç"
	UiText.locale = "en"
	_ok(tr_ok and UiText.num(1234567) == "1,234,567" and UiText.data("ACH_NAME_CLEAN_START", "Clean Start") == "Clean Start", "TR copy / '1.234.567' grouping / data copy switch with UiText.locale; EN unchanged")
	_complete("l05_turkish_table")

func _l06() -> void:
	print("[l06 plurals: EN one/other, TR one form]")
	var fam := {"RESULTS_CARDS": ["+1 Card", "+2 Cards"], "RESULTS_BOT_PARTS": ["+1 Bot Part", "+2 Bot Parts"],
		"CEREMONY_ROW_HEART": ["+1 Heart", "+2 Hearts"], "DAILY_STREAK": ["Login streak: 1 day.", "Login streak: 2 days."],
		"COMEBACK_GIFT": ["1 gift waiting in the Gift Bar", "2 gifts waiting in the Gift Bar"],
		"CEREMONY_ROW_STANDARD_PACK": ["+1 Standard Card Pack", "+2 Standard Card Packs"]}
	for k in fam:
		var got := [UiText.tn(k, 1, ["1"]), UiText.tn(k, 2, ["2"])]
		_ok(got == fam[k] and UiText.tn(k, 0, ["0"]) == UiText.t(k, ["0"]), "EN %s: %s (0 -> other)" % [k, str(got)])
	_ok(UiText.tn("RANKS_NEXT", 1, ["1", "Gold"]) == "1 more level to Gold" and UiText.tn("RANKS_NEXT", 3, ["3", "Gold"]) == "3 more levels to Gold", "EN ranks: 1 more level / 3 more levels")
	var receipt := {"reveal_queue": [{"kind": "bot_parts", "amount": 1}, {"kind": "collection_cards", "amount": 3}]}
	var rows: Array = ResultsScreen.reward_rows(receipt).map(func(r): return r["text"])
	_ok(rows == ["+1 Bot Part", "+3 Cards"], "real Results rows: %s" % str(rows))
	_ok(UiText.t("TIME_DHM", [1, 1, 1]) == "1d 1h 1m", "time remaining uses unit abbreviations (no plural)")
	UiText.locale = "tr"
	var tr_rows: Array = ResultsScreen.reward_rows(receipt).map(func(r): return r["text"])
	var tr_ok := UiText.tn("RESULTS_CARDS", 1, ["1"]) == "+1 Kart" and UiText.tn("RESULTS_CARDS", 2, ["2"]) == "+2 Kart" and UiText.t("TIME_DHM", [1, 2, 3]) == "1g 2sa 3dk"
	UiText.locale = "en"
	_ok(tr_ok and tr_rows == ["+1 Robot Parçası", "+3 Kart"], "TR: noun stays singular after a number %s" % str(tr_rows))
	_complete("l06_plurals")

func _l07() -> void:
	print("[l07 language choice: resolve, strict save field, Settings row switches + persists]")
	_ok(UiText.resolve_language("", "tr") == "tr" and UiText.resolve_language("", "de") == "en" and UiText.resolve_language("en", "tr") == "en" and UiText.resolve_language("tr", "en") == "tr" and UiText.resolve_language("xx", "tr") == "tr",
		"saved choice > device language > English")
	var fx := EffectsSettingsService.new()
	var rej := 0
	for bad in ["de", "", 5, true, null]:
		rej += 0 if fx.strict_import_snapshot({"reduced": false, "language": bad}) else 1
	_ok(rej == 5 and not fx.snapshot().has("language") and fx.strict_import_snapshot({"reduced": false, "language": "tr"}) and fx.get_language() == "tr" and fx.snapshot()["language"] == "tr",
		"save field: absent = follow device (not written), only en / tr accepted (%d/5 rejected)" % rej)
	await _boot("l07", Vector2i(1080, 2160))
	var path := MainScript.boot_save_path_override
	_root.open_settings()
	await _frames(4)
	var panel = _root.get_settings_panel()
	var body: Node = panel.find_child("Body", true, false)
	var order: Array = []
	for c in body.get_children():
		if String(c.name).begins_with("Card_"):
			order.append(String(c.name))
	_ok(order.slice(-4) == ["Card_HapticsToggle", "Card_ReducedEffectsToggle", "Card_ColorSymbolsRow", "Card_LanguageRow"], "one LANGUAGE card added after the existing cards, Reduced Effects in place %s" % str(order))
	var en_b: Button = panel.get_language_button("en")
	var tr_b: Button = panel.get_language_button("tr")
	_ok(en_b.button_pressed and not tr_b.button_pressed and en_b.size.y >= 88.0 and tr_b.size.y >= 88.0 and tr_b.text == "TÜRKÇE", "EN active by default; both buttons >= 88 px tall %s %s" % [str(en_b.size), str(tr_b.size)])
	var got := []
	panel.language_changed.connect(func(c): got.append(c))
	tr_b.pressed.emit()
	await _frames(2)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ok(got == ["tr"] and UiText.locale == "tr" and tr_b.button_pressed and not en_b.button_pressed and saved["settings"]["effects"].get("language", "") == "tr",
		"TÜRKÇE applies at once, emits language_changed, is saved (settings.effects.language = tr)")
	UiText.locale = "en"
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)
	var home_en := _untranslated_en(_root.get_home())
	_root.open_settings()
	await _frames(4)
	var title: Label = _root.get_settings_panel().find_child("Title", true, false)
	_ok(UiText.locale == "tr" and title.text == "AYARLAR" and home_en.is_empty(), "reboot on that save: Settings '%s', no English-only copy on Home %s" % [title.text, str(home_en)])
	UiText.locale = "en"
	_complete("l07_language_choice")

func _l08() -> void:
	print("[l08 static guard: no hard-coded user text / currency in UI code, every literal key exists]")
	var text_re := RegEx.create_from_string("(?:\\b(?:text|tooltip_text|placeholder_text)\\s*=|set_text\\()\\s*\"([^\"]*)\"")
	var words_re := RegEx.create_from_string("\"([A-Za-z][A-Za-z']*(?: [A-Za-z][A-Za-z',]*)+[.!?]?)\"")
	var money_re := RegEx.create_from_string("\"[^\"]*(?:[$€£₺¥]\\s*%|[$€£₺¥]\\s*\\d|\\d\\s*[$€£₺¥]|%[0-9.]*[dfs]\\s*(?:USD|EUR|TRY|TL)\\b)[^\"]*\"")
	var key_re := RegEx.create_from_string("UiText\\.tn?\\(\"([A-Za-z0-9_]+)\"\\s*[,)]")
	var hits: Array = []
	var bad_keys: Array = []
	var files := 0
	for d in GUARD_DIRS:
		for f in _files(d):
			if f.get_file().begins_with("ui_text"):
				continue   # the EN / TR copy tables themselves
			files += 1
			var rel: String = f.trim_prefix("res://")
			var ln := 0
			for raw in FileAccess.get_file_as_string(f).split("\n"):
				ln += 1
				var line := _code(raw)
				if line.strip_edges().is_empty() or line.contains("push_warning") or line.contains("push_error") or line.contains("print("):
					continue
				for m in text_re.search_all(line):
					if _has_letter2(m.get_string(1)) and not GUARD_ALLOW.has(rel + "|" + m.get_string(1)):
						hits.append("%s:%d text '%s'" % [rel, ln, m.get_string(1)])
				for m in words_re.search_all(line):
					if not GUARD_ALLOW.has(rel + "|" + m.get_string(1)):
						hits.append("%s:%d words '%s'" % [rel, ln, m.get_string(1)])
				for m in money_re.search_all(line):
					hits.append("%s:%d currency %s" % [rel, ln, m.get_string()])
				for m in key_re.search_all(line):
					if not UiText.EN.has(m.get_string(1)):
						bad_keys.append("%s:%d %s" % [rel, ln, m.get_string(1)])
	_ok(files > 80 and hits.is_empty(), "%d files: no hard-coded user text or hand-formatted currency %s" % [files, str(hits)])
	_ok(bad_keys.is_empty(), "every literal UiText.t / tn key exists %s" % str(bad_keys))
	# The guard really fires on the patterns it exists for.
	var probe := ["\tlbl.text = \"Shop\" + x", "\tlbl.add_child(_label(\"Coming soon today\"))", "\tb.text = \"$%s\" % price", "\tx.text = \"%.2f TRY\" % p"]
	var fired := 0
	for pl in probe:
		var tm := text_re.search(pl)
		fired += 1 if (tm != null and _has_letter2(tm.get_string(1))) or words_re.search(pl) != null or money_re.search(pl) != null else 0
	_ok(fired == probe.size(), "guard self-check: %d/%d planted violations detected" % [fired, probe.size()])
	_complete("l08_hardcoded_text_guard")

## %s / %d / %f specifiers in order (a literal %% is not a placeholder).
static func _ph(s: String) -> Array:
	var out: Array = []
	var i := 0
	while i < s.length():
		if s[i] == "%":
			if i + 1 < s.length() and s[i + 1] == "%":
				i += 2
				continue
			var j := i + 1
			while j < s.length() and not (s[j] >= "a" and s[j] <= "z"):
				j += 1
			out.append(s.substr(i, j - i + 1))
			i = j
		i += 1
	return out

## Code part of a line: an "#" outside quotes starts a comment.
static func _code(line: String) -> String:
	var q := false
	for i in range(line.length()):
		if line[i] == "\"":
			q = not q
		elif line[i] == "#" and not q:
			return line.substr(0, i)
	return line

static func _has_letter2(s: String) -> bool:
	return RegEx.create_from_string("[A-Za-z]{2}").search(s) != null

static func _files(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir.path_join(f))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(sub)))
	return out

## Visible Label / Button texts equal to an English table value that Turkish changes.
func _untranslated_en(node) -> Array:
	var en_only := {}
	for k in UiTextTr.TR:
		if String(UiText.EN[k]) != String(UiTextTr.TR[k]):
			en_only[String(UiText.EN[k])] = true
	var out: Array = []
	for n in (node as Node).find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and en_only.has(n.text):
			out.append("%s='%s'" % [n.name, n.text])
	return out

# ------------------------------------------------------------------ helpers ----

## Visible Label / Button texts with letters that do not carry the pseudo brackets.
func _untranslated(node) -> Array:
	var out: Array = []
	for n in (node as Node).find_children("*", "", true, false):
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var txt := ""
		if n is Label:
			txt = (n as Label).text
		elif n is Button:
			txt = (n as Button).text
		else:
			continue
		txt = txt.strip_edges()
		if txt.is_empty() or GLYPHS.has(txt) or not _has_letter(txt) or txt.begins_with("["):
			continue
		out.append("%s='%s'" % [n.name, txt.left(40)])
	return out

## Visible text controls whose rect leaves the viewport.
func _offscreen(node) -> Array:
	var vp := Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(1.0)
	var out: Array = []
	for n in (node as Node).find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
			var r: Rect2 = (n as Control).get_global_rect()
			if r.has_area() and not vp.encloses(r):
				out.append("%s %s" % [n.name, str(r)])
	return out

static func _has_letter(s: String) -> bool:
	for ch in s:
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
			return true
	return false

func _boot(tag: String, size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m51_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

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
	UiText.pseudo = false
	UiText.locale = "en"
	MainScript.boot_save_path_override = ""
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
	print("M51 localization readiness evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
