extends Control
## BasePopup — preload (res://scripts/ui/popup/base_popup.gd).
##
## M43-C002 (SB-M43-015) — the ONE reusable production popup component. Every production
## popup (Pause, confirm, reward/confirmation, insufficient SB, network/error, busy,
## success/failure feedback) is a BasePopup configured by `popups.gd`; there is no second
## bespoke popup scene architecture.
##
##   BasePopup (full rect, STOP)
##   ├── Scrim            dim background; swallows every pointer event behind the frame
##   └── SafeAreaRoot     safe-area-aware portrait placement (same component as screens)
##       └── Center
##           └── Frame    FrameBox: promoted common popup frame (NinePatch, uniform scale)
##               └── Body header (royal title pill + optional close) / content / busy / footer
##
## Chrome is the EXISTING promoted art (assets/ui/final/common/frames/popup_*_frame.png,
## never written here). Every title, body line, value and CTA label is a live Label/Button.
##
## Lifecycle (canonical, exactly-once):
##   NEW --ModalStack.push--> OPEN --close(reason)--> CLOSED   (opened / closed emitted once)
## Actions: add_action(id, ...) buttons emit action_selected(id, context) at most once per
## arming, and only while this popup is OPEN, TOP of its ModalStack, not busy and not
## latched. A closing action closes first, then emits. A non-closing action latches the
## popup until rearm() / begin_pending() + resolve_pending().
## Pending (SB-M43-024): begin_pending() blocks every action + back until the matching
## token resolves (or the timeout fires); a stale/duplicate/late resolve is ignored.
## Presentation only: a popup never grants, spends or mutates gameplay/economy truth.

signal opened
signal closed(reason: String)
signal action_selected(action_id: String, context: Dictionary)
signal pending_resolved(action_id: String, result: Dictionary)

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const SafeAreaRootScene = preload("res://scenes/components/ui/common/safe_area_root.tscn")

## Promoted common frames: texture size + measured cream-interior insets (texture px),
## used as the 9-slice margins so corners/emblems never distort.
const FRAMES := {
	"small": {"path": "res://assets/ui/final/common/frames/popup_small_frame.png", "tex": Vector2(1536, 1024), "patch": [176, 205, 176, 223]},
	"medium": {"path": "res://assets/ui/final/common/frames/popup_medium_frame.png", "tex": Vector2(1212, 1298), "patch": [119, 169, 119, 185]},
	"large": {"path": "res://assets/ui/final/common/frames/popup_large_frame.png", "tex": Vector2(1145, 1374), "patch": [125, 133, 126, 144]},
	"reward": {"path": "res://assets/ui/final/common/frames/popup_reward_frame.png", "tex": Vector2(1199, 1312), "patch": [128, 331, 122, 216]},
	"warning": {"path": "res://assets/ui/final/common/frames/popup_warning_frame.png", "tex": Vector2(1214, 1295), "patch": [119, 356, 120, 220]},
}
const FRAME_WIDTH := 880.0      ## same reference width as the accepted Results frame
const SIDE_GUTTER := 40.0
const SCRIM := Color(0, 0, 0, 0.6)
const PRIMARY_HEIGHT := 112
## Results/Life/Help family values (see results_screen.gd).
const ROYAL := Color(0.106, 0.365, 0.788)
const ROYAL_EDGE := Color(0.047, 0.180, 0.459)
const ROW := Color(0.976, 0.898, 0.769)
const ROW_EDGE := Color(0.749, 0.604, 0.380)
const INK := Color(0.106, 0.180, 0.349)
## M43-C003 yellow SB offer CTA (Life reference: gold body, warm edge, white label).
const GOLD_BODY := Color(1.0, 0.765, 0.102)
const GOLD_EDGE := Color(0.690, 0.380, 0.020)
const GOLD_DISABLED := Color(0.78, 0.70, 0.52)
const WARN_INK := Color(0.62, 0.12, 0.10)

enum State { NEW, OPEN, CLOSED }

