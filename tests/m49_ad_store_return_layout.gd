extends SceneTree
## SB-M49-029 (mock part) — rewarded-ad, interstitial and store-purchase RETURN transitions do not
## corrupt the safe-area layout. Real app root (main.tscn) on throw-away saves; TEST-ONLY provider
## subclasses (no SDK, no network) simulate a platform overlay while it is up:
##   FOCUS_OUT + PAUSED -> viewport resize (landscape) + safe-area change -> size / insets back
##   -> RESUMED + FOCUS_IN, then the provider delivers completed / cancelled / failed.
## Per surface and outcome: the layout on return equals the pre-overlay layout (Home regions,
## gameplay board region / slots / supply / buttons, Results CTA, every popup frame), every rect
## stays inside the safe rect, no popup is left busy, a real tap still reaches the top, the stack
## returns to its pre-overlay depth and the Home banner slot matches StoreService.ads_allowed.
##   r01 Shop store purchase   r02 Shop restore   r03 Results LOST -> Need a Hand rewarded
##   r04 WON -> Home PLAY interstitial   r05 Home Rewarded Ads card   r06 Life rewarded heart
## Sizes: tests/m49_responsive_matrix.gd 720x1280 + 1170x2532 with its notch, 1080x2160 without.
## Real AdMob / Play Billing / StoreKit overlays stay a device check.
##
## Run: godot --headless --path . -s res://tests/m49_ad_store_return_layout.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const StoreProvider = preload("res://scripts/economy/store_provider.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const RespMatrix = preload("res://tests/m49_responsive_matrix.gd")
const EMU := InputEvent.DEVICE_ID_EMULATION

const NOTCH: Array = RespMatrix.NOTCH
## Insets while the overlay is up (landscape: the cut-out moved to the side).
const OVERLAY_INSETS := [132, 0, 96, 40]
const SIZES := [[Vector2i(720, 1280), true], [Vector2i(1080, 2160), false], [Vector2i(1170, 2532), true]]
const OUTCOMES := ["cancelled", "failed", "completed"]
const HOME_REGIONS := ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily",
	"BottomNav", "TopCurrencyHUD", "GiftMeter", "AdBannerSlot"]
const BOOSTERS0 := {"plus_one_slot": 0, "random": 0, "selector": 0, "tornado": 0}

var EXPECTED_CASES := [
	"r01_shop_purchase", "r02_shop_restore", "r03_results_need_a_hand_rewarded",
	"r04_continue_interstitial", "r05_home_rewarded_card", "r06_life_rewarded",
]

## TEST-ONLY ad provider: banner / interstitial / rewarded calls are recorded; a rewarded video
## resolves only when the test calls finish() (after the overlay returned).
class OverlayAds extends AdProvider:
	var fill := true
	var banner: Array = []
	var interstitials: Array = []
	var requests: Array = []
	var _deliver: Callable
	func set_banner(visible: bool) -> void:
		banner.append(visible)
	func show_interstitial(placement: String) -> bool:
		interstitials.append(placement)
		return fill
	func is_available(_placement: String) -> bool:
		return true
	func request(placement: String, token: String, deliver: Callable) -> bool:
		requests.append([placement, token])
		_deliver = deliver
		return true
	func finish(outcome: String) -> void:
		_deliver.call(requests[-1][1], {"outcome": outcome, "verified": true})

## TEST-ONLY store provider: purchase / restore sheets stay open until finish() / finish_restore().
class OverlayStore extends StoreProvider:
	var prices := {"scrubbucks_100": "US$0.99", "scrubbucks_550": "US$4.99", "scrubbucks_1200": "US$9.99",
		"scrubbucks_2600": "US$19.99", "scrubbucks_7000": "US$49.99", "no_ads": "US$4.99"}
	var started: Array = []
	var restores := 0
	var _deliver: Callable
	var _restore: Callable
	func is_available() -> bool:
		return true
	func query_products(ids: Array, deliver: Callable) -> bool:
		var out := {}
		for id in ids:
			if prices.has(id):
				out[id] = prices[id]
		deliver.call(out)
		return true
	func purchase(id: String, deliver: Callable) -> bool:
		started.append(id)
		_deliver = deliver
		return true
	func finish(token: String, outcome: String) -> void:
		_deliver.call({"product_id": started[-1], "token": token, "outcome": "purchased" if outcome == "completed" else outcome})
	func restore(deliver: Callable) -> bool:
		restores += 1
		_restore = deliver
		return true
	## completed = No Ads owned; cancelled = nothing owned; failed = the store never answers.
	func finish_restore(outcome: String) -> void:
		if outcome == "completed":
			_restore.call([{"product_id": "no_ads", "token": "tokR"}])
		elif outcome == "cancelled":
			_restore.call([])

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _ads: OverlayAds
var _store: OverlayStore
var _lv := Vector2i.ZERO
var _phys := Vector2i.ZERO
var _notch := false

