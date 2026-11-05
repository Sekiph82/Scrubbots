extends SceneTree
## SB-VIDEO-006 — Gift Meter milestone hero video (scripts/ui/ceremony/meta_ceremonies.gd):
##   FULL effects: start_motion plays ONE green-keyed box opening video in the hero slot (small
##   box for a normal milestone, big crate for the cycle max), the static art hidden under it and
##   replaced by the keyed last frame it holds afterwards; reward rows and CONTINUE stay usable
##   while it plays; finishing or closing the popup frees the decoder. Reduced Effects, a missing
##   or failing stream = the static hero exactly as before, no VideoStreamPlayer.
##
## Run: godot --headless --path . -s res://tests/sb_video_006_gift_meter_video.gd

const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")

var EXPECTED_CASES := [
	"small_vs_big", "reduced_static", "rows_cta_usable", "finish_holds_last_frame",
	"close_frees_decoder", "failure_fallback",
]

var _fail := 0
var _completed: Dictionary = {}
var _stack
var _videos: Dictionary

func _initialize() -> void:
	_videos = MetaCeremonies.gift_video.duplicate()
	_stack = ModalStack.new()
	get_root().add_child(_stack)
	await process_frame
	await _small_vs_big()
	await _reduced_static()
	await _rows_cta_usable()
	await _finish_holds_last_frame()
	await _close_frees_decoder()
	await _failure_fallback()
	_done()

## Open one gift milestone ceremony on the stack (CeremonyPresenter order: push, then start_motion).
func _open(milestone: int, reduced := false):
	var p = MetaCeremonies.build({"key": "gift:t%d" % milestone, "kind": "gift_milestone", "milestone": milestone,
		"cycle_max": 1000, "rewards": {"scrub_bucks": 50, "standard_card_packs": 1}}, reduced)
	_stack.push(p)
	MetaCeremonies.start_motion(p)
	await process_frame
	return p

func _players(n: Node) -> Array:
	return n.find_children("*", "VideoStreamPlayer", true, false)

func _hero(p) -> TextureRect:
	return p.find_child("HeroArt", true, false)

func _shut(p) -> void:
	p.close("test")
	await process_frame
	await process_frame

# ------------------------------------------------------------------ cases ----

func _small_vs_big() -> void:
	for c in [[10, "gift_small"], [1000, "gift_big"]]:
		var p = await _open(c[0])
		var v: Array = _players(p)
		_ok(v.size() == 1 and v[0].is_playing() and v[0].stream == MetaCeremonies.gift_video[c[1]], "milestone %d plays the %s video (one decoder)" % [c[0], c[1]])
		_ok(v.size() == 1 and (v[0].material as ShaderMaterial).shader == MetaCeremonies.CHROMA_KEY_GREEN and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE, "green-keyed, ignores input")
		var h := _hero(p)
		_ok(h.self_modulate.a == 0.0 and h.texture.resource_path == MetaCeremonies.GIFT_VIDEO_DIR + c[1] + "_opening_still.png", "static art hidden; hero holds the keyed last frame under the video")
		_ok(h.custom_minimum_size == MetaCeremonies.GIFT_VIDEO_SIZE[c[1]], "hero sized to the video box")
		await _shut(p)
	_complete("small_vs_big")

func _reduced_static() -> void:
	for c in [[10, "gift_small"], [1000, "gift_big"]]:
		var p = await _open(c[0], true)
		var h := _hero(p)
		_ok(_players(p).is_empty(), "Reduced %d: no VideoStreamPlayer" % c[0])
		_ok(h.texture.resource_path == MetaCeremonies.ART[c[1]] and h.self_modulate.a == 1.0 and h.custom_minimum_size == (Vector2(300, 300) if c[0] == 1000 else Vector2(220, 220)), "Reduced %d: static hero art exactly as before" % c[0])
		await _shut(p)
	_complete("reduced_static")

func _rows_cta_usable() -> void:
	var p = await _open(25)
	var closed := [""]
	p.closed.connect(func(r): closed[0] = r)
	var rows: Node = p.find_child("RewardRows", true, false)
	var b: Button = p.get_action_button("continue")
	_ok(_players(p).size() == 1 and rows.is_visible_in_tree() and rows.get_child_count() == 2, "reward rows shown while the video plays")
	_ok(b.is_visible_in_tree() and not b.disabled, "CONTINUE visible and enabled while the video plays")
	b.pressed.emit()
	await process_frame
	await process_frame
	_ok(closed[0] == "action:continue" and not is_instance_valid(p), "CONTINUE closes the ceremony mid-video (claim never blocked)")
	_complete("rows_cta_usable")

func _finish_holds_last_frame() -> void:
	var p = await _open(5)
	var v: VideoStreamPlayer = _players(p)[0]
	v.finished.emit()
	await process_frame
	var h := _hero(p)
	_ok(not is_instance_valid(v) and _players(p).is_empty(), "finishing frees the decoder")
	_ok(h.self_modulate.a == 1.0 and h.texture.resource_path == MetaCeremonies.GIFT_VIDEO_DIR + "gift_small_opening_still.png", "hero holds the keyed last frame")
	_ok(p.is_open() and p.get_action_button("continue").is_visible_in_tree(), "popup stays open with its CTA")
	await _shut(p)
	_complete("finish_holds_last_frame")

func _close_frees_decoder() -> void:
	var p = await _open(1000)
	var v: VideoStreamPlayer = _players(p)[0]
	p.close("test")
	_ok(not v.is_inside_tree() and (v.get_parent().is_queued_for_deletion() or p.is_queued_for_deletion()), "closing the popup takes the decoder out of the tree, queued for free")
	await process_frame
	_ok(not is_instance_valid(v), "decoder freed one frame after close")
	_complete("close_frees_decoder")

func _failure_fallback() -> void:
	var broken := VideoStreamTheora.new()
	broken.file = "res://assets/ui/final/rewards/gift_videos/missing.ogv"
	for injected in [null, broken]:
		MetaCeremonies.gift_video = {"gift_small": injected, "gift_big": injected}
		for c in [[10, "gift_small"], [1000, "gift_big"]]:
			var p = await _open(c[0])
			var h := _hero(p)
			_ok(_players(p).is_empty() and p.find_child("GiftVideoBox", true, false) == null, "%s stream, %d: no decoder left" % ["null" if injected == null else "broken", c[0]])
			_ok(h.texture.resource_path == MetaCeremonies.ART[c[1]] and h.self_modulate.a == 1.0 and h.custom_minimum_size == (Vector2(300, 300) if c[0] == 1000 else Vector2(220, 220)), "%s stream, %d: static hero art exactly as before" % ["null" if injected == null else "broken", c[0]])
			await _shut(p)
	MetaCeremonies.gift_video = _videos
	_complete("failure_fallback")

# -------------------------------------------------------------------- harness ----

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS ", msg)
	else:
		_fail += 1
		print("  FAIL ", msg)

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			_fail += 1
			print("  FAIL missing case ", c)
	print("SB-VIDEO-006 gift meter video: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
