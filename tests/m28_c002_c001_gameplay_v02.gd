extends SceneTree
## M28-C002-C001 — Gameplay Screen V02 core evidence (OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02).
## Production path: real main.tscn root inside a resizable SubViewport, real frontier
## launch, real ProductionGameplayHost / GameplayScreen / economy services.
##
## Run: godot --headless --path . -s res://tests/m28_c002_c001_gameplay_v02.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const EPS := 1.0e-3
const MATRIX := [
	Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400),
	Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048),
]

var EXPECTED_CASES := [
	"composition_no_obsolete", "responsive_matrix", "safe_area_insets", "connectors_truthful",
	"sixth_connector_conditional", "supply_columns_rows", "preview_non_interactive",
	"front_click_mapping", "four_boosters_live", "booster_requests_no_silent_spend",
	"timed_2x_wallclock", "speed_modes", "pause_top_right", "retry_no_accumulation",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [1_800_000_000]
var _sub: SubViewport
var _root

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _boot(2)
	_composition_no_obsolete()
	await _responsive_matrix()
	await _safe_area_insets()
	await _connectors_truthful()
	await _sixth_connector_conditional()
	_supply_columns_rows()
	await _preview_non_interactive()
	await _front_click_mapping()
	await _four_boosters_live()
	await _booster_requests_no_silent_spend()
	await _timed_2x_wallclock()
	await _speed_modes()
	await _pause_top_right()
	await _retry_no_accumulation()
	_shutdown()
	MainScript.boot_clock_override = Callable()
	MainScript.boot_opening_override = -1
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixture ----

func _boot(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	var path := "user://m28c002_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_host().get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _host():
	return _root.get_gameplay_host()

func _screen():
	return _host().get_screen()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _resize(size: Vector2i) -> void:
	_sub.size = size
	await _settle()

# ------------------------------------------------------------------ cases ----

func _composition_no_obsolete() -> void:
	print("[composition / no obsolete elements]")
	var s = _screen()
	_ok(s is GameplayScreen and _host().get_screen() == s, "the REAL ProductionGameplayHost screen is the V02 GameplayScreen")
	_ok(not s.has_ad_placeholder(), "no bottom ad placeholder / bottom action row")
	_ok(not s.has_settings_control(), "no gameplay Settings control")
	_ok(not s.has_heart_hud(), "no Heart HUD")
	_ok(not s.has_goal_moves_panel() and not s.has_level_lock_rail(), "no Goal/Moves/Time panel, no Level/lock rail")
	_ok(s.get_booster_count() == 4 and s.get_booster_ids() == ["plus_one_slot", "random", "selector", "tornado"], "exactly four boosters, canonical order")
	_ok(s.get_rail_view().is_art_skinned(), "Railroad V1 production skin (approved rail art) loaded")
	_ok(s.get_profile_level_text() == "Level 2", "profile chip shows the live frontier level (%s)" % s.get_profile_level_text())
	var p: Dictionary = _host().get_economy().robots.next_robot_progress()
	_ok(s.get_profile_parts_text() == "%d/%d" % [p["parts"], p["cost"]], "profile Bot Parts from RobotUnlockService (%s)" % s.get_profile_parts_text())
	_complete("composition_no_obsolete")

## Responsive matrix: hierarchy, board dominance/aspect, safe containment, touch sizes.
func _responsive_matrix() -> void:
	print("[responsive matrix]")
	var h = _host()
	var bw: int = h.get_board().get_width()
	var bh: int = h.get_board().get_height()
	for size in MATRIX:
		await _resize(size)
		var s = _screen()
		var tag := "%dx%d" % [size.x, size.y]
		var safe: Rect2 = s.get_safe_rect()
		var board: Rect2 = s.get_board_rect()
		var cell: float = s.get_cell_size()
		var env: Rect2 = board.grow(GameplayScreen.RAIL_PAD_CELLS * cell)
		var top: Rect2 = s.get_top_region_rect()
		var strip: Rect2 = s.get_five_slot_strip_rect()
		var supply: Rect2 = s.get_supply_panel_rect()
		var boosters: Rect2 = s.get_booster_row_rect()
		var pause: Rect2 = s.get_pause_rect()
		var speed: Rect2 = s.get_speed_control_rect()
		_ok(absf(board.size.x / board.size.y - float(bw) / float(bh)) < 0.01, "%s: board aspect preserved" % tag)
		_ok(board.get_area() > strip.get_area() + supply.get_area() and board.get_area() > boosters.get_area() * 4.0, "%s: board is the dominant region" % tag)
		_ok(_inside(env, safe) and _inside(top, safe) and _inside(strip, safe) and _inside(supply, safe) and _inside(boosters, safe),
			"%s: rail envelope, HUD, slots, supply, boosters inside safe rect" % tag)
		_ok(top.end.y <= env.position.y + 1.0 and env.end.y < strip.position.y and strip.end.y < supply.position.y and supply.end.y < boosters.position.y,
			"%s: vertical hierarchy HUD > board+rail > slots > supply > boosters" % tag)
		_ok(pause.size.x >= UiTokens.TOUCH_MIN and pause.size.y >= UiTokens.TOUCH_MIN and speed.size.x >= UiTokens.TOUCH_MIN and speed.size.y >= UiTokens.TOUCH_MIN,
			"%s: Pause/2x >= touch minimum" % tag)
		var fronts_ok := true
		var sp = s.get_supply_panel()
		for c in range(sp.get_column_count()):
			var r: Rect2 = sp.get_column_row_panels(c)[0].get_global_rect()
			fronts_ok = fronts_ok and r.size.x >= UiTokens.TOUCH_MIN and r.size.y >= UiTokens.TOUCH_MIN and _inside(r, safe)
		_ok(fronts_ok, "%s: every supply front is a >= %d px tappable target on screen" % [tag, UiTokens.TOUCH_MIN])
		var views: Array = s.get_five_slot_strip().get_slot_views()
		_ok(views.all(func(v): return v.size.x >= UiTokens.BATCH_SLOT_MIN - 1 and v.size.y >= UiTokens.BATCH_SLOT_MIN - 1), "%s: slots readable (>= %d px)" % [tag, UiTokens.BATCH_SLOT_MIN])
		var rt := _roundtrip(s, bw, bh)
		_ok(rt < EPS, "%s: board coordinate round-trip err %.6f" % [tag, rt])
	await _resize(Vector2i(1080, 2160))
	_complete("responsive_matrix")

func _safe_area_insets() -> void:
	print("[safe-area insets]")
	var s = _screen()
	for spec in [{"size": Vector2i(1170, 2532), "l": 0, "t": 141, "r": 0, "b": 102}, {"size": Vector2i(1080, 2400), "l": 0, "t": 96, "r": 0, "b": 132}]:
		await _resize(spec["size"])
		s.set_synthetic_safe_insets(spec["l"], spec["t"], spec["r"], spec["b"])
		await _settle()
		var inner := Rect2(Vector2(spec["l"], spec["t"]), Vector2(spec["size"].x - spec["l"] - spec["r"], spec["size"].y - spec["t"] - spec["b"]))
		var ess := [s.get_profile_rect(), s.get_pause_rect(), s.get_speed_control_rect(), s.get_board_rect(),
			s.get_five_slot_strip_rect(), s.get_supply_panel_rect(), s.get_booster_row_rect()]
		_ok(ess.all(func(r): return _inside(r, inner)), "%s notch %d / gesture %d: every essential control inside the inner safe rect" % [str(spec["size"]), spec["t"], spec["b"]])
		_ok(s.get_speed_control_rect().position.y >= spec["t"] and s.get_booster_row_rect().end.y <= spec["size"].y - spec["b"], "top controls below the notch, boosters above the gesture bar")
		s.set_synthetic_safe_insets(0, 0, 0, 0)
	await _resize(Vector2i(1080, 2160))
	_complete("safe_area_insets")

## Each connector = [exact runtime route origin, geometry bottom entry] for its slot.
func _connectors_truthful() -> void:
	print("[connectors truthful]")
	var h = _host()
	var s = _screen()
	var segs: Array = s.get_connector_segments()
	var geom = ScrubRailGeometry.new(h.get_board().get_width(), h.get_board().get_height())
	var prov = h.get_origin_provider()
	var ok := segs.size() == 5
	for i in range(segs.size()):
		var o: Vector2 = prov.origin_for_slot(i)
		ok = ok and segs[i][0].is_equal_approx(o) and segs[i][1].is_equal_approx(geom.bottom_entry(o.x))
		ok = ok and absf(segs[i][1].y - geom.bottom_y()) < EPS and o.y > geom.bottom_y() + geom.rail_width() * 0.5
		ok = ok and absf(segs[i][0].x - segs[i][1].x) < EPS
	_ok(ok, "5 connectors = runtime origin_for_slot(i) -> ScrubRailGeometry.bottom_entry (vertical, below the rail)")
	_ok(s.get_rail_view().get_connectors().size() == 5, "all five connectors drawn while every slot is EMPTY")
	var anchor_ok := true
	for i in range(5):
		var g: Vector2 = s.get_five_slot_strip().get_slot_anchor_global(i)
		anchor_ok = anchor_ok and s.global_to_board_local(g).is_equal_approx(segs[i][0])
	_ok(anchor_ok, "connector origin is the visible slot top-centre (spawn anchor)")
	# Same fixture on a rectangular board through a standalone screen.
	var scr = GameplayScreen.new()
	_sub.add_child(scr)
	var lvl = BoardDebugFixtures.make_level(24, 40)
	scr.configure(BoardDebugFixtures.make_board(24, 40), lvl.palette, [], [])
	await _settle()
	_ok(scr.get_connector_segments().size() == 5 and absf(scr.get_board_rect().size.x / scr.get_board_rect().size.y - 0.6) < 0.01, "rectangular 24x40 board: aspect kept, five connectors")
	scr.free()
	_complete("connectors_truthful")

func _sixth_connector_conditional() -> void:
	print("[sixth connector conditional]")
	var h = _host()
	var s = _screen()
	var eco = h.get_economy()
	eco.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	var sb0: int = eco.wallet.scrub_bucks()
	var r: Dictionary = h.request_booster(BoosterInventory.PLUS_ONE_SLOT)
	await _settle()
	var segs: Array = s.get_connector_segments()
	_ok(r.get("ok", false) and s.get_five_slot_strip().get_slot_count() == 6 and segs.size() == 6, "+1 Slot: sixth slot and sixth connector appear")
	_ok(segs[5][0].is_equal_approx(h.get_origin_provider().origin_for_slot(5)), "sixth connector = runtime origin_for_slot(5)")
	_ok(eco.boosters.charges(BoosterInventory.PLUS_ONE_SLOT) == 0 and eco.wallet.scrub_bucks() == sb0, "charge consumed, no SB spent")
	var strip: Rect2 = s.get_five_slot_strip_rect()
	_ok(strip.end.y < s.get_supply_panel_rect().position.y and _inside(strip, s.get_safe_rect())
		and s.get_five_slot_strip().get_slot_views().all(func(v): return v.size.x >= UiTokens.BATCH_SLOT_MIN - 1),
		"six slots readable, no collision with supply, on screen")
	_ok(s.get_booster_state("plus_one_slot")["state"] == "selected", "+1 Slot presented as selected/active this attempt")
	_ok(h.retry(), "retry")
	await _settle()
	_ok(s.get_five_slot_strip().get_slot_count() == 5 and s.get_connector_segments().size() == 5, "fresh attempt: back to five slots / five connectors")
	_complete("sixth_connector_conditional")

func _supply_columns_rows() -> void:
	print("[supply 3/4/5 columns]")
	for cols in [3, 4, 5]:
		var scr = GameplayScreen.new()
		_sub.add_child(scr)
		var lvl = BoardDebugFixtures.make_level(30, 30)
		var sup = BatchSupplyGenerator.generate(lvl, cols, 3, 11)
		scr.configure(BoardDebugFixtures.make_board(30, 30), lvl.palette, [], sup.player_snapshot())
		var sp = scr.get_supply_panel()
		var rows_ok := true
		for c in range(sp.get_column_count()):
			rows_ok = rows_ok and sp.get_column_row_panels(c).size() == 3
		_ok(sp.get_column_count() == cols and rows_ok, "%d-column supply renders %dx3 visible tiles" % [cols, cols])
		scr.free()
	_complete("supply_columns_rows")

func _preview_non_interactive() -> void:
	print("[preview rows non-interactive]")
	var sp = _screen().get_supply_panel()
	var ok: bool = sp.is_front_input_enabled()
	for c in range(sp.get_column_count()):
		var rows: Array = sp.get_column_row_panels(c)
		ok = ok and rows[0].mouse_filter == Control.MOUSE_FILTER_STOP
		for r in [1, 2]:
			ok = ok and rows[r].mouse_filter == Control.MOUSE_FILTER_IGNORE and rows[r].gui_input.get_connections().is_empty()
			ok = ok and rows[r].modulate.r < 0.9   # visibly distinct (dimmed)
	_ok(ok, "only fronts receive input; preview rows IGNORE, unconnected and visibly dimmed")
	# A synthetic press/release on a preview panel never activates anything.
	var h = _host()
	var before: Array = h.get_slots().snapshot()
	var prev = sp.get_column_row_panels(0)[1]
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		prev.gui_input.emit(e)
	_ok(h.get_slots().snapshot() == before, "preview-row press/release: no placement")
	_complete("preview_non_interactive")

func _front_click_mapping() -> void:
	print("[front click mapping]")
	var h = _host()
	var sp = _screen().get_supply_panel()
	var col := -1
	for c in range(sp.get_column_count()):
		if sp.get_front_enabled(c):
			col = c
			break
	var got := [-1]
	var cb := func(c): got[0] = c
	sp.front_batch_activated.connect(cb)
	var front = sp.get_column_row_panels(col)[0]
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		front.gui_input.emit(e)
	sp.front_batch_activated.disconnect(cb)
	var occ: int = h.get_slots().snapshot().filter(func(s): return bool(s.get("occupied", false))).size()
	_ok(got[0] == col and occ >= 1, "front press/release on column %d -> front_batch_activated(%d) -> real placement" % [col, col])
	_complete("front_click_mapping")

func _four_boosters_live() -> void:
	print("[four boosters live data]")
	await _boot(2)
	var h = _host()
	var s = _screen()
	var eco = h.get_economy()
	var cfg = eco.config
	eco.boosters.add_charges(BoosterInventory.RANDOM, 3)
	eco.wallet.credit("scrub_bucks", 0)
	h._refresh_hud()
	var ok := true
	for id in BoosterInventory.BOOSTERS:
		var st: Dictionary = s.get_booster_state(id)
		ok = ok and st["charges"] == eco.boosters.charges(id) and st["price"] == cfg.booster_price(id)
		var b: Button = s.get_booster_button(id)
		ok = ok and b.get_node("Badge").visible == (st["charges"] > 0) and b.get_node("Price").visible == (st["charges"] == 0)
		if st["charges"] == 0:
			ok = ok and b.get_node("Price").text == "%d SB" % cfg.booster_price(id)
	_ok(ok, "badge = live charges, price = canonical EconomyConfig price when no charge")
	_ok(s.get_booster_state("random")["state"] == "available" and s.get_booster_button("random").get_node("Badge").text == "3", "Random: 3 owned charges shown")
	eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())
	h._refresh_hud()
	_ok(s.get_booster_state("tornado")["state"] == "unavailable" and s.get_booster_button("tornado").get_node("UnavailableOverlay").visible, "0 charges + 0 SB -> unavailable overlay")
	eco.wallet.credit("scrub_bucks", 5000)
	h._refresh_hud()
	_ok(s.get_booster_state("tornado")["state"] == "purchasable", "0 charges + enough SB -> purchasable (price shown)")
	_ok(BoosterInventory.BOOSTERS.all(func(id): return s.get_booster_state(id)["state"] != "locked"), "no booster falsely locked (no unlock authority exists)")
	_complete("four_boosters_live")

func _booster_requests_no_silent_spend() -> void:
	print("[booster requests: no silent spend]")
	var h = _host()
	var eco = h.get_economy()
	var s = _screen()
	var asked := []
	h.booster_acquire_requested.connect(func(id): asked.append(id))
	var sb0: int = eco.wallet.scrub_bucks()
	var e0: Dictionary = eco.boosters.snapshot()
	s.get_booster_button("tornado").pressed.emit()
	_ok(h.last_booster_request.get("reason") == "acquire_required" and asked == ["tornado"] and eco.wallet.scrub_bucks() == sb0 and eco.boosters.snapshot() == e0,
		"no charge: acquire seam emitted, NO SB spent, nothing consumed")
	eco.boosters.add_charges(BoosterInventory.SELECTOR, 1)
	s.get_booster_button("selector").pressed.emit()
	_ok(h.last_booster_request.get("reason") == "target_selection_required" and eco.boosters.charges(BoosterInventory.SELECTOR) == 1 and eco.wallet.scrub_bucks() == sb0,
		"Selector with charge: target UI deferred, charge NOT consumed")
	s.get_booster_button("random").pressed.emit()
	var rr: Dictionary = h.last_booster_request
	_ok(eco.wallet.scrub_bucks() == sb0 and (rr.get("ok", false) == (eco.boosters.charges(BoosterInventory.RANDOM) == 2)),
		"Random with charge: canonical facade, charge-first (ok=%s reason=%s, charges now %d; a refused effect refunds the charge), SB untouched" % [str(rr.get("ok")), str(rr.get("reason", "")), eco.boosters.charges(BoosterInventory.RANDOM)])
	_complete("booster_requests_no_silent_spend")

## Timed 2x: live wall-clock label; frozen on clock rollback (M55-C002 high-water).
func _timed_2x_wallclock() -> void:
	print("[timed 2x wall clock]")
	var h = _host()
	var s = _screen()
	var eco = h.get_economy()
	eco.wallet.credit("scrub_bucks", 1000)
	s.get_speed_button().pressed.emit()
	h.get_speed_acquisition_popup().get_offer_button("timed_900").pressed.emit()
	_ok(s.get_speed_mode() == "timed" and s.get_speed_label() == "15:00" and h.get_speed_authority().is_2x(), "timed 900 purchase -> 2x on, label 15:00")
	_now[0] += 62
	var old_scale := Engine.time_scale
	Engine.time_scale = 4.0
	for _i in range(3):
		await process_frame
	h._refresh_hud()
	_ok(s.get_speed_label() == "13:58" and s.get_speed_label() == GameplayScreen.format_remaining(eco.speed.timed_seconds_remaining()), "+62 s wall clock -> 13:58 (independent of time_scale)")
	Engine.time_scale = old_scale
	_now[0] -= 600
	h._refresh_hud()
	_ok(s.get_speed_label() == "13:58", "clock rolled back 600 s -> label frozen at 13:58 (anti-rollback preserved)")
	_now[0] += 600
	s.get_speed_button().pressed.emit()
	_ok(not h.get_speed_authority().is_2x() and s.get_speed_mode() == "timed" and s.get_speed_state() == "1x", "toggle off: 1x, countdown still shown (entitlement keeps running)")
	s.get_speed_button().pressed.emit()
	_ok(h.get_speed_authority().is_2x() and (h.get_speed_acquisition_popup() == null or not h.get_speed_acquisition_popup().visible), "entitled: toggle back to 2x without purchase UI")
	_now[0] += 2000
	h._refresh_hud()
	_ok(s.get_speed_label() == "2x" and s.get_speed_mode() != "timed", "after expiry: label back to 2x")
	_complete("timed_2x_wallclock")

func _speed_modes() -> void:
	print("[speed modes]")
	await _boot(2)
	var h = _host()
	var s = _screen()
	var eco = h.get_economy()
	_ok(s.get_speed_mode() == "off" and s.get_speed_label() == "2x" and s.get_speed_state() == "1x", "inactive/unentitled: label 2x, state 1x")
	eco.wallet.credit("scrub_bucks", 500)
	s.get_speed_button().pressed.emit()
	h.get_speed_acquisition_popup().get_offer_button("level").pressed.emit()
	_ok(s.get_speed_mode() == "level" and s.get_speed_state() == "2x", "current-level entitlement: selected 2x")
	s.get_speed_button().pressed.emit()
	await _boot(3)
	h = _host()
	s = _screen()
	# Free M23-exhausted automatic 2x (runtime path, no entitlement).
	h.get_runtime().set_speed_2x(true)
	s.set_speed_2x(true)
	h._refresh_hud()
	var sb0: int = h.get_economy().wallet.scrub_bucks()
	_ok(s.get_speed_mode() == "auto" and s.get_speed_button().modulate != Color(1, 1, 1), "free automatic 2x: distinct 'auto' presentation")
	s.get_speed_button().pressed.emit()
	_ok((h.get_speed_acquisition_popup() == null or not h.get_speed_acquisition_popup().visible) and h.get_economy().wallet.scrub_bucks() == sb0, "tapping during free auto-2x never opens purchase UI / spends")
	_complete("speed_modes")

func _pause_top_right() -> void:
	print("[pause top-right]")
	var h = _host()
	var s = _screen()
	var p: Rect2 = s.get_pause_rect()
	var sp: Rect2 = s.get_speed_control_rect()
	_ok(p.end.x <= sp.position.x and sp.end.x >= s.get_safe_rect().end.x - 1.0 and p.position.y < s.get_board_rect().position.y, "PAUSE | 2x side by side at top-right")
	s.get_pause_button().pressed.emit()
	_ok(h.get_runtime().is_user_paused() and s.is_paused_visual(), "Pause keeps the existing runtime pause behaviour")
	s.get_pause_button().pressed.emit()
	_ok(not h.get_runtime().is_user_paused() and not s.is_paused_visual(), "second press resumes")
	_complete("pause_top_right")

func _retry_no_accumulation() -> void:
	print("[retry / rebuild no accumulation]")
	var h = _host()
	var s = _screen()
	await _settle()
	var n0 := _count(s)
	var c0: int = s.booster_pressed.get_connections().size()
	var p0: int = s.get_pause_button().pressed.get_connections().size()
	for _i in range(5):
		h.retry()
		await _settle()
	_ok(_count(s) == n0, "screen node count stable over 5 retries (%d -> %d)" % [n0, _count(s)])
	_ok(s.booster_pressed.get_connections().size() == c0 and s.get_pause_button().pressed.get_connections().size() == p0
		and h.find_children("HudTimer", "Timer", false, false).size() == 1, "no signal / timer accumulation")
	_complete("retry_no_accumulation")

# ------------------------------------------------------------------ helpers ----

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 1.0 and inner.position.y >= outer.position.y - 1.0 \
		and inner.end.x <= outer.end.x + 1.0 and inner.end.y <= outer.end.y + 1.0

func _roundtrip(s, w: int, h: int) -> float:
	var err := 0.0
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1), Vector2i(w / 2, h / 2)]:
		var g: Vector2 = s.cell_center_to_global(p.x, p.y)
		var back: Vector2 = s.global_to_board_local(g)
		err = maxf(err, back.distance_to(Vector2(p.x + 0.5, p.y + 0.5)))
	return err

func _cleanup() -> void:
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
	print("M28-C002-C001 Gameplay V02 core evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
