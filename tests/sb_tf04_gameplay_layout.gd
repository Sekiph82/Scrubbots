extends SceneTree
## SB-TF-04 (owner 2026-11-18) gameplay layout: the Home banner area at the bottom of gameplay
## (No Ads collapses it), boosters higher and bigger right of Scrubby, bucket + Caution sign 25%
## smaller beside the Supply panel, Scrubby 25% bigger, the speech bubble behind the slot strip
## and Supply panel with its live text clear of everything, and the brighter board floor tone.
## SB-TF-10 (owner 2026-11-19): boosters directly under the Supply panel, centred on screen, drawn
## over Scrubby but clear of Supply / slots / banner. SB-TF-13: board floor = the owner-chosen dark
## purple-grey #4A3258 (Lab distance >= 20 is asserted in tests/sb_tf13_feedback.gd).
## Six shells x the required viewport matrix on the real GameplayScreen.
##
## Run: godot --headless --path . -s res://tests/sb_tf04_gameplay_layout.gd

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")
const BoardPresentation = preload("res://scripts/gameplay/board/board_presentation.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const VIEWPORTS := [Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532),
	Vector2i(1080, 2400), Vector2i(1290, 2796), Vector2i(1440, 3200), Vector2i(1536, 2048)]
## Pre-change geometry, measured on main (0c1fb64a) at 1080x2400 with the same fixtures:
## board region (rail) rect and display cell per square board side.
const PRE_BOARD_REGION := Rect2(101.4085, 391.2676, 873.3803, 872.1127)
const PRE_CELL := {20: 34.9098, 24: 30.0947, 32: 23.5877, 40: 19.3943, 59: 13.6366}
const PRE_BOOSTER_SIDE_REF := 98.0
## SHA-256 prefixes (16 hex) of RGB8 master regions on main (0c1fb64a), per shell:
## [rail tube lines, slot interiors inset 10, Supply cells inset 4, props rect, Scrubby rect,
## bubble text area]. The first three must be unchanged, the last three must have moved.
const OLD_REGIONS := {
	"5slot_3col": ["77449af14117ea48", "66e21a3600909f71", "aaa3566554bd4eee", "2f7da99cd635991e", "27ac0411483ef72e", "aea36883c665b50e"],
	"5slot_4col": ["77449af14117ea48", "66e21a3600909f71", "5469461110f8b6bd", "2f7da99cd635991e", "c388ea8433c80c9d", "aea36883c665b50e"],
	"5slot_5col": ["77449af14117ea48", "66e21a3600909f71", "d34de1e9e2e97a34", "2f7da99cd635991e", "15925a3dfbbded6a", "aea36883c665b50e"],
	"6slot_3col": ["2909ae91dfffa473", "9c0a105e95ca6df5", "aaa3566554bd4eee", "2f7da99cd635991e", "27ac0411483ef72e", "aea36883c665b50e"],
	"6slot_4col": ["2909ae91dfffa473", "9c0a105e95ca6df5", "5469461110f8b6bd", "2f7da99cd635991e", "c388ea8433c80c9d", "aea36883c665b50e"],
	"6slot_5col": ["2909ae91dfffa473", "9c0a105e95ca6df5", "d34de1e9e2e97a34", "2f7da99cd635991e", "15925a3dfbbded6a", "aea36883c665b50e"],
}
const RAIL_LINES := [[78, 283, 772, 288], [78, 971, 772, 976], [78, 283, 83, 976], [767, 283, 772, 976]]

