extends RefCounted

const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 16
const SPACE_LG := 24
const SPACE_XL := 32

const RADIUS_SM := 12
const RADIUS_MD := 20
const RADIUS_LG := 28

const ICON_SM := 48
const ICON_MD := 72
const ICON_LG := 96

const TOUCH_MIN := 88

const FONT_BODY := 30
const FONT_BUTTON := 34
const FONT_TITLE := 48
const FONT_HERO := 64

const REFERENCE_VIEWPORT := Vector2i(1080, 2160)
const COLOR_SELECTION_MIN_WIDTH := 620
const BOOSTER_ROW_MIN_HEIGHT := 108
const BOTTOM_ACTION_ROW_MIN_HEIGHT := 120

# M28 gameplay screen layout tokens (presentation only).
const BATCH_SLOT_MIN := 120            # one read-only five-slot view (reference px)
const FIVE_SLOT_STRIP_MIN_HEIGHT := 132
const SUPPLY_TILE_MIN := 96            # one supply row/column cell
const SUPPLY_VISIBLE_ROWS := 3         # V1: exactly three visible rows per column
const SUPPLY_PANEL_MIN_WIDTH := 620    # protected usable supply width
const BATCH_REGION_MIN_HEIGHT := 360   # slots + supply + decoration, protected
