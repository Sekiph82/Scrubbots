extends SceneTree
## SB-TF-13 (owner TestFlight build 26 feedback, 2026-11-19), real app root / real screens on temp saves:
##   t01 Home activity buttons +40% (206x153, 0.98x the V06 panel), labels fitted, 4 + 4 columns clear
##       of the profile card, gift bar, area title text, Scrubby's head, journey strip, PLAY and banner;
##   t02 event details: the board card shows the WHOLE level artwork (every pixel ACTIVE / opaque),
##       centred, square cells, nearest filter;
##   t03 event details + tutorial above the banner (iPhone 1179x2556 logical 1080x2341, notch 170 /
##       home bar 93): the JOIN / WATCH AD area, every step's Continue button and n / N pill end above
##       the banner reservation; exactly one visible X while the tutorial is open, the details X is
##       back after it closes;
##   t04 board floor #4A3258: CIE76 Lab distance >= 20 from every C01..C16 and from BG01;
##   t05 gameplay fills the width on tall phones (shell width == viewport width), the top bar ..
##       booster band inside the safe rect above the banner, a cover backdrop behind any side gap,
##       bigger display cell than the old whole-shell fit;
##   t06 Rewarded Ads: after a verified video the next slot is offered in place once the provider has
##       loaded the next video (AdPoll), without leaving the screen; nothing offered while loading;
##   t07 Home bow video = the re-keyed owner clip (manifest pin), the other four keyed videos unchanged.
##
## Run: godot --headless --path . -s res://tests/sb_tf13_feedback.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const HomeScreen = preload("res://scripts/ui/home/home_screen.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
const EventTutorial = preload("res://scripts/ui/events/event_tutorial.gd")
const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## iPhone 1179x2556 under the 1080x2160 canvas_items / expand stretch, and its insets in that space.
const IPHONE := Vector2i(1080, 2341)
const IPHONE_TOP := 170
const IPHONE_BOTTOM := 93
const KEYED_UNCHANGED := {
	"wave": "ee968d6ecc14aaee8ece0f44168decc223f2d48ef461576c47963c57c3ab7957",
	"turn": "7e0d46561b83003587340806e328236c9f39862adce71dee8fd0f18c233bae21",
	"full_turn": "9c00b52953bda8ebdf4baa2906088d1645f4878738497f9cb246dea7a82a84e9",
	"sweep": "92619140b674e2d73ee4ae18e4e219a5b437c53946ef814889396f2125fe37dd",
}

class FakeEvents extends "res://scripts/economy/events_v02_service.gd":
	var views: Array = []
	func list() -> Array:
		return views.duplicate(true)

## Rewarded double: `ready` is the provider's loaded state; a shown video consumes it (like AdMob,
## which only starts loading the next one when the video closes).
class LoadingProvider extends AdProvider:
	var ready := true
	var _deliver: Callable
	var _token := ""
	func is_available(_placement: String) -> bool:
		return ready
	func request(_placement: String, token: String, deliver: Callable) -> bool:
		if not ready:
			return false
		ready = false
		_token = token
		_deliver = deliver
		return true
	func finish() -> void:
		_deliver.call(_token, {"outcome": "completed", "verified": true})

var EXPECTED_CASES := ["t01_home_buttons", "t02_event_art_whole", "t03_events_above_banner", "t04_floor_lab",
	"t05_gameplay_fill", "t06_rewarded_reoffer", "t07_bow_video"]

