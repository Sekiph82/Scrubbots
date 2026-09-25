extends SceneTree
## M42 Home master convergence V02 — presentation accounting + composition evidence
## (revised for owner V03: retired/disabled modes; V03 specifics in m42_home_v03.gd).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home_composition.gd

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const MATRIX := [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]

var EXPECTED_CASES := [
	"accounting_covers_manifest", "static_nodes_presented", "inactive_rows_present_nothing",
	"labels_full", "nav_dock", "area_banner", "decor_ignores_input", "responsive_matrix",
	"unapproved_not_bound",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	var r = await _home(Vector2i(1080, 2160), "main")
	var home = r[1]
	_accounting(home)
	_static_nodes(home)
	_inactive(home)
	_labels(home)
	_nav(home)
	_banner(home)
	_decor(home)
	r[0].queue_free()
	await _matrix()
	await _unapproved()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _home(size: Vector2i, tag: String, binder = null) -> Array:
	var p := "user://m42_comp_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var app = AppState.new(p)
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	if binder != null:
		home.set_art_binder(binder)
	for _i in range(4):
		await process_frame
	return [sub, home]

func _accounting(home) -> void:
	print("[accounting covers manifest]")
	var m = V.load_manifest()
	var art_ids: Array = []
	for a in m["assets"]:
		if a["status"] == "APPROVED":
			art_ids.append(a["id"])
	var acc: Array = home.get_presentation_accounting()
	var ids: Array = []
	for row in acc:
		ids.append(row["id"])
	art_ids.sort()
	ids.sort()
	_ok(ids == art_ids, "every APPROVED manifest entry has exactly one presentation row (%d rows / %d approved)" % [ids.size(), art_ids.size()])
	var slug_ok := true
	for a in m["assets"]:
		if HomePresentationMap.ENTRIES.has(a["id"]):
			slug_ok = slug_ok and HomePresentationMap.ENTRIES[a["id"]]["slug"] == a["slug"]
	_ok(slug_ok, "presentation-map slugs equal manifest slugs")
	var modes := {}
	for row in acc:
		modes[row["mode"]] = int(modes.get(row["mode"], 0)) + 1
	_ok(modes == {"STATIC": 45, "OWNER_RETIRED": 3, "OWNER_DISABLED": 2}, "V03: 45 STATIC + 3 OWNER_RETIRED + 2 OWNER_DISABLED (%s)" % str(modes))
	_complete("accounting_covers_manifest")

func _static_nodes(home) -> void:
	print("[static nodes presented]")
	var bad: Array = []
	for row in home.get_presentation_accounting():
		if row["mode"] != "STATIC":
			continue
		for n in row["nodes"]:
			if not n["exists"] or n["texture"] == null or not n["visible"]:
				bad.append("%s/%s" % [row["id"], n["name"]])
	_ok(bad.is_empty(), "every STATIC entry presents its approved texture on a visible node %s" % str(bad))
	_complete("static_nodes_presented")

func _inactive(home) -> void:
	print("[inactive rows present nothing]")
	var ids: Array = []
	var bad: Array = []
	for row in home.get_presentation_accounting():
		if HomePresentationMap.INACTIVE_MODES.has(row["mode"]):
			ids.append(row["id"])
			if not (row["nodes"] as Array).is_empty() or String(row["reason"]).is_empty():
				bad.append(row["id"])
	ids.sort()
	_ok(ids == ["HOME-011", "HOME-031", "HOME-032", "HOME-078", "HOME-087"], "owner-retired/disabled set %s" % str(ids))
	_ok(bad.is_empty(), "inactive rows have no presentation node and carry a reason %s" % str(bad))
	var m = V.load_manifest()
	var still_approved := 0
	for a in m["assets"]:
		if ids.has(a["id"]) and a["status"] == "APPROVED" and String(a.get("approved_sha256", "")).length() == 64:
			still_approved += 1
	_ok(still_approved == 5, "historical approval + sha pins of retired/disabled entries unchanged in the manifest")
	_complete("inactive_rows_present_nothing")

func _labels(home) -> void:
	print("[labels full]")
	var bad: Array = []
	for id in ["win_streak", "gift_bar", "collection", "shop", "no_ads", "daily", "tasks", "cards_exchange"]:
		var b: Button = home.get_region("Shortcut_" + id)
		if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING or b.icon == null:
			bad.append(id)
	_ok(bad.is_empty(), "shortcut cards: icon + untrimmed wrapping label %s" % str(bad))
	_ok(home.get_region("Shortcut_cards_exchange").text == "CARDS EXCHANGE" and home.get_region("Shortcut_win_streak").text == "WIN STREAK" and home.get_region("Shortcut_collection").text == "COLLECTION", "full labels WIN STREAK / COLLECTION / CARDS EXCHANGE")
	_complete("labels_full")

func _nav(home) -> void:
	print("[nav dock]")
	var ok := true
	for id in ["events", "robots", "home", "leaderboard", "settings"]:
		var b: Button = home.get_region("Nav_" + id)
		var icon: TextureRect = home.get_region("NavIcon_" + id)
		ok = ok and icon.get_parent() == b and icon.texture != null and b.get_global_rect().encloses(icon.get_global_rect())
	_ok(ok, "every nav tab shows its approved icon inside the tab")
	_ok(home.get_region("Nav_home").button_pressed, "HOME tab is the selected state")
	_ok(home.get_region("Nav_settings").name == "SettingsButton" and not home.get_region("Nav_settings").disabled, "SETTINGS tab live")
	_complete("nav_dock")

func _banner(home) -> void:
	print("[area banner]")
	var banner: Control = home.get_region("AreaBanner")
	var arch: Control = home.get_region("Art_arch")
	_ok(String(home.get_region("AreaTitle").text) == UiText.t("HOME_AREA_TITLE") and String(home.get_region("AreaNumber").text) == UiText.t("HOME_AREA_NUMBER", [1]), "area title/number are live localizable labels")
	_ok(arch.get_global_rect().intersects(banner.get_global_rect()), "banner sits on the arch")
	_complete("area_banner")

func _decor(home) -> void:
	print("[decor ignores input]")
	var bad: Array = []
	for row in home.get_presentation_accounting():
		for n in row["nodes"]:
			var node: Control = home.get_region(n["name"])
			if node is TextureRect and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				bad.append(n["name"])
	for n in ["WorldStage", "Layer_central_world_and_environment", "Layer_characters", "AreaBanner"]:
		if home.get_region(n).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			bad.append(n)
	_ok(bad.is_empty(), "decorative art never steals input %s" % str(bad))
	_complete("decor_ignores_input")

func _matrix() -> void:
	print("[responsive matrix]")
	for size in MATRIX:
		var r = await _home(size, "mx")
		var home = r[1]
		var vp := Rect2(Vector2.ZERO, Vector2(size))
		var bad: Array = []
		var names: Array = ["PlayButton", "BottomNav", "TopCurrencyHUD", "GiftMeter", "WinStreakRewardTrack"]
		for id in ["win_streak", "gift_bar", "collection", "shop", "no_ads", "daily", "tasks", "cards_exchange"]:
			names.append("Shortcut_" + id)
		for n in names:
			var c: Control = home.get_region(n)
			if not vp.grow(0.5).encloses(c.get_global_rect()) or c.size.y < 88:
				bad.append(n)
		var play: Rect2 = home.get_region("PlayButton").get_global_rect()
		for id in ["shop", "cards_exchange"]:
			if home.get_region("Shortcut_" + id).get_global_rect().intersects(play):
				bad.append("overlap:" + id)
		var sc := (home.get_region("Art_scrubby") as Control).get_global_rect()
		if not home.get_region("MainWorldArea").get_global_rect().grow(8).encloses(sc):
			bad.append("scrubby_outside_world")
		_ok(bad.is_empty(), "%dx%d: regions in viewport, >=88px, no CTA overlap, hero in world %s" % [size.x, size.y, str(bad)])
		r[0].queue_free()
		await process_frame
	_complete("responsive_matrix")

class _NoArt extends RefCounted:
	func texture(_slug: String) -> Texture2D:
		return null

func _unapproved() -> void:
	print("[unapproved not bound]")
	var r = await _home(Vector2i(1080, 2160), "noart", _NoArt.new())
	var home = r[1]
	var any := false
	for row in home.get_presentation_accounting():
		for n in row["nodes"]:
			any = any or n["texture"] != null
	_ok(not any, "a binder that approves nothing leaves every presentation node without art (native fallback)")
	_ok(home.get_region("PlayButton").text == UiText.t("HOME_PLAY") and home.get_region("ScrubBucksChip").value_label.text != "", "native controls still render live values without art")
	r[0].queue_free()
	await process_frame
	_complete("unapproved_not_bound")

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
	print("m42_home_composition: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
