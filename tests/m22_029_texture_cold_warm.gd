extends SceneTree
## SB-M22-029 — cold / warm loaded-texture check on the real main.tscn (1080x2400 phone, m49
## logical size, throw-away save). Counts the res://assets/ui/final/ textures in the
## ResourceLoader cache and their resident RGBA8 bytes: cold Home, peak while Shop / Collection
## (album, set, card) / Daily / Robots / Profile are open, and warm Home after closing them, twice.
## Fails if a second visit leaves more textures than the first (a leak), if catalog card art stays
## resident after the album closes, or if cold / peak exceed the 2 GB-device proxy budgets. Also:
## every final/ import stays lossless (compress/mode=0) and without mipmaps.
## Run: godot --headless --path . -s res://tests/m22_029_texture_cold_warm.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")

const F := "res://assets/ui/final/"
const CARDS := "res://assets/ui/final/collection/cards/"
const THUMBS := "res://assets/ui/final/collection/card_thumbs/"   # SB-M22-028 set-grid thumbnails
const MIB := 1024.0 * 1024.0
## Measured 2026-11-05 (factory 101): cold 133.50, peak 145.91 MiB (93 textures), plus ~10%.
const COLD_BUDGET_MIB := 147.0
const PEAK_BUDGET_MIB := 161.0

var _fail := 0
var _pngs: Array = []
var _root
var _save := ""

func _initialize() -> void:
	_list(F)
	_imports()
	MainScript.boot_opening_override = 0
	_save = "user://m22_029_cold_warm_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2400)
	sub.disable_3d = true
	get_root().add_child(sub)
	_root = MainScene.instantiate()
	sub.add_child(_root)
	await _frames(6)
	_root.get_modal_stack().clear("test")
	_root.get_app_state().economy.collection.add_card("s1_c0")   # its art is then drawn by the set / card
	await _frames(4)
	var cold := _count()
	print("cold Home: %d textures, %.2f MiB" % [cold["n"], cold["mib"]])
	var peak := 0.0
	var peak_cards := 0
	var warm: Array = []
	for visit in 2:
		var v: Dictionary = await _visit()
		peak = maxf(peak, v["mib"])
		peak_cards = maxi(peak_cards, v["cards"])
		await _frames(4)
		warm.append(_count())
		print("warm Home after visit %d: %d textures, %.2f MiB (peak %.2f MiB)" % [visit + 1, warm[visit]["n"], warm[visit]["mib"], peak])
	_ok(warm[1]["n"] <= warm[0]["n"], "second visit leaves no more textures than the first (%d <= %d)" % [warm[1]["n"], warm[0]["n"]])
	_ok(peak_cards > 0, "card art was resident while the set / card was open (%d)" % peak_cards)
	_ok(warm[0]["cards"] == 0 and warm[1]["cards"] == 0, "no catalog card art or thumbnail resident after the album closes")
	_ok(cold["mib"] <= COLD_BUDGET_MIB, "cold Home %.2f <= %.0f MiB" % [cold["mib"], COLD_BUDGET_MIB])
	_ok(peak <= PEAK_BUDGET_MIB, "peak %.2f <= %.0f MiB" % [peak, PEAK_BUDGET_MIB])
	_root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))
	print("M22-029 TEXTURE COLD/WARM: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

## Opens each screen (Collection: album, then set 1 and card s1_c0 over it), closes it; returns
## the peak resident MiB and card-art count seen.
func _visit() -> Dictionary:
	var st = _root.get_modal_stack()
	var app = _root.get_app_state()
	var peak := {"mib": 0.0, "cards": 0}
	for screen in [[func(): _root.get_acquisition().open_shop({"source": "test"})],
			[func(): CollectionScreen.open_album(st, app), func(): CollectionScreen.open_set(st, app, 1),
				func(): CollectionScreen.open_card(st, app, "s1_c0")],
			[func(): DailyScreens.open_daily(st, app)],
			[func(): RobotsScreen.open(st, app, _root.ceremonies)],
			[func(): ProfileScreens.open_profile(st, app)]]:
		for open in screen:
			open.call()
			await _frames(6)
			var c := _count()
			peak = {"mib": maxf(peak["mib"], c["mib"]), "cards": maxi(peak["cards"], c["cards"])}
		st.clear("test")
		await _frames(2)
	return peak

func _count() -> Dictionary:
	var n := 0
	var cards := 0
	var bytes := 0
	for p in _pngs:
		if not ResourceLoader.has_cached(p):
			continue
		var t := ResourceLoader.get_cached_ref(p) as Texture2D
		n += 1
		cards += int(p.begins_with(CARDS) or p.begins_with(THUMBS))
		bytes += t.get_width() * t.get_height() * 4
	return {"n": n, "cards": cards, "mib": bytes / MIB}

func _imports() -> void:
	var bad: Array = []
	for p in _pngs:
		var c := ConfigFile.new()
		if c.load(p + ".import") != OK or int(c.get_value("params", "compress/mode", -1)) != 0 or bool(c.get_value("params", "mipmaps/generate", true)):
			bad.append(p)
	_ok(bad.is_empty(), "%d final/ imports lossless (compress/mode=0) without mipmaps %s" % [_pngs.size(), str(bad.slice(0, 5))])

func _list(dir: String) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			_pngs.append(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_list(dir + d + "/")

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