## Detached caller context (pending action token, acquisition context, ...). Never truth.
var context: Dictionary = {}
var popup_id: String
## Back/Escape closes this popup (when not busy). False = back is consumed, nothing happens.
var dismissible := true

var _state: int = State.NEW
var _top := false
var _latched := false
var _pending_token := 0
var _pending_action := ""
var _next_token := 0
var _timer: Timer = null
var _frame_kind := "medium"

var _scrim: ColorRect
var _safe
var _frame
var _hero: TextureRect
var _stack_box: VBoxContainer
var _title: Label
var _close: Button
var _content: VBoxContainer
var _busy: Label
var _footer: VBoxContainer
var _actions: Dictionary = {}   ## id -> {button, closes}

func _init(id: String = "popup") -> void:
	popup_id = id
	name = "Popup_" + id.validate_node_name()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = HomeStyle.make_theme()
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)
	_safe = SafeAreaRootScene.instantiate()
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	var content_root: Control = _safe.get_node("MarginContainer/Content")
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.name = "Center"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_root.add_child(center)
	content_root.resized.connect(_fit_width)
	# Optional hero art above/overlapping the frame (hidden unless set_hero()).
	_stack_box = VBoxContainer.new()
	_stack_box.name = "Stack"
	_stack_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack_box.add_theme_constant_override("separation", 0)
	center.add_child(_stack_box)
	_hero = HomeStyle.art("Hero")
	_hero.visible = false
	_hero.z_index = 1
	_stack_box.add_child(_hero)
	_frame = FrameBox.new()
	_frame.name = "Frame"
	_stack_box.add_child(_frame)
	var body := VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	_frame.set_body(body)
	var head := HBoxContainer.new()
	head.name = "Header"
	head.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	body.add_child(head)
	var left_pad := Control.new()
	left_pad.name = "HeaderBalance"
	left_pad.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, 0)
	left_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(left_pad)
	var pill := PanelContainer.new()
	pill.name = "TitlePill"
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(ROYAL, ROYAL_EDGE, 5, 30, 6, 6), UiTokens.SPACE_LG, UiTokens.SPACE_SM))
	head.add_child(pill)
	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 44)
	pill.add_child(_title)
	_close = Button.new()
	_close.name = "CloseButton"
	_close.text = "X"
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
	_close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled"]:
		_close.add_theme_stylebox_override(st, HomeStyle.box(ROYAL if st != "disabled" else Color(0.5, 0.56, 0.66), ROYAL_EDGE, 4, 44, 4, 3))
	_close.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_close.add_theme_font_size_override("font_size", 38)
	_close.pressed.connect(func(): request_back())
	head.add_child(_close)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	body.add_child(_content)
	_busy = body_label("", UiTokens.FONT_BODY)
	_busy.name = "BusyLabel"
	_busy.visible = false
	body.add_child(_busy)
	_footer = VBoxContainer.new()
	_footer.name = "Footer"
	_footer.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	body.add_child(_footer)
	set_frame("medium")
	set_close_enabled(true)

# ------------------------------------------------------------------ configure --

func set_frame(kind: String) -> void:
	if not FRAMES.has(kind):
		kind = "medium"
	_frame_kind = kind
	_frame.set_frame(FRAMES[kind])

## Existing approved art drawn above the frame, overlapping its top edge by `overlap`.
func set_hero(texture_path: String, hero_size: Vector2, overlap: int) -> void:
	_hero.texture = load(texture_path) as Texture2D
	_hero.custom_minimum_size = hero_size
	_hero.visible = _hero.texture != null
	_stack_box.add_theme_constant_override("separation", -overlap if _hero.visible else 0)

func get_hero() -> TextureRect:
	return _hero

func get_frame_kind() -> String:
	return _frame_kind

func get_frame_texture_path() -> String:
	return _frame.get_texture_path()

func set_title(text: String) -> void:
	_title.text = text

func get_title() -> String:
	return _title.text

