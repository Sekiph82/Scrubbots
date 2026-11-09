extends "res://tests/m49_surface_matrix.gd"
## M50 assistive walk (SB-M50-012/015/016/017) on every M43/M44 surface the factory 118 walk
## reaches (tests/m49_surface_matrix.gd rows), REAL app root on throw-away saves, 1080x2400,
## English (the TR names: tests/m50_accessibility_audit.gd a09).
##   x01 every visible interactive button has a screen-reader name (Control.accessibility_name,
##       or its own text when that has >= 2 letters, e.g. "OK": "X", "?", "2x", "<" need a name)
##       and is reachable by screen-reader focus (focus_mode != FOCUS_NONE)
##   x02 text scale: every text control is scaled x1.15 and x1.3 (Godot 4.7 exposes no OS font
##       scale, so this is headroom, not a live setting): no text may be cut, ellipsized or
##       lose lines at x1.15; overhangs past the 1.0 layout are REPORTED per scale
##   x03 colour-coded / animated state has a text cue on the surface (robot lock, rank, rarity,
##       reward track lock / claim, event progress + reset timer, catch-up eligibility)
##
## Run: godot --headless --path . -s res://tests/m50_a11y_surfaces.gd   (~3 min, local only)

const PHONE := Vector2i(1080, 2400)
const SCALES := [1.15, 1.3]
## surface -> UiText keys whose text (up to its first argument) must be visible on it.
const STATE_CUES := {
	"comeback": ["COMEBACK_CATCHUP", "COMEBACK_CATCHUP_NEXT"],
	"robots": ["ROBOTS_LOCKED"],
	"leaderboard": ["RANKS_STATE_CURRENT"],
	"collection_set": ["RARITY_COMMON", "RARITY_RARE", "RARITY_EPIC", "RARITY_LEGENDARY"],
	"card_detail": ["RARITY_COMMON"],
	"rewarded_ads": ["RADS_LOCKED", "POPUP_CLAIM"],
	"daily": ["POPUP_CLAIM"],
	"events": ["POPUP_CLAIM", "EVENT_ENDS_IN", "EVENT_PROGRESS", "FIRST_TRY_RUN"],
}

var _unnamed: Array = []
var _unfocusable: Array = []
var _buttons := 0
var _clipped: Dictionary = {1.15: [], 1.3: []}
var _overhang: Dictionary = {1.15: [], 1.3: []}
var _cues_bad: Array = []
var _cues_seen := 0
var _letter := RegEx.create_from_string("\\p{L}")

func _initialize() -> void:
	EXPECTED_CASES = ["x01_names_and_focus", "x02_text_scale", "x03_state_text_cues"]
	await _setup()
	print("[x01 names + focus, x02 text scale x1.15 / x1.3, x03 state text cues at %s]" % str(PHONE))
	await _walk(PHONE)
	var missing: Array = []
	for row in _rows():
		if int(_walked.get(row, 0)) != 1:
			missing.append(row)
	_ok(missing.is_empty(), "every inventory row walked once %s" % str(missing))
	_ok(_buttons > 150 and _unnamed.is_empty(), "%d interactive buttons each have a screen-reader name %s" % [_buttons, str(_unnamed)])
	_ok(_unfocusable.is_empty(), "every interactive button takes screen-reader focus (FOCUS_ACCESSIBILITY) %s" % str(_unfocusable))
	_complete("x01_names_and_focus")
	_ok(_clipped[1.15].is_empty(), "x1.15 text scale: no text cut / ellipsized / losing lines %s" % str(_clipped[1.15]))
	for k in SCALES:
		print("    REPORT x%s: %d cut %s; %d overhang past the 1.0 layout %s" % [k, _clipped[k].size(), str(_clipped[k]), _overhang[k].size(), str(_overhang[k])])
	_complete("x02_text_scale")
	_ok(_cues_seen == STATE_CUES.size() and _cues_bad.is_empty(), "%d state surfaces show their text cues %s" % [_cues_seen, str(_cues_bad)])
	_complete("x03_state_text_cues")
	_finish()

func _scan(_phys: Vector2i, _lv: Vector2i, surf: String, node, _extra: Array = []) -> void:
	if node == null or not is_instance_valid(node):
		_ok(false, "%s: surface missing" % surf)
		return
	_walked[surf] = int(_walked.get(surf, 0)) + 1
	var texts := {}
	for n in [node] + node.find_children("*", "", true, false):
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		if (n is Label or n is Button) and not String(n.text).strip_edges().is_empty():
			texts[String(n.text).strip_edges()] = true
		if not (n is BaseButton) or (n as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		var b := n as BaseButton
		_buttons += 1
		var own := String(b.text).strip_edges() if b is Button else ""
		if String(b.accessibility_name).strip_edges().is_empty() and _letter.search_all(own).size() < 2:
			_unnamed.append("%s/%s '%s'" % [surf, b.name, own])
		if b.focus_mode == Control.FOCUS_NONE:
			_unfocusable.append("%s/%s" % [surf, b.name])
	if STATE_CUES.has(surf):
		_cues_seen += 1
		for key in STATE_CUES[surf]:
			var want: String = String(UiText.EN[key]).get_slice("%", 0)
			if not texts.keys().any(func(t): return String(t).begins_with(want)):
				_cues_bad.append("%s lacks '%s'" % [surf, want])
	# x02: the 1.0 layout is the overhang baseline (approved corner badges etc.), then each scale.
	_baseline_pass = true
	_text_bad(node, [])
	_baseline_pass = false
	for k in SCALES:
		var saved: Array = []
		for n in node.find_children("*", "", true, false):
			if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
				var c := n as Control
				saved.append([c, c.get_theme_font_size("font_size") if c.has_theme_font_size_override("font_size") else -1])
				c.add_theme_font_size_override("font_size", int(round(c.get_theme_font_size("font_size") * k)))
		await _frames(3)
		for why in _text_bad(node, []):
			(_overhang[k] if String(why).contains("leaves") else _clipped[k]).append("%s: %s" % [surf, why])
		for s in saved:
			if s[1] == -1:
				(s[0] as Control).remove_theme_font_size_override("font_size")
			else:
				(s[0] as Control).add_theme_font_size_override("font_size", s[1])
		await _frames(2)

func _title() -> String:
	return "M50 a11y surfaces"
