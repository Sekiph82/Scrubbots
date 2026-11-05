extends RefCounted
## CharacterMotion — preload (res://scripts/ui/feel/character_motion.gd).
##
## SB-POLISH-011 V1 — code-driven character motion on the EXISTING static robot art (no new
## art, no video), per docs/ANIMATION_PLACEMENT_ANALYSIS_V1.md A1..A4:
##   win    crouch -> stretched jump -> squash landing -> settle, then a happy bob loop with a
##          small sparkle burst at each peak (plays alongside the Results WIN confetti);
##   lose   gentle droop (squashed, slight tilt), then a hopeful hop, then a slow breathe loop;
##   help   slides in from the right, then a small wave/tilt, repeated every few seconds;
##   ready  one quick squash -> hop -> settle (READY_S < 1 s), no loop.
## Every motion starts (help: lands) and ends on the static pose: scale 1, rotation 0, offset 0.
## Presentation only: the Control's layout rect never moves (travel is a draw-only shader
## offset, the pivot is the feet) and nothing here takes input. One live motion per Control (a
## replay kills the old one); the tweens are owned by the Control, so they die with it.
## Reduced = static: no tween, no material change, no node. The only node ever added is one
## "Sparkle" CPUParticles2D under a `win` character while it loops (stop() removes it).

const SHADER := preload("res://scripts/ui/feel/character_offset.gdshader")
const META := "character_motion"
const MODES := ["win", "lose", "help", "ready"]
const READY_S := 0.62
const PLAN := "character_motion_offset"   ## build-time: where the last queued segment ends

## Start `mode` on `c`. `intro` = false skips straight to the idle loop (same terminal re-shown).
static func play(c: Control, mode: String, reduced: bool, intro := true) -> void:
	stop(c)
	if reduced or not MODES.has(mode) or not c.is_inside_tree():
		return
	var mat := c.material as ShaderMaterial
	if mat == null or mat.shader != SHADER:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		c.material = mat
	c.pivot_offset_ratio = Vector2(0.5, 1.0)
	var tw := c.create_tween()
	c.set_meta(META, tw)
	c.set_meta(PLAN, Vector2.ZERO)
	if intro:
		match mode:
			"win":
				_step(tw, c, Vector2(1.08, 0.9), 0.0, Vector2.ZERO, 0.12)
				_step(tw, c, Vector2(0.92, 1.1), 0.0, Vector2(0, -70), 0.22, Tween.TRANS_QUAD, Tween.EASE_OUT)
				_step(tw, c, Vector2(0.96, 1.04), 0.0, Vector2.ZERO, 0.18, Tween.TRANS_QUAD, Tween.EASE_IN)
				_step(tw, c, Vector2(1.1, 0.9), 0.0, Vector2.ZERO, 0.08)
				_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.22, Tween.TRANS_BACK, Tween.EASE_OUT)
			"lose":
				_step(tw, c, Vector2(1.04, 0.94), -4.0, Vector2(0, 6), 0.5)
				tw.tween_interval(0.35)
				_step(tw, c, Vector2(0.96, 1.06), 2.0, Vector2(0, -26), 0.22, Tween.TRANS_QUAD, Tween.EASE_OUT)
				_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
				_step(tw, c, Vector2(1.05, 0.95), 0.0, Vector2.ZERO, 0.07)
				_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.18, Tween.TRANS_BACK, Tween.EASE_OUT)
			"help":
				mat.set_shader_parameter("offset", Vector2(260, 0))
				c.modulate.a = 0.0
				tw.tween_property(c, "modulate:a", 1.0, 0.2)
				tw.parallel().tween_method(func(v: Vector2): mat.set_shader_parameter("offset", v), Vector2(260, 0), Vector2.ZERO, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_wave(tw, c)
			"ready":
				_step(tw, c, Vector2(1.08, 0.92), 0.0, Vector2.ZERO, 0.1)
				_step(tw, c, Vector2(0.95, 1.07), 0.0, Vector2(0, -28), 0.16, Tween.TRANS_QUAD, Tween.EASE_OUT)
				_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.14, Tween.TRANS_QUAD, Tween.EASE_IN)
				_step(tw, c, Vector2(1.06, 0.94), 0.0, Vector2.ZERO, 0.06)
				_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.16, Tween.TRANS_BACK, Tween.EASE_OUT)
	if mode == "ready":
		tw.tween_callback(func(): c.remove_meta(META))
	else:
		tw.tween_callback(_loop.bind(c, mode))