var _fail := 0
var _completed := {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [0]
var _epoch := 0

func _initialize() -> void:
	AppStateScript.test_unlock_all = true
	await process_frame
	_epoch = int(JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))["schedule"]["epoch_utc"])
	_now[0] = _epoch + 3600
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_opening_override = 0
	await _t01()
	await _t02_t03()
	_t04()
	await _t05()
	await _t06()
	_t07()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _t01() -> void:
	print("[t01 Home activity buttons +40%, clear of the HUD / title / Scrubby head / PLAY]")
	for vp in [IPHONE, Vector2i(1080, 1920)]:
		await _boot("t01", vp)
		var h = _root.get_home()
		var fake := FakeEvents.new(func(): return _now[0])
		_root.get_app_state().economy.events_v02 = fake
		for i in range(6):
			fake.views.append({"iid": "ev_%d:1" % i, "id": "ev_%d" % i, "phase": "active", "claimable": 0,
				"steps": [{"rid": "m0", "claimed": false}]})
		h.refresh()
		await _frames(3)
		var lay: Dictionary = h.get_activity_layout()
		var names: Array = lay["LeftShortcutColumn"] + lay["RightShortcutColumn"]
		_ok(names.size() == 8, "%s: 4 + 4 buttons shown %s" % [str(vp), str(lay)])
		var size_ok := true
		var label_ok := true
		var clash: Array = []
		var avoid := {"profile card": _rect(h, "ProfileCard"), "gift bar": _rect(h, "GiftMeter"), "area title": _text_rect(h.get_region("HomeAreaTitle")),
			"Scrubby head": _head(h), "journey strip": _rect(h, "HomeJourneyStrip"), "PLAY": _rect(h, "PlayButton"), "banner": _rect(h, "AdBannerSlot")}
		for n in names:
			var b: Button = h.get_region(n)
			var r: Rect2 = b.get_global_rect()
			size_ok = size_ok and absf(r.size.x - 206.0) <= 1.0 and absf(r.size.y - 153.0) <= 1.0
			var avail: float = r.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
			label_ok = label_ok and b.get_theme_font_size("font_size") >= 14 and b.get_theme_font("font").get_multiline_string_size(b.text, HORIZONTAL_ALIGNMENT_CENTER, avail, b.get_theme_font_size("font_size")).x <= avail + 0.5
			for k in avoid:
				if (avoid[k] as Rect2).has_area() and r.grow(-0.5).intersects(avoid[k]):
					clash.append("%s/%s" % [n, k])
		_ok(HomeScreen.PANEL_SIZE == (Vector2(210, 156) * HomeScreen.PANEL_SCALE).round() and is_equal_approx(HomeScreen.PANEL_SCALE, 0.7 * 1.4) and HomeScreen.PANEL_FONT == 28,
			"constants: 0.98x the V06 210x156 panel (= 0.7x + 40%), 28 px label font")
		_ok(size_ok, "%s: every button 206x153 +-1 (was 147x109)" % str(vp))
		_ok(label_ok, "%s: every label >= 14 px and inside its panel" % str(vp))
		_ok(clash.is_empty(), "%s: no button over the profile card, gift bar, area title, Scrubby's head, journey strip, PLAY or banner %s" % [str(vp), str(clash)])
	_complete("t01_home_buttons")

