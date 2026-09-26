extends SceneTree
## M42 Home REBUILD V04 — single world background evidence
## (coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md). Expected /
## completed case ledger (AL-091). Kept as the V04-invariant suite after owner polish V05
## (coordination/OWNER_M42_HOME_POLISH_V05.md): the assertions V05 deliberately changes
## (Scrubby +15% beyond the V04 safe box, panel glass alpha, (+) overlapping its pill,
## ad reservation 96..160) are updated here; V05 specifics live in m42_home_v05.gd.
##
## Run: godot --headless --path . -s res://tests/m42_home_v04.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HomeScreenScript = preload("res://scripts/ui/home/home_screen.gd")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const HomeWorldCatalog = preload("res://scripts/ui/home/home_world_catalog.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

const WORLD_PATH := "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"
const WORLD_SRC := "res://assets/art/references/_owner_inbox/world_01_whispering_park_1080x2160.png"
const WORLD_SHA := "8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b"
const MATRIX := [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]
## V03 measured references at 1080x2160 (audited V03 build): Bot Parts bar 24 px, icon box
## 206x164 inside each shortcut card, PLAY 470x150.
const V03_BAR_H := 24.0
const V03_ICON_BOX := Vector2(206, 164)
const V03_PLAY := Vector2(470, 150)