func _initialize() -> void:
	AppState.test_unlock_all = true
	MainScript.boot_opening_override = 0
	await process_frame
	await _r01()
	await _r02()
	await _r03()
	await _r04()
	await _r05()
	await _r06()
	_shutdown()
	MainScript.boot_opening_override = -1
	AppState.test_unlock_all = false
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _r01() -> void:
	print("[r01 Shop store purchase: sheet overlay -> completed / cancelled / failed]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r01", sz[0], sz[1])
			_root.get_acquisition().open_shop({"source": "test"})
			await _frames(4)
			var shop = _top()
			var pre := _layout()
			var sb0: int = _eco().wallet.scrub_bucks()
			shop._on_action("buy:store:scrubbucks_550")
			await _frames(2)
			_ok(_store.started == ["scrubbucks_550"], "%s: store sheet opened" % _tag(outcome))
			await _return_check(_layout(), outcome)
			_store.finish("tok_" + outcome, outcome)
			await _frames(4)
			_ok(_eco().wallet.scrub_bucks() == sb0 + (550 if outcome == "completed" else 0), "%s: grant only on completed" % _tag(outcome))
			await _result_check(pre, outcome, 1)
	_complete("r01_shop_purchase")

func _r02() -> void:
	print("[r02 Shop restore: sheet overlay -> No Ads restored / nothing owned / no answer]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r02", sz[0], sz[1])
			_root.get_acquisition().open_shop({"source": "test"})
			await _frames(4)
			var pre := _layout()
			_top()._on_action("restore")
			await _frames(2)
			_ok(_store.restores == 1, "%s: restore started" % _tag(outcome))
			await _return_check(_layout(), outcome)
			_store.finish_restore(outcome)
			await _frames(4)
			var no_ads: bool = outcome == "completed"
			_ok(_eco().store.no_ads() == no_ads, "%s: No Ads entitlement %s" % [_tag(outcome), str(no_ads)])
			# A restored No Ads legitimately collapses the Home banner slot (checked by _banner_ok).
			await _result_check(pre, outcome, 1, no_ads)
	_complete("r02_shop_restore")

func _r03() -> void:
	print("[r03 Results LOST -> Need a Hand WATCH: video overlay -> result]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r03", sz[0], sz[1])
			var host = await _start(_root.play_current_frontier().get("ok", false))
			host.get_completion().terminal_reached.emit(&"LOST", {})
			await _frames(6)
			_modals().clear("t")
			_eco().boosters.import_snapshot(BOOSTERS0)
			var nah = _root.get_acquisition().open_need_a_hand({"show": true, "level": 1, "picks": [{"id": "tornado"}, {"id": "random"}]})
			await _frames(4)
			_ok(nah != null and _results_visible(), "%s: Need a Hand over LOST Results" % _tag(outcome))
			var pre := _layout()
			nah._on_action("watch:tornado")
			await _frames(2)
			_ok(_ads.requests.size() == 1 and nah.is_busy(), "%s: video requested, popup busy" % _tag(outcome))
			await _return_check(_layout(), outcome)
			_ads.finish(outcome)
			await _frames(4)
			_ok(_eco().boosters.charges("tornado") == (1 if outcome == "completed" else 0), "%s: charge only on completed" % _tag(outcome))
			await _result_check(pre, outcome, 1)
	_complete("r03_results_need_a_hand_rewarded")

