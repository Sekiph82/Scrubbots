extends SceneTree
## SB-POLISH-010 V04 evidence: stills of the four storyboard stages of the SHIPPING Standard and
## Premium pack ceremonies (real ModalStack, committed fixture models, real taps). Evidence only.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/pack_opening_v04_snapshot.gd -- <out_dir>

const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")
const PFx = preload("res://tests/support/premium_pack_fixtures.gd")

const SIZE := Vector2i(1080, 2160)

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://pack_opening_v04"
	DirAccess.make_dir_recursive_absolute(_out if _out.is_absolute_path() else ProjectSettings.globalize_path(_out))
	var stages := {
		"1_drop": func(p): return p.phase() == "IDLE" and p.get_meta("idle_frames", 0) > 45,
		"2_shake_charge": func(p): return p.pack_frame == 3,
		"3_tear_burst": func(p): return p.pack_frame == 9 and p.get_card_views()[-1].emerge > 0.7 and p.get_card_views()[0].settle == 0.0,
		"4_reveal": func(p): return p.phase() == "AWAIT_ROUTE",
	}
	await _flow("standard", StandardPackCeremony.create(Fx.mixed("ev_std"))["popup"], stages)
	await _flow("premium", PremiumPackCeremony.create_premium(PFx.mixed("ev_prem"))["popup"], {
		"3_tear_burst": stages["3_tear_burst"], "4_reveal": stages["4_reveal"]})
	await _flow("reduced", StandardPackCeremony.create(Fx.mixed("ev_red"), true)["popup"], {"4_reveal": stages["4_reveal"]})
	quit(1 if _bad > 0 else 0)

## Push, tap once at IDLE (after its shot), capture each state the first frame it holds.
func _flow(tag: String, p, shots: Dictionary) -> void:
	var sub := SubViewport.new()
	sub.size = SIZE
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var stack = ModalStack.new()
	sub.add_child(stack)
	stack.set_synthetic_safe_insets(0, 96, 0, 64)
	stack.push(p)
	var pending: Array = shots.keys()
	for _f in range(900):
		await RenderingServer.frame_post_draw
		p.set_meta("idle_frames", p.get_meta("idle_frames", 0) + 1)
		for k in pending.duplicate():
			if shots[k].call(p):
				var path := "%s/%s_%s_%dx%d.png" % [_out, tag, k, SIZE.x, SIZE.y]
				print("SNAPSHOT ", path, " err=", sub.get_texture().get_image().save_png(path), " phase=", p.phase(), " frame=", p.pack_frame)
				pending.erase(k)
		if pending.is_empty():
			break
		if p.phase() == "IDLE" and not pending.has("1_drop"):
			p.tap()
	if not pending.is_empty():
		_bad += 1
		print("MISSING ", tag, " ", pending)
	sub.free()
	await process_frame
