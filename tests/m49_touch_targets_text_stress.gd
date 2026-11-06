extends SceneTree
## M49 touch targets + text stress (SB-M49-020..022) against the REAL app root (main.tscn) on
## throw-away saves, in sized SubViewports (canvas_items / expand on 1080x2160, same mapping as
## tests/m49_responsive_matrix.gd), at 1080x2400, 1170x2532, 1536x2048 and compact 720x1280:
##   t00 English: the t02 checks hold; text overhanging its parent here is the approved design
##       (corner badges, price tags) and is the only overhang t02 / t03 accept
##   t01 every visible interactive control (BaseButton, Slider, supply front HitArea) on Home +
##       BottomNav, gameplay HUD (Pause, 2x, supply, boosters incl. locked plates), Pause popup,
##       Results WON / LOST, Shop, Daily, Tasks, Gift bar, Collection, Robots, Events, Ranks,
##       Profile, Help, Life and Settings is >= 88x88 design px and overlaps no other one; Home +
##       gameplay are measured again on a save WITHOUT the test unlock (real locked entries/plates)
##   t02 UiText pseudo-locale (+40%) on the same surfaces: no Label / Button text clipped,
##       ellipsized, cut to fewer visible lines, or leaving its parent / clip ancestor / screen
##   t03 a long Turkish sample (every key -> dotted / cedilla capitals, +60% length): same checks,
##       and every font used by a visible text control has the Turkish glyphs.
##   t04 the REAL Turkish table (SB-M51-005/009, UiText.locale = "tr"): same checks + glyphs.
##
## Run: godot --headless --path . -s res://tests/m49_touch_targets_text_stress.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")

const PHYSICAL := [Vector2i(1080, 2400), Vector2i(1170, 2532), Vector2i(1536, 2048), Vector2i(720, 1280)]
const TOUCH := float(UiTokens.TOUCH_MIN)
const TR_GLYPHS := "İıŞşĞğÇçÖöÜü"
const POPUPS := ["tasks", "daily", "gift_bar", "shop", "collection", "robots", "events", "profile", "leaderboard", "settings", "help", "life"]

