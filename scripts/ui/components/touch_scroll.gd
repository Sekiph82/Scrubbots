extends RefCounted
## TouchScroll — preload (res://scripts/ui/components/touch_scroll.gd).
##
## M47-FAMILY-APK-TOUCH-R01 — finger drag-scrolling for popup lists (Collection album / Exchange,
## Robots, Shop, Gift Bar, Achievements). Godot's ScrollContainer scrolls by touch only from the
## (touch-emulated) mouse press + motion that REACH it; a list row PanelContainer or row Button
## with the default MOUSE_FILTER_STOP swallows them, so a swipe that starts on a row or its VIEW /
## BUY button never scrolls ("Collection scroll takılıyor"). enable():
##   - turns every STOP Control inside the list into PASS (now and for rows added later), so the
##     press / motion also reach the ScrollContainer. Buttons still receive their own press: a
##     stationary tap activates them exactly as before, and once a drag passes the deadzone the
##     ScrollContainer propagates NOTIFICATION_SCROLL_BEGIN, on which BaseButton cancels its press
##     (scene/gui/base_button.cpp) - a swipe never activates a row button;
##   - sets a small scroll_deadzone so an ordinary tap with finger jitter stays a tap.
## Mouse wheel / desktop behaviour is unchanged. Presentation-input only: no state, no authority.

const DEADZONE_PX := 16   ## canvas px (1080-wide reference), ~2 mm on a phone

static func enable(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = DEADZONE_PX
	_pass_tree(scroll)

static func _pass_tree(n: Node) -> void:
	for c in n.get_children():
		if c is Control and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_tree(c)
	if not n.child_entered_tree.is_connected(_on_child):
		n.child_entered_tree.connect(_on_child)

static func _on_child(c: Node) -> void:
	if c is Control and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	_pass_tree(c)
