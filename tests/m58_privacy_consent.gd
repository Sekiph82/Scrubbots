extends SceneTree
## SB-M58-007..014 — privacy consent screen + privacy guards on the REAL app root:
##   p01 analytics consent is OFF by default: nothing tracked, no consent file written
##   p02 Settings has one PRIVACY button sharing the CLOSE row (touch >= 88, inside the frame,
##       frame fits 1080x1920); the existing cards keep their order (Reduced Effects in place)
##   p03 PRIVACY closes Settings and opens the "privacy" popup: ONE switch (SHARE ANALYTICS,
##       mirrors consent) that gates AnalyticsService.track and persists across a relaunch; the
##       no-ads line, summary and policy note; one CLOSE action
##   p04 SB-M58-014: every visible label keyed (English + Turkish), Turkish fits the screen,
##       touch >= 88, fonts >= the M50 floor, INK / ROYAL_EDGE text contrast >= 4.5 on the card
##   p05 AnalyticsService.set_consent has exactly one production caller (privacy_screen.gd)
##   p06 SB-M58-010: the scheduled reminder is (app name, fixed copy, seconds): no inserted
##       value / personal data in any reminder copy (EN + TR), no deep-link payload
##   p07 SB-M58-013: pack receipts / applied tx ids hold only their schema keys (no time, device
##       or store data), stay small per entry, are never pruned (a committed tx replays after a
##       relaunch, never redraws)
## Never boots main.tscn on the real save: temp user:// paths, removed at the end.
##
## Run: godot --headless --path . -s res://tests/m58_privacy_consent.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")
const PrivacyScreen = preload("res://scripts/ui/privacy_screen.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const A11y = preload("res://tools/accessibility_audit.gd")
const LocalNotifications = preload("res://scripts/economy/local_notifications.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const PackReceiptLedger = preload("res://scripts/collection/pack_receipt_ledger.gd")

## tests/m50_accessibility_audit.gd FONT_FLOOR.
const FONT_FLOOR := 18
## Popup text keys -> node names (p04 checks each label shows exactly its key's copy).
const LABELS := {"AnalyticsHint": "PRIVACY_ANALYTICS_HINT", "AdsNote": "PRIVACY_ADS", "SummaryHeader": "PRIVACY_SUMMARY_HEADER",
	"Summary_PRIVACY_SUMMARY_DEVICE": "PRIVACY_SUMMARY_DEVICE", "Summary_PRIVACY_SUMMARY_NO_ACCOUNT": "PRIVACY_SUMMARY_NO_ACCOUNT",
	"Summary_PRIVACY_SUMMARY_NOTIFY": "PRIVACY_SUMMARY_NOTIFY", "Summary_PRIVACY_SUMMARY_DELETE": "PRIVACY_SUMMARY_DELETE",
	"PolicyLink": "PRIVACY_POLICY_LINK"}
const REMINDER_KEYS := ["NOTIFY_HEARTS_FULL", "NOTIFY_DAILY", "NOTIFY_EVENT_ENDING", "NOTIFY_GIFT"]

var EXPECTED_CASES := ["p01_default_off", "p02_settings_row", "p03_popup_consent", "p04_localized_a11y",
	"p05_sole_caller", "p06_notification_privacy", "p07_receipt_retention"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _path := ""

class FakeHearts:
	func hearts() -> int: return 3
	func max_hearts() -> int: return 5
	func seconds_to_next() -> int: return 300

class FakeConfig:
	func hearts_regen_seconds() -> int: return 900

class FakeEvents:
	func list() -> Array: return [{"phase": "active", "claimable": 1, "ends_in": 3 * 86400}]

class FakeEconomy:
	var hearts := FakeHearts.new()
	var config := FakeConfig.new()
	var events := FakeEvents.new()

class FakeBackend:
	var scheduled: Array = []
	func schedule(title: String, body: String, seconds: int) -> void: scheduled.append([title, body, seconds])
	func cancel_all() -> void: pass

class FakePermission:
	func granted() -> bool: return true

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	_p01()
	await _boot()
	await _p02()
	await _p03()
	await _p04()
	_shutdown()
	_p05()
	_p06()
	_p07()
	_cleanup()
	_done()

func _p01() -> void:
	print("[p01 consent OFF by default]")
	var path := _new_path("p01")
	var app = AppState.new(path)
	_ok(not app.analytics.has_consent(), "fresh profile: analytics consent OFF")
	_ok(not app.analytics.track("session_start", {"trigger": "cold_start"}) and app.analytics.queued() == 0, "track() drops events without consent")
	_ok(not FileAccess.file_exists(_analytics_path(path)), "no consent file written before a choice")
	_completed["p01_default_off"] = true

func _p02() -> void:
	print("[p02 Settings PRIVACY row]")
	_root.open_settings()
	await _frames(4)
	var panel = _root.get_settings_panel()
	var b: Button = panel.get_privacy_button()
	var frame: Control = panel.find_child("Frame", true, false)
	_ok(b != null and b.is_visible_in_tree() and b.name == "PrivacyButton" and b.text == "PRIVACY", "PrivacyButton visible, keyed label %s" % (b.text if b != null else "<none>"))
	_ok(b.size.y >= 88, "touch height %d >= 88" % int(b.size.y))
	_ok(frame.get_global_rect().grow(0.5).encloses(b.get_global_rect()), "row inside the Settings frame")
	_ok(Rect2(Vector2.ZERO, Vector2(_sub.size)).encloses(frame.get_global_rect()), "Settings frame fits %s: %s" % [str(_sub.size), str(frame.get_global_rect())])
	var body: Node = panel.find_child("Body", true, false)
	var cards: Array = []
	for c in panel.find_child("Cards", true, false).get_children():
		if String(c.name).begins_with("Card_"):
			cards.append(String(c.name))
	_ok(cards.slice(-4) == ["Card_HapticsToggle", "Card_ReducedEffectsToggle", "Card_ColorSymbolsRow", "Card_LanguageRow"], "cards unchanged, Reduced Effects in place %s" % str(cards))
	var close: Button = panel.find_child("CloseButton", true, false)
	_ok(close.get_parent() == b.get_parent() and b.get_parent().get_parent() == body, "PRIVACY shares the CLOSE row (no extra row)")
	_completed["p02_settings_row"] = true

func _p03() -> void:
	print("[p03 PRIVACY popup + consent]")
	var stack = _root.get_modal_stack()
	_root.get_settings_panel().get_privacy_button().pressed.emit()
	await _frames(4)
	var p = stack.top()
	_ok(not _root.get_navigation().is_settings_open(), "Settings closed first")
	_ok(p != null and p.popup_id == "privacy" and stack.depth() == 1, "privacy popup is the one top modal")
	if p == null:
		_completed["p03_popup_consent"] = true
		return
	_ok(p.get_title() == "PRIVACY", "title %s" % p.get_title())
	var toggles: Array = p.find_children("*", "CheckButton", true, false)
	var t: CheckButton = p.find_child("AnalyticsToggle", true, false)
	_ok(toggles.size() == 1 and toggles[0] == t and t.text == "SHARE ANALYTICS", "exactly one switch: SHARE ANALYTICS (no ads placeholder toggle)")
	var an = _root.app_state.analytics
	_ok(not t.button_pressed and not an.has_consent(), "switch shows OFF by default")
	t.button_pressed = true
	_ok(an.has_consent() and an.track("session_start", {"trigger": "cold_start"}) and an.queued() == 1, "ON: consent granted, events tracked")
	_ok(AppState.new(_path).analytics.has_consent(), "ON persists across a relaunch")
	t.button_pressed = false
	_ok(not an.has_consent() and an.queued() == 0 and not an.track("session_start", {"trigger": "cold_start"}), "OFF: consent revoked, queue dropped, events refused")
	_ok(not AppState.new(_path).analytics.has_consent(), "OFF persists across a relaunch")
	_ok(_text(p, "AdsNote") == UiText.t("PRIVACY_ADS") and _text(p, "PolicyLink") == UiText.t("PRIVACY_POLICY_LINK"), "no-ads line and policy-link note shown")
	_ok(Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(0.5).encloses(p.get_frame_rect()), "popup frame inside the screen")
	_ok(p.get_action_ids() == ["close"], "one action: close")
	p.get_action_button("close").pressed.emit()
	await _frames(2)
	_ok(stack.depth() == 0 and not is_instance_valid(p), "CLOSE empties the stack")
	an.set_consent(true)
	var p2 = _root.open_privacy()
	await _frames(2)
	_ok(p2 != null and (p2.find_child("AnalyticsToggle", true, false) as CheckButton).button_pressed, "reopened switch mirrors saved consent ON")
	p2.close()
	an.set_consent(false)
	await _frames(2)
	_completed["p03_popup_consent"] = true

func _p04() -> void:
	print("[p04 localized + accessible]")
	for lang in ["en", "tr"]:
		UiText.locale = lang
		var p = PrivacyScreen.open(_root.get_modal_stack(), _root.app_state)
		await _frames(3)
		var keyed: bool = p.get_title() == UiText.t("PRIVACY_TITLE") and (p.find_child("AnalyticsToggle", true, false) as CheckButton).text == UiText.t("PRIVACY_ANALYTICS")
		for n in LABELS:
			keyed = keyed and _text(p, n) == UiText.t(LABELS[n])
		_ok(keyed, "%s: title, switch and every line show their key's copy" % lang)
		if lang == "tr":
			var all_tr := true
			for k in UiText.EN:
				if String(k).begins_with("PRIVACY_") and String(UiTextTr.TR.get(k, "")).is_empty():
					all_tr = false
			_ok(all_tr and p.get_title() == "GİZLİLİK", "every PRIVACY_ key has Turkish copy (title %s)" % p.get_title())
		_ok(Rect2(Vector2.ZERO, Vector2(_sub.size)).grow(0.5).encloses(p.get_frame_rect()), "%s: frame inside %s" % [lang, str(_sub.size)])
		var touch_ok := true
		var font_ok := true
		var scroll: Control = p.find_child("PrivacyScroll", true, false)
		for n in p.find_children("*", "", true, false):
			if n is BaseButton and (n as Control).is_visible_in_tree() and (n as Control).size.y < 88.0 - 0.5:
				touch_ok = false
				print("    small target %s %s" % [n.name, str((n as Control).size)])
			if (n is Label or n is Button) and (n as Control).get_theme_font_size("font_size") < FONT_FLOOR:
				font_ok = false
			if n is Label and scroll.is_ancestor_of(n) and (n as Control).size.x > scroll.size.x + 0.5:
				font_ok = false
				print("    label wider than the scroll %s" % n.name)
		_ok(touch_ok, "%s: every button / switch >= 88 px tall" % lang)
		_ok(font_ok, "%s: fonts >= %d px, wrapped inside the scroll" % [lang, FONT_FLOOR])
		p.close()
		await _frames(2)
	UiText.locale = "en"
	var ink := A11y.contrast_ratio(BasePopup.INK, BasePopup.ROW)
	var head := A11y.contrast_ratio(BasePopup.ROYAL_EDGE, BasePopup.ROW)
	_ok(ink >= 4.5 and head >= 4.5, "text contrast on the cream card: INK %.1f, ROYAL_EDGE %.1f (>= 4.5)" % [ink, head])
	_completed["p04_localized_a11y"] = true

func _p05() -> void:
	print("[p05 one consent caller]")
	var callers: Array = []
	_scan("res://scripts", callers)
	_ok(callers == ["res://scripts/ui/privacy_screen.gd"], "set_consent( called only from privacy_screen.gd %s" % str(callers))
	_completed["p05_sole_caller"] = true

func _p06() -> void:
	print("[p06 reminder privacy]")
	var pol := NotificationPolicy.new()
	pol.enabled = true
	var ln := LocalNotifications.new(pol, FakePermission.new(), func(): return 1790000000)
	ln.utc_offset_fn = func(): return 0
	var b := FakeBackend.new()
	ln.backend = b
	var r := ln.on_background(FakeEconomy.new(), false, func(k): return UiText.t(k))
	var app_name := String(ProjectSettings.get_setting("application/config/name", ""))
	_ok(b.scheduled.size() == 1 and b.scheduled[0][0] == app_name and b.scheduled[0][1] == UiText.t(r.get("key", "")),
		"scheduled reminder = (app name, fixed copy, seconds) %s" % str(b.scheduled))
	_ok(r.keys().all(func(k): return k in ["category", "key", "at"]), "plan carries only category / key / time %s" % str(r.keys()))
	var fixed := true
	for k in REMINDER_KEYS:
		for txt in [String(UiText.EN[k]), String(UiTextTr.TR[k])]:
			if txt.contains("%"):
				fixed = false
				print("    placeholder in %s: %s" % [k, txt])
	_ok(fixed, "every reminder copy (EN + TR) is fixed text: no inserted value")
	_ok(NotificationPolicy.deep_link("https://x.example/?id=1") == "home" and NotificationPolicy.deep_link("profile") == "profile", "deep links: allowlisted destinations only, anything else -> home")
	_completed["p06_notification_privacy"] = true

func _p07() -> void:
	print("[p07 receipt / tx retention]")
	var path := _new_path("p07")
	var app = AppState.new(path)
	var n := 12
	for i in range(n):
		var r: Dictionary = app.commit_pack("premium" if i % 2 == 0 else "standard", "m58_retention:%d" % i)
		if not bool(r.get("ok", false)):
			_ok(false, "commit %d: %s" % [i, str(r)])
	app.economy.reward.grant("m58_retention:grant", {})
	var snap: Dictionary = app.economy.snapshot()
	var receipts: Array = snap["pack_receipts"]["receipts"]
	_ok(receipts.size() == n, "%d receipts kept (none pruned)" % receipts.size())
	var keys_ok := true
	var biggest := 0
	for rc in receipts:
		var ks: Array = rc.keys()
		ks.sort()
		keys_ok = keys_ok and ks == ["cards", "kind", "presentation_id", "schema", "status", "tx_id"]
		for c in rc["cards"]:
			keys_ok = keys_ok and (c as Dictionary).size() == PackReceiptLedger.CARD_KEYS.size() and (c as Dictionary).keys().all(func(k): return k in PackReceiptLedger.CARD_KEYS)
		biggest = maxi(biggest, JSON.stringify(rc).length())
	_ok(keys_ok, "receipts hold only schema / tx / kind / status / card rows (no time, device or store data)")
	_ok(biggest <= 1500, "largest receipt %d bytes <= 1500" % biggest)
	var applied: Array = snap["reward"]["applied"]
	_ok(applied.all(func(t): return typeof(t) == TYPE_STRING and String(t).length() <= 64), "applied tx ids are short strings only (%d)" % applied.size() if not applied.is_empty() else "applied tx ids recorded")
	var again = AppState.new(path)
	var rp: Dictionary = again.commit_pack("premium", "m58_retention:0")
	_ok(bool(rp.get("replay", false)) and rp["receipt"] == receipts[0], "after a relaunch a committed tx replays its receipt, never redraws")
	_completed["p07_receipt_retention"] = true

# ---------------------------------------------------------------- helpers ----

func _scan(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.get_extension() == "gd" and FileAccess.get_file_as_string(dir.path_join(f)).contains(".set_consent("):
			out.append(dir.path_join(f))
	for s in d.get_directories():
		_scan(dir.path_join(s), out)

func _text(p, n: String) -> String:
	var l: Label = p.find_child(n, true, false)
	return l.text if l != null else "<missing %s>" % n

func _new_path(tag: String) -> String:
	var p := "user://m58_consent_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _analytics_path(save_path: String) -> String:
	return save_path.get_basename() + "_analytics.json"

func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 1920)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_path = _new_path("root")
	MainScript.boot_save_path_override = _path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	UiText.locale = "en"
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp", _analytics_path(p)]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M58 privacy consent evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