var EXPECTED_CASES := ["t00_english_baseline", "t01_touch_targets", "t02_pseudo_text_stress", "t03_turkish_text_stress", "t04_real_turkish_table"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _baseline: Dictionary = {}   ## size|parent|control -> English parent overhang (l, t, r, b)
var _baseline_pass := false
var _scanned := 0   ## text controls measured in the current case
var _stressed := 0  ## ... of which carry the stress marker (pseudo "~" / Turkish " LER" suffix)

func _initialize() -> void:
	AppStateScript.test_unlock_all = true
	await process_frame
	MainScript.boot_opening_override = 0
	print("[t00 English baseline: no clipped / off-screen text; parent overhangs recorded as design]")
	_baseline_pass = true
	await _matrix("t00", _text_bad)
	_baseline_pass = false
	print("    diag: %d English parent overhangs %s" % [_baseline.size(), str(_baseline.keys().slice(0, 12))])
	_scanned = 0
	_stressed = 0
	_complete("t00_english_baseline")
	print("[t01 interactive hit rects >= 88x88 and non-overlapping on every surface]")
	await _matrix("t01", _touch_bad)
	_complete("t01_touch_targets")
	print("[t02 pseudo-locale +40%: no clipped / overflowing text]")
	UiText.pseudo = true
	await _matrix("t02", _text_bad)
	UiText.pseudo = false
	_stress_ok("~")
	_complete("t02_pseudo_text_stress")
	print("[t03 long Turkish sample: no clipped / overflowing text, Turkish glyphs present]")
	var tr := _turkish()
	TranslationServer.add_translation(tr)
	TranslationServer.set_locale("tr")
	await _matrix("t03", _text_bad)
	TranslationServer.set_locale("en")
	TranslationServer.remove_translation(tr)
	_stress_ok("LER")
	_complete("t03_turkish_text_stress")
	print("[t04 real Turkish table: no clipped / overflowing text, Turkish glyphs present]")
	UiText.locale = "tr"
	await _matrix("t04", _text_bad)
	UiText.locale = "en"
	_ok(_scanned > 500, "%d text controls measured in Turkish" % _scanned)
	_scanned = 0
	_stressed = 0
	_complete("t04_real_turkish_table")
	_shutdown()
	_cleanup()
	_done()

## Walk every surface on every size; `check` returns the findings for one scanned subtree.
func _matrix(tag: String, check: Callable) -> void:
	for phys in PHYSICAL:
		var lv := _logical(phys)
		await _boot(tag, lv)
		var stack = _root.get_modal_stack()
		stack.clear("test")
		await _frames(2)
		_report(phys, lv, "home", check.call(_root.get_home(), []))
		if tag == "t00":
			var ra: int = _root.get_home().get_region("RewardedAdsButton").get_theme_font_size("font_size")
			_ok(ra == 24, "%s: English REWARDED ADS keeps its 24 px font (%d)" % [str(phys), ra])
		for d in POPUPS:
			var top = await _open(d)
			if top == null:
				_ok(false, "%s %s: %s did not open" % [tag, str(phys), d])
				continue
			_report(phys, lv, d, check.call(top, []))
			stack.clear("test")
			await _frames(2)
		_root.play_current_frontier()
		await _frames(6)
		var host = _root.get_gameplay_host()
		if host == null:
			_ok(false, "%s %s: gameplay did not start" % [tag, str(phys)])
			continue
		host.get_runtime().set_process(false)
		_report(phys, lv, "gameplay", check.call(host.get_screen(), _fronts(host.get_screen())))
		if tag == "t00":
			_english_fonts(phys, host.get_screen())
		var pause = host.open_pause()
		await _frames(4)
		_report(phys, lv, "pause", check.call(pause, []) if pause != null else ["did not open"])
		host.modal_stack.clear("test")
		await _frames(2)
		for status in ["WON", "LOST"]:
			var res = _root.get_results_screen()
			res.visible = true
			res.show_model(_root._results_model({"status": status, "level": 1, "attempt": 1}))
			await _frames(6)
			_report(phys, lv, "results_" + status, check.call(res, []))
		# A fresh L1 save WITHOUT the test unlock: real locked Home entries and locked booster
		# plates (SB-M44-032 "LV N").
		AppStateScript.test_unlock_all = false
		await _boot(tag + "_locked", lv)
		AppStateScript.test_unlock_all = true
		_root.get_modal_stack().clear("test")
		await _frames(2)
		_report(phys, lv, "home_locked", check.call(_root.get_home(), []))
		_root.play_current_frontier()
		await _frames(6)
		var lh = _root.get_gameplay_host()
		if lh == null:
			_ok(false, "%s %s: locked gameplay did not start" % [tag, str(phys)])
			continue
		lh.get_runtime().set_process(false)
		var ls = lh.get_screen()
		var plates := 0
		for id in ls.get_booster_ids():
			plates += 1 if (ls.get_booster_button(id).get_node("LockedPlate") as Control).visible else 0
		_ok(plates > 0, "%s: %d locked booster plates shown at L1" % [str(phys), plates])
		_report(phys, lv, "gameplay_locked", check.call(ls, _fronts(ls)))

## The SB-M49-022 fit rule (HomeStyle.fit_font) never shrinks the English copy.
func _english_fonts(phys: Vector2i, s) -> void:
	var sc: float = s.get_shell_scale()
	var got := {"ProfileLevel": s.find_child("ProfileLevel", true, false).get_theme_font_size("font_size")}
	var want := {"ProfileLevel": int(22.0 * sc)}
	for id in s.get_booster_ids():
		got[id] = (s.get_booster_button(id).get_node("Price") as Label).get_theme_font_size("font_size")
		want[id] = int(20.0 * sc)
	_ok(got == want, "%s: English keeps the design font sizes %s" % [str(phys), str(got)])

## Supply front HitAreas (the real tap targets; panels are smaller) as extra touch items.
func _fronts(s) -> Array:
	var panel = s.get_supply_panel()
	var hits: Array = []
	for c in range(panel.get_column_count()):
		hits.append(["front%d" % c, panel.get_front_hit_rect(c)])
	return hits

func _open(d: String):
	var stack = _root.get_modal_stack()
	match d:
		"leaderboard":
			_root._on_home_nav("leaderboard")
		"settings":
			_root.open_settings()
			await _frames(4)
			return _root.get_settings_panel()
		"help":
			HelpTipsScreen.open(stack, _root.get_app_state())
		"life":
			_root.open_life("home")
		_:
			_root.open_deep_link(d)
	await _frames(4)
	return stack.top()

## The stress copy really reached the measured controls (most text is keyed UiText).
func _stress_ok(marker: String) -> void:
	_ok(_scanned > 500 and _stressed * 2 > _scanned, "%d text controls measured, %d carry the '%s' stress copy" % [_scanned, _stressed, marker])
	_scanned = 0
	_stressed = 0

func _report(phys: Vector2i, lv: Vector2i, surface: String, bad: Array) -> void:
	_ok(bad.is_empty(), "%s (logical %s) %s %s" % [str(phys), str(lv), surface, str(bad)])

# ------------------------------------------------------------------ checks ----

## Interactive hit rects under `node` (+ extra [name, Rect2] pairs): >= 88x88, no overlaps.
## Overlap uses the rect clipped by clip ancestors; size uses the full rect for scroll content
## (the player scrolls a partly hidden row into view), else the clipped rect.
func _touch_bad(node: Node, extra: Array) -> Array:
	var items: Array = []
	for e in extra:
		items.append([e[0], e[1], e[1]])
	for n in node.find_children("*", "", true, false):
		if (n is BaseButton or n is Slider) and (n as Control).is_visible_in_tree() and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			var full := (n as Control).get_global_rect()
			var hit := full.intersection(_clip_rect(n, true))
			if hit.has_area():
				items.append([_path(node, n), full if _in_scroll(n) else hit, hit])
	var bad: Array = []
	for it in items:
		var r: Rect2 = it[1]
		if r.size.x < TOUCH - 0.5 or r.size.y < TOUCH - 0.5:
			bad.append("%s %s<88" % [it[0], _rs(r)])
	for i in range(items.size()):
		for k in range(i + 1, items.size()):
			if (items[i][2] as Rect2).grow(-0.5).intersects((items[k][2] as Rect2).grow(-0.5)):
				bad.append("%s overlaps %s" % [items[i][0], items[k][0]])
	return bad

## Visible Label / Button text under `node` that is clipped, ellipsized, loses lines, or leaves
## its parent / clip ancestor / the screen.
func _text_bad(node: Node, _extra: Array) -> Array:
	var bad: Array = []
	var vp := Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(1.0)
	for n in node.find_children("*", "", true, false):
		if not (n is Label or n is Button) or not (n as Control).is_visible_in_tree():
			continue
		var c := n as Control
		var txt: String = c.text
		if txt.strip_edges().is_empty():
			continue
		var font: Font = c.get_theme_font("font")
		for ch in TR_GLYPHS:
			if (TranslationServer.get_locale() == "tr" or UiText.locale == "tr") and not font.has_char(ch.unicode_at(0)):
				bad.append("%s font lacks %s" % [_path(node, n), ch])
				break
		var r := c.get_global_rect()
		if not r.has_area():
			continue
		_scanned += 1
		if txt.contains("~") or txt.contains(" LER") or txt.contains(" ler"):
			_stressed += 1
		var why := _cut(c)
		if not why.is_empty():
			bad.append("%s %s '%s'" % [_path(node, n), why, txt.left(24)])
		var clip := _clip_rect(c, false).grow(1.0)
		var screen := Rect2(vp.position.x, -1e6, vp.size.x, 2e6) if _in_scroll(c) else vp
		if not screen.encloses(r) or not clip.encloses(r):
			bad.append("%s leaves %s %s" % [_path(node, n), "screen" if not screen.encloses(r) else "clip", _rs(r)])
		# Leaving the parent: English overhangs (corner badges, price tags under a plate) are the
		# approved design and recorded by t00; stress copy may not overhang further on any side.
		var par := c.get_parent() as Control
		if par != null and not (par is ScrollContainer) and par.get_global_rect().has_area():
			var pr := par.get_global_rect()
			var over := Vector4(pr.position.x - r.position.x, pr.position.y - r.position.y, r.end.x - pr.end.x, r.end.y - pr.end.y)
			var key := "%s|%s|%s" % [str(_sub.size), par.name, c.name]
			if _baseline_pass:
				if over[over.max_axis_index()] > 1.0:
					_baseline[key] = over
			else:
				var base: Vector4 = _baseline.get(key, Vector4.ZERO)
				for i in range(4):
					if over[i] > maxf(base[i], 0.0) + 1.0:
						bad.append("%s leaves parent %s %s" % [_path(node, n), _rs(r), _rs(pr)])
						break
	return bad

## Why the control's own text does not fully show ("" = it does).
func _cut(c: Control) -> String:
	if c is Label:
		var l := c as Label
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return "lines %d>%d" % [l.get_line_count(), l.get_visible_line_count()] if l.get_line_count() > l.get_visible_line_count() else ""
		if l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			var w := l.get_theme_font("font").get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
			return "cut %d>%d" % [int(w), int(l.size.x)] if w > l.size.x + 1.0 else ""
		return ""
	var b := c as Button
	if b.autowrap_mode != TextServer.AUTOWRAP_OFF or not (b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
		return ""
	var avail := b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
	if b.icon != null and not b.expand_icon:
		avail -= b.icon.get_width() + b.get_theme_constant("h_separation")
	var tw := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
	return "cut %d>%d" % [int(tw), int(avail)] if tw > avail + 1.0 else ""

## Intersection of every clip_contents ancestor rect. ScrollContainers clip input fully
## (`touch`); for text only their horizontal extent counts (content scrolls out vertically).
func _clip_rect(n: Node, touch: bool) -> Rect2:
	var r := Rect2(-1e6, -1e6, 2e6, 2e6)
	var p := n.get_parent()
	while p != null and p is Control:
		var pc := p as Control
		if pc is ScrollContainer and not touch:
			var g := pc.get_global_rect()
			r = r.intersection(Rect2(g.position.x, -1e6, g.size.x, 2e6))
		elif pc.clip_contents:
			r = r.intersection(pc.get_global_rect())
		p = p.get_parent()
	return r

## Every UiText key -> a long Turkish-flavoured sample: English with Turkish capitals / cedillas
## swapped in and padded to +60% with a Turkish suffix, placeholders kept.
func _turkish() -> Translation:
	var tr := Translation.new()
	tr.locale = "tr"
	var swap := {"I": "İ", "i": "ı", "S": "Ş", "s": "ş", "G": "Ğ", "g": "ğ", "C": "Ç", "c": "ç", "O": "Ö", "o": "ö", "U": "Ü", "u": "ü"}
	for k in UiText.EN:
		var en := String(UiText.EN[k])
		if en.is_empty():
			continue
		var out := ""
		var prev := ""
		for ch in en:
			out += ch if prev == "%" else String(swap.get(ch, ch))   # keep %s / %d placeholders
			prev = ch
		var pad := int(ceil(en.length() * 0.6))
		var suffix := "LERİNİZDEN" if en == en.to_upper() else "lerinizden"
		out += " " + suffix.repeat(pad / suffix.length() + 1).left(pad)
		tr.add_message(String(k), out)
	return tr

static func _in_scroll(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false

# ------------------------------------------------------------------ helpers ----

static func _path(root: Node, n: Node) -> String:
	return String(root.get_path_to(n)).get_file() if n != root else String(n.name)

static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

static func _rs(r: Rect2) -> String:
	return "[%d,%d %dx%d]" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]

func _boot(tag: String, size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m49_tt_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M49 touch targets + text stress evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