func _r04() -> void:
	print("[r04 Results WON -> Home -> PLAY with a due interstitial: overlay over the next level]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r04", sz[0], sz[1])
			var host = await _start(_root.play_current_frontier().get("ok", false))
			host.get_completion().terminal_reached.emit(&"WON", {})
			await _frames(6)
			_modals().clear("t")
			_eco().ads.import_snapshot({"plays": 5, "last_interstitial": 0})
			_ads.fill = outcome != "failed"
			await _frames(2)
			host = await _start(_home_play())
			_ok(_ads.interstitials == ["interstitial_between_levels"] and _ads.requests.is_empty(), "%s: interstitial requested at Home PLAY (the next attempt start)" % _tag(outcome))
			_ok(_eco().ads.interstitial_due() == (outcome == "failed"), "%s: cadence (no fill stays due)" % _tag(outcome))
			var pre := _layout()
			await _return_check(pre, outcome)
			var rt = host.get_runtime()
			_ok(not rt.is_paused() and not rt.is_system_suspended(), "%s: gameplay not left suspended" % _tag(outcome))
			_ok(_ads.banner[-1] == _eco().store.ads_allowed("banner"), "%s: provider banner = ads_allowed(banner)" % _tag(outcome))
			_ok(await _tap_front(host), "%s: a real tap on a supply front still places it (no input blocker)" % _tag(outcome))
	_complete("r04_continue_interstitial")

func _r05() -> void:
	print("[r05 Home Rewarded Ads card: WATCH AD video overlay -> result]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r05", sz[0], sz[1])
			_ok(_app().actions.claim_rewarded_daily_free().get("ok", false), "%s: slot 1 claimed" % _tag(outcome))
			var p = RewardedAdsScreen.open(_modals(), _app())
			await _frames(4)
			var pre := _layout()
			p._on_action("slot:2")
			await _frames(2)
			_ok(_ads.requests.size() == 1 and p.is_busy(), "%s: video requested, popup busy" % _tag(outcome))
			await _return_check(_layout(), outcome)
			_ads.finish(outcome)
			await _frames(4)
			_ok(_eco().rewarded_daily.slot_state(2) == ("claimed" if outcome == "completed" else "ready_ad"), "%s: slot 2 %s" % [_tag(outcome), _eco().rewarded_daily.slot_state(2)])
			await _result_check(pre, outcome, 1)
	_complete("r05_home_rewarded_card")

func _r06() -> void:
	print("[r06 Home Heart + -> Life WATCH: video overlay -> result]")
	for sz in SIZES:
		for outcome in OUTCOMES:
			await _boot("r06", sz[0], sz[1])
			_eco().hearts.import_snapshot({"hearts": 2, "anchor": int(Time.get_unix_time_from_system())})
			var p = _root.get_acquisition().open_life("home")
			await _frames(4)
			var pre := _layout()
			p._on_action("watch")
			await _frames(2)
			_ok(_ads.requests.size() == 1 and p.is_busy(), "%s: video requested, popup busy" % _tag(outcome))
			await _return_check(_layout(), outcome)
			_ads.finish(outcome)
			await _frames(4)
			_ok(_eco().hearts.hearts() == (3 if outcome == "completed" else 2), "%s: +1 Heart only on completed" % _tag(outcome))
			await _result_check(pre, outcome, 1)
	_complete("r06_life_rewarded")

# ------------------------------------------------------------- overlay checks ----

