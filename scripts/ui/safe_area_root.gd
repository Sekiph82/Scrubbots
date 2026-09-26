extends Control

@export var margin_container_path: NodePath = NodePath("MarginContainer")

@onready var _margin: MarginContainer = get_node(margin_container_path)

## Narrow PRESENTATION-ONLY test seam (M28): synthetic safe-area insets in this
## viewport's own pixels. When set, they replace the DisplayServer probe so headless
## viewport tests can exercise non-zero notch/gesture insets deterministically. This
## is layout data only — NEVER read as gameplay truth and changes no engine.
var _synthetic_insets = null  # null, or {"left","top","right","bottom"} ints

func set_synthetic_insets(left: int, top: int, right: int, bottom: int) -> void:
    _synthetic_insets = {"left": max(0, left), "top": max(0, top),
        "right": max(0, right), "bottom": max(0, bottom)}
    if _margin != null:
        _apply_safe_area()

func clear_synthetic_insets() -> void:
    _synthetic_insets = null
    if _margin != null:
        _apply_safe_area()

func _ready() -> void:
    resized.connect(_apply_safe_area)
    _apply_safe_area()

## M42 V07 platform policy (coordination/OWNER_M42_HOME_POLISH_V07_DESKTOP_SAFE_AREA.md):
## only mobile (Android, iOS) and Web derive UI safe-area margins from
## DisplayServer.get_display_safe_area(). On desktop OSes (Windows, macOS, Linux, *BSD)
## that probe can report the desktop WORK AREA (e.g. minus the Windows taskbar), which is
## not a mobile notch/gesture inset, so desktop runtime margins are zero.
const RUNTIME_SAFE_AREA_PLATFORMS := ["Android", "iOS", "Web"]

static func uses_runtime_display_safe_area(os_name: String) -> bool:
    return RUNTIME_SAFE_AREA_PLATFORMS.has(os_name)

## Pure conversion of a DisplayServer safe-area probe into viewport-space margins
## [left, top, right, bottom]. An invalid/empty probe (desktop/headless) yields zeros.
static func margins_from_probe(safe: Rect2i, screen: Vector2i, viewport_size: Vector2) -> Array:
    if safe.size.x <= 0 or safe.size.y <= 0:
        return [0, 0, 0, 0]
    var sx := viewport_size.x / float(max(1, screen.x))
    var sy := viewport_size.y / float(max(1, screen.y))
    var left := int(round(safe.position.x * sx))
    var top := int(round(safe.position.y * sy))
    var right := int(round((screen.x - safe.end.x) * sx))
    var bottom := int(round((screen.y - safe.end.y) * sy))
    return [max(0, left), max(0, top), max(0, right), max(0, bottom)]

## Precedence: 1) synthetic insets (test seam, every platform); 2) desktop platforms ->
## zero; 3) mobile/web DisplayServer probe; 4) invalid/empty probe -> zero.
func _apply_safe_area() -> void:
    if _synthetic_insets != null:
        _set_margins(_synthetic_insets["left"], _synthetic_insets["top"],
            _synthetic_insets["right"], _synthetic_insets["bottom"])
        return
    if not uses_runtime_display_safe_area(OS.get_name()):
        _set_margins(0, 0, 0, 0)
        return
    var m := margins_from_probe(DisplayServer.get_display_safe_area(),
        DisplayServer.screen_get_size(), get_viewport_rect().size)
    _set_margins(m[0], m[1], m[2], m[3])

## Current applied margins [left, top, right, bottom] (tests / runtime evidence).
func get_applied_margins() -> Array:
    return [_margin.get_theme_constant("margin_left"), _margin.get_theme_constant("margin_top"),
        _margin.get_theme_constant("margin_right"), _margin.get_theme_constant("margin_bottom")]

func _set_margins(left: int, top: int, right: int, bottom: int) -> void:
    _margin.add_theme_constant_override("margin_left", left)
    _margin.add_theme_constant_override("margin_top", top)
    _margin.add_theme_constant_override("margin_right", right)
    _margin.add_theme_constant_override("margin_bottom", bottom)