## Kill any live motion and put `c` back on its static pose.
static func stop(c: Control) -> void:
	if c.has_meta(META):
		var tw: Tween = c.get_meta(META)
		if tw != null and tw.is_valid():
			tw.kill()
		c.remove_meta(META)
	c.scale = Vector2.ONE
	c.rotation = 0.0
	c.modulate.a = 1.0
	if c.material is ShaderMaterial:
		(c.material as ShaderMaterial).set_shader_parameter("offset", Vector2.ZERO)
	var spark := c.get_node_or_null("Sparkle") as CPUParticles2D
	if spark != null:   # removed, not kept: a stopped character leaves no extra node (M55)
		c.remove_child(spark)
		spark.queue_free()

static func is_playing(c: Control) -> bool:
	if not c.has_meta(META):
		return false
	var tw: Tween = c.get_meta(META)
	return tw != null and tw.is_valid() and tw.is_running()

## The idle loop; every cycle returns to the static pose.
static func _loop(c: Control, mode: String) -> void:
	var tw := c.create_tween().set_loops()
	c.set_meta(META, tw)
	c.set_meta(PLAN, Vector2.ZERO)
	match mode:
		"win":
			_step(tw, c, Vector2(0.98, 1.03), 0.0, Vector2(0, -10), 0.5)
			tw.tween_callback(_sparkle.bind(c))
			_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 0.5)
			tw.tween_interval(1.0)
		"lose":
			_step(tw, c, Vector2(1.0, 1.025), 0.0, Vector2.ZERO, 1.2)
			_step(tw, c, Vector2.ONE, 0.0, Vector2.ZERO, 1.2)
			tw.tween_interval(0.6)
		"help":
			tw.tween_interval(2.4)
			_wave(tw, c)

static func _wave(tw: Tween, c: Control) -> void:
	for deg in [7.0, -5.0, 4.0, 0.0]:
		tw.tween_property(c, "rotation", deg_to_rad(deg), 0.13).set_trans(Tween.TRANS_SINE)

## One parallel segment: scale + rotation (degrees) + draw offset.
static func _step(tw: Tween, c: Control, s: Vector2, deg: float, off: Vector2, d: float, trans := Tween.TRANS_SINE, ease := Tween.EASE_IN_OUT) -> void:
	tw.tween_property(c, "scale", s, d).set_trans(trans).set_ease(ease)
	tw.parallel().tween_property(c, "rotation", deg_to_rad(deg), d).set_trans(trans).set_ease(ease)
	var mat := c.material as ShaderMaterial
	var from: Vector2 = c.get_meta(PLAN, Vector2.ZERO)   # the previous segment's target
	c.set_meta(PLAN, off)
	tw.parallel().tween_method(func(v: Vector2): mat.set_shader_parameter("offset", v), from, off, d).set_trans(trans).set_ease(ease)

## A few gold pixel sparks over the character's head (one emitter per looping character).
static func _sparkle(c: Control) -> void:
	var p := c.get_node_or_null("Sparkle") as CPUParticles2D
	if p == null:
		p = CPUParticles2D.new()
		p.name = "Sparkle"
		p.one_shot = true
		p.emitting = false
		p.amount = 8
		p.lifetime = 0.8
		p.explosiveness = 0.85
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.direction = Vector2(0, -1)
		p.spread = 70.0
		p.initial_velocity_min = 40.0
		p.initial_velocity_max = 90.0
		p.gravity = Vector2(0, 60)
		p.scale_amount_min = 5.0
		p.scale_amount_max = 9.0
		p.color = Color(1.0, 0.86, 0.35)
		var fade := Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 1))
		fade.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = fade
		c.add_child(p)
	p.position = Vector2(c.size.x * 0.5, c.size.y * 0.25)
	p.emission_rect_extents = Vector2(c.size.x * 0.35, c.size.y * 0.15)
	p.restart()
