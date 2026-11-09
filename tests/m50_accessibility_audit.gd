extends SceneTree
## M50 Accessibility (SB-M50-001/003/004/005/006/007/009/010/011, evidence) — measurements with the
## developer tool res://tools/accessibility_audit.gd against REAL production constants, the
## production level catalog and the real gameplay screen. Thresholds that are product
## decisions (colour-blind assist) are REPORTED, not invented as pass/fail rules.
##   a05 (SB-M50-010) icon families at 48 px: every same-family pair differs in silhouette or hue
##   a06 (SB-M50-007) readable font floor FONT_FLOOR: tokens above it; fit_font's long-locale shrink
##       below it is REPORTED (owner / localization decision)
##   a07 (SB-M50-005) Reduced Effects: the Settings toggle reaches every live consumer, and every
##       effect path has its REDUCED-arm suite (ledger)
##   a08 (SB-M50-011) a real level with Reduced Effects ON, the feel plugins absent and colour
##       symbols OFF: board / slots / supply / Scrubbots render and the level is WON
## Rendered text contrast on every M43/M44 surface: tests/m50_contrast_surfaces.gd (windowed).
## Touch sizes (SB-M50-006): tests/m49_touch_targets_text_stress.gd t01 + m49_surface_matrix v02.
##
## Run: godot --headless --path . -s res://tests/m50_accessibility_audit.gd