var EXPECTED_CASES := [
	"world_asset_identity", "world_binds_through_lifecycle", "no_duplicate_world_art",
	"scrubby_anchor_contract", "four_panels", "panel_icons", "panel_style_and_margin",
	"play_standalone", "profile", "currency_hud", "gift_and_track", "nav_and_ad_slot",
	"ad_slot_collapse", "daily_modal", "settings_modal", "world_seam", "responsive_matrix",
	"historical_assets_intact",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _paths: Dictionary = {}

func _initialize() -> void:
	await process_frame
	for a in V.load_manifest()["assets"]:
		if a.has("path"):
			_paths[a["id"]] = "res://" + String(a["path"])
	_world_identity()
	var r = await _home(Vector2i(1080, 2160), "main")
	var home = r[1]
	_binds(home)
	_no_duplicates(home)
	_anchor(home)
	_panels(home)
	_icons(home)
	_panel_style(home)
	_play(home)
	_profile(home)
	_currency(home)
	_gift_track(home)
	_nav_ad(home)
	await _ad_collapse(home)
	await _daily_modal(home)
	r[0].free()
	await _settings_modal()
	_world_seam()
	await _matrix()
	_historical()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _home(size: Vector2i, tag: String, insets := [0, 0, 0, 0]) -> Array:
	var p := "user://m42_v04_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var app = AppState.new(p)
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	home.get_region("SafeAreaRoot").set_synthetic_insets(insets[0], insets[1], insets[2], insets[3])
	for _i in range(8):
		await process_frame
	return [sub, home]

func _drawn_paths(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "", true, false):
		var t = null
		if n is TextureRect:
			t = n.texture
		elif n is Button:
			t = n.icon
		if t != null and (n as CanvasItem).is_visible_in_tree():
			out.append(t.resource_path)
	return out

func _world_identity() -> void:
	print("[world asset identity]")
	var img := Image.load_from_file(ProjectSettings.globalize_path(WORLD_PATH))
	_ok(img != null and img.get_size() == Vector2i(1080, 2160), "World 01 is exactly 1080x2160 (%s)" % str(img.get_size() if img else null))
	_ok(FileAccess.get_sha256(WORLD_PATH) == WORLD_SHA, "World 01 SHA-256 is the owner-approved %s" % WORLD_SHA)
	_ok(FileAccess.get_file_as_bytes(WORLD_PATH) == FileAccess.get_file_as_bytes(WORLD_SRC), "promoted final bytes == owner-inbox source bytes")
	_complete("world_asset_identity")

func _binds(home) -> void:
	print("[world binds through lifecycle]")
	var m = V.load_manifest()
	var entry: Dictionary = {}
	for a in m["assets"]:
		if a["slug"] == "world_01_whispering_park_background":
			entry = a
	_ok(entry.get("id") == "HOME-120" and entry.get("status") == "APPROVED" and entry.get("approved_sha256") == WORLD_SHA and entry.get("path") == WORLD_PATH.trim_prefix("res://"), "manifest HOME-120 APPROVED with the exact sha + final path")
	_ok(V.validate(m)["ok"], "manifest validates with HOME-120")
	var binder := HomeArtBinder.new()
	_ok(binder.state("world_01_whispering_park_background") == "APPROVED_BOUND", "HomeArtBinder gate: APPROVED_BOUND")
	var wb: TextureRect = home.get_region("WorldBackground")
	_ok(wb.texture != null and wb.texture.resource_path == WORLD_PATH and wb.is_visible_in_tree(), "WorldBackground presents HOME-120")
	var acc: Dictionary = {}
	for row in home.get_presentation_accounting():
		acc[row["id"]] = row
	_ok(acc["HOME-120"]["mode"] == "STATIC" and acc["HOME-120"]["nodes"][0]["name"] == "WorldBackground", "HOME-120 accounted STATIC on WorldBackground")
	_complete("world_binds_through_lifecycle")

func _no_duplicates(home) -> void:
	print("[no duplicate world art]")
	var baked := ["HOME-001", "HOME-002", "HOME-003", "HOME-004", "HOME-006", "HOME-007", "HOME-010", "HOME-011", "HOME-013", "HOME-014", "HOME-015", "HOME-016", "HOME-018", "HOME-019", "HOME-020", "HOME-021", "HOME-022", "HOME-023", "HOME-024"]
	var drawn := _drawn_paths(home)
	var leaked: Array = []
	for id in baked:
		if drawn.has(_paths[id]):
			leaked.append(id)
	_ok(leaked.is_empty(), "no old sky/city/street/portal/platform/prop/helper art drawn %s" % str(leaked))
	var acc: Dictionary = {}
	for row in home.get_presentation_accounting():
		acc[row["id"]] = row
	var bad: Array = []
	for id in baked:
		if not HomePresentationMap.INACTIVE_MODES.has(acc[id]["mode"]) or not (acc[id]["nodes"] as Array).is_empty():
			bad.append(id)
	_ok(bad.is_empty(), "all 19 accounted inactive (WORLD_BAKED_RETIRED / OWNER_RETIRED) with no node %s" % str(bad))
	var nodes: Array = []
	for n in ["Art_arch", "Art_arch_decor", "Art_platform_main", "Art_platform_top", "Art_helper_floor", "Art_helper_cart", "Art_helper_alt", "AreaBanner", "AreaTitle", "AreaNumber", "Layer_background.sky", "Layer_background.city_far", "Layer_background.city_mid", "Layer_background.street_foreground", "Layer_central_world_and_environment"]:
		if home.get_region(n) != null:
			nodes.append(n)
	_ok(nodes.is_empty(), "no platform / helper / portal / layered-background / live area-title nodes exist %s" % str(nodes))
	var area_text := false
	for l in home.find_children("*", "Label", true, false):
		var t := String(l.text).to_upper()
		if t.find("WHISPERING") != -1 or t.find("AREA") != -1:
			area_text = true
	_ok(not area_text, "no live WHISPERING PARK / AREA label over the baked sign")
	var tex_count := 0
	for n in home.find_children("*", "TextureRect", true, false):
		if (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path == WORLD_PATH and n.is_visible_in_tree():
			tex_count += 1
	_ok(tex_count == 1, "at 1:2 the world image is drawn exactly once (%d)" % tex_count)
	_complete("no_duplicate_world_art")

func _anchor(home) -> void:
	print("[scrubby anchor contract]")
	var w: Dictionary = home.get_world()
	var c: Dictionary = home.get_scrubby_canonical()
	var t: Dictionary = home.get_world_transform()
	_ok(w["scrubby_feet_anchor"] == Vector2(540, 1297) and w["scrubby_safe_box"] == Rect2(353, 779, 374, 518), "catalog contract feet (540,1297) / safe box 353..727 x 779..1297")
	_ok(absf(c["center_x"] - 540.0) < 0.01 and absf(c["feet_y"] - 1297.0) < 0.01, "visible centre X = 540, visible soles Y = 1297 (%.2f, %.2f)" % [c["center_x"], c["feet_y"]])
	var vr: Rect2 = c["visible_rect"]
	var box: Rect2 = w["scrubby_safe_box"]
	var v04_vis := Rect2(Vector2(540.0 - box.size.x * 0.5, 1297.0 - (1318.0 - 7.0) * c["k_v04"]), Vector2(box.size.x, 1327.0 * c["k_v04"]))
	_ok(v04_vis.position.x >= box.position.x - 0.01 and v04_vis.end.x <= box.end.x + 0.01 and v04_vis.position.y >= box.position.y - 0.01, "the V04 base fit stays inside the safe box (V05 enlarges it about the soles)")
	_ok(vr.end.y - 1297.0 <= 7.0, "only the brush bristles reach below the soles line (%.1f px)" % (vr.end.y - 1297.0))
	_ok(HomeScreenScript.SCRUBBY_FEET_Y == 1318.0 and HomeScreenScript.SCRUBBY_VISIBLE_BBOX == Rect2(27, 7, 1130, 1327), "documented HOME-026 visible-feet offset (soles at 1318 of 1358; visible bbox 27,7 1130x1327)")
	var sc: TextureRect = home.get_region("Art_scrubby")
	var feet_screen: Vector2 = home.world_to_screen(Vector2(540, 1297))
	var k: float = c["k"] * t["scale"]
	_ok(absf(sc.position.y + HomeScreenScript.SCRUBBY_FEET_Y * k - feet_screen.y) < 0.5, "on screen the soles sit on the mapped anchor")
	var sign: Rect2 = w["baked_sign_rect"]
	_ok(not vr.intersects(sign), "Scrubby does not cover the baked sign")
	var bot_hit := false
	for b in w["helper_bot_rects"]:
		if vr.intersects(b):
			bot_hit = true
	_ok(not bot_hit, "Scrubby does not cover the baked helper bots")
	_ok(home.get_region("Art_scrubby").get_parent() == home.get_region("Layer_characters") and home.get_region("Layer_characters").get_index() > home.get_region("WorldBackground").get_index(), "Scrubby is a separate layer above the world")
	_complete("scrubby_anchor_contract")

func _names(c: Node) -> Array:
	var out: Array = []
	for n in c.get_children():
		out.append(String(n.name))
	return out

func _panels(home) -> void:
	print("[four panels]")
	_ok(_names(home.get_region("LeftShortcutColumn")) == ["Shortcut_shop", "Shortcut_collection"], "left = SHOP, COLLECTION")
	_ok(_names(home.get_region("RightShortcutColumn")) == ["Shortcut_tasks", "Shortcut_daily"], "right = TASKS, DAILY")
	var all: Array = home.find_children("Shortcut_*", "Button", true, false)
	_ok(all.size() == 4, "exactly four Home shortcut panels (%d)" % all.size())
	var gone: Array = []
	for id in ["win_streak", "gift_bar", "no_ads", "cards_exchange"]:
		if home.get_region("Shortcut_" + id) != null:
			gone.append(id)
	_ok(gone.is_empty(), "WIN STREAK / GIFTS / NO ADS / CARDS EXCHANGE panels removed %s" % str(gone))
	var app = home.get_app_state()
	_ok(app.economy.gift != null and app.economy.exchange != null and app.economy.streak != null, "their services still exist")
	_ok(not home.get_region("Shortcut_daily").disabled and home.get_region("Shortcut_shop").disabled and home.get_region("Shortcut_collection").disabled and home.get_region("Shortcut_tasks").disabled, "DAILY live; SHOP / COLLECTION / TASKS remain future-disabled seams")
	_complete("four_panels")

func _icons(home) -> void:
	print("[panel icons]")
	var d: Dictionary = {}
	for id in ["shop", "collection", "tasks", "daily"]:
		var b = home.get_region("Shortcut_" + id)
		var tex: Texture2D = home.get_region("ShortcutIcon_" + id).texture
		var a := float(tex.get_width()) / float(tex.get_height())
		var v03 := Vector2(V03_ICON_BOX.y * a, V03_ICON_BOX.y) if V03_ICON_BOX.y * a <= V03_ICON_BOX.x else Vector2(V03_ICON_BOX.x, V03_ICON_BOX.x / a)
		d[id] = {"now": b.get_icon_draw_size(), "v03": v03, "rect": home.get_region("ShortcutIcon_" + id).size}
	_ok(d["shop"]["now"].x > d["shop"]["v03"].x * 1.15 and d["collection"]["now"].x > d["collection"]["v03"].x * 1.15, "SHOP / COLLECTION icons enlarged vs V03 (%s / %s)" % [str(d["shop"]), str(d["collection"])])
	_ok(d["tasks"]["now"].is_equal_approx(d["tasks"]["v03"]) and d["daily"]["now"].is_equal_approx(d["daily"]["v03"]), "TASKS / DAILY icons keep the V03 size (%s / %s)" % [str(d["tasks"]), str(d["daily"])])
	var ok := true
	for id in d:
		ok = ok and (d[id]["rect"] as Vector2).is_equal_approx(d[id]["now"])
	_ok(ok, "icon nodes are sized to their drawn size")
	_complete("panel_icons")

func _panel_style(home) -> void:
	print("[panel style and margin]")
	var vp: Vector2 = home.get_viewport_rect().size
	var sizes := {}
	var alpha_ok := true
	var margin_ok := true
	for id in ["shop", "collection", "tasks", "daily"]:
		var b: Button = home.get_region("Shortcut_" + id)
		sizes[b.size] = true
		var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
		alpha_ok = alpha_ok and sb != null and sb.bg_color.a >= 0.40 and sb.bg_color.a <= 0.48 and sb.border_width_left >= 2 and sb.border_width_left <= 3
		var r: Rect2 = b.get_global_rect()
		margin_ok = margin_ok and r.position.x >= 20.0 and vp.x - r.end.x >= 20.0
	_ok(sizes.size() == 1, "one panel size system for all four (%s)" % str(sizes.keys()))
	_ok(sizes.keys()[0].x <= 226.0 and sizes.keys()[0].y < 220.0, "panels smaller than V03 cards (226 x 220)")
	_ok(alpha_ok, "V05 translucent glass body (alpha 0.40..0.48) with 2-3 px outline")
	_ok(margin_ok, "visible outer margin from the screen edges (>= 20 px)")
	var sc: Rect2 = home.get_region("Art_scrubby").get_global_rect()
	var c: Dictionary = home.get_scrubby_canonical()
	var t: Dictionary = home.get_world_transform()
	var vis := Rect2((c["visible_rect"] as Rect2).position * t["scale"] + t["offset"], (c["visible_rect"] as Rect2).size * t["scale"])
	var hit: Array = []
	for id in ["shop", "collection", "tasks", "daily"]:
		var r: Rect2 = home.get_region("Shortcut_" + id).get_global_rect()
		if r.intersects(vis):
			hit.append(id)
		for bot in home.get_world()["helper_bot_rects"]:
			if r.intersects(Rect2(home.world_to_screen(bot.position), bot.size * t["scale"])):
				hit.append(id + ":bot")
	_ok(hit.is_empty(), "panels cover neither Scrubby nor the baked helper bots %s" % str(hit))
	_complete("panel_style_and_margin")

func _play(home) -> void:
	print("[play standalone]")
	var play: Button = home.get_region("PlayButton")
	var vp: Vector2 = home.get_viewport_rect().size
	_ok(home.get_region("ActionRow") == null, "V03 SHOP | PLAY | CARDS row retired")
	_ok(absf(play.get_global_rect().get_center().x - vp.x * 0.5) < 1.0, "PLAY centred (%.1f)" % play.get_global_rect().get_center().x)
	_ok(absf(play.size.x - V03_PLAY.x) < 1.0 and play.size.y >= V03_PLAY.y and play.size.y <= V03_PLAY.y + 10.0, "V03 Play size kept (%s)" % str(play.size))
	_ok(home.get_region("PlayTriangle") != null and not (home.get_region("PlayTriangle") is TextureRect), "native white triangle kept")
	_ok(play.text == UiText.t("HOME_PLAY") and home.get_region("PlaySubtitle").text == UiText.t("HOME_START_LEVEL", [1]), "live PLAY + frontier subtitle")
	_ok(not _drawn_paths(home).has(_paths["HOME-078"]), "HOME-078 stays retired")
	var status: Label = home.get_region("StatusLabel")
	_ok(status.get_parent() == play, "status pill floats on the CTA (never resizes the track row)")
	_complete("play_standalone")

func _profile(home) -> void:
	print("[profile]")
	var frame: Control = home.get_region("ProfileAvatarFrame")
	var portrait: Control = home.get_region("ProfilePortrait")
	var f: Rect2 = frame.get_global_rect()
	var p: Rect2 = portrait.get_global_rect()
	var vis_bottom := p.position.y + p.size.y * HomeScreenScript.PORTRAIT_VIS_BOTTOM
	_ok(absf(vis_bottom - (f.position.y + f.size.y * HomeScreenScript.FRAME_INNER_BOTTOM)) < 1.0, "portrait's visible bottom rests on the frame's inner bottom")
	_ok(portrait.get_index() > frame.get_index() and p.position.y + p.size.y * HomeScreenScript.PORTRAIT_VIS_TOP < f.position.y, "portrait in front of the frame and popping above it")
	var vis_w := p.size.x * (1011.0 - 265.0) / 1254.0
	_ok(vis_w < f.size.x * 0.85, "frame sides stay visible around the portrait body")
	var card: Control = home.get_region("ProfileCard")
	_ok(card.size.x <= 560.0, "profile card stays narrow (%.0f)" % card.size.x)
	var parts = home.get_region("ProfileBotParts")
	_ok(parts.bar.size.y >= V03_BAR_H * 1.6, "Bot Parts bar thicker than V03 (%.0f vs %.0f)" % [parts.bar.size.y, V03_BAR_H])
	_ok(parts.caption.get_parent() == parts.bar and parts.caption.text == "0/250" and parts.caption.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and absf(parts.caption.get_global_rect().get_center().y - parts.bar.get_global_rect().get_center().y) < 1.0, "only N/250, centred inside the bar")
	_ok(home.get_region("ProfileRankBadge").get_parent() == parts.get_parent() and home.get_region("ProfileLevel").text == "1", "level badge attached on the same row, live")
	_ok(home.get_region("MenuButton") == null, "no top Settings/menu")
	_complete("profile")

func _currency(home) -> void:
	print("[currency hud]")
	for id in ["ScrubBucksChip", "HeartsChip"]:
		var chip = home.get_region(id)
		var drawn: Vector2 = chip.icon.size
		_ok(chip.icon.texture != null and drawn.y >= 88.0 and chip.icon.get_index() > -1, "%s icon enlarged (%s)" % [id, str(drawn)])
		_ok(drawn.y > chip.size.y and chip.icon.get_parent() == chip.icon_slot and chip.icon_slot.size.y < drawn.y, "%s icon overhangs / sits in front of its chip panel (drawn %.0f > chip %.0f)" % [id, drawn.y, chip.size.y])
	var got: Array = []
	home.scrub_bucks_purchase_requested.connect(func(): got.append("sb"))
	home.hearts_purchase_requested.connect(func(): got.append("hearts"))
	var app = home.get_app_state()
	var before: Dictionary = app.economy.snapshot()
	for n in ["ScrubBucksPlus", "HeartsPlus"]:
		var b: Button = home.get_region(n)
		_ok(b.is_visible_in_tree() and b.text == "+" and b.size.x >= 88 and b.size.y >= 88, "%s visible, >= 88 px" % n)
		b.pressed.emit()
	_ok(got == ["sb", "hearts"] and app.economy.snapshot() == before, "(+) buttons emit intents only; economy untouched")
	var sb_line: Rect2 = home.get_region("ScrubBucksChip").get_global_rect()
	_ok(home.get_region("ScrubBucksPlus").get_global_rect().get_center().x > sb_line.end.x - 1.0, "(+) attached on the right end of its pill")
	_complete("currency_hud")

func _gift_track(home) -> void:
	print("[gift and track]")
	var meter = home.get_region("GiftMeterBar")
	var ratio := RegEx.create_from_string("^[0-9,]+/[0-9,]+$")
	_ok(ratio.search(meter.caption.text) != null and meter.caption.text.ends_with("/1,000"), "Gift Meter shows only N/1000 (%s)" % meter.caption.text)
	_ok(home.get_region("GiftEmblem").size.x >= 112 and home.get_region("GiftCrate").size.x >= 112, "emblem / crate modestly enlarged")
	var vals: Array = []
	for i in range(1, 6):
		vals.append(home.get_region("TrackStep%d" % i).text)
	_ok(vals == ["1", "5", "10", "25", "100"], "track values only 1/5/10/25/100 (%s)" % str(vals))
	var bad: Array = []
	for l in home.get_region("WinStreakRewardTrack").find_children("*", "Label", true, false):
		var t := String(l.text)
		if t.find("+") != -1 or t.to_upper().find("WIN") != -1:
			bad.append(t)
	_ok(bad.is_empty() and not _drawn_paths(home.get_region("WinStreakRewardTrack")).has(_paths["HOME-087"]), "no '+', no WIN copy, no per-step SB icon")
	_ok(home.get_region("WinStreakRewardTrack").size.y < 160.0, "track stays thin (%.0f)" % home.get_region("WinStreakRewardTrack").size.y)
	_complete("gift_and_track")

func _nav_ad(home) -> void:
	print("[nav and ad slot]")
	var nav: Control = home.get_region("BottomNav")
	var ad: Control = home.get_region("AdBannerSlot")
	var track: Control = home.get_region("WinStreakRewardTrack")
	var vp: Vector2 = home.get_viewport_rect().size
	_ok(track.get_global_rect().end.y <= nav.get_global_rect().position.y and nav.get_global_rect().end.y <= ad.get_global_rect().position.y + 0.5, "order: track -> nav -> ad slot")
	_ok(absf(ad.get_global_rect().end.y - vp.y) < 1.0 and ad.size.y >= 96.0 and ad.size.y <= 160.0, "ad slot is the screen-bottom element (%.0f px tall)" % ad.size.y)
	_ok(home.get_ad_mount() != null and home.get_ad_mount().get_parent() == ad and home.get_ad_mount().get_child_count() == 0, "empty AdMount seam (no fake ad content)")
	var labels := ad.find_children("*", "Label", true, false)
	_ok(labels.is_empty(), "no fake ad text")
	var wb: Control = home.get_region("Background")
	_ok(wb.clip_contents and absf(wb.get_global_rect().end.y - ad.get_global_rect().position.y) < 1.0, "world canvas is clipped at the ad slot top (no world in the ad slot)")
	_ok(_names(nav.get_child(0)) == ["Nav_events", "Nav_robots", "Nav_home", "Nav_leaderboard", "SettingsButton"] and home.get_region("Nav_home").button_pressed and home.get_region("Nav_leaderboard").text == "RANKS", "five tabs, HOME selected, RANKS kept")
	_complete("nav_and_ad_slot")

func _ad_collapse(home) -> void:
	print("[ad slot collapse]")
	var nav: Control = home.get_region("BottomNav")
	var vp: Vector2 = home.get_viewport_rect().size
	var nav_before: float = nav.get_global_rect().end.y
	home.set_ad_slot_enabled(false)
	for _i in range(4):
		await process_frame
	_ok(not home.get_region("AdBannerSlot").visible and absf(nav.get_global_rect().end.y - vp.y) < 1.0 and nav.get_global_rect().end.y > nav_before, "collapsed: nav moves down to the screen bottom")
	_ok(absf(home.get_region("Background").size.y - vp.y) < 1.0, "collapsed: world canvas extends to the bottom (behind the dock)")
	home.set_ad_slot_enabled(true)
	for _i in range(4):
		await process_frame
	_ok(absf(nav.get_global_rect().end.y - nav_before) < 1.0 and home.is_ad_slot_enabled(), "re-enabled: layout restored")
	_complete("ad_slot_collapse")

func _hidden(home) -> bool:
	return not home.get_region("HomeActionLayer").is_visible_in_tree() and not home.get_region("ScrubBucksPlus").is_visible_in_tree() and not home.get_region("HeartsPlus").is_visible_in_tree()

func _daily_modal(home) -> void:
	print("[daily modal]")
	var before: Rect2 = home.get_region("PlayButton").get_global_rect()
	var p = home.open_popup("daily")
	await process_frame
	_ok(p.visible and home.is_modal_active() and _hidden(home), "Daily open: HomeActionLayer + (+) buttons hidden")
	var leak: Array = []
	for b in home.find_children("*", "BaseButton", true, false):
		if (b as Control).is_visible_in_tree() and not p.is_ancestor_of(b):
			leak.append(b.name)
	_ok(leak.is_empty(), "no Home button visible/clickable behind Daily %s" % str(leak))
	_ok(home.get_region("ActionHost").is_visible_in_tree() and home.get_region("AdBannerSlot").is_visible_in_tree(), "layout slot kept; persistent ad slot stays")
	_ok(home.close_top_popup() and not home.is_modal_active(), "back closes the top modal")
	for _i in range(3):
		await process_frame
	_ok(not _hidden(home) and home.get_region("HomeActionLayer").visible and home.get_region("PlayButton").get_global_rect().is_equal_approx(before), "exact Home restored")
	_complete("daily_modal")

func _settings_modal() -> void:
	print("[settings modal]")
	var path := "user://m42_v04_root_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var home = root.get_home()
	var panel = root.get_settings_panel()
	home.get_region("Nav_settings").pressed.emit()
	await process_frame
	_ok(panel.visible and _hidden(home), "Settings open: action layer hidden")
	_ok(root.handle_back() != "" and not panel.visible and not _hidden(home), "back closes Settings and restores Home")
	root.free()
	MainScript.boot_save_path_override = ""
	_complete("settings_modal")

func _world_seam() -> void:
	print("[world seam]")
	var c: Dictionary = HomeWorldCatalog.load_catalog()
	_ok(c.get("default_world") == "world_01" and (c["worlds"] as Dictionary).keys() == ["world_01"], "catalog: world_01 default only (no speculative worlds)")
	var txt := FileAccess.get_file_as_string(HomeWorldCatalog.PATH).to_lower()
	_ok(txt.find("level_range") == -1 and txt.find("\"levels\"") == -1 and txt.find("world_02") == -1, "no level ranges / World 02+ invented")
	var w := HomeWorldCatalog.world("world_01")
	_ok(w["background_slug"] == "world_01_whispering_park_background" and w["canvas"] == Vector2(1080, 2160), "world_id -> background slug + canvas + anchor contract")
	_ok(HomeWorldCatalog.world("world_99").is_empty(), "unknown world -> empty (no fallback invention)")
	_complete("world_seam")

func _matrix() -> void:
	print("[responsive matrix]")
	for size in MATRIX:
		for insets in [[0, 0, 0, 0], [0, 132, 0, 96]]:
			var r = await _home(size, "mx", insets)
			var home = r[1]
			var safe := Rect2(Vector2(insets[0], insets[1]), Vector2(size) - Vector2(insets[0] + insets[2], insets[1] + insets[3]))
			var bad: Array = []
			for b in home.find_children("*", "BaseButton", true, false):
				var rr: Rect2 = (b as Control).get_global_rect()
				if rr.size.x < 87.5 or rr.size.y < 87.5 or not safe.grow(0.5).encloses(rr):
					bad.append(b.name)
			var t: Dictionary = home.get_world_transform()
			var wb: Rect2 = home.get_region("WorldBackground").get_global_rect()
			if absf(wb.size.x / wb.size.y - 0.5) > 0.001:
				bad.append("world_stretched")
			var canvas: Rect2 = home.get_region("Background").get_global_rect()
			# V05: the world is locked to its V04 transform; the ad-slot clip may sit lower
			# than the image bottom only behind the opaque nav dock.
			var covered: bool = wb.position.y <= canvas.position.y + 0.5 and wb.end.y >= home.get_region("BottomNav").get_global_rect().position.y - 0.5
			if not covered:
				bad.append("world_not_covering_canvas")
			var play: Rect2 = home.get_region("PlayButton").get_global_rect()
			var plat_bottom: float = HomeScreenScript.PLATFORM_BOTTOM_Y * t["scale"] + t["offset"].y
			if plat_bottom > play.position.y:
				bad.append("platform_under_play")
			var c: Dictionary = home.get_scrubby_canonical()
			var feet_screen: float = home.world_to_screen(Vector2(540, 1297)).y
			var sc: TextureRect = home.get_region("Art_scrubby")
			if absf(sc.position.y + HomeScreenScript.SCRUBBY_FEET_Y * c["k"] * t["scale"] - feet_screen) > 0.5:
				bad.append("feet_off_anchor")
			for id in ["shop", "collection", "tasks", "daily"]:
				var pr: Rect2 = home.get_region("Shortcut_" + id).get_global_rect()
				for bot in home.get_world()["helper_bot_rects"]:
					if pr.intersects(Rect2(home.world_to_screen(bot.position), bot.size * t["scale"])):
						bad.append(id + "_covers_bot")
				if home.get_region("ShortcutIcon_" + id).get_global_rect().position.y < home.get_region("GiftMeter").get_global_rect().end.y:
					bad.append(id + "_icon_into_gift_meter")
			var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
			if absf(ad.end.y - safe.end.y) > 1.0:
				bad.append("ad_not_at_safe_bottom")
			_ok(bad.is_empty(), "%s insets=%s: touch >= 88 in safe area, world uniform + covering, platform above PLAY, feet on anchor, panels clear of bots/meter, ad at bottom %s" % [str(size), str(insets), str(bad)])
			r[0].free()
			await process_frame
	_complete("responsive_matrix")

func _historical() -> void:
	print("[historical assets intact]")
	var m = V.load_manifest()
	var bad: Array = []
	var n := 0
	for a in m["assets"]:
		if a["status"] == "APPROVED" and a.has("path"):
			n += 1
			if FileAccess.get_sha256("res://" + String(a["path"])) != String(a["approved_sha256"]):
				bad.append(a["id"])
	_ok(n == 51 and bad.is_empty(), "all 51 APPROVED entries (incl. retired history) match their pinned sha %s" % str(bad))
	_complete("historical_assets_intact")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fail += 1
		print("  FAIL: ", msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: ", missing)
	print("m42_home_v04: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
