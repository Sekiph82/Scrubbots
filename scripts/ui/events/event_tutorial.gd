extends RefCounted
## EventTutorial — preload (res://scripts/ui/events/event_tutorial.gd).
##
## SB-TF-12 (owner 2026-11-19) — the per-event coach-mark walkthrough over the REAL event details
## screen (EventsV02Ui.open_details), one step per entry of that event's steps in
## data/config/events_v02_tutorials.json (6..10 steps, copied from the owner's tutorial storyboards):
## the screen dims except the step's target section (meta "coach": hero / board / team / ranking /
## map / progress / rewards / timer / start_button), which is scrolled into view and framed with a
## native gold glow; a cream speech bubble with a blue rim points at it with the localized bubble
## text, and the green button carries the localized button text (last step = Start / Başla: joins a
## joinable event and closes). The step pill shows "n / N"; X skips. Shown once automatically on an
## event's first visit, replayable from the (i) button. No gameplay of its own and no painted
## screenshots: the storyboard PNGs are design references only and never shipped. Reduced Effects =
## the focus glow does not pulse. Locked before Level 30 like every Events entry.

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")

const CREAM := Color(1.0, 0.965, 0.863)
const BUBBLE_EDGE := Color(0.122, 0.384, 0.851)
const DIM := Color(0, 0, 0, 0.5)
const GLOW := Color(1.0, 0.82, 0.25)
const BUBBLE_W := 760.0

## The event's steps (step, target, bubble_en/tr, button_en/tr).
static func steps(id: String) -> Array:
	return EventsV02Ui.data(id).get("steps", [])

## Localized field of one step ("bubble" / "button").
static func text(s: Dictionary, field: String) -> String:
	return String(s.get(field + "_" + ("tr" if UiText.locale == "tr" else "en"), ""))

static func open(stack, app, iid: String) -> BasePopup:
	if not app.feature_unlocked("events"):
		return null
	var v: Dictionary = app.economy.events_v02.view(iid)
	if v.is_empty():
		return null
	var id := String(v["id"])
	var d = stack.top()
	if d == null or d.popup_id != "event_details" or String(d.get_meta("iid", "")) != iid:
		d = EventsV02Ui.open_details(stack, app, iid, false)   # the coach marks sit on the real screen
		if d == null:
			return null
	var p := BasePopup.new("event_tutorial")
	p.set_meta("iid", iid)
	p.set_meta("details", d)
	p.set_meta("step", 1)
	p.set_title(EventsV02Ui.title(id))
	(p.get_node("Scrim") as ColorRect).color = Color(0, 0, 0, 0)   # the Coach draws the dim with a hole
	(p.find_child("Center", true, false) as Control).visible = false
	var coach := Coach.new()
	coach.name = "Coach"
	p.add_child(coach)
	var bubble := VBoxContainer.new()
	bubble.name = "Bubble"
	bubble.add_theme_constant_override("separation", -4)
	bubble.custom_minimum_size.x = BUBBLE_W
	coach.add_child(bubble)
	bubble.add_child(_pointer("PointerUp", true))
	var panel := PanelContainer.new()
	panel.name = "BubblePanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(CREAM, BUBBLE_EDGE, 7, 44, 10, 2), UiTokens.SPACE_LG, UiTokens.SPACE_MD))
	bubble.add_child(panel)
	var l := BasePopup.body_label("", 36, BasePopup.INK)
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)
	bubble.add_child(_pointer("PointerDown", false))
	var ctrl := VBoxContainer.new()
	ctrl.name = "Controls"
	ctrl.custom_minimum_size.x = 640
	ctrl.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	coach.add_child(ctrl)
	EventsV02Ui.style_go(p.add_action("tut_next", "", "primary", false, "", ctrl))
	var pill := PanelContainer.new()
	pill.name = "StepPill"
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(Color(0.039, 0.204, 0.651), GLOW, 5, 32, 6, 2), UiTokens.SPACE_LG, 2))
	var pl := HomeStyle.label("", 34, Color.WHITE, 8)
	pl.name = "StepText"
	pill.add_child(pl)
	ctrl.add_child(EventsV02Ui._flanked("StepRow", pill, "sparkle_left", "sparkle_right", 56))
	var skip := p.add_action("tut_close", "X", "secondary", true, "", coach)
	EventsV02Ui._round_button(skip, Color(0.85, 0.16, 0.18), UiText.t("POPUP_CLOSE"))
	coach.skip = skip
	p.action_selected.connect(func(aid, _c):
		if aid != "tut_next":
			return
		var n := int(p.get_meta("step"))
		if n < steps(id).size():
			show_step(p, app, n + 1)
			p.rearm_soon()
			return
		var now: Dictionary = app.economy.events_v02.view(iid)   # Start: join a joinable event, then close
		if now["phase"] == "active" and not now["joined"]:
			app.actions.join_event(iid)
		if is_instance_valid(d) and d.is_open():
			EventsV02Ui.refresh_details(d, app)
		p.close("done"))
	app.actions.mark_event_tutorial_seen(id)
	show_step(p, app, 1)
	if not stack.push(p):
		p.free()
		return null
	return p

