extends CanvasLayer
## ModalStack — preload (res://scripts/ui/popup/modal_stack.gd).
##
## M43-C002 (SB-M43-016 / SB-M43-026 / SB-M43-027) — the ONE modal-stack authority. The
## app root owns one instance above Home / gameplay / Results and injects it into the
## gameplay host; a harness host with no app root creates its own. It is presentation /
## input state only — never gameplay or economy truth.
##
## Rules:
##   - deterministic LIFO order; exactly one TOP popup owns input (lower popups are
##     disabled and covered by the top popup's full-screen scrim);
##   - everything behind the stack (gameplay, Home, Results) receives no pointer input
##     while any popup is open (the top scrim is on a higher CanvasLayer), and owners are
##     told through modal_changed(active) so they can gate their own non-GUI paths;
##   - Back/Escape closes ONLY the top popup and is always consumed while a popup is open
##     (never leaks to the screen behind), even when the top popup is busy/non-dismissible;
##   - closing the top restores the next popup (or the screen) as input owner;
##   - a popup can be pushed once; closed popups are removed and freed (no accumulation);
##   - focus loss / background / resume never touches the stack, so no callback replays.

signal modal_changed(active: bool)
signal top_changed(popup)

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const LAYER := 64
const Z_BAND := 4   ## per-depth z offset; > any z a popup uses internally (hero = 1)

var _stack: Array = []
var _root: Control
var _insets = null   ## synthetic safe insets for tests/evidence, applied to every popup

func _init() -> void:
	name = "ModalStack"
	layer = LAYER
	_root = Control.new()
	_root.name = "ModalRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

## Push `popup` as the new top. Rejects null, a non-BasePopup, an already pushed/closed
## popup. Returns true when it is now the top input owner.
func push(popup) -> bool:
	if popup == null or not (popup is BasePopup) or _stack.has(popup) or popup.get_parent() != null:
		return false
	if popup.is_open() or popup.is_closed():
		return false
	var was_active := not _stack.is_empty()
	_root.add_child(popup)
	if _insets != null:
		popup.set_synthetic_insets(_insets[0], _insets[1], _insets[2], _insets[3])
	_stack.append(popup)
	popup.closed.connect(_on_popup_closed.bind(popup), CONNECT_ONE_SHOT)
	popup._stack_open()
	_sync()
	if not was_active:
		modal_changed.emit(true)
	top_changed.emit(popup)
	return true

func is_open() -> bool:
	return not _stack.is_empty()

func depth() -> int:
	return _stack.size()

func top():
	return _stack.back() if not _stack.is_empty() else null

func has_popup(id: String) -> bool:
	return _stack.any(func(p): return p.popup_id == id)

## Ordered popup ids, bottom -> top (tests/evidence).
func ids() -> Array:
	return _stack.map(func(p): return p.popup_id)

func close_top(reason: String = "close") -> bool:
	return not _stack.is_empty() and _stack.back().close(reason)

## Back/Escape entry. True = consumed by the stack (a popup was open), whether or not the
## top popup was allowed to close. False = no popup open; the caller handles back.
func handle_back() -> bool:
	if _stack.is_empty():
		return false
	_stack.back().request_back()
	return true

## Close every popup top-down (route change / host release). Emits no actions.
func clear(reason: String = "clear") -> void:
	while not _stack.is_empty():
		var p = _stack.back()
		if not p.close(reason):
			_remove(p)

func set_synthetic_safe_insets(l: int, t: int, r: int, b: int) -> void:
	_insets = [l, t, r, b]
	for p in _stack:
		p.set_synthetic_insets(l, t, r, b)

func _on_popup_closed(_reason: String, popup) -> void:
	_remove(popup)

func _remove(popup) -> void:
	var was_top: bool = not _stack.is_empty() and _stack.back() == popup
	_stack.erase(popup)
	if popup.get_parent() == _root:
		_root.remove_child(popup)
	popup.queue_free()
	_sync()
	if was_top:
		top_changed.emit(top())
	if _stack.is_empty():
		modal_changed.emit(false)

func _sync() -> void:
	for i in range(_stack.size()):
		var is_top: bool = i == _stack.size() - 1
		# Lower popups keep drawing (dimmed under the top scrim) but accept no action.
		_stack[i]._stack_set_top(is_top)
		# Z band per depth (M43-C005F-PHASE2-R01): a popup's own raised children (BasePopup hero,
		# z 1) must never draw above a popup stacked over it (e.g. the Gift Bar hero over an
		# earned-pack ceremony). Relative z, so each popup's internal order is unchanged.
		_stack[i].z_index = i * Z_BAND

## Escape / ui_cancel: consumed here before any screen's _unhandled_input can see it.
func _input(event: InputEvent) -> void:
	if not _stack.is_empty() and event.is_action_pressed("ui_cancel"):
		handle_back()
		get_viewport().set_input_as_handled()
