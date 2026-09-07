extends "res://scripts/gameplay/board/board_renderer.gd"
## Test double: a real BoardRenderer subclass that records the palette array it
## was handed by GameplaySession._configure_renderer(). Used to prove the
## session passes a DETACHED palette copy across the presentation seam
## (F-M11-STRICT-005): mutating last_palette must not touch the session source.

var last_palette = null

func configure(board, palette: PackedStringArray, available_size: Vector2) -> void:
	last_palette = palette
	super(board, palette, available_size)
