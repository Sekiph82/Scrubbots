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
## M31 identity-stable presentation-only cleaning-effect layer. Created ONCE, shares this
## node's board origin and the renderer's cell scale exactly like AgentLayer, and is kept
## UNDER the AgentLayer so a short cleaning cue reads over the cleared (transparent) cell
## without hiding a moving Scrubbot. Holds NO gameplay authority.
var _fx_layer: Node2D
## M32 identity-stable presentation-only Scrubbot retire-echo layer. Created ONCE, shares
## this node's board origin and the renderer's cell scale exactly like AgentLayer, and is
## kept ABOVE the AgentLayer so a short disappearance echo reads on top of the vanished
## bot without hiding live board truth. Holds NO gameplay authority.
var _retire_layer: Node2D

## Build (once) or reconfigure the renderer + agent layer sharing this node's origin.
## `available_size` is the display rect the board should fit inside.
##
## IDENTITY-STABLE (M29-C001 V03, F-M29-MANUAL-001): the BoardRenderer and AgentLayer are
## created EXACTLY ONCE per presentation. Every later call — the responsive relayout path
## calls this on each resize — REUSES those exact instances: it re-renders the same
## renderer at the new cell size and rescales the same AgentLayer, changing geometry, not
## presentation-node authority identity. The M29 runtime binds M20 to get_renderer() and
## the dispatcher/runtime to get_agent_layer(); recreating them here would strand those
## bindings on stale, off-screen nodes (authoritative clears + live agents becoming
## invisible), which is exactly the owner-observed freeze. Live ScrubbotAgent children of
## the AgentLayer, and the ScrubRailView the screen inserts, survive untouched because
## neither node is replaced or reordered here.
func configure(board, palette: PackedStringArray, available_size: Vector2) -> void:
	if _renderer == null or not is_instance_valid(_renderer):
		_renderer = BoardRenderer.new()
		_renderer.name = "BoardRenderer"
		add_child(_renderer)
		_renderer.position = Vector2.ZERO
	_renderer.configure(board, palette, available_size)
	_renderer.position = Vector2.ZERO

	if _agent_layer == null or not is_instance_valid(_agent_layer):
		_agent_layer = Node2D.new()
		_agent_layer.name = "AgentLayer"
		add_child(_agent_layer)
		_agent_layer.position = Vector2.ZERO
	# M31 CleaningFxLayer: created ONCE, same origin + cell scale as AgentLayer, kept just
	# UNDER it (created before, so lower z). Identity-stable across relayout exactly like the
	# renderer/AgentLayer — a later configure() only rescales it, never recreates it, so
	# active cleaning cues are never stranded on a stale off-screen node.
	if _fx_layer == null or not is_instance_valid(_fx_layer):
		_fx_layer = Node2D.new()
		_fx_layer.name = "CleaningFxLayer"
		add_child(_fx_layer)
		_fx_layer.position = Vector2.ZERO
		if _agent_layer != null and is_instance_valid(_agent_layer):
			move_child(_fx_layer, _agent_layer.get_index())

	# M32 RetireFxLayer: created ONCE, same origin + cell scale as AgentLayer, kept ABOVE
	# it (created after, so higher z). Identity-stable across relayout exactly like the
	# renderer/AgentLayer/CleaningFxLayer — a later configure() only rescales it, never
	# recreates it, so an active disappearance echo is never stranded on a stale node.
	if _retire_layer == null or not is_instance_valid(_retire_layer):
		_retire_layer = Node2D.new()
		_retire_layer.name = "RetireFxLayer"
		add_child(_retire_layer)
		_retire_layer.position = Vector2.ZERO

	var cs: float = _renderer.get_cell_size()
	# One board-local movement unit maps to exactly the renderer's cell-size.
	_agent_layer.scale = Vector2(cs, cs)
	_fx_layer.scale = Vector2(cs, cs)
	_retire_layer.scale = Vector2(cs, cs)

func get_renderer():
	return _renderer

func get_agent_layer() -> Node2D:
	return _agent_layer

func get_cleaning_fx_layer() -> Node2D:
	return _fx_layer

func get_retire_fx_layer() -> Node2D:
	return _retire_layer

func get_cell_size() -> float:
	return _renderer.get_cell_size() if _renderer != null else 1.0

## Map a board-local point (cell units) to this presentation's GLOBAL display point
## via the AgentLayer transform — the same transform spawned agents inherit. Lets
## tests compare an agent's transformed position against BoardRenderer cell centers.
func board_local_to_global(p: Vector2) -> Vector2:
	if _agent_layer == null:
		return p
	return _agent_layer.to_global(p)

## Inverse of board_local_to_global: map a GLOBAL display point (e.g. a visible
## SlotView spawn anchor) into board-local cell units through the SAME AgentLayer
## transform spawned agents inherit. Lets the owner scene derive a route start from
## real visible slot geometry instead of a hardcoded constant (F-M21-V04-002).
func global_to_board_local(global_point: Vector2) -> Vector2:
	if _agent_layer == null:
		return global_point
	return _agent_layer.to_local(global_point)