var EXPECTED_CASES := ["geometry_constants", "shell_viewport_matrix", "no_ads_collapse", "bubble_strings_en_tr",
	"board_not_smaller", "masters_regenerated", "board_floor_tone"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_geometry_constants()
	await _shell_viewport_matrix()
	await _no_ads_collapse()
	await _bubble_strings_en_tr()
	await _board_not_smaller()
	_masters_regenerated()
	await _board_floor_tone()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	return sub

## A real GameplayScreen on a 24x24 board with `cols` Supply columns and slot capacity `cap`.
func _screen(sub: SubViewport, cols: int, cap: int, side: int = 24):
	var lvl = BoardDebugFixtures.make_level(side, side)
	var scr = GameplayScreen.new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(BoardDebugFixtures.make_board(side, side), lvl.palette, [], BatchSupplyGenerator.generate(lvl, cols, 3, 5).player_snapshot())
	if cap == 6:
		scr.get_five_slot_strip().set_capacity(6)
		scr.refresh_slot_snapshot([])
	await _settle()
	return scr

func _settle() -> void:
	for _i in range(3):
		await process_frame

func _hits(a: Rect2, b: Rect2) -> bool:
	return a.grow(-0.5).intersects(b.grow(-0.5))

# ------------------------------------------------------------------ cases ----

func _geometry_constants() -> void:
	print("[geometry constants]")
	var bb: Rect2 = Shell.rect(Shell.BOOSTERS)
	_ok(Shell.BOOSTERS == [172, 1516, 680, 1636] and bb.size == Vector2(508, 120) and bb.get_center().x == Shell.SIZE.x / 2.0,
		"Shell.BOOSTERS == [172,1516,680,1636]: SB-TF-04 508x120 band, centred on the master width (SB-TF-10)")
	_ok(not (Shell as Script).get_script_constant_map().has("AD"), "Shell.AD removed (the banner is screen space)")
	var props: Rect2 = Shell.rect(GameplayScreen.PROPS_ANCHOR)
	var scrub: Rect2 = Shell.rect(GameplayScreen.SCRUBBY_ANCHOR)
	_ok(GameplayScreen.PROPS_ANCHOR == [661, 1204, 845, 1500] and absf(props.size.x - 245.0 * 0.75) <= 1.0 and absf(props.size.y - 395.0 * 0.75) <= 1.0,
		"PROPS_ANCHOR [661,1204,845,1500] = 0.75 x the old 245x395 (%s)" % str(props.size))
	_ok(GameplayScreen.SCRUBBY_ANCHOR == [14, 1310, 324, 1654] and absf(scrub.size.x - 248.0 * 1.25) <= 1.0 and absf(scrub.size.y - 275.0 * 1.25) <= 1.0,
		"SCRUBBY_ANCHOR [14,1310,324,1654] = 1.25 x the old 248x275 (%s)" % str(scrub.size))
	_ok(scrub.intersects(bb) and bb.position.y >= 1515.0 and not bb.intersects(props),
		"booster band overlaps Scrubby (allowed), starts below the Supply panel's baked shadow (y 1515), clear of the props")
	_completed["geometry_constants"] = true

func _shell_viewport_matrix() -> void:
	print("[six shells x %d viewports]" % VIEWPORTS.size())
	for cap in [5, 6]:
		for cols in [3, 4, 5]:
			var sub := _sub(VIEWPORTS[0])
			var scr = await _screen(sub, cols, cap)
			var id := "%dslot_%dcol" % [cap, cols]
			_ok(scr.get_shell_id() == id, "%s selected" % id)
			for vp in VIEWPORTS:
				sub.size = vp
				await _settle()
				_check_layout(scr, "%s %dx%d" % [id, vp.x, vp.y], vp)
			scr.free()
			sub.free()
	_completed["shell_viewport_matrix"] = true

func _check_layout(s, label: String, vp: Vector2i) -> void:
	var sc: float = s.get_shell_scale()
	# b. banner: full width, flush with the bottom, Home's height rule, empty mount.
	var ad: Rect2 = s.get_ad_region_rect()
	var want_h := clampf(vp.x * 50.0 / 320.0, 72.0, 112.0)
	_ok(s.has_ad_region() and absf(ad.position.x) < 0.5 and absf(ad.size.x - vp.x) < 0.5 and absf(ad.end.y - vp.y) < 0.5
		and absf(ad.size.y - want_h) < 0.5 and s.get_ad_mount().get_child_count() == 0 and not s.is_ad_placeholder_visible(),
		"%s: banner %s = full width, bottom flush, height clamp(w*50/320,72,112)=%.0f, empty AdMount" % [label, str(ad), want_h])
	# c. boosters: order, squares >= TOUCH_MIN and >= 1.2x the old side, inside the band.
	var band: Rect2 = s.ref_rect_to_global(Shell.rect(Shell.BOOSTERS))
	var ids: Array = s.get_booster_ids()
	var ok: bool = ids == ["plus_one_slot", "random", "selector", "tornado"] and s.get_booster_count() == 4
	var prev_x := -INF
	var side := 0.0
	for id in ids:
		var r: Rect2 = s.get_booster_button(id).get_global_rect()
		side = r.size.x
		ok = ok and absf(r.size.x - r.size.y) < 0.5 and r.size.x >= UiTokens.TOUCH_MIN and r.size.x >= 1.2 * PRE_BOOSTER_SIDE_REF * sc - 0.5
		# inside the band; only the TOUCH_MIN floor may reach below it (720x1280: band 83 px)
		var in_x: bool = r.position.x >= band.position.x - 0.5 and r.end.x <= band.end.x + 0.5
		var in_y: bool = absf(r.position.y - band.position.y) < 0.5 and (r.end.y <= band.end.y + 0.5 or r.size.y == UiTokens.TOUCH_MIN)
		ok = ok and in_x and in_y and r.position.x > prev_x and r.end.y + 2.0 <= ad.position.y
		ok = ok and absf(r.size.x - maxf(floorf(band.size.y), UiTokens.TOUCH_MIN)) < 0.5   # size unchanged
		prev_x = r.position.x
	ok = ok and s.get_booster_button("tornado").get_global_rect().position.x == prev_x
	_ok(ok, "%s: 4 boosters plus_one_slot..tornado (rightmost), %.1f px squares >= %d and >= 1.2x old, inside the band, >= 2 px above the banner" % [label, side, UiTokens.TOUCH_MIN])
	var supply: Rect2 = s.get_supply_panel_rect()
	_ok(band.end.y + 2.0 <= ad.position.y and band.position.y >= supply.end.y,
		"%s: band %.1f..%.1f below the Supply panel (%.1f), >= 2 px above the banner (%.1f)" % [label, band.position.y, band.end.y, supply.end.y, ad.position.y])
	# SB-TF-10: the row (and the four buttons) centred on screen; the only later ScreenContent child is
	# the board-sized magnifier touch area (its loupe is hidden until the board is held).
	var row: Rect2 = s.get_booster_row_rect()
	var first: Rect2 = s.get_booster_button(ids[0]).get_global_rect()
	var last: Rect2 = s.get_booster_button(ids[ids.size() - 1]).get_global_rect()
	var node: Control = s.get_booster_button(ids[0]).get_parent()
	var after: Array = node.get_parent().get_children().slice(node.get_index() + 1)
	# <= 1.5 px: the shell origin is floored to whole px and the row separation is a whole px
	_ok(absf(row.get_center().x - vp.x / 2.0) <= 1.5 and absf((first.position.x + last.end.x) / 2.0 - vp.x / 2.0) <= 1.5
		and after.size() == 1 and after[0] == s.get_board_magnifier() and not _hits(row, s.get_board_magnifier().get_global_rect())
		and not s.get_board_magnifier().is_inspecting(),
		"%s: booster row centred on screen (row %.1f, buttons %.1f, screen %.1f); nothing draws over it" % [label, row.get_center().x, (first.position.x + last.end.x) / 2.0, vp.x / 2.0])
	# Never over a Supply cell / front tap target (5-column case included) or an execution slot.
	var covered := []
	var sp = s.get_supply_panel()
	for c in range(sp.get_column_count()):
		if _hits(row, sp.get_front_hit_rect(c)):
			covered.append("front%d" % c)
	for v in s.get_five_slot_strip().get_slot_views():
		if _hits(row, v.get_global_rect()):
			covered.append("slot")
	_ok(covered.is_empty() and not _hits(row, supply), "%s: boosters cover no Supply column / front tap target / slot %s" % [label, str(covered)])
	# d / e. no overlaps among the lower-screen elements; live text inside the visible bubble.
	var strip: Rect2 = s.get_five_slot_strip_rect()
	var scrub: Rect2 = s.get_scrubby_anchor_rect()
	var props: Rect2 = s.get_props_anchor_rect()
	var top: Rect2 = s.get_top_region_rect()
	var labels: Array = s.get_bubble_labels()
	var head: Rect2 = (labels[0] as Label).get_global_rect()
	var body: Rect2 = (labels[1] as Label).get_global_rect()
	var named := {"band": band, "strip": strip, "scrubby": scrub, "banner": ad, "headline": head, "instruction": body}
	var keys: Array = named.keys()
	var clash := []
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			if keys[i] == "band" and keys[j] == "scrubby":
				continue   # SB-TF-10: the boosters may draw over Scrubby
			if _hits(named[keys[i]], named[keys[j]]):
				clash.append("%s/%s" % [keys[i], keys[j]])
	for k in ["band", "strip", "top"]:
		if _hits(props, band if k == "band" else (strip if k == "strip" else top)):
			clash.append("props/%s" % k)
	for k in ["headline", "instruction"]:
		for o in [["supply", supply], ["props", props], ["top", top]]:
			if _hits(named[k], o[1]):
				clash.append("%s/%s" % [k, o[0]])
	_ok(clash.is_empty(), "%s: band / strip / Scrubby / props / banner / both bubble lines never overlap (band over Scrubby allowed) %s" % [label, str(clash)])
	var bubble: Rect2 = s.get_speech_anchor_rect()
	var mask: Rect2 = s.get_bubble_mask().get_global_rect()
	_ok(s.bubble_text_fits() and bubble.encloses(head) and bubble.encloses(body) and mask.grow(0.5).encloses(head) and mask.grow(0.5).encloses(body),
		"%s: both bubble lines fit and lie inside the bubble's visible text area" % label)

func _no_ads_collapse() -> void:
	print("[No Ads collapses the banner]")
	var sub := _sub(Vector2i(1080, 2400))
	var scr = await _screen(sub, 4, 5)
	var row: Rect2 = scr.get_booster_row_rect()
	var board: Rect2 = scr.get_board_region_rect()
	scr.set_ad_slot_enabled(false)
	await _settle()
	var ad: Rect2 = scr.get_ad_region_rect()
	_ok(not scr.has_ad_region() and not scr.is_ad_slot_enabled() and ad.size.y == 0.0 and not scr.get_ad_mount().is_visible_in_tree(),
		"No Ads: banner height 0 and hidden (%s)" % str(ad))
	_ok(scr.get_booster_row_rect() == row and scr.get_board_region_rect() == board, "shell lays out exactly as before (boosters, board)")
	scr.set_ad_slot_enabled(true)
	await _settle()
	_ok(scr.has_ad_region() and absf(scr.get_ad_region_rect().size.y - 112.0) < 0.5, "re-enabled: 112 px banner back")
	scr.free()
	sub.free()
	_completed["no_ads_collapse"] = true

func _bubble_strings_en_tr() -> void:
	print("[bubble strings EN / TR]")
	var prev := UiText.locale
	for lang in ["en", "tr"]:
		UiText.locale = lang
		for vp in [Vector2i(720, 1280), Vector2i(1080, 2400)]:
			var sub := _sub(vp)
			var scr = await _screen(sub, 5, 6)
			var labels: Array = scr.get_bubble_labels()
			_ok(labels[0].text == UiText.t("GP_BUBBLE_HEADLINE") and labels[1].text == UiText.t("GP_BUBBLE_INSTRUCTION") and scr.bubble_text_fits()
				and not _hits(labels[0].get_global_rect(), scr.get_supply_panel_rect()) and not _hits(labels[1].get_global_rect(), scr.get_five_slot_strip_rect()),
				"%s %dx%d: GP_BUBBLE_HEADLINE / GP_BUBBLE_INSTRUCTION unchanged, fit, clear of strip + Supply" % [lang, vp.x, vp.y])
			scr.free()
			sub.free()
	UiText.locale = prev
	_completed["bubble_strings_en_tr"] = true

func _board_not_smaller() -> void:
	print("[board region / cell not smaller than main]")
	var sub := _sub(Vector2i(1080, 2400))
	for n in PRE_CELL:
		var scr = await _screen(sub, 4, 5, n)
		var r: Rect2 = scr.get_board_region_rect()
		_ok(r.size.x >= PRE_BOARD_REGION.size.x - 0.01 and r.size.y >= PRE_BOARD_REGION.size.y - 0.01 and scr.get_cell_size() >= PRE_CELL[n] - 0.001,
			"%dx%d at 1080x2400: region %s >= %s, cell %.4f >= %.4f" % [n, n, str(r.size), str(PRE_BOARD_REGION.size), scr.get_cell_size(), PRE_CELL[n]])
		scr.free()
	sub.free()
	_completed["board_not_smaller"] = true

func _masters_regenerated() -> void:
	print("[six regenerated masters]")
	for id in Shell.SHA256:
		_ok(FileAccess.get_sha256(Shell.texture_path(id)) == Shell.SHA256[id], "%s matches the new Shell.SHA256" % id)
		var img := Image.load_from_file(ProjectSettings.globalize_path(Shell.texture_path(id)))
		img.convert(Image.FORMAT_RGB8)
		var g: Dictionary = Shell.SHELLS[id]
		var cells := []
		for row in g["rows"]:
			for col in g["cols"]:
				cells.append([col[0], row[0], col[1], row[1]])
		var now := [_region_hash(img, RAIL_LINES, 0), _region_hash(img, g["slots"], 10), _region_hash(img, cells, 4),
			_region_hash(img, [GameplayScreen.PROPS_ANCHOR], 0), _region_hash(img, [GameplayScreen.SCRUBBY_ANCHOR], 0),
			_region_hash(img, [[32, 1178, 206, 1306]], 0)]
		var old: Array = OLD_REGIONS[id]
		_ok(now[0] == old[0] and now[1] == old[1] and now[2] == old[2], "%s: rail, slot interiors and Supply cells byte-identical to main" % id)
		_ok(now[3] != old[3] and now[4] != old[4] and now[5] != old[5], "%s: props, Scrubby and bubble-text pixels changed (art moved)" % id)
		# The live text boxes sit on plain bubble cream in every master (no panel, no baked text).
		var cream := true
		for r in [GameplayScreen.BUBBLE_HEADLINE_REF, GameplayScreen.BUBBLE_INSTRUCTION_REF]:
			for y in range(r[1], r[3], 3):
				for x in range(r[0], r[2], 3):
					var c := img.get_pixel(x, y)
					cream = cream and c.r8 > 235 and c.g8 > 228 and c.b8 > 210
		_ok(cream, "%s: both bubble text boxes lie on visible bubble cream" % id)
	_completed["masters_regenerated"] = true

func _region_hash(img: Image, rects: Array, inset: int) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for r in rects:
		ctx.update(img.get_region(Rect2i(r[0] + inset, r[1] + inset, r[2] - r[0] - 2 * inset, r[3] - r[1] - 2 * inset)).get_data())
	return ctx.finish().hex_encode().substr(0, 16)

func _board_floor_tone() -> void:
	print("[board floor tone]")
	var tone: Color = BoardPresentation.BOARD_FLOOR
	var sub := _sub(Vector2i(1080, 2400))
	var scr = await _screen(sub, 4, 5)
	_ok(scr.get_presentation().get_background().color == tone, "BoardBackground.color == BOARD_FLOOR %s" % tone.to_html(false))
	scr.free()
	sub.free()
	_ok(tone == Color8(74, 50, 88), "BOARD_FLOOR == #4A3258, the owner-chosen dark purple-grey (SB-TF-13)")
	var consts: Dictionary = (BoardPresentation as Script).get_script_constant_map()
	_ok(not consts.has("BOARD_FLOOR_TONES") and not consts.has("BOARD_FLOOR_TONE"), "the four SB-TF-04 candidate tones and their selector are gone")
	_ok(_lum(tone) > _lum(BoardPresentation.BG01), "floor brighter than BG01 (%.4f > %.4f)" % [_lum(tone), _lum(BoardPresentation.BG01)])
	var pal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	var no_equal := true
	var min_cr := INF
	for c in pal["colors"]:
		var rgb: Array = c["rgb"]
		var pc := Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))
		no_equal = no_equal and tone != pc
		var hi := maxf(_lum(pc), _lum(tone))
		var lo := minf(_lum(pc), _lum(tone))
		min_cr = minf(min_cr, (hi + 0.05) / (lo + 0.05))
	_ok(no_equal and pal["colors"].size() == 16, "floor equals no C01..C16 colour")
	# Owner waiver (SB-TF-10): the SB-TF-04 1.3:1 floor-contrast rule does not apply; reported only.
	print("  info: min C01..C16 contrast vs the floor %.3f:1 (1.3:1 rule waived by the owner)" % min_cr)
	# The masters bake the same floor into the board field (centre of the rail opening).
	var img := Image.load_from_file(ProjectSettings.globalize_path(Shell.texture_path("5slot_4col")))
	var px := img.get_pixel(426, 630)
	_ok(absi(px.r8 - 74) <= 6 and absi(px.g8 - 50) <= 6 and absi(px.b8 - 88) <= 6, "masters' board field baked to the floor (centre %s)" % px.to_html(false))
	_completed["board_floor_tone"] = true

## WCAG relative luminance of an sRGB colour.
func _lum(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)

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
	print("SB-TF-04 gameplay layout evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