func _t02_t03() -> void:
	print("[t02 / t03 event details: whole artwork; JOIN, tutorial Continue + pill above the banner; one X]")
	await _boot("t03", IPHONE)
	var app = _root.get_app_state()
	var ev = app.economy.events_v02
	for id in ev.event_ids():
		ev.mark_tutorial_seen(id)
	var st = _root.get_modal_stack()
	var x: Dictionary = ev.scheduled(_now[0], _now[0] + 1)[0]
	var d = EventsV02Ui.open_details(st, app, x["iid"])
	d.set_synthetic_insets(0, IPHONE_TOP, 0, IPHONE_BOTTOM)
	await _frames(3)
	# t02: the real level, all ACTIVE, centred square cells, nearest filter.
	var board: TextureRect = d.find_child("Board", true, false)
	var back: Control = d.find_child("BoardBack", true, false)
	var img: Image = board.texture.get_image()
	var opaque := true
	for y in range(img.get_height()):
		for xx in range(img.get_width()):
			opaque = opaque and img.get_pixel(xx, y).a >= 0.999
	var br := board.get_global_rect()
	var bk := back.get_global_rect()
	_ok(opaque and img.get_width() > 0, "every %dx%d artwork pixel ACTIVE (no CLEARED / BG01 rows)" % [img.get_width(), img.get_height()])
	_ok(absf(br.get_center().x - bk.get_center().x) <= 1.0 and absf(br.get_center().y - bk.get_center().y) <= 1.0 and absf(br.size.x / br.size.y - float(img.get_width()) / img.get_height()) < 0.01
		and board.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "artwork centred in its card, aspect kept, nearest filter (%s in %s)" % [str(br), str(bk)])
	_complete("t02_event_art_whole")
	# t03: everything the player taps ends above the banner reservation.
	var vp := Vector2(IPHONE)
	var banner_top: float = vp.y - IPHONE_BOTTOM - HomeStyle.ad_slot_height(vp.x)
	var start: Control = d.find_child("StartArea", true, false)
	var join: Button = d.get_action_button("join")
	var scroll: ScrollContainer = d.find_child("DetailScroll", true, false)
	_ok(start.get_global_rect().end.y <= banner_top and join.is_visible_in_tree() and join.get_global_rect().end.y <= banner_top
		and scroll.get_global_rect().end.y <= banner_top and not scroll.is_ancestor_of(start),
		"JOIN area pinned under the scroll, ends %.0f <= banner top %.0f (scroll ends %.0f)" % [start.get_global_rect().end.y, banner_top, scroll.get_global_rect().end.y])
	var t = EventTutorial.open(st, app, x["iid"])
	t.set_synthetic_insets(0, IPHONE_TOP, 0, IPHONE_BOTTOM)
	var n: int = EventTutorial.steps(String(x["id"])).size()
	var bad: Array = []
	var xs_bad: Array = []
	for i in range(n):
		EventTutorial.show_step(t, app, i + 1)
		await _frames(3)
		var nb: Rect2 = t.get_action_button("tut_next").get_global_rect()
		var pill: Rect2 = (t.find_child("StepPill", true, false) as Control).get_global_rect()
		if nb.end.y > banner_top or pill.end.y > banner_top or not t.get_action_button("tut_next").is_visible_in_tree():
			bad.append("step %d next %.0f pill %.0f" % [i + 1, nb.end.y, pill.end.y])
		var xs := _visible_x()
		if xs.size() != 1 or xs[0] != t.get_action_button("tut_close"):
			xs_bad.append("step %d: %d X" % [i + 1, xs.size()])
	_ok(bad.is_empty(), "%d steps: Continue + n / N pill end above the banner top %.0f %s" % [n, banner_top, str(bad)])
	_ok(xs_bad.is_empty(), "%d steps: exactly one visible X (the tutorial's) %s" % [n, str(xs_bad)])
	var skip: Rect2 = t.get_action_button("tut_close").get_global_rect()
	var bar: Rect2 = (d.find_child("TopBar", true, false) as Control).get_global_rect()
	_ok(absf(skip.end.x - bar.end.x) <= 1.0 and absf(skip.position.y - bar.position.y) <= 1.0, "the tutorial X stands where the details X was (%s, bar %s)" % [str(skip), str(bar)])
	t.rearm()
	t._on_action("tut_close")
	await _frames(2)
	_ok(st.ids() == ["event_details"] and _visible_x().size() == 1 and _visible_x()[0] == d.get_action_button("close"), "after X: the details X is back, still one X")
	_complete("t03_events_above_banner")

func _t04() -> void:
	print("[t04 board floor: Lab distance >= 20 from C01..C16 and BG01]")
	var floor_c: Color = BoardPresentation.BOARD_FLOOR
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	var worst := INF
	var worst_id := ""
	var cols: Array = pal["colors"].duplicate()
	cols.append({"id": "BG01", "rgb": [32, 37, 51]})
	for c in cols:
		var rgb: Array = c["rgb"]
		var dist := _lab_dist(floor_c, Color8(int(rgb[0]), int(rgb[1]), int(rgb[2])))
		if dist < worst:
			worst = dist
			worst_id = String(c["id"])
	_ok(floor_c == Color8(74, 50, 88), "BOARD_FLOOR == #4A3258 (owner dark purple-grey)")
	_ok(pal["colors"].size() == 16 and worst >= 20.0, "nearest of 16 palette colours + BG01: %s at Lab distance %.1f (>= 20)" % [worst_id, worst])
	var near_old := _lab_dist(Color8(0, 104, 216), Color8(36, 80, 164))
	_ok(_lab_dist(floor_c, Color8(36, 80, 164)) > near_old and _lab_dist(floor_c, Color8(54, 144, 234)) >= 20.0,
		"C08 / C07 now stand off the floor (C08 %.1f vs %.1f on the old #0068D8)" % [_lab_dist(floor_c, Color8(36, 80, 164)), near_old])
	_complete("t04_floor_lab")

