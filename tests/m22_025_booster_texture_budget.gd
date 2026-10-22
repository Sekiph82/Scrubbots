extends SceneTree
## SB-M22-025 (booster slice) — booster textures import capped at 512 px, alpha kept,
## resident RGBA8 total within the gameplay booster-set budget.
## Run: godot --headless --path . -s res://tests/m22_025_booster_texture_budget.gd

const ROOT := "res://assets/ui/final/boosters/"
const BOOSTER_TEXTURE_MAX_DIM := 512
const BOOSTER_TEXTURE_BUDGET_BYTES := 12 * 1024 * 1024
const EXPECTED_COUNT := 10
const GAMEPLAY_SCREEN := "res://scripts/ui/gameplay_screen.gd"
const ACQUISITION_FLOW := "res://scripts/ui/popup/acquisition_flow.gd"

var _fail := 0

func _initialize() -> void:
	_budget()
	_referenced_paths()
	_done()

func _pngs(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png"):
			out.append(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_pngs(dir + d + "/", out)

func _budget() -> void:
	print("[budget]")
	var paths: Array = []
	_pngs(ROOT, paths)
	_ok(paths.size() == EXPECTED_COUNT, "%d booster PNGs (expected %d)" % [paths.size(), EXPECTED_COUNT])
	var total := 0
	for p in paths:
		var tex := load(p) as Texture2D
		if tex == null:
			_ok(false, "%s loads" % p)
			continue
		var w := tex.get_width()
		var h := tex.get_height()
		_ok(maxi(w, h) <= BOOSTER_TEXTURE_MAX_DIM, "%s %dx%d <= %d" % [p, w, h, BOOSTER_TEXTURE_MAX_DIM])
		_ok(_has_alpha_format(tex.get_image()), "%s keeps alpha" % p)
		total += w * h * 4
	print("  booster textures resident RGBA8: %.2f MiB (budget %.0f MiB)" % [total / 1048576.0, BOOSTER_TEXTURE_BUDGET_BYTES / 1048576.0])
	_ok(total <= BOOSTER_TEXTURE_BUDGET_BYTES, "total %d <= %d bytes" % [total, BOOSTER_TEXTURE_BUDGET_BYTES])

func _has_alpha_format(img: Image) -> bool:
	return img.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_LA8, Image.FORMAT_RGBA4444, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]

func _referenced_paths() -> void:
	print("[referenced]")
	var gs: GDScript = load(GAMEPLAY_SCREEN)
	var af: GDScript = load(ACQUISITION_FLOW)
	var refs: Array = []
	for spec in gs.BOOSTERS:
		refs.append(spec["art"])
	refs.append(gs.BOOSTER_SELECTED_ART)
	refs.append(gs.BOOSTER_UNAVAILABLE_ART)
	refs.append(gs.BOOSTER_FREE_BADGE_ART)
	refs.append(gs.BOOSTER_REWARD_GLOW_ART)
	refs.append(gs.BOOSTER_ACTIVATED_BURST_ART)
	for id in af.BOOSTER_DEFS:
		refs.append(af.BOOSTER_DEFS[id]["icon"])
	for p in refs:
		_ok(load(p) as Texture2D != null, "%s loads" % p)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22-025 BOOSTER TEXTURE BUDGET: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