## Optional close affordance (also governs whether back may close this popup).
func set_close_enabled(enabled: bool) -> void:
	dismissible = enabled
	_close.visible = enabled
	(_close.get_parent().get_node("HeaderBalance") as Control).visible = enabled

## Live wrapped body line in the family ink colour.
static func body_label(text: String, size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l

func add_body_line(text: String, node_name: String = "", color: Color = INK, size: int = UiTokens.FONT_BODY) -> Label:
	var l := body_label(text, size, color)
	if not node_name.is_empty():
		l.name = node_name
	_content.add_child(l)
	return l

## Small live note at the very bottom of the frame, under the actions.
func add_footer_note(text: String, node_name: String) -> Label:
	var l := body_label(text, 24)
	l.name = node_name
	_footer.add_child(l)
	return l

func get_content() -> VBoxContainer:
	return _content

## style: "primary" (green Life/Help CTA) | "secondary" (cream) | "offer" (yellow SB
## offer). `closes`: the action closes this popup before it is emitted; otherwise it
## latches the popup (see header). `row`: buttons sharing a row id sit side by side.
func add_action(id: String, text: String, style: String = "secondary", closes: bool = true, row: String = "") -> Button:
	var b := Button.new()
	b.name = ("Action_" + id).validate_node_name()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UiTokens.FONT_BUTTON)
	if style == "primary":
		HomeStyle.style_play_button(b)
		b.custom_minimum_size = Vector2(0, PRIMARY_HEIGHT)
	elif style == "offer":
		b.add_theme_stylebox_override("normal", HomeStyle.pad(HomeStyle.box(GOLD_BODY, GOLD_EDGE, 6, 40, 10, 10), 20, 8))
		b.add_theme_stylebox_override("hover", HomeStyle.pad(HomeStyle.box(GOLD_BODY.lightened(0.1), GOLD_EDGE, 6, 40, 10, 10), 20, 8))
		b.add_theme_stylebox_override("pressed", HomeStyle.pad(HomeStyle.box(GOLD_BODY.darkened(0.1), GOLD_EDGE, 6, 40, 5, 5), 20, 8))
		b.add_theme_stylebox_override("disabled", HomeStyle.pad(HomeStyle.box(GOLD_DISABLED, Color(0.55, 0.47, 0.33), 6, 40, 6, 8), 20, 8))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, Color(1, 1, 1))
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.75))
		b.add_theme_color_override("font_outline_color", GOLD_EDGE.darkened(0.3))
		b.add_theme_constant_override("outline_size", 10)
		b.custom_minimum_size = Vector2(0, PRIMARY_HEIGHT)
	else:
		var sb := HomeStyle.box(ROW, ROW_EDGE, 4, 30, 4, 4)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(c, INK)
		b.add_theme_color_override("font_disabled_color", Color(INK, 0.45))
		b.add_theme_constant_override("outline_size", 0)
		b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	b.pressed.connect(_on_action.bind(id))
	if row.is_empty():
		_footer.add_child(b)
	else:
		var line: HBoxContainer = _footer.get_node_or_null(("Row_" + row).validate_node_name())
		if line == null:
			line = HBoxContainer.new()
			line.name = ("Row_" + row).validate_node_name()
			line.add_theme_constant_override("separation", UiTokens.SPACE_MD)
			_footer.add_child(line)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(b)
	_actions[id] = {"button": b, "closes": closes}
	_sync_buttons()
	return b

func get_action_button(id: String) -> Button:
	return (_actions.get(id, {}) as Dictionary).get("button")

func get_action_ids() -> Array:
	return _actions.keys()

## Hide/show one action (live availability). A hidden action cannot be pressed.
func set_action_visible(id: String, v: bool) -> void:
	var b: Button = get_action_button(id)
	if b != null:
		b.visible = v

## Force-disable one action on top of the lifecycle gating (e.g. unaffordable / illegal).
func set_action_blocked(id: String, blocked: bool) -> void:
	if _actions.has(id):
		_actions[id]["blocked"] = blocked
		_sync_buttons()