func _t05() -> void:
	print("[t05 gameplay: full width on tall phones, top bar .. boosters in the safe rect above the banner]")
	var cases := [[IPHONE, IPHONE_TOP, IPHONE_BOTTOM], [Vector2i(1080, 2400), 0, 0], [Vector2i(1170, 2532), 0, 0], [Vector2i(1290, 2796), 0, 0],
		[Vector2i(1440, 3200), 0, 0], [Vector2i(1080, 2160), 0, 0], [Vector2i(1080, 1920), 0, 0], [Vector2i(720, 1280), 0, 0], [Vector2i(1536, 2048), 0, 0]]
	for c in cases:
		var vp: Vector2i = c[0]
		var sub := SubViewport.new()
		sub.size = vp
		sub.disable_3d = true
		get_root().add_child(sub)
		var lvl = BoardDebugFixtures.make_level(32, 32)
		var scr = GameplayScreen.new()
		scr.set_anchors_preset(Control.PRESET_FULL_RECT)
		sub.add_child(scr)
		scr.configure(BoardDebugFixtures.make_board(32, 32), lvl.palette, [], BatchSupplyGenerator.generate(lvl, 4, 3, 5).player_snapshot())
		scr.set_synthetic_safe_insets(0, c[1], 0, c[2])
		for _i in range(3):
			await process_frame
		var label := "%dx%d (insets %d/%d)" % [vp.x, vp.y, c[1], c[2]]
		var shell: Rect2 = scr.get_shell_node_rect()
		var safe: Rect2 = scr.get_safe_rect()
		var tall: bool = float(safe.size.y - HomeStyle.ad_slot_height(vp.x) - 24.0) >= (Shell.BOOSTERS[3] - GameplayScreen.CRIT_TOP) * vp.x / Shell.SIZE.x
		var banner_top: float = safe.end.y - HomeStyle.ad_slot_height(vp.x)
		var row: Rect2 = scr.get_booster_row_rect()
		var top_ok: bool = scr.get_pause_rect().position.y >= safe.position.y - 1.0 and _rect_of(scr.find_child("ProfileChip", true, false)).position.y >= safe.position.y - 1.0   # origin floored to whole px
		if tall:
			_ok(absf(shell.size.x - vp.x) < 1.0 and absf(shell.position.x) < 1.0, "%s: shell width %.1f == viewport width (no side bars)" % [label, shell.size.x])
		else:
			_ok(shell.size.x < vp.x and absf(shell.get_center().x - vp.x / 2.0) <= 1.0, "%s: short screen, shell %.1f wide centred (backdrop fills the sides)" % [label, shell.size.x])
		# Shell + visible edge stretches (the master's own outer columns / rows) tile the whole screen.
		var bd: Control = scr.find_child("GameplayBackdrop", true, false)
		var tex: Texture2D = scr.find_child("GameplayShell", true, false).texture
		var area := shell.intersection(Rect2(Vector2.ZERO, Vector2(vp))).get_area()
		var edges_ok: bool = bd != null and bd.get_index() < scr.get_node("SafeAreaRoot").get_index()
		for e in bd.get_children():
			edges_ok = edges_ok and (e.texture as AtlasTexture).atlas == tex
			if e.visible:
				area += (e as Control).get_global_rect().get_area()
				edges_ok = edges_ok and not (e as Control).get_global_rect().grow(-0.5).intersects(shell)
		_ok(edges_ok and absf(area - float(vp.x * vp.y)) < vp.x + vp.y, "%s: shell + edge stretches of the same master cover the screen exactly (no FILL bars)" % label)
		_ok(top_ok and row.end.y + 2.0 <= banner_top and row.end.y <= scr.get_ad_region_rect().position.y, "%s: top bar inside the safe top, boosters end %.0f above the banner top %.0f" % [label, row.end.y, banner_top])
		if c[1] > 0:
			var old_scale := minf(safe.size.x / Shell.SIZE.x, safe.size.y / Shell.SIZE.y)
			_ok(scr.get_shell_scale() > old_scale * 1.1, "%s: shell scale %.3f vs the old whole-shell fit %.3f (art %.0f%% bigger)" % [label, scr.get_shell_scale(), old_scale, (scr.get_shell_scale() / old_scale - 1.0) * 100.0])
		scr.free()
		sub.free()
	_complete("t05_gameplay_fill")