## The platform overlay is up: focus out / pause, a landscape resize and a safe-area change,
## then everything comes back (size, insets, resume, focus). The layout must equal `pre`
## (taken after the request, so a popup's own busy line is part of it).
func _return_check(pre: Dictionary, outcome: String) -> void:
	_os(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_os(NOTIFICATION_APPLICATION_PAUSED)
	await _frames(2)
	_sub.size = Vector2i(_lv.y, _lv.x)
	_insets(OVERLAY_INSETS)
	await _frames(4)
	var during := _layout()
	_sub.size = _lv
	_insets(NOTCH if _notch else [0, 0, 0, 0])
	await _frames(2)
	_os(NOTIFICATION_APPLICATION_RESUMED)
	_os(NOTIFICATION_APPLICATION_FOCUS_IN)
	await _frames(4)
	var post := _layout()
	_ok(during != pre, "%s: overlay really changed the layout while up" % _tag(outcome))
	var diff := _diff(pre, post, false)
	_ok(diff.is_empty(), "%s: layout on return == pre-overlay %s" % [_tag(outcome), str(diff)])
	var out := _outside(post)
	_ok(out.is_empty(), "%s: on return every rect inside the safe rect %s" % [_tag(outcome), str(out)])

## After the delivered result: no busy popup, rects inside, banner correct; the result popups
## (feedback by a real tap on its X; a reward ceremony without one closes programmatically) come
## off down to the pre-request depth, where the layout equals `pre` again (the Home banner region
## excepted when the result legitimately collapsed it).
func _result_check(pre: Dictionary, outcome: String, close_to: int, banner_changed := false) -> void:
	var top = _top()
	_ok(top != null and not top.is_busy(), "%s: top popup %s not busy after the result" % [_tag(outcome), str(_modals().ids())])
	var out := _outside(_layout())
	_ok(out.is_empty(), "%s: after the result every rect inside the safe rect %s" % [_tag(outcome), str(out)])
	var guard := 0
	while _modals().depth() > close_to and guard < 4:
		guard += 1
		var d: int = _modals().depth()
		var id: String = _top().popup_id
		var tap: bool = _top().get_close_button().is_visible_in_tree()
		if tap:
			await _tap_close_top()
		else:
			_top().close("test")
			await _frames(2)
		_ok(_modals().depth() == d - 1, "%s: result popup %s closed (%s)" % [_tag(outcome), id, "real tap" if tap else "no X: programmatic"])
	_ok(_modals().depth() == close_to, "%s: back to pre-overlay depth %d %s" % [_tag(outcome), close_to, str(_modals().ids())])
	var diff := _diff(pre, _layout(), banner_changed)
	_ok(diff.is_empty(), "%s: layout after the result == pre-overlay %s" % [_tag(outcome), str(diff)])
	_ok(_banner_ok(), "%s: banner slot = ads_allowed(banner) (slot %s, provider %s)" % [_tag(outcome), str(_root.get_home().is_ad_slot_enabled()), str(_ads.banner.slice(-1))])
	var sid: String = _top().popup_id
	await _tap_close_top()
	# A Rewarded Ads pack reward that was closed above without opening re-presents on Home: only
	# the surface popup itself must be gone.
	_ok(_modals().depth() == close_to - 1 or not _modals().ids().has(sid), "%s: a real tap on its X still closes the surface popup (no input blocker) %s" % [_tag(outcome), str(_modals().ids())])

# ------------------------------------------------------------------ layout ----

## Every measured rect of what is on screen now, plus the popup stack.
func _layout() -> Dictionary:
	var out := {}
	var home = _root.get_home()
	if home.is_visible_in_tree():
		for n in HOME_REGIONS:
			var c: Control = home.get_region(n)
			if c != null and c.is_visible_in_tree():
				out["home/" + n] = c.get_global_rect()
		out["banner"] = home.is_ad_slot_enabled()
	if _results_visible():
		out["results/cta"] = _root.get_results_screen().get_primary_button().get_global_rect()
	var host = _root.get_gameplay_host()
	if host != null and is_instance_valid(host) and host.get_screen() != null and host.get_screen().is_visible_in_tree():
		var s = host.get_screen()
		out["game/board"] = s.get_board_rect()
		out["game/board_region"] = s.get_board_region_rect()
		out["game/slots"] = s.get_five_slot_strip_rect()
		out["game/supply"] = s.get_supply_panel_rect()
		out["game/pause"] = s.get_pause_button().get_global_rect()
		for id in ["plus_one_slot", "random", "selector", "tornado"]:
			out["game/booster_" + id] = s.get_booster_button(id).get_global_rect()
	out["modals"] = _modals().ids()
	var i := 0
	for id in _modals().ids():
		var p = _modals()._stack[i]
		out["modal%d/%s" % [i, id]] = p.get_frame_rect()
		i += 1
	return out

func _diff(a: Dictionary, b: Dictionary, skip_banner: bool) -> Array:
	var bad: Array = []
	var keys: Array = a.keys()
	for k in b.keys():
		if not keys.has(k):
			keys.append(k)
	for k in keys:
		if skip_banner and String(k).begins_with("home/") or skip_banner and k == "banner":
			continue
		if not (a.has(k) and b.has(k)):
			bad.append("%s only on one side" % k)
		elif typeof(a[k]) == TYPE_RECT2:
			if not (a[k] as Rect2).is_equal_approx(b[k]):
				bad.append("%s %s->%s" % [k, _rs(a[k]), _rs(b[k])])
		elif a[k] != b[k]:
			bad.append("%s %s->%s" % [k, str(a[k]), str(b[k])])
	return bad

## Rects outside the safe rect (Results has no safe root: it is measured against the screen).
func _outside(l: Dictionary) -> Array:
	var safe := Rect2(Vector2.ZERO, Vector2(_lv))
	if _notch:
		safe = Rect2(Vector2(NOTCH[0], NOTCH[1]), Vector2(_lv) - Vector2(NOTCH[0] + NOTCH[2], NOTCH[1] + NOTCH[3]))
	var bad: Array = []
	for k in l:
		if typeof(l[k]) == TYPE_RECT2:
			var outer: Rect2 = Rect2(Vector2.ZERO, Vector2(_lv)) if String(k).begins_with("results/") else safe
			if not RespMatrix._inside(l[k], outer):
				bad.append("%s %s" % [k, _rs(l[k])])
	return bad

func _banner_ok() -> bool:
	var want: bool = _eco().store.ads_allowed("banner")
	var home = _root.get_home()
	var slot: Control = home.get_region("AdBannerSlot")
	return home.is_ad_slot_enabled() == want and slot.visible == want and not _ads.banner.is_empty() and _ads.banner[-1] == want

# ------------------------------------------------------------------ helpers ----

func _tag(outcome: String) -> String:
	return "%dx%d (logical %dx%d)%s %s" % [_phys.x, _phys.y, _lv.x, _lv.y, " notch" if _notch else "", outcome]

func _boot(tag: String, phys: Vector2i, notch: bool) -> void:
	_shutdown()
	_phys = phys
	_lv = RespMatrix._logical(phys)
	_notch = notch
	_sub = SubViewport.new()
	_sub.size = _lv
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m49_asr_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)
	_modals().clear("t")
	_ads = OverlayAds.new()
	_eco().ads.set_provider(_ads)
	_store = OverlayStore.new()
	_eco().store.set_provider(_store)
	_insets(NOTCH if notch else [0, 0, 0, 0])
	await _frames(4)