const A = preload("res://tools/accessibility_audit.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ColorSymbols = preload("res://scripts/ui/color_symbols.gd")
const LevelIntroOverlay = preload("res://scripts/ui/level_intro_overlay.gd")

## Smallest readable text on the 1080-wide design canvas: 18 design px = ~6.9 dp on a 411 dp wide
## phone, the smallest size the shipped English UI uses (tests/m50_contrast_surfaces.gd c02).
const FONT_FLOOR := 18
const ICON_PX := 48
## Same-family icons are distinguishable at 48 px when their opaque silhouettes differ by >= 15%
## (1 - IoU) OR their mean colours differ by CIEDE2000 >= 10 under normal vision AND every
## simulated CVD (protan / deutan / tritan).
const SILHOUETTE_MIN := 0.15
const HUE_DE00_MIN := 10.0
const ICON_FAMILIES := {
	"currencies": ["common/currencies/icon_currency_scrub_bucks.png", "common/currencies/icon_currency_heart.png", "robots/bot_parts_icon.png"],
	"boosters": ["boosters/extra_slot.png", "boosters/random.png", "boosters/selector.png", "boosters/tornado.png"],
	"nav": ["common/navigation/icon_nav_events.png", "common/navigation/icon_nav_robots.png", "common/navigation/icon_nav_home.png",
		"common/navigation/icon_nav_leaderboard.png", "common/navigation/icon_nav_settings.png"],
	## The ceremony / reward-row icons shown side by side (MetaCeremonies.REWARD_ROWS).
	"reward_rows": ["common/currencies/icon_currency_scrub_bucks.png", "robots/bot_parts_icon.png", "rewards/card_pack_standard.png",
		"rewards/card_pack_premium.png", "rewards/gift_box.png", "rewards/booster_of_choice.png", "collection/states/card_back.png",
		"common/currencies/icon_currency_heart.png"],
	"shortcuts": ["home/shortcuts/icon_shortcut_cards_exchange.png", "home/shortcuts/icon_shortcut_collection.png", "home/shortcuts/icon_shortcut_daily.png",
		"home/shortcuts/icon_shortcut_gift_bar.png", "home/shortcuts/icon_shortcut_no_ads.png", "home/shortcuts/icon_shortcut_rewarded_ads.png",
		"home/shortcuts/icon_shortcut_shop.png", "home/shortcuts/icon_shortcut_tasks.png", "home/shortcuts/icon_shortcut_win_streak.png"],
}
## Reduced Effects consumer -> the suite whose REDUCED arm proves its calm path.
const REDUCED_LEDGER := {
	"scripts/gameplay/presentation/cleaning_effects_controller.gd": "m31_cleaning_effects_evidence",
	"scripts/ui/gameplay_screen.gd": "sb_polish_003_booster_vfx",
	"scripts/ui/feel/booster_vfx.gd": "sb_polish_003_booster_vfx",
	"scripts/ui/five_slot_strip.gd": "sb_m22_008_polish_013_slot_fx",
	"scripts/ui/batch_slot_view.gd": "sb_m22_008_polish_013_slot_fx",
	"scripts/ui/feel/feedback_adapter.gd": "m43_c005f_015_e2e_feel",
	"scripts/ui/feel/meta_reward_feel.gd": "m43_c005f_phase3_meta_rewards_acquisition",
	"scripts/ui/feel/home_micro_feel.gd": "m43_c005f_phase4_terminal_home_micro",
	"scripts/ui/feel/meta_feedback.gd": "m43_master_c011_c014",
	"scripts/ui/feel/character_motion.gd": "sb_polish_011_character_motion",
	"scripts/ui/results_screen.gd": "m43_c005f_phase2_results_pack_feel",
	"scripts/ui/components/reveal_sequencer.gd": "m43_c005_c005_reward_reveal_sequencer",
	"scripts/ui/ceremony/meta_ceremonies.gd": "m43_master_c005_meta_ceremonies",
	"scripts/ui/ceremony/ceremony_presenter.gd": "m43_master_c005_meta_ceremonies",
	"scripts/ui/ceremony/standard_pack_ceremony.gd": "m43_c005_c006_standard_pack_presentation",
	"scripts/ui/ceremony/premium_pack_ceremony.gd": "m43_c005_c007_premium_pack_presentation",
	"scripts/ui/ceremony/pack_presenter.gd": "m43_c005f_phase2_r01_earned_pack_runtime",
	"scripts/ui/home/home_scrubby_hero.gd": "m42_c003_scrubby_animation",
	"scripts/ui/home/home_screen.gd": "m43_master_c005r_gift_micro_progress",
	"scripts/ui/components/gift_tick_overlay.gd": "m43_master_c005r_gift_micro_progress",
	"scripts/ui/tutorial/coachmark_layer.gd": "m44_ftue",
	"scripts/ui/level_intro_overlay.gd": "sb_video_005_level_intro",
	"scripts/ui/popup/acquisition_flow.gd": "sb_video_009_polish_011b_region_need_a_hand_video",
	"scripts/ui/profile/profile_screens.gd": "sb_video_007_008_set_complete_welcome_video",
	"scripts/ui/daily/daily_screens.gd": "m43_c005f_phase3_meta_rewards_acquisition",
}

const WCAG_AA := 4.5

var EXPECTED_CASES := ["a01_math_reference_values", "a02_ui_text_contrast", "a03_level_cvd_report", "a04_non_colour_cues_live",
	"a05_icon_families_48px", "a06_font_floor", "a07_reduced_effects_wiring", "a08_plain_gameplay_completes"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_a01()
	_a02()
	_a03()
	await _a04()
	_a05()
	_a06()
	await _a07()
	await _a08()
	_cleanup()
	_done()

func _a01() -> void:
	print("[a01 reference values: WCAG contrast, Lab, CVD simulation]")
	_ok(absf(A.contrast_ratio(Color.BLACK, Color.WHITE) - 21.0) < 0.01 and absf(A.contrast_ratio(Color(0.3, 0.6, 0.2), Color(0.3, 0.6, 0.2)) - 1.0) < 1e-6, "contrast black/white = 21, identical = 1")
	var lab: Vector3 = A.to_lab(Color.WHITE)
	_ok(absf(lab.x - 100.0) < 0.1 and absf(lab.y) < 0.5 and absf(lab.z) < 0.5, "white -> L* 100, a* b* ~ 0 (%s)" % str(lab))
	var red := Color("#FF4500")
	_ok(A.simulate(red, "normal") == red and A.delta_e(red, red) == 0.0, "normal vision is identity; dE(x,x) = 0")
	var grey := Color(0.5, 0.5, 0.5)
	var grey_ok := true
	for k in ["protan", "deutan", "tritan"]:
		grey_ok = grey_ok and A.delta_e(A.simulate(grey, k), grey) < 1.5
	_ok(grey_ok, "neutral grey ~unchanged by every CVD matrix")
	_ok(A.delta_e(A.simulate(Color(1, 0, 0), "protan"), A.simulate(Color(0, 0.5, 0), "protan")) < A.delta_e(Color(1, 0, 0), Color(0, 0.5, 0)), "protanopia reduces red/green separation")
	var red_lab: Vector3 = A.to_lab(Color(1, 0, 0))
	_ok(red_lab.distance_to(Vector3(53.24, 80.09, 67.20)) < 0.2, "sRGB red -> Lab (53.24, 80.09, 67.20) reference (%s)" % str(red_lab))
	# Sharma, Wu & Dalal (2005) CIEDE2000 published test pairs.
	var sharma := [[Vector3(50, 2.6772, -79.7751), Vector3(50, 0, -82.7485), 2.0425], [Vector3(50, 0, 0), Vector3(50, -1, 2), 2.3669],
		[Vector3(50, 2.5, 0), Vector3(73, 25, -18), 27.1492], [Vector3(50, 2.5, 0), Vector3(50, 3.1736, 0.5854), 1.0000]]
	var s_ok := true
	for s in sharma:
		s_ok = s_ok and absf(A.ciede2000(s[0], s[1]) - float(s[2])) < 0.0005
	_ok(s_ok, "CIEDE2000 matches 4 published Sharma test pairs")
	_complete("a01_math_reference_values")

func _a02() -> void:
	print("[a02 text contrast of production colour constants (WCAG AA 4.5)]")
	var pairs := [
		["popup body INK on cream ROW card", BasePopup.INK, BasePopup.ROW],
		["white title on ROYAL plaque", Color.WHITE, BasePopup.ROYAL],
		["white label on CARD shortcut", HomeStyle.TEXT, HomeStyle.CARD],
		["white on NAVY dock", HomeStyle.TEXT, HomeStyle.NAVY],
		["SUBTITLE yellow on PANEL", HomeStyle.SUBTITLE, HomeStyle.PANEL],
		["INK on GOLD", BasePopup.INK, HomeStyle.GOLD],
	]
	for p in pairs:
		var r: float = A.contrast_ratio(p[1], p[2])
		_ok(r >= WCAG_AA, "%s: %.2f:1" % [p[0], r])
	# M50 decision B (owner 2026-10-15): the hero PLAY label is NAVY text on the unchanged green
	# (tests/m50_color_symbols.gd s07 checks the live button states). Other green buttons keep white.
	var navy: float = A.contrast_ratio(HomeStyle.NAVY, HomeStyle.GREEN)
	_ok(navy >= WCAG_AA, "hero PLAY label: NAVY on GREEN %.2f:1" % navy)
	print("    note: white label on other green buttons (popup / results primary) stays %.2f:1 fill + navy outline" % A.contrast_ratio(HomeStyle.TEXT, HomeStyle.GREEN))
	_ok(UiTokens.FONT_BODY >= 28 and UiTokens.FONT_BUTTON >= 30 and UiTokens.TOUCH_MIN >= 88, "type / touch tokens: body %d, button %d, touch %d" % [UiTokens.FONT_BODY, UiTokens.FONT_BUTTON, UiTokens.TOUCH_MIN])
	_complete("a02_ui_text_contrast")

func _a03() -> void:
	print("[a03 production levels: closest colour pair under normal / protan / deutan / tritan vision]")
	var cat = LevelCatalog.new()
	_ok(cat.load_manifest().ok, "catalog loads")
	var rows := 0
	var normal_ok := true
	for e in cat.get_entries_ordered():
		var lv: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(e.level_path))
		var cols: Array = (lv["palette"] as Array).map(func(h): return Color(String(h)))
		var rep: Dictionary = A.palette_report(cols)
		var parts: Array = []
		for k in A.KINDS:
			var r: Dictionary = rep[k]
			parts.append("%s dE76 %.1f (%s/%s) dE00 %.1f (%s/%s)" % [k, float(r["min"]), lv["palette"][int(r["a"])], lv["palette"][int(r["b"])],
				float(r["min00"]), lv["palette"][int(r["a00"])], lv["palette"][int(r["b00"])]])
		print("    L%d %s %d colours | %s" % [int(e.order), String(e.id), cols.size(), " | ".join(parts)])
		normal_ok = normal_ok and is_finite(float(rep["normal"]["min"])) and float(rep["normal"]["min"]) >= 10.0
		rows += 1
	_ok(rows >= 10 and normal_ok, "%d levels measured; every level's closest pair >= dE76 10 under normal vision (builder sanity floor, not an owner threshold)" % rows)
	print("    FINDING (owner decision, SB-M50-002/003): CVD minima above (severity 1.0 = full dichromacy; CIE76 understates, see dE00); colour identity has no non-colour cue on tiles")
	_complete("a03_level_cvd_report")

func _a04() -> void:
	print("[a04 live non-colour cues on the real gameplay screen]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var path := "user://m50_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	for _i in range(6):
		await process_frame
	root.play_current_frontier()
	for _i in range(6):
		await process_frame
	var host = root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var panel = host.get_screen().get_supply_panel()
	var snap: Array = host.get_supply().player_snapshot()
	var counts_ok := true
	var checked := 0
	for c in range(panel.get_column_count()):
		var front = snap[c].get("front", null) if c < snap.size() else null
		if front is Dictionary:
			checked += 1
			counts_ok = counts_ok and panel.get_row_count_text(c, 0) == str(int(front.get("robot_count", -1)))
	_ok(counts_ok and checked > 0, "every supply front (%d checked) shows its live robot count as text (quantity is not colour-only)" % checked)
	var badges_ok := true
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		var b: Button = host.get_screen().get_booster_button(id)
		badges_ok = badges_ok and b.get_node("Icon") is TextureRect and (b.get_node("Icon") as TextureRect).texture != null
	_ok(badges_ok, "each booster is identified by its own icon art, not colour")
	root.free()
	sub.free()
	_complete("a04_non_colour_cues_live")

func _a05() -> void:
	print("[a05 icon families at %d px: silhouette (1 - IoU) >= %.2f or mean-colour dE00 >= %.0f under every vision kind]" % [ICON_PX, SILHOUETTE_MIN, HUE_DE00_MIN])
	for fam in ICON_FAMILIES:
		var files: Array = ICON_FAMILIES[fam]
		var icons: Array = files.map(func(f): return _icon48("res://assets/ui/final/" + f))
		var bad: Array = []
		for i in range(icons.size()):
			for k in range(i + 1, icons.size()):
				var sil := 1.0 - _iou(icons[i], icons[k])
				var de := 1e9
				for kind in A.KINDS:
					de = minf(de, A.delta_e00(A.simulate(_mean(icons[i]), kind), A.simulate(_mean(icons[k]), kind)))
				var pair := "%s/%s" % [String(files[i]).get_file().get_basename(), String(files[k]).get_file().get_basename()]
				print("    %s %s: silhouette %.2f, worst-vision colour dE00 %.1f" % [fam, pair, sil, de])
				if sil < SILHOUETTE_MIN and de < HUE_DE00_MIN:
					bad.append(pair)
		_ok(bad.is_empty(), "%s: %d icons pairwise distinguishable at %d px %s" % [fam, icons.size(), ICON_PX, str(bad)])
	_complete("a05_icon_families_48px")

## The icon fitted into a transparent 48x48 square (aspect kept), as a HUD chip shows it.
func _icon48(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	var sc := float(ICON_PX) / maxf(img.get_width(), img.get_height())
	var w := maxi(1, int(round(img.get_width() * sc)))
	var h := maxi(1, int(round(img.get_height() * sc)))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(ICON_PX, ICON_PX, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((ICON_PX - w) / 2, (ICON_PX - h) / 2))
	return out

static func _iou(a: Image, b: Image) -> float:
	var inter := 0
	var uni := 0
	for y in range(ICON_PX):
		for x in range(ICON_PX):
			var ia := a.get_pixel(x, y).a >= 0.5
			var ib := b.get_pixel(x, y).a >= 0.5
			inter += 1 if ia and ib else 0
			uni += 1 if ia or ib else 0
	return float(inter) / maxf(uni, 1)

static func _mean(img: Image) -> Color:
	var sum := Vector3.ZERO
	var n := 0
	for y in range(ICON_PX):
		for x in range(ICON_PX):
			var c := img.get_pixel(x, y)
			if c.a >= 0.5:
				sum += Vector3(c.r, c.g, c.b)
				n += 1
	sum /= maxf(n, 1)
	return Color(sum.x, sum.y, sum.z)

func _a06() -> void:
	print("[a06 readable font floor %d design px (~6.9 dp on a 411 dp wide phone)]" % FONT_FLOOR)
	_ok(UiTokens.FONT_BODY >= FONT_FLOOR and UiTokens.FONT_BUTTON >= FONT_FLOOR, "body %d / button %d tokens >= floor" % [UiTokens.FONT_BODY, UiTokens.FONT_BUTTON])
	# Every production HomeStyle.fit_font call (SB-M49-022) starts at these design px; English never
	# shrinks (tests/m49_touch_targets_text_stress.gd t00), a longer locale may go down to 60%.
	var starts := {"booster Price": 20, "HUD ProfileLevel": 22, "Home REWARDED ADS": 24, "event pill": 30}
	var below: Array = []
	for k in starts:
		var l := Label.new()
		l.text = "W".repeat(80)
		HomeStyle.fit_font(l, starts[k], 50.0)
		var fs: int = l.get_theme_font_size("font_size")
		l.free()
		_ok(fs == int(starts[k] * 0.6), "%s: fit_font floor %d px for a %d px start" % [k, fs, starts[k]])
		if fs < FONT_FLOOR:
			below.append("%s %d px" % [k, fs])
	print("    FINDING (owner / localization decision, SB-M50-007): a long locale can shrink %s below the %d px floor; clamping breaks those plates (m49 stress), so it needs shorter copy or a wider plate per locale" % [str(below), FONT_FLOOR])
	_complete("a06_font_floor")

func _a07() -> void:
	print("[a07 Reduced Effects: Settings toggle -> every live consumer; REDUCED-arm ledger]")
	var miss: Array = []
	for f in REDUCED_LEDGER:
		if not FileAccess.get_file_as_string("res://" + f).to_lower().contains("reduced") or not FileAccess.get_file_as_string("res://tests/%s.gd" % REDUCED_LEDGER[f]).to_lower().contains("reduced"):
			miss.append(f)
	_ok(miss.is_empty(), "%d Reduced Effects consumers each name a suite with a REDUCED arm %s" % [REDUCED_LEDGER.size(), str(miss)])
	var unlisted: Array = []
	for f in _gd_files("res://scripts/ui") + _gd_files("res://scripts/gameplay"):
		var rel := String(f).trim_prefix("res://")
		if FileAccess.get_file_as_string(f).to_lower().contains("reduced") and not REDUCED_LEDGER.has(rel) \
				and not rel.get_file() in ["settings_panel.gd", "production_gameplay_host.gd", "ui_text.gd"]:   # toggle / wiring / copy only
			unlisted.append(rel)
	_ok(unlisted.is_empty(), "every Reduced-aware UI / gameplay script is in the ledger %s" % str(unlisted))
	var b := await _boot()
	var root = b[1]
	var app = root.get_app_state()
	root.open_settings()
	await _frames(4)
	root.get_settings_panel().get_reduced_effects_toggle().button_pressed = true
	root.get_navigation().close_settings()
	root.refresh_coachmark()
	await _frames(4)
	var live := {"service": app.effects.is_reduced(), "feedback_adapter": root.feel.reduced(), "meta_reward_feel": root.get_meta_reward_feel()._reduced(),
		"ceremonies": root.get_ceremonies()._reduced(), "home_hero": root.get_home()._nodes["HomeScrubbyHero"].is_reduced(),
		"coachmarks": root.get_coachmarks() == null or root.get_coachmarks().is_reduced(),
		"results_model": bool(root._results_model({"status": "WON", "level": 1, "attempt": 1})["reduced_effects"])}
	root.play_current_frontier()
	await _frames(6)
	var host = root.get_gameplay_host()
	host.get_runtime().set_process(false)
	live["cleaning_fx"] = host._cleaning_fx.is_reduced_effects()
	live["gameplay_screen"] = host.get_screen()._reduced_effects
	var intro: Array = host.find_children("*", "", true, false).filter(func(n): return n is LevelIntroOverlay)
	live["level_intro"] = intro.is_empty() or intro[0].reduced
	_ok(live.values().all(func(v): return v == true), "Reduced ON via the Settings toggle reaches every live consumer %s" % str(live))
	app.set_reduced_effects(false)
	await _frames(2)
	_ok(not host._cleaning_fx.is_reduced_effects() and not host.get_screen()._reduced_effects and not root.feel.reduced(), "turning it OFF applies live to the running level (no rebuild)")
	_free(b)
	_complete("a07_reduced_effects_wiring")

func _a08() -> void:
	print("[a08 plain gameplay: Reduced ON, feel plugins absent, colour symbols OFF -> level WON]")
	var b := await _boot()
	var root = b[1]
	root.feel.set_backends_for_test(null, null)
	root.get_app_state().set_reduced_effects(true)
	_ok(not root.get_app_state().effects.is_color_symbols(), "colour symbols OFF (the default)")
	_ok(root.play_current_frontier().get("ok", false), "level launches")
	await _frames(6)
	var host = root.get_gameplay_host()
	var rt = host.get_runtime()
	rt.set_process(false)
	var screen = host.get_screen()
	var pres = screen.get_presentation()
	var board = host.get_board()
	var active := 0
	for y in range(board.get_height()):
		for x in range(board.get_width()):
			active += 1 if pres.get_renderer().get_pixel_color(x, y).a > 0.99 else 0
	_ok(active > 0 and screen.get_board_rect().has_area(), "board renders its ACTIVE pixel art (%d opaque cells)" % active)
	_ok(screen.get_five_slot_strip().is_visible_in_tree() and screen.get_five_slot_strip_rect().has_area(), "five-slot strip shown")
	_ok(host.get_supply().get_column_count() > 0 and screen.get_supply_panel().is_visible_in_tree(), "supply shown (%d columns)" % host.get_supply().get_column_count())
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var i := 0
	var guard := 0
	var bots := 0
	# Same driver as tests/m43_c005f_015_e2e_feel.gd: owner supply-plan clicks + runtime ticks.
	while guard < 200000 and not host.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(host.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(1.0)
		bots = maxi(bots, pres.get_agent_layer().get_children().filter(func(n): return n is CanvasItem and n.visible).size())
		guard += 1
	_ok(bots > 0, "dispatched Scrubbots are drawn on the board's agent layer (%d visuals over the level)" % bots)
	_ok(String(host.get_completion().get_state()) == "WON", "the level is WON with no decoration / effects (%s, %d ticks)" % [String(host.get_completion().get_state()), guard])
	_ok(root.feel.dispatch_log().all(func(e): return int(e[2]["amount"]) == 0), "Reduced: no particle work planned for any of the %d feel requests" % root.feel.dispatch_log().size())
	_free(b)
	_complete("a08_plain_gameplay_completes")

## [SubViewport, main root] on a throw-away save, every feature unlocked.
func _boot() -> Array:
	AppStateScript.test_unlock_all = true
	MainScript.boot_opening_override = 0
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var path := "user://m50_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(8)
	return [sub, root]

func _free(b: Array) -> void:
	b[1].free()
	b[0].free()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _gd_files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sd in d.get_directories():
		out.append_array(_gd_files(dir + "/" + sd))
	return out

func _cleanup() -> void:
	AppStateScript.test_unlock_all = false
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))

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
	print("M50 accessibility audit evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
