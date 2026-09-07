extends "res://scripts/gameplay/board/board_renderer.gd"
## Test double: a real BoardRenderer subclass (calls super.configure) that
## directly records every configure() invocation. Used for positive-path
## sensitivity checks under Strict Audit Standard v2 (M11-C001 V06):
##   - configure_calls: exact number of configure() calls received;
##   - last_board / last_palette / last_size: the arguments of the last call.
## Proves detached-palette isolation (F-M11-STRICT-005) and that malformed/
## invalid binds never reach a valid renderer (F-M11-STRICT-002/003).

var configure_calls: int = 0
var last_board = null
var last_palette = null
var last_size := Vector2.ZERO

func configure(board, palette: PackedStringArray, available_size: Vector2) -> void:
	configure_calls += 1
	last_board = board
	last_palette = palette
	last_size = available_size
	super(board, palette, available_size)
