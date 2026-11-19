extends SceneTree
## M42 Home master convergence V02 — presentation accounting + composition evidence
## (revised for owner V03 retired/disabled modes and V04 single-world-background
## retirements; V04 specifics in m42_home_v04.gd).
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
		if a["status"] in ["APPROVED", "RETIRED_DELETED"]:
			art_ids.append(a["id"])
	var acc: Array = home.get_presentation_accounting()
	var ids: Array = []
	for row in acc:
		ids.append(row["id"])
	art_ids.sort()
	ids.sort()
	_ok(ids == art_ids, "every APPROVED / RETIRED_DELETED manifest entry has exactly one presentation row (%d rows / %d entries)" % [ids.size(), art_ids.size()])
	var slug_ok := true
	for a in m["assets"]:
		if HomePresentationMap.ENTRIES.has(a["id"]):
			slug_ok = slug_ok and HomePresentationMap.ENTRIES[a["id"]]["slug"] == a["slug"]
	_ok(slug_ok, "presentation-map slugs equal manifest slugs")
	var modes := {}
	for row in acc:
		modes[row["mode"]] = int(modes.get(row["mode"], 0)) + 1
	_ok(modes == {"STATIC": 13, "WORLD_BAKED_RETIRED": 18, "OWNER_RETIRED": 23, "OWNER_DISABLED": 2}, "V04 + R01-V02 + R15-004 (HOME-122) + SB-HOME-BG (HOME-124; HOME-121/123 retired) + SB-HOME-VIDEO (HOME-125) + SB-TF-03 (Shop / Collection tiles, win-streak strip, 4 nav icons retired) + SB-TF-11 (Daily button, HOME-067): 13 STATIC + 18 WORLD_BAKED_RETIRED + 23 OWNER_RETIRED (7 + HOME-120/121/123 + 12 SB-TF-03 + 1 SB-TF-11) + 2 OWNER_DISABLED (%s)" % str(modes))
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
	var want := ["HOME-001", "HOME-002", "HOME-003", "HOME-004", "HOME-006", "HOME-007", "HOME-010", "HOME-011", "HOME-013", "HOME-014", "HOME-015", "HOME-016", "HOME-018", "HOME-019", "HOME-020", "HOME-021", "HOME-022", "HOME-023", "HOME-024", "HOME-031", "HOME-032", "HOME-062", "HOME-063", "HOME-064", "HOME-065", "HOME-066", "HOME-067", "HOME-069", "HOME-078", "HOME-086", "HOME-087", "HOME-090", "HOME-091", "HOME-092", "HOME-093", "HOME-094", "HOME-101", "HOME-102", "HOME-103", "HOME-104", "HOME-120", "HOME-121", "HOME-123"]
	_ok(ids == want, "retired/disabled set (V03 + V04 + R01-V02 HOME-120 + SB-HOME-BG HOME-121/123 + SB-TF-03 HOME-064/065/086/090..094/101..104 + SB-TF-11 HOME-067) %s" % str(ids))
	_ok(bad.is_empty(), "inactive rows have no presentation node and carry a reason %s" % str(bad))
	var m = V.load_manifest()
	var still_approved := 0
	var deleted := 0
	for a in m["assets"]:
		if ids.has(a["id"]) and String(a.get("approved_sha256", "")).length() == 64:
			if a["status"] == "APPROVED":
				still_approved += 1
			elif a["status"] == "RETIRED_DELETED" and not FileAccess.file_exists("res://" + String(a["path"])):
				deleted += 1
	_ok(still_approved == 19 and deleted == 24, "retired/disabled entries keep their historical sha pins: 19 still APPROVED on disk (6 + 12 SB-TF-03 + 1 SB-TF-11), 24 RETIRED_DELETED with the file gone (SB-ASSET-PURGE-2026-11-17) (%d / %d)" % [still_approved, deleted])
	_complete("inactive_rows_present_nothing")

func _labels(home) -> void:
	print("[labels full]")
	var bad: Array = []
	# SB-TF-03 / SB-TF-13: one-line labels font-fitted to the 0.98x panel (never trimmed in EN / TR).
	for n in ["RewardedAdsButton", "Shortcut_tasks"]:
		var b: Button = home.get_region(n)
		var avail: float = b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
		var w: float = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		if w > avail + 0.5 or b.icon_rect.texture == null:
			bad.append(n)
	_ok(bad.is_empty(), "activity panels: icon + full one-line label inside the panel %s" % str(bad))
	_ok(home.get_region("RewardedAdsButton").text == "REWARDED ADS" and home.get_region("Shortcut_tasks").text == "TASKS", "full live labels REWARDED ADS / TASKS")
	_complete("labels_full")

func _nav(home) -> void:
	print("[nav dock -> SB-TF-03 top-HUD Settings icon, no dock]")
	var b: Button = home.get_region("SettingsButton")
	var icon: TextureRect = home.get_region("SettingsIcon")
	_ok(home.get_region("BottomNav") == null and icon.get_parent() == b and icon.texture != null and b.get_global_rect().encloses(icon.get_global_rect()), "no bottom dock; the Settings icon shows its approved art inside its button")
	_ok(not b.disabled and home.get_region("TopCurrencyHUD").is_ancestor_of(b), "SETTINGS icon live in the top HUD")
	_complete("nav_dock")

func _banner(home) -> void:
	print("[area banner]")
	# V04 (owner 5-7): WHISPERING PARK / AREA 1 is baked into HOME-120; no live overlay.
	_ok(home.get_region("AreaBanner") == null and home.get_region("AreaTitle") == null and home.get_region("AreaNumber") == null, "no live area banner over the baked World 01 sign")
	_complete("area_banner")

func _decor(home) -> void:
	print("[decor ignores input]")
	var bad: Array = []
	for row in home.get_presentation_accounting():
		for n in row["nodes"]:
			var node: Control = home.get_region(n["name"])
			if node is TextureRect and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				bad.append(n["name"])
	for n in ["Background", "WorldBackground", "Layer_characters", "Art_scrubby", "ActionHost", "WorldMargin", "MainWorldArea"]:
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
		var names: Array = ["PlayButton", "SettingsButton", "TopCurrencyHUD", "GiftMeter", "AdBannerSlot", "RewardedAdsButton", "Shortcut_tasks"]
		for n in names:
			var c: Control = home.get_region(n)
			if not vp.grow(0.5).encloses(c.get_global_rect()) or c.size.y < 88:
				bad.append(n)
		var play: Rect2 = home.get_region("PlayButton").get_global_rect()
		for n in ["RewardedAdsButton", "Shortcut_tasks"]:
			if home.get_region(n).get_global_rect().intersects(play):
				bad.append("overlap:" + n)
		var sc := (home.get_region("Art_scrubby") as Control).get_global_rect()
		if not home.get_region("Background").get_global_rect().encloses(sc):
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
	_ok(home.get_region("PlayButton").text == UiText.t("HOME_PLAY_LEVEL", [1]) and home.get_region("ScrubBucksChip").value_label.text != "", "native controls still render live values without art")
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