func get_close_button() -> Button:
	return _close

func get_frame_rect() -> Rect2:
	return Rect2(_frame.global_position, _frame.size)

func get_safe_root():
	return _safe

func set_synthetic_insets(l: int, t: int, r: int, b: int) -> void:
	_safe.set_synthetic_insets(l, t, r, b)

func _fit_width() -> void:
	var avail: float = (_safe.get_node("MarginContainer/Content") as Control).size.x
	if avail > 0.0:
		_frame.set_width(minf(FRAME_WIDTH, avail - 2.0 * SIDE_GUTTER))

# ------------------------------------------------------------------ lifecycle --

func is_open() -> bool:
	return _state == State.OPEN

func is_closed() -> bool:
	return _state == State.CLOSED

func is_top() -> bool:
	return _top

func is_busy() -> bool:
	return _pending_token != 0

func is_latched() -> bool:
	return _latched

## ModalStack-only: NEW -> OPEN exactly once.
func _stack_open() -> bool:
	if _state != State.NEW:
		return false
	_state = State.OPEN
	_fit_width()
	opened.emit()
	return true

## ModalStack-only: this popup is (not) the one input owner.
func _stack_set_top(value: bool) -> void:
	_top = value
	_sync_buttons()

## OPEN -> CLOSED exactly once (programmatic close is always allowed, even while busy;
## a pending transaction is abandoned and a late resolve is then ignored).
func close(reason: String = "close") -> bool:
	if _state != State.OPEN:
		return false
	_state = State.CLOSED
	_top = false
	_clear_pending()
	_sync_buttons()
	closed.emit(reason)
	return true

## Back/Escape/close-button. Returns true when this popup closed. Busy or non-dismissible
## popups consume back without closing (the ModalStack never lets it leak).
func request_back() -> bool:
	if _state != State.OPEN or not _top or is_busy() or not dismissible:
		return false
	return close("back")

func rearm() -> void:
	_latched = false
	_sync_buttons()

## Re-arm after a short guard so a same-frame / double tap cannot repeat a committed
## purchase (M43-C003 SB-M43-048). No node is created; closing first cancels it.
func rearm_soon(delay_s: float = 0.35) -> void:
	if not is_inside_tree():
		rearm()
		return
	get_tree().create_timer(delay_s, true, false, true).timeout.connect(func():
		if _state == State.OPEN and not is_busy():
			rearm())

func _on_action(id: String) -> void:
	if _state != State.OPEN or not _top or is_busy() or _latched or not _actions.has(id):
		return
	if bool(_actions[id].get("blocked", false)) or not (_actions[id]["button"] as Button).visible:
		return
	if bool(_actions[id]["closes"]):
		close("action:" + id)
	else:
		_latched = true
		_sync_buttons()
	action_selected.emit(id, context.duplicate(true))

# ---------------------------------------------------------- pending / busy --

## Enter the busy state for one unresolved external transaction. Returns its token (>0),
## or 0 when refused (closed, not top, or a transaction is already unresolved).
func begin_pending(action_id: String, busy_text: String = "", timeout_s: float = 0.0) -> int:
	if _state != State.OPEN or is_busy():
		return 0
	_next_token += 1
	_pending_token = _next_token
	_pending_action = action_id
	_latched = true
	_busy.text = busy_text if not busy_text.is_empty() else UiText.t("POPUP_BUSY")
	_busy.visible = true
	if timeout_s > 0.0:
		if _timer == null:
			_timer = Timer.new()
			_timer.name = "PendingTimeout"
			_timer.one_shot = true
			_timer.ignore_time_scale = true
			_timer.timeout.connect(_on_pending_timeout)
			add_child(_timer)
		if _timer.is_inside_tree():
			_timer.start(timeout_s)
	_sync_buttons()
	return _pending_token

func get_pending_token() -> int:
	return _pending_token