func _start(ok: bool):
	_ok(ok, "level %d started" % _app().progression.current_level())
	await _frames(6)
	var host = _root.get_gameplay_host()
	host.get_runtime().set_process(false)
	_insets(NOTCH if _notch else [0, 0, 0, 0])
	await _frames(4)
	return host

## Synthetic safe insets on every safe-area root on screen (Home, popups, gameplay).
func _insets(i: Array) -> void:
	_root.get_home().get_region("SafeAreaRoot").set_synthetic_insets(i[0], i[1], i[2], i[3])
	_modals().set_synthetic_safe_insets(i[0], i[1], i[2], i[3])
	var host = _root.get_gameplay_host()
	if host != null and is_instance_valid(host) and host.get_screen() != null:
		host.get_screen().set_synthetic_safe_insets(i[0], i[1], i[2], i[3])

## An OS lifecycle notification, delivered the way SceneTree does (to the whole tree).
func _os(what: int) -> void:
	get_root().propagate_notification(what)

func _results_visible() -> bool:
	return _root.get_results_screen() != null and _root.get_results_screen().is_visible_in_tree()

func _tap_close_top() -> void:
	var top = _top()
	if top == null:
		return
	var b: Button = top.get_close_button()
	if b == null or not b.is_visible_in_tree():
		b = top.get_action_button("close")
	if b != null:
		await _sub_tap(b.get_global_rect().get_center())
	await _frames(2)

## A real tap on the first enabled supply front places exactly that column.
func _tap_front(host) -> bool:
	var panel = host.get_screen().get_supply_panel()
	var got: Array = []
	host.get_input_controller().activation_result.connect(func(c, ok, _e): got.append([c, ok]))
	for c in range(panel.get_column_count()):
		if panel.get_front_enabled(c):
			await _sub_tap(panel.get_front_hit_rect(c).get_center())
			return got.size() == 1 and int(got[0][0]) == c and bool(got[0][1])
	return false

## One platform-ordered tap into the sized SubViewport (same order as tests/m49_responsive_matrix).
func _sub_tap(p: Vector2) -> void:
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.device = EMU
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.global_position = p
		m.pressed = pressed
		_sub.push_input(m, true)
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = p
		t.pressed = pressed
		_sub.push_input(t, true)
		await process_frame

func _app():
	return _root.get_app_state()

func _eco():
	return _app().economy

func _modals():
	return _root.get_modal_stack()

func _top():
	return _modals().top()

static func _rs(r: Rect2) -> String:
	return "[%d,%d %dx%d]" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]

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
	MainScript.boot_save_path_override = ""

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		var an: String = p.get_basename() + "_analytics.json"
		if FileAccess.file_exists(an):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(an))

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
	print("M49 ad/store return layout evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)

## SB-PHONE-2026-11-12-B: a win goes Home (the WON primary), then Home PLAY starts the next level.
func _home_play() -> bool:
	_root.get_results_screen().get_primary_button().pressed.emit()
	return _root.play_current_frontier().get("ok", false)