func _t06() -> void:
	print("[t06 Rewarded Ads: next video offered in place once loaded]")
	await _boot("t06", Vector2i(1080, 2160))
	var app = _root.get_app_state()
	var prov := LoadingProvider.new()
	app.economy.ads.set_provider(prov)
	var st = _root.get_modal_stack()
	st.clear("test")
	var p = RewardedAdsScreen.open(st, app)
	await _frames(2)
	p.rearm()
	p._on_action("slot:1")
	await create_timer(0.5).timeout
	var poll: Timer = p.get_node("AdPoll")
	_ok(poll != null and is_equal_approx(poll.wait_time, RewardedAdsScreen.AD_POLL_S) and not poll.is_stopped(), "AdPoll runs every %.1f s while the screen is open" % RewardedAdsScreen.AD_POLL_S)
	_ok(_slot(p, 2) == "ready_ad", "slot 2 offers WATCH AD (%s)" % _slot(p, 2))
	p.rearm()
	p._on_action("slot:2")
	await _frames(2)
	prov.finish()   # verified; the provider has started loading the next video (ready false)
	await _frames(2)
	_ok(app.economy.rewarded_daily.is_claimed(2) and _slot(p, 3) == "ad_unavailable", "slot 2 granted; slot 3 NO VIDEO while the next video loads (%s)" % _slot(p, 3))
	prov.ready = true   # the next video finished loading
	poll.timeout.emit()
	await _frames(1)
	var b: Button = p.get_action_button("slot:3")
	_ok(st.top() == p and _slot(p, 3) == "ready_ad" and b.text == UiText.t("RADS_WATCH") and not b.disabled,
		"same screen, no Home round-trip: slot 3 now WATCH AD and tappable (%s)" % _slot(p, 3))
	p._on_action("slot:3")
	await _frames(2)
	prov.finish()
	await _frames(2)
	_ok(app.economy.rewarded_daily.is_claimed(3), "slot 3 granted from the same screen")
	_complete("t06_rewarded_reoffer")

func _t07() -> void:
	print("[t07 Home bow video re-keyed from the owner clip; the other keyed videos unchanged]")
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/HOME_ASSET_MANIFEST.json"))["video_sets"]["home_scrubby_videos_keyed_v2"]
	var v: Dictionary = m["videos"]
	var bow: Dictionary = v["bow"]
	_ok(FileAccess.get_sha256("res://" + String(bow["path"])) == String(bow["sha256"]) and String(bow["sha256"]).begins_with("35ceb28b"), "bow pinned to the SB-TF-13 re-key %s" % String(bow["sha256"]).substr(0, 8))
	_ok(String(m["provenance"]).contains("Robot_Scrubby_bowing_c77edbed.mp4"), "provenance names the owner clip")
	var same := true
	for k in KEYED_UNCHANGED:
		same = same and String(v[k]["sha256"]) == KEYED_UNCHANGED[k] and FileAccess.get_sha256("res://" + String(v[k]["path"])) == KEYED_UNCHANGED[k]
	_ok(same, "wave, turn, full_turn, sweep byte-identical (owner confirmed)")
	_complete("t07_bow_video")

# ---------------------------------------------------------------- helpers ----

func _slot(p, n: int) -> String:
	return String(p.find_child("Slot_%d" % n, true, false).get_meta("state"))

## Every visible Button labelled "X" on the modal stack.
func _visible_x() -> Array:
	return _root.find_children("*", "Button", true, false).filter(func(b): return b.text == "X" and b.is_visible_in_tree())

func _rect(h, n: String) -> Rect2:
	var c = h.get_region(n)
	return (c as Control).get_global_rect() if c is Control and (c as Control).is_visible_in_tree() else Rect2()

func _rect_of(c) -> Rect2:
	return (c as Control).get_global_rect() if c is Control else Rect2()

## The drawn text of a centred Label (its rect spans the whole row).
func _text_rect(l: Label) -> Rect2:
	if l == null or l.text.is_empty():
		return Rect2()
	var r := l.get_global_rect()
	var w: float = l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	return Rect2(r.get_center().x - w / 2.0, r.position.y, w, r.size.y)

## Scrubby's head: the top 40% of his visible rect, middle 60% of its width (the waving hand is not the face).
func _head(h) -> Rect2:
	var v: Rect2 = h.get_scrubby_canonical()["visible_rect"]
	return Rect2(h.global_position + v.position + Vector2(v.size.x * 0.2, 0), Vector2(v.size.x * 0.6, v.size.y * 0.4))

func _lab(c: Color) -> Vector3:
	var lin := func(u: float) -> float: return u / 12.92 if u <= 0.04045 else pow((u + 0.055) / 1.055, 2.4)
	var r: float = lin.call(c.r)
	var g: float = lin.call(c.g)
	var b: float = lin.call(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	return Vector3(116.0 * f.call(y) - 16.0, 500.0 * (f.call(x) - f.call(y)), 200.0 * (f.call(y) - f.call(z)))

func _lab_dist(a: Color, b: Color) -> float:
	return _lab(a).distance_to(_lab(b))

func _boot(tag: String, size: Vector2i) -> void:
	_shutdown()
	var path := "user://sb_tf13_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")
	await _frames(2)

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

func _complete(id: String) -> void:
	_completed[id] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-TF-13 feedback evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