## Shows `step` (1-based) of the popup's event: focus its target, bubble + button text, pill.
static func show_step(p: BasePopup, app, step: int) -> void:
	var v: Dictionary = app.economy.events_v02.view(String(p.get_meta("iid")))
	var all := steps(String(v["id"]))
	var s: Dictionary = all[step - 1]
	p.set_meta("step", step)
	p.set_meta("state", s)
	var d: Control = p.get_meta("details")
	var coach: Coach = p.get_node("Coach")
	(coach.find_child("Text", true, false) as Label).text = text(s, "bubble")
	p.get_action_button("tut_next").text = text(s, "button")
	(coach.find_child("StepText", true, false) as Label).text = "%s / %s" % [UiText.num(step), UiText.num(all.size())]
	var headers: Array = d.find_children("HeaderText", "Label", true, false) + d.find_children("Title", "Label", true, false)
	coach.aim(EventsV02Ui.target(d, String(s["target"])), app.effects != null and app.effects.is_reduced(), headers)

static func _pointer(n: String, up: bool) -> Control:
	var tip := Control.new()
	tip.name = n
	tip.custom_minimum_size = Vector2(0, 34)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var poly := Polygon2D.new()
	poly.color = BUBBLE_EDGE
	poly.polygon = PackedVector2Array([Vector2(-28, 38), Vector2(0, 0), Vector2(28, 38)] if up else [Vector2(-28, -4), Vector2(0, 34), Vector2(28, -4)])
	tip.add_child(poly)
	return tip