## Caller-committed outcome for `token`. Exactly-once: a stale, duplicate or late (after
## timeout/close) resolve returns false and changes nothing. Restores a usable state.
func resolve_pending(token: int, result: Dictionary) -> bool:
	if token == 0 or token != _pending_token or _state != State.OPEN:
		return false
	var action := _pending_action
	_clear_pending()
	_latched = false
	_sync_buttons()
	pending_resolved.emit(action, result.duplicate(true))
	return true

func _on_pending_timeout() -> void:
	resolve_pending(_pending_token, {"ok": false, "reason": "timeout"})

func _clear_pending() -> void:
	_pending_token = 0
	_pending_action = ""
	if _busy != null:
		_busy.visible = false
	if _timer != null and is_instance_valid(_timer):
		_timer.stop()

func _sync_buttons() -> void:
	var live: bool = _state == State.OPEN and _top and not is_busy() and not _latched
	for id in _actions:
		(_actions[id]["button"] as Button).disabled = not live or bool(_actions[id].get("blocked", false))
	if _close != null:
		_close.disabled = not (_state == State.OPEN and _top and not is_busy())

## True when every live Label in the frame fits its rect (no clipping; tests/evidence).
func text_fits() -> bool:
	for l in _frame.find_children("*", "Label", true, false):
		var lb := l as Label
		if not lb.is_visible_in_tree() or lb.text.is_empty():
			continue
		var m := lb.get_minimum_size()
		if m.y > lb.size.y + 0.5 or (lb.autowrap_mode == TextServer.AUTOWRAP_OFF and m.x > lb.size.x + 0.5):
			return false
	var fr := get_frame_rect()
	var vp := get_viewport_rect() if is_inside_tree() else Rect2(Vector2.ZERO, Vector2(1e9, 1e9))
	return vp.encloses(fr)

## Promoted frame drawn as a uniformly scaled NinePatch behind the Body. The scale is
## width / texture width, so the frame's own emblems and corners are never distorted.
class FrameBox extends Container:
	var _chrome: NinePatchRect
	var _body: Control
	var _patch: Array = [0, 0, 0, 0]
	var _tex_w := 1.0
	var _width := 880.0
	var _path := ""
	const PAD := 18.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_chrome = NinePatchRect.new()
		_chrome.name = "Chrome"
		_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_chrome)

	func set_body(b: Control) -> void:
		_body = b
		add_child(b)

	func set_frame(spec: Dictionary) -> void:
		_path = spec["path"]
		_chrome.texture = load(_path) as Texture2D
		_patch = spec["patch"]
		_tex_w = spec["tex"].x
		_chrome.patch_margin_left = _patch[0]
		_chrome.patch_margin_top = _patch[1]
		_chrome.patch_margin_right = _patch[2]
		_chrome.patch_margin_bottom = _patch[3]
		update_minimum_size()
		queue_sort()

	func get_texture_path() -> String:
		return _path

	func set_width(w: float) -> void:
		w = maxf(w, 320.0)
		if absf(w - _width) < 0.5:
			return
		_width = w
		update_minimum_size()
		queue_sort()

	func _k() -> float:
		return _width / _tex_w

	func _insets() -> Array:
		var k := _k()
		return [_patch[0] * k + PAD, _patch[1] * k + PAD * 0.5, _patch[2] * k + PAD, _patch[3] * k + PAD]

	func _get_minimum_size() -> Vector2:
		var i := _insets()
		var bm: Vector2 = _body.get_combined_minimum_size() if _body != null else Vector2.ZERO
		# Chrome needs at least its own top+bottom patch height.
		var chrome_h: float = (_patch[1] + _patch[3]) * _k()
		return Vector2(_width, maxf(bm.y + i[1] + i[3], chrome_h))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_SORT_CHILDREN:
			var i := _insets()
			var k := _k()
			_chrome.position = Vector2.ZERO
			_chrome.scale = Vector2(k, k)
			_chrome.size = size / k
			if _body != null:
				fit_child_in_rect(_body, Rect2(Vector2(i[0], i[1]), size - Vector2(i[0] + i[2], i[1] + i[3])))
