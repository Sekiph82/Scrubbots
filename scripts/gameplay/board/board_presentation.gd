extends Node2D
## BoardPresentation — preload this script
## (res://scripts/gameplay/board/board_presentation.gd) rather than relying on
## global class_name lookup (AL-001).
##
## M21-C001 V04 presentation-ONLY shared board/agent transform (owner playtest
## decision F-M21-OWNER-PLAYTEST-002). It maps board-local ScrubbotAgent movement
## truth onto the exact same on-screen board origin and cell scale as BoardRenderer,
## so a dispatched agent is visibly aligned with the rendered board instead of
## moving as a tiny root-space dot.
##
##   BoardPresentation (this Node2D — the shared board origin)
##   ├── BoardRenderer  (Control/TextureRect at local (0,0))
##   └── AgentLayer     (Node2D at local (0,0), scale = cell_size)
##         └── real ScrubbotAgent(s)  (positioned in board-local cell units)
##
## Because AgentLayer sits at the same origin as the renderer and is scaled by the
## renderer's integer cell-size, a ScrubbotAgent at board-local (x, y) draws at the
## same display point as BoardRenderer's cell (x, y). Movement/route truth stays
## board-local; NO screen-pixel math is pushed into RoutingSystem/ScrubbotAgent.
## The dispatcher is bound with get_agent_layer() as its agent_parent so spawned
## agents inherit this transform.

const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")

var _renderer  # BoardRenderer (Control)
var _agent_layer: Node2D

## Build the renderer + agent layer sharing this node's origin. `available_size` is
## the display rect the board should fit inside (same contract as BoardRenderer).
func configure(board, palette: PackedStringArray, available_size: Vector2) -> void:
	_renderer = BoardRenderer.new()
	add_child(_renderer)
	_renderer.configure(board, palette, available_size)
	_renderer.position = Vector2.ZERO

	_agent_layer = Node2D.new()
	_agent_layer.name = "AgentLayer"
	add_child(_agent_layer)
	_agent_layer.position = Vector2.ZERO
	var cs: float = _renderer.get_cell_size()
	# One board-local movement unit maps to exactly the renderer's cell-size.
	_agent_layer.scale = Vector2(cs, cs)

func get_renderer():
	return _renderer

func get_agent_layer() -> Node2D:
	return _agent_layer

func get_cell_size() -> float:
	return _renderer.get_cell_size() if _renderer != null else 1.0

## Map a board-local point (cell units) to this presentation's GLOBAL display point
## via the AgentLayer transform — the same transform spawned agents inherit. Lets
## tests compare an agent's transformed position against BoardRenderer cell centers.
func board_local_to_global(p: Vector2) -> Vector2:
	if _agent_layer == null:
		return p
	return _agent_layer.to_global(p)
