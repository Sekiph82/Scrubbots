extends Control

@export var margin_container_path: NodePath = NodePath("MarginContainer")

@onready var _margin: MarginContainer = get_node(margin_container_path)

func _ready() -> void:
    resized.connect(_apply_safe_area)
    _apply_safe_area()

func _apply_safe_area() -> void:
    var viewport_size := get_viewport_rect().size
    var safe := DisplayServer.get_display_safe_area()

    # Desktop/headless environments may report an empty/invalid safe area.
    if safe.size.x <= 0 or safe.size.y <= 0:
        _set_margins(0, 0, 0, 0)
        return

    var sx := viewport_size.x / float(max(1, DisplayServer.screen_get_size().x))
    var sy := viewport_size.y / float(max(1, DisplayServer.screen_get_size().y))

    var left := int(round(safe.position.x * sx))
    var top := int(round(safe.position.y * sy))
    var right := int(round((DisplayServer.screen_get_size().x - safe.end.x) * sx))
    var bottom := int(round((DisplayServer.screen_get_size().y - safe.end.y) * sy))

    _set_margins(max(0, left), max(0, top), max(0, right), max(0, bottom))

func _set_margins(left: int, top: int, right: int, bottom: int) -> void:
    _margin.add_theme_constant_override("margin_left", left)
    _margin.add_theme_constant_override("margin_top", top)
    _margin.add_theme_constant_override("margin_right", right)
    _margin.add_theme_constant_override("margin_bottom", bottom)
