extends SceneTree
## M43-C015R (SB-M43-R15-001..003) owner runtime evidence from the real app root (opening skipped):
##   Home with the REWARDED ADS CTA; Rewarded Ads fresh / slot 1 claimed / production provider
##   unavailable; TEST-provider WATCH AD + one verified slot claimed (banner-labelled, test only:
##   no production ad SDK exists); Settings and fixed Daily Rewards at the owner sizes.
## Each frame renders at the LOGICAL canvas the real window gets under stretch canvas_items /
## expand (base 1080x2160) and is saved at the PHYSICAL owner size. Needs a rendering driver:
##   godot --path . --rendering-driver opengl3 -s res://tests/tools/r15_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const RewardedAdProvider = preload("res://scripts/economy/rewarded_ad_provider.gd")

const DAILY_SIZES := [Vector2i(683, 1366), Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1080, 2160),
	Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

class TestProvider extends RewardedAdProvider:
	var deliver := {}
	func is_available(_p: String) -> bool:
		return true
	func request(_p: String, token: String, d: Callable) -> bool:
		deliver[token] = d
		return true

var _out := ""
var _n := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://r15_snapshots"
	DirAccess.make_dir_recursive_absolute(_out)
	await _rewarded(Vector2i(683, 1366))
	await _rewarded(Vector2i(1080, 2160))
	for phys in [Vector2i(683, 1366), Vector2i(1080, 2160)]:
		await _settings(phys)
	for phys in DAILY_SIZES:
		await _daily(phys)
	print("R15_EVIDENCE %d frames -> %s" % [_n, _out])
	quit()

static func logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

func _boot(phys: Vector2i) -> Array:
	var sub := SubViewport.new()
	sub.size = logical(phys)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = "user://r15_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(8)
	root.get_modal_stack().clear("evidence")
	await _frames(2)
	return [sub, root]

func _rewarded(phys: Vector2i) -> void:
	var b := await _boot(phys)
	var sub: SubViewport = b[0]
	var root = b[1]
	var app = root.get_app_state()
	await _shot(sub, phys, "1_home_rewarded_ads_cta")
	root.get_home().get_region("RewardedAdsButton").pressed.emit()
	await _frames(4)
	await _shot(sub, phys, "2_rewarded_ads_fresh_slot1_ready_production_no_video")
	root.get_modal_stack().top().get_action_button("slot:1").pressed.emit()
	await _frames(4)
	await _shot(sub, phys, "3_rewarded_ads_slot1_claimed_production_provider_unavailable")
	root.get_modal_stack().clear("evidence")
	var tp := TestProvider.new()
	app.economy.rewarded.set_provider(tp)
	var banner := _banner(sub)
	root.get_home().get_region("RewardedAdsButton").pressed.emit()
	await _frames(4)
	await _shot(sub, phys, "4_TEST_PROVIDER_rewarded_ads_watch_ad")
	var p = root.get_modal_stack().top()
	p.get_action_button("slot:2").pressed.emit()
	await _frames(2)
	var tok: String = tp.deliver.keys()[0]
	tp.deliver[tok].call(tok, {"outcome": "completed", "verified": true})
	await _frames(4)
	await _shot(sub, phys, "5_TEST_PROVIDER_rewarded_ads_verified_slot2_claimed")
	banner.queue_free()
	root.free()
	sub.free()

func _settings(phys: Vector2i) -> void:
	var b := await _boot(phys)
	b[1].open_settings()
	await _frames(4)
	await _shot(b[0], phys, "6_settings")
	b[1].free()
	b[0].free()

func _daily(phys: Vector2i) -> void:
	var b := await _boot(phys)
	var app = b[1].get_app_state()
	DailyScreens.open_daily(b[1].get_modal_stack(), app)
	await _frames(4)
	await _shot(b[0], phys, "7_daily_rewards_fixed")
	b[1].free()
	b[0].free()

## Test-only on-image label: this capture uses an injected TEST provider (no production ad SDK).
func _banner(sub: SubViewport) -> Node:
	var layer := CanvasLayer.new()
	layer.layer = 128
	var l := Label.new()
	l.text = "TEST / EVIDENCE PROVIDER - NOT PRODUCTION (no ad SDK; M57 gate)"
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0.6, 0, 0))
	l.add_theme_constant_override("outline_size", 10)
	var bg := ColorRect.new()
	bg.color = Color(0.75, 0.05, 0.05, 0.92)
	bg.position = Vector2(0, sub.size.y - 120)
	bg.size = Vector2(sub.size.x, 70)
	l.position = Vector2(20, sub.size.y - 110)
	layer.add_child(bg)
	layer.add_child(l)
	sub.add_child(layer)
	return layer

func _shot(sub: SubViewport, phys: Vector2i, tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := sub.get_texture().get_image()
	if img.get_size() != phys:
		img.resize(phys.x, phys.y, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s_%dx%d.png" % [_out, tag, phys.x, phys.y]
	img.save_png(path)
	_n += 1

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
