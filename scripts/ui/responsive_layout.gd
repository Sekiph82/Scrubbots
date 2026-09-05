extends RefCounted

enum LayoutMode {
    COMPACT,
    NORMAL,
    TALL,
}

const COMPACT_MAX_RATIO := 1.85
const TALL_MIN_RATIO := 2.15

static func get_layout_mode(viewport_size: Vector2) -> LayoutMode:
    if viewport_size.x <= 0.0:
        return LayoutMode.NORMAL
    var ratio := viewport_size.y / viewport_size.x
    if ratio < COMPACT_MAX_RATIO:
        return LayoutMode.COMPACT
    if ratio >= TALL_MIN_RATIO:
        return LayoutMode.TALL
    return LayoutMode.NORMAL

static func get_safe_board_square(available_size: Vector2) -> float:
    return floor(min(available_size.x, available_size.y))

static func is_required_test_viewport(size: Vector2i) -> bool:
    return size in [
        Vector2i(1080, 2160),
        Vector2i(1170, 2532),
        Vector2i(1290, 2796),
        Vector2i(1080, 2400),
        Vector2i(1440, 3200),
    ]