## Full-screen coach layer: dim with a hole over the target, gold focus frame, bubble near the
## target, button + step pill at the bottom (top when the target sits there). Follows the target
## every frame (layout / scroll), so the frame always matches the real section.
class Coach extends Control:
	var target: Control = null
	var headers: Array = []   ## section header / title labels the bubble must never cover
	var hole := Rect2()
	var skip: Button
	var _focus: Panel
	var _scroll := false
	var _tween: Tween = null

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP   # the real screen underneath is not tappable mid-tutorial
		_focus = Panel.new()
		_focus.name = "FocusFrame"
		_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = GLOW
		sb.set_border_width_all(8)
		sb.set_corner_radius_all(30)
		sb.shadow_color = Color(GLOW, 0.75)
		sb.shadow_size = 24
		sb.anti_aliasing = true
		_focus.add_theme_stylebox_override("panel", sb)
		add_child(_focus)

	## Focus `t` (null = no target: the whole screen stays dim). Reduced Effects: no pulse.
	func aim(t: Control, reduced: bool, header_labels: Array = []) -> void:
		target = t
		headers = header_labels
		hole = Rect2()
		_scroll = true
		_focus.set_meta("target", t)
		if _tween != null:
			_tween.kill()
			_tween = null
		_focus.modulate.a = 1.0
		set_meta("pulse", not reduced)
		if not reduced:
			_tween = _focus.create_tween().set_loops()
			_tween.tween_property(_focus, "modulate:a", 0.55, 0.6)
			_tween.tween_property(_focus, "modulate:a", 1.0, 0.6)

	func _process(_delta: float) -> void:
		if target == null or not is_instance_valid(target):
			return
		if _scroll and target.size.y > 0.0:
			_scroll = false
			var sc := _scroller(target)
			if sc != null:   # centre the target in the details scroll
				var y := target.get_global_rect().position.y - sc.get_global_rect().position.y + sc.scroll_vertical
				sc.scroll_vertical = int(y - (sc.size.y - target.size.y) * 0.5)
		var r := target.get_global_rect()
		r.position -= global_position
		var bh: float = (get_node("Bubble") as Control).get_combined_minimum_size().y
		if r != hole or skip.size.x <= 0.0 or not is_equal_approx(bh, (get_node("Bubble") as Control).size.y):
			hole = r
			_place()
			queue_redraw()

	static func _scroller(c: Node) -> ScrollContainer:
		var n := c.get_parent()
		while n != null and not (n is ScrollContainer):
			n = n.get_parent()
		return n

	func _place() -> void:
		var w := size.x
		var h := size.y
		var safe_top := 150.0
		_focus.position = hole.position - Vector2(14, 14)
		_focus.size = hole.size + Vector2(28, 28)
		var ctrl: Control = get_node("Controls")
		var cs := ctrl.get_combined_minimum_size()
		ctrl.size = cs
		var bottom := h - cs.y - 60.0
		var ctrl_y := bottom if hole.end.y + 20.0 < bottom else safe_top
		ctrl.position = Vector2((w - cs.x) / 2.0, ctrl_y)
		var lo := safe_top if ctrl_y > safe_top else ctrl_y + cs.y + 20.0   # free band for the bubble
		var hi := ctrl_y - 20.0 if ctrl_y > safe_top else h - 40.0
		var bubble: Control = get_node("Bubble")
		var up_tip: Control = bubble.get_node("PointerUp")
		var down_tip: Control = bubble.get_node("PointerDown")
		up_tip.visible = true
		down_tip.visible = false
		var bs := bubble.get_combined_minimum_size()
		var bx := (w - BUBBLE_W) / 2.0
		var at := _free_y(Rect2(bx, 0, BUBBLE_W, bs.y), lo, hi)
		var below: bool = at.x > 0.5
		up_tip.visible = below
		down_tip.visible = not below
		bubble.size = Vector2(BUBBLE_W, bs.y)
		bubble.position = Vector2(bx, at.y)
		var tx := clampf(hole.get_center().x - bubble.position.x, 80.0, BUBBLE_W - 80.0)
		for tip in [up_tip, down_tip]:
			(tip.get_child(0) as Polygon2D).position.x = tx
		skip.position = Vector2(w - skip.size.x - 24.0, 24.0)

	## Header / title label rects (coach space) currently on screen.
	func header_rects() -> Array:
		var out: Array = []
		for l in headers:
			if is_instance_valid(l) and (l as Control).is_visible_in_tree():
				var r := (l as Control).get_global_rect()
				r.position -= global_position
				if r.intersects(Rect2(Vector2.ZERO, size)):
					out.append(r)
		return out

	## Bubble y next to the target that covers neither the target nor any header: tries below
	## and above, sliding away in 8 px steps inside [lo, hi]; returns (1 = below / 0 = above, y),
	## the nearest free spot winning. Falls back to the side with more room.
	func _free_y(b: Rect2, lo: float, hi: float) -> Vector2:
		var blocks: Array = header_rects()
		blocks.append(hole.grow(6.0))
		var best := Vector2(-1, 0)
		var best_d := INF
		for side in [1.0, 0.0]:
			var y0: float = hole.end.y + 24.0 if side > 0.5 else hole.position.y - 24.0 - b.size.y
			var y := y0
			while y >= lo - 0.5 and y + b.size.y <= hi + 0.5:
				var r := Rect2(b.position.x, y, b.size.x, b.size.y)
				if not blocks.any(func(x): return (x as Rect2).intersects(r)):
					if absf(y - y0) < best_d:
						best_d = absf(y - y0)
						best = Vector2(side, y)
					break
				y += 8.0 if side > 0.5 else -8.0
		if best.x >= 0.0:
			return best
		var room_below := hi - hole.end.y
		return Vector2(1.0, clampf(hole.end.y + 24.0, lo, hi - b.size.y)) if room_below > hole.position.y - lo else Vector2(0.0, clampf(hole.position.y - 24.0 - b.size.y, lo, hi - b.size.y))

	func _draw() -> void:
		var r := hole.grow(10.0) if hole.size != Vector2.ZERO else Rect2(size / 2.0, Vector2.ZERO)
		r = r.intersection(Rect2(Vector2.ZERO, size)) if r.intersects(Rect2(Vector2.ZERO, size)) else Rect2(size / 2.0, Vector2.ZERO)
		draw_rect(Rect2(0, 0, size.x, r.position.y), DIM)
		draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), DIM)
		draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), DIM)
		draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), DIM)
