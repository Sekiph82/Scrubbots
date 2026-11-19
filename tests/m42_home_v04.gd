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
const C002 = preload("res://tests/m42_c002_scrubby_scale.gd")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const HomeWorldCatalog = preload("res://scripts/ui/home/home_world_catalog.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

## SB-HOME-BG-2026-11-16: the Home background is the owner plaza file below (941x1672,
## HOME-124); the V04 1080x2160 HOME-120 file stays on disk, retired and never loaded; the
## M28 HOME-121 file was deleted (SB-ASSET-PURGE-2026-11-17).
const WORLD_PATH := "res://assets/ui/final/home/background/home_background_plaza.png"
const WORLD_SHA := "0aa7463b12cd156883aeb8d9b91f59632bbe6899ce4a61ad74a6f77026f9cde3"
const WORLD_SLUG := "home_background_plaza"
const OLD_WORLD_PATH := "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"
const M28_WORLD_PATH := "res://assets/ui/final/home/background/home_background.png"
const KEYED_STILL_PATH := "res://assets/ui/final/home/videos/home_scrubby_still_keyed.png"
## SB-HOME-VIDEO-MAGENTA-2026-11-17: + bow, full_turn, sweep from the owner's magenta Flow videos.
const KEYED_GESTURES := ["wave", "turn", "bow", "full_turn", "sweep"]
## SB-HOME-VIDEO-MAGENTA-2-2026-11-17: wave/turn re-made from the magenta Flow videos; the job-160 difference mattes are gone.
const OLD_MATTE_SHAS := ["a8b14736c3dc2cb3854ea605165ca630db6b3450769271915020a44bf30187f0", "679d7eaf83460fa5279bd0663357123b15b495137c759df85f911a524f3b6467"]
const FEET := Vector2(470, 1240)
const SAFE_BOX := Rect2(305, 620, 330, 620)
const WORLD_ASPECT := 941.0 / 1672.0
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
	# Frozen clock: Heart regen / 2x windows are wall-clock state; a real clock could tick them between
	# two economy snapshots of one case (currency_hud "economy untouched" was flaky).
	var app = AppState.new(p, func(): return 1790000000, func(): return 20000)
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
	_ok(img != null and img.get_size() == Vector2i(941, 1672), "Home background is exactly 941x1672 (%s)" % str(img.get_size() if img else null))
	_ok(FileAccess.get_sha256(WORLD_PATH) == WORLD_SHA, "Home background SHA-256 is the owner plaza %s" % WORLD_SHA)
	_ok(FileAccess.file_exists(OLD_WORLD_PATH), "retired HOME-120 file is kept on disk (never deleted or overwritten)")
	_ok(not FileAccess.file_exists(M28_WORLD_PATH), "retired HOME-121 file was deleted (SB-ASSET-PURGE-2026-11-17)")
	_complete("world_asset_identity")

func _binds(home) -> void:
	print("[world binds through lifecycle]")
	var m = V.load_manifest()
	var entry: Dictionary = {}
	for a in m["assets"]:
		if a["slug"] == WORLD_SLUG:
			entry = a
	_ok(entry.get("id") == "HOME-124" and entry.get("status") == "APPROVED" and entry.get("approved_sha256") == WORLD_SHA and entry.get("path") == WORLD_PATH.trim_prefix("res://"), "manifest HOME-124 APPROVED with the exact sha + final path")
	_ok(V.validate(m)["ok"], "manifest validates with HOME-124")
	var binder := HomeArtBinder.new()
	_ok(binder.state(WORLD_SLUG) == "APPROVED_BOUND", "HomeArtBinder gate: APPROVED_BOUND")
	var wb: TextureRect = home.get_region("WorldBackground")
	_ok(wb.texture != null and wb.texture.resource_path == WORLD_PATH and wb.is_visible_in_tree(), "WorldBackground presents HOME-124 (the owner plaza file)")
	var acc: Dictionary = {}
	for row in home.get_presentation_accounting():
		acc[row["id"]] = row
	_ok(acc["HOME-124"]["mode"] == "STATIC" and acc["HOME-124"]["nodes"][0]["name"] == "WorldBackground" and acc["HOME-120"]["mode"] == "OWNER_RETIRED" and (acc["HOME-120"]["nodes"] as Array).is_empty(), "HOME-124 accounted STATIC on WorldBackground; replaced HOME-120 is OWNER_RETIRED with no node")
	var retired_ok := true
	for id in ["HOME-121", "HOME-123"]:
		retired_ok = retired_ok and acc[id]["mode"] == "OWNER_RETIRED" and (acc[id]["nodes"] as Array).is_empty()
	_ok(retired_ok, "SB-HOME-BG-2026-11-16: HOME-121 + the baked-background HOME-123 video still stay retired")
	# SB-HOME-VIDEO-2026-11-17: the keyed set (Scrubby on magenta) is bound over HOME-124.
	var hero = home.get_region("HomeScrubbyHero")
	var still: TextureRect = home.get_region("WorldStill")
	var video: VideoStreamPlayer = home.get_region("WorldVideo")
	var keyed := still.material is ShaderMaterial and (still.material as ShaderMaterial).shader.resource_path.ends_with("chroma_key_magenta.gdshader") and video.material == still.material
	_ok(acc["HOME-125"]["mode"] == "STATIC" and acc["HOME-125"]["nodes"][0]["name"] == "WorldStill" and still.texture != null and still.texture.resource_path == KEYED_STILL_PATH and still.is_visible_in_tree(), "HOME-125 keyed still bound on WorldStill and shown")
	_ok(hero.has_video() and hero.get_streams().keys() == KEYED_GESTURES and keyed and not home.get_region("HeroFocusShade").visible and home.get_region("Art_scrubby").self_modulate.a == 0.0, "keyed video set bound (%s), still + player chroma-keyed, shade + frame Scrubby off" % str(hero.get_streams().keys()))
	_ok(still.get_global_rect().is_equal_approx(wb.get_global_rect()) and video.get_global_rect().is_equal_approx(wb.get_global_rect()), "keyed still + video share the WorldBackground rect (Scrubby where the frame-set Scrubby stands)")
	var pins_ok := true
	for g in KEYED_GESTURES:
		var v: Dictionary = m["video_sets"]["home_scrubby_videos_keyed_v2"]["videos"][g]
		pins_ok = pins_ok and FileAccess.get_sha256("res://" + String(v["path"])) == String(v["sha256"]) and String(v["path"]).ends_with("_keyed.ogv") and hero.get_streams()[g] is VideoStreamTheora
	_ok(pins_ok, "all %d keyed videos pinned (sha256 == bytes) and bound as Theora streams" % KEYED_GESTURES.size())
	var vids: Dictionary = m["video_sets"]["home_scrubby_videos_keyed_v2"]["videos"]
	_ok(not OLD_MATTE_SHAS.has(String(vids["wave"]["sha256"])) and not OLD_MATTE_SHAS.has(String(vids["turn"]["sha256"])), "wave/turn are the magenta Flow re-encodes, not the job-160 difference mattes")
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
		if l.name in ["HomeAreaTitle", "HomeAreaNumber"]:
			continue
		var t := String(l.text).to_upper()
		if t.find("WHISPERING") != -1 or t.find("AREA") != -1:
			area_text = true
	_ok(not area_text, "no stray WHISPERING PARK / AREA text outside the native area label")
	# SB-HOME-BG-2026-11-16: the area name is native text (no longer baked into the art).
	var title: Label = home.get_region("HomeAreaTitle")
	var number: Label = home.get_region("HomeAreaNumber")
	_ok(title.text == "WHISPERING PARK" and number.text == UiText.t("HOME_AREA_NUMBER", [1]) and title.is_visible_in_tree() and number.is_visible_in_tree(), "native area label: %s / %s" % [title.text, number.text])
	_ok(title.get_theme_constant("outline_size") >= 9 and home.get_region("HomeAreaLabel").get_parent() == home.get_region("Layer_characters"), "area label outlined, in the world character layer (below all live UI)")
	var prev_locale := UiText.locale
	UiText.locale = "tr"
	home.refresh()
	_ok(title.text == "FISILTILI PARK" and number.text == "BÖLGE 1" and _area_fits(home), "TR area label: %s / %s" % [title.text, number.text])
	# Owner 2026-11-17: the title follows the current world's name (worlds_v1: L151 = world 2).
	var app = home.get_app_state()
	var lvl: int = app.progression.current_level()
	app.progression.debug_set_current_level(151)
	home.refresh()
	_ok(title.text == "KÖPÜK MAHALLESİ" and number.text == "BÖLGE 2" and _area_fits(home), "TR world 2 area label: %s / %s" % [title.text, number.text])
	UiText.locale = prev_locale
	home.refresh()
	_ok(title.text == "BUBBLE DISTRICT" and number.text == "AREA 2" and _area_fits(home), "world 2 area label: %s / %s" % [title.text, number.text])
	app.progression.debug_set_current_level(lvl)
	home.refresh()
	_ok(title.text == "WHISPERING PARK" and number.text == "AREA 1" and _area_fits(home), "back on world 1: %s / %s" % [title.text, number.text])
	var tex_count := 0
	for n in home.find_children("*", "TextureRect", true, false):
		if (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path == WORLD_PATH and n.is_visible_in_tree() and not String(n.name).begins_with("WorldEdge"):
			tex_count += 1
	_ok(tex_count == 1, "at 1:2 the world image is drawn exactly once, besides its SB-TF-03 mirrored floor continuation below (%d)" % tex_count)
	_complete("no_duplicate_world_art")

## Both area label lines are one line and their text fits the label width.
func _area_fits(home) -> bool:
	for n in ["HomeAreaTitle", "HomeAreaNumber"]:
		var l: Label = home.get_region(n)
		if l.get_line_count() != 1 or l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x > l.size.x + 0.5:
			return false
	return true

func _anchor(home) -> void:
	print("[scrubby anchor contract]")
	var w: Dictionary = home.get_world()
	var c: Dictionary = home.get_scrubby_canonical()
	var t: Dictionary = home.get_world_transform()
	_ok(w["scrubby_feet_anchor"] == FEET and w["scrubby_safe_box"] == SAFE_BOX, "catalog contract feet (470,1240) / safe box 305..635 x 620..1240")
	_ok(absf(c["center_x"] - FEET.x) < 0.01 and absf(c["feet_y"] - FEET.y) < 0.01, "visible centre X = 470, visible soles Y = 1240 (%.2f, %.2f)" % [c["center_x"], c["feet_y"]])
	var vr: Rect2 = c["visible_rect"]
	var box: Rect2 = w["scrubby_safe_box"]
	var v04_vis := Rect2(Vector2(FEET.x - box.size.x * 0.5, FEET.y - (1318.0 - 7.0) * c["k_v04"]), Vector2(box.size.x, 1327.0 * c["k_v04"]))
	_ok(v04_vis.position.x >= box.position.x - 0.01 and v04_vis.end.x <= box.end.x + 0.01 and v04_vis.position.y >= box.position.y - 0.01, "the V04 base fit stays inside the safe box (V05 enlarges it about the soles)")
	# bristles: texture rows 1318..1334 (16 texels) below the soles, scaled by k (M42-C002 1.612)
	_ok(vr.end.y - FEET.y <= 16.0 * float(c["k"]) + 0.01, "only the brush bristles reach below the soles line (%.1f px <= 16 texels x k)" % (vr.end.y - FEET.y))
	_ok(HomeScreenScript.SCRUBBY_FEET_Y == 1318.0 and HomeScreenScript.SCRUBBY_VISIBLE_BBOX == Rect2(27, 7, 1130, 1327), "documented HOME-026 visible-feet offset (soles at 1318 of 1358; visible bbox 27,7 1130x1327)")
	var sc: TextureRect = home.get_region("Art_scrubby")
	var feet_screen: Vector2 = home.world_to_screen(FEET)
	var k: float = c["k"] * t["scale"]
	_ok(absf(sc.position.y + HomeScreenScript.SCRUBBY_FEET_Y * k - feet_screen.y) < 0.5, "on screen the soles sit on the mapped anchor")
	var sign: Rect2 = w["area_label_rect"]
	_ok(not vr.intersects(sign), "Scrubby does not cover the area label band")
	# M42-C002 (owner lock 1.612): the hero bbox edges reach <= 47 canvas px into each bot
	# rect; pixel-level only the brush bristles enter the left one, the right one gets no
	# hero pixel (tests/m42_c002_scrubby_scale.gd).
	var bots: Array = w["helper_bot_rects"]
	_ok(vr.position.x >= (bots[0] as Rect2).end.x - 47.0 and vr.end.x <= (bots[1] as Rect2).position.x + 47.0, "helper bots: bbox intrusion left %.1f / right %.1f <= 47 canvas px" % [(bots[0] as Rect2).end.x - vr.position.x, vr.end.x - (bots[1] as Rect2).position.x])
	_ok(home.get_region("Art_scrubby").get_parent() == home.get_region("Layer_characters") and home.get_region("Layer_characters").get_index() > home.get_region("WorldBackground").get_index(), "Scrubby is a separate layer above the world")
	_complete("scrubby_anchor_contract")

func _names(c: Node) -> Array:
	var out: Array = []
	for n in c.get_children():
		out.append(String(n.name))
	return out

func _panels(home) -> void:
	print("[four panels -> SB-TF-03 activity buttons]")
	_ok(_names(home.get_region("LeftShortcutColumn")) == ["RewardedAdsButton", "Shortcut_tasks"], "left = REWARDED ADS, TASKS (SB-TF-11: Daily lives on Profile Login Days)")
	_ok(_names(home.get_region("RightShortcutColumn")).is_empty(), "right = the Event buttons (none on a standalone L1 Home)")
	var all: Array = home.find_children("Shortcut_*", "Button", true, false)
	_ok(all.size() == 1 and home.get_region("RewardedAdsButton") != null, "exactly two activity buttons, no Shop / Collection tile (%d + Rewarded Ads)" % all.size())
	var gone: Array = []
	for id in ["win_streak", "gift_bar", "no_ads", "cards_exchange", "shop", "collection"]:
		if home.get_region("Shortcut_" + id) != null:
			gone.append(id)
	_ok(gone.is_empty(), "WIN STREAK / GIFTS / NO ADS / CARDS EXCHANGE / SHOP / COLLECTION panels removed %s" % str(gone))
	var app = home.get_app_state()
	_ok(app.economy.gift != null and app.economy.exchange != null and app.economy.streak != null, "their services still exist")
	_ok(home.get_region("Shortcut_tasks").disabled and home.get_region("RewardedAdsButton").disabled, "standalone Home: TASKS / REWARDED ADS wait for the app root destinations")
	_complete("four_panels")

func _icons(home) -> void:
	print("[panel icons]")
	var d: Dictionary = {}
	for id in ["rewarded_ads", "tasks"]:
		var b = home.get_region("RewardedAdsButton" if id == "rewarded_ads" else "Shortcut_" + id)
		var tex: Texture2D = home.get_region("ShortcutIcon_" + id).texture
		var a := float(tex.get_width()) / float(tex.get_height())
		var box := V03_ICON_BOX * HomeScreenScript.PANEL_SCALE
		var v03 := Vector2(box.y * a, box.y) if box.y * a <= box.x else Vector2(box.x, box.x / a)
		d[id] = {"now": b.get_icon_draw_size(), "v03": v03, "rect": home.get_region("ShortcutIcon_" + id).size}
	_ok(d["rewarded_ads"]["now"].is_equal_approx(d["rewarded_ads"]["v03"]) and d["tasks"]["now"].is_equal_approx(d["tasks"]["v03"]), "SB-TF-13: icons at PANEL_SCALE (0.98x) the V03 box (%s / %s)" % [str(d["rewarded_ads"]), str(d["tasks"])])
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
	for n in ["RewardedAdsButton", "Shortcut_tasks"]:
		var b: Button = home.get_region(n)
		sizes[b.size] = true
		var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
		alpha_ok = alpha_ok and sb != null and sb.bg_color.a >= 0.24 and sb.bg_color.a <= 0.27 and sb.border_width_left >= 2 and sb.border_width_left <= 3
		var r: Rect2 = b.get_global_rect()
		margin_ok = margin_ok and r.position.x >= 20.0 and vp.x - r.end.x >= 20.0
	_ok(sizes.size() == 1, "one panel size system for every activity button (%s)" % str(sizes.keys()))
	_ok(sizes.keys()[0].is_equal_approx(Vector2(206, 153)), "SB-TF-13 panels 0.98x the V06 210x156 (%s)" % str(sizes.keys()[0]))
	_ok(alpha_ok, "see-through glass body (SB-TF-03: half the V06 0.51 = 0.255) with 2-3 px outline")
	_ok(margin_ok, "visible outer margin from the screen edges (>= 20 px)")
	var sc: Rect2 = home.get_region("Art_scrubby").get_global_rect()
	var t: Dictionary = home.get_world_transform()
	# M42-C002: at 1.612 the hero's rectangular bbox corners may reach a panel over transparent
	# texels only; a panel must never cover an opaque hero pixel.
	var img: Image = (home.get_region("Art_scrubby") as TextureRect).texture.get_image()
	var hit: Array = []
	for id in ["RewardedAdsButton", "Shortcut_tasks"]:
		var r: Rect2 = home.get_region(id).get_global_rect()
		if int(C002.opaque_in(img, sc, r)["px"]) > 0:
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
	_ok(play.text == UiText.t("HOME_PLAY_LEVEL", [1]) and home.get_region("PlaySubtitle") == null, "live PLAY · LEVEL 1, no second level line (SB-TF-03)")
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
	_ok(home.get_region("ProfileRankBadge").get_parent() == parts.get_parent() and home.get_region("ProfileLevel") == null and home.get_region("ProfileRankBadge").is_ancestor_of(home.get_region("ProfileBotPartsIcon")), "SB-TF-03: badge on the same row shows the Bot Parts icon, not the level")
	_ok(home.get_region("MenuButton") == null and home.get_region("TopCurrencyHUD").is_ancestor_of(home.get_region("SettingsButton")), "no menu; SB-TF-03 Settings icon in the top HUD")
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
		_ok(b.is_visible_in_tree() and home.get_region(n + "Glyph") != null and b.size.x >= 88 and b.size.y >= 88, "%s visible '+' glyph, >= 88 px hit target" % n)
		b.pressed.emit()
	_ok(got == ["sb", "hearts"] and app.economy.snapshot() == before, "(+) buttons emit intents only; economy untouched")
	var sb_line: Rect2 = home.get_region("ScrubBucksChip").get_global_rect()
	var gx: float = home.get_region("ScrubBucksPlusGlyph").get_global_rect().get_center().x
	_ok(gx < sb_line.end.x and gx > sb_line.end.x - 80.0, "(+) glyph at the right end of its pill (V06: inside the pill)")
	_complete("currency_hud")

func _gift_track(home) -> void:
	print("[gift and track -> SB-TF-03: no win-streak strip]")
	var meter = home.get_region("GiftMeterBar")
	var ratio := RegEx.create_from_string("^[0-9,]+/[0-9,]+$")
	_ok(ratio.search(meter.caption.text) != null and meter.caption.text.ends_with("/1"), "Gift Meter shows only N/next milestone (fresh 0/1, SB-POLISH-002) (%s)" % meter.caption.text)
	_ok(home.get_region("GiftEmblem").size.x >= 112 and home.get_region("GiftCrate").size.x >= 112, "emblem / crate modestly enlarged")
	_ok(home.get_region("WinStreakRewardTrack") == null and home.find_children("Track*", "", true, false).is_empty(), "win-streak strip removed (owner 2026-11-18)")
	_ok(not _drawn_paths(home).has(_paths["HOME-086"]), "the win-streak badge (HOME-086) is drawn nowhere on Home")
	_complete("gift_and_track")

func _nav_ad(home) -> void:
	print("[nav and ad slot -> SB-TF-03: PLAY directly above the banner area]")
	var ad: Control = home.get_region("AdBannerSlot")
	var play: Control = home.get_region("PlayButton")
	var vp: Vector2 = home.get_viewport_rect().size
	_ok(home.get_region("BottomNav") == null and play.get_global_rect().end.y <= ad.get_global_rect().position.y + 0.5, "order: PLAY -> banner area (no nav)")
	_ok(absf(ad.get_global_rect().end.y - vp.y) < 1.0 and absf(ad.size.y - clampf(vp.x * 50.0 / 320.0, 72.0, 112.0)) < 1.0, "banner area is the screen-bottom element, 320x50 scaled + clamped (%.0f px tall)" % ad.size.y)
	_ok(home.get_ad_mount() != null and home.get_ad_mount().get_parent() == ad and home.get_ad_mount().get_child_count() == 0, "empty AdMount seam (no fake ad content)")
	var labels := ad.find_children("*", "Label", true, false)
	_ok(labels.is_empty(), "no fake ad text")
	var wb: Control = home.get_region("Background")
	_ok(wb.clip_contents and absf(wb.get_global_rect().end.y - ad.get_global_rect().position.y) < 1.0, "world canvas is clipped at the ad slot top (no world in the ad slot)")
	_ok(home.find_children("Nav_*", "", true, false).is_empty(), "no nav tabs")
	_complete("nav_and_ad_slot")

func _ad_collapse(home) -> void:
	print("[ad slot collapse]")
	var stack: Control = home.get_region("BottomActionStack")
	var vp: Vector2 = home.get_viewport_rect().size
	var before: float = stack.get_global_rect().end.y
	home.set_ad_slot_enabled(false)
	for _i in range(4):
		await process_frame
	_ok(not home.get_region("AdBannerSlot").visible and absf(stack.get_global_rect().end.y - vp.y) < 1.0 and stack.get_global_rect().end.y > before, "collapsed (No Ads): the PLAY stack moves down to the screen bottom")
	_ok(absf(home.get_region("Background").size.y - vp.y) < 1.0, "collapsed: world canvas extends to the bottom")
	home.set_ad_slot_enabled(true)
	for _i in range(4):
		await process_frame
	_ok(absf(stack.get_global_rect().end.y - before) < 1.0 and home.is_ad_slot_enabled(), "re-enabled: layout restored")
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
	home.get_region("SettingsButton").pressed.emit()
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
	_ok(w["background_slug"] == WORLD_SLUG and w["canvas"] == Vector2(941, 1672), "world_id -> background slug + canvas + anchor contract")
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
			if absf(wb.size.x / wb.size.y - WORLD_ASPECT) > 0.001:
				bad.append("world_stretched")
			var canvas: Rect2 = home.get_region("Background").get_global_rect()
			# V05: the world is locked to its V04 transform; SB-TF-03 (no opaque nav dock) it must
			# reach the canvas bottom (the banner-area top), directly or by its mirrored floor continuation.
			var below: Control = home.get_region("WorldEdgeBottom")
			var covered: bool = wb.position.y <= canvas.position.y + 0.5 and (wb.end.y >= canvas.end.y - 0.5 or (below.visible and below.get_global_rect().end.y >= canvas.end.y - 0.5))
			if not covered:
				bad.append("world_not_covering_canvas")
			var play: Rect2 = home.get_region("PlayButton").get_global_rect()
			var plat_bottom: float = HomeScreenScript.PLATFORM_BOTTOM_Y * t["scale"] + t["offset"].y
			if plat_bottom > play.position.y:
				bad.append("platform_under_play")
			var c: Dictionary = home.get_scrubby_canonical()
			var feet_screen: float = home.world_to_screen(FEET).y
			var sc: TextureRect = home.get_region("Art_scrubby")
			if absf(sc.position.y + HomeScreenScript.SCRUBBY_FEET_Y * c["k"] * t["scale"] - feet_screen) > 0.5:
				bad.append("feet_off_anchor")
			for id in ["rewarded_ads", "tasks"]:
				var pr: Rect2 = home.get_region("RewardedAdsButton" if id == "rewarded_ads" else "Shortcut_" + id).get_global_rect()
				for bot in home.get_world()["helper_bot_rects"]:
					if pr.intersects(Rect2(home.world_to_screen(bot.position), bot.size * t["scale"])):
						bad.append(id + "_covers_bot")
				if home.get_region("ShortcutIcon_" + id).get_global_rect().position.y < home.get_region("GiftMeter").get_global_rect().end.y:
					bad.append(id + "_icon_into_gift_meter")
			var ad: Rect2 = home.get_region("AdBannerSlot").get_global_rect()
			if absf(ad.end.y - safe.end.y) > 1.0:
				bad.append("ad_not_at_safe_bottom")
			# SB-HOME-BG-2026-11-16: the native area label sits in the sky band, one line each,
			# clear of the HUD, Gift Meter, Scrubby, PLAY and every shortcut panel.
			# Only the short 16:9 / tablet extras with a deep notch may hide it (no sky left).
			var al: Rect2 = home.get_region("HomeAreaLabel").get_global_rect()
			var cv: Rect2 = c["visible_rect"]
			var hero_r := Rect2(home.world_to_screen(cv.position), cv.size * t["scale"])
			var shown: bool = home.get_region("HomeAreaLabel").is_visible_in_tree()
			if MATRIX.find(size) < 5 and not shown:
				bad.append("area_label_hidden_on_required_viewport")
			if not shown:
				al = Rect2()
			elif al.size.x < 200.0 or al.size.y < 40.0:
				bad.append("area_label_too_small")
			for n in ["TopCurrencyHUD", "ProfileCard", "GiftMeter", "PlayButton", "RewardedAdsButton", "Shortcut_tasks"]:
				if al.intersects(home.get_region(n).get_global_rect()):
					bad.append("area_label_over_" + n)
			if al.intersects(hero_r):
				bad.append("area_label_over_scrubby")
			for n in ["HomeAreaTitle", "HomeAreaNumber"]:
				var l: Label = home.get_region(n)
				if shown and l.get_line_count() != 1 or l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x > l.size.x + 0.5:
					bad.append(n + "_not_fitting")
			_ok(bad.is_empty(), "%s insets=%s: touch >= 88 in safe area, world uniform + covering, platform above PLAY, feet on anchor, panels clear of bots/meter, ad at bottom, area label clear + fitting %s" % [str(size), str(insets), str(bad)])
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
	_ok(n == 32 and bad.is_empty(), "all 32 APPROVED entries (56 minus the 24 SB-ASSET-PURGE-2026-11-17 deletions) (incl. retired history) match their pinned sha %s" % str(bad))
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
