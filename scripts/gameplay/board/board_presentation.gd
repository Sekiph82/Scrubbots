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

## M32-C002 board-resolution-independent Scrubbot apparent size (OWNER_SCRUBBOT_SIZE_AND_
## GAMEPLAY_TEMPO_V01 §1). The owner reference is the accepted 32x32 / 2.4-cell look: a
## 32-cell board fitted into the SAME available rect by the SAME floored rule BoardRenderer
## uses. Presentation-only: never read by routing/agents/BoardState.
const SCRUBBOT_REFERENCE_CELLS := 32.0
var _available_size: Vector2 = Vector2.ZERO
## Reference 32-cell display size for the current available rect, and the resulting
## compensation = reference / actual rendered cell size (1.0 on a 32x32 board).
var _reference_cell_size: float = 1.0
var _scrubbot_size_compensation: float = 1.0
## Bumped on every configure() (responsive relayout). Live visuals/echoes compare it in
## O(1) and recompute their local scale only when it changes — no scene-tree scan.
var _presentation_generation: int = 0

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

	_available_size = available_size
	_reference_cell_size = reference_cell_size_for(available_size)
	_scrubbot_size_compensation = _reference_cell_size / cs if cs > 0.0 else 1.0
	_presentation_generation += 1

## The display size one cell would have if a SCRUBBOT_REFERENCE_CELLS x SCRUBBOT_REFERENCE_CELLS
## board were fitted into `available_size` by BoardRenderer's own floored rule.
static func reference_cell_size_for(available_size: Vector2) -> float:
	if not (is_finite(available_size.x) and is_finite(available_size.y)):
		return 1.0
	var fit: float = min(available_size.x / SCRUBBOT_REFERENCE_CELLS, available_size.y / SCRUBBOT_REFERENCE_CELLS)
	return max(floor(fit), 1.0)

## Production seam (GameplayScreen._layout_board): after it scales this presentation, the screen
## reports the DISPLAY cell size a 32x32 reference board would get from the SAME layout rule in
## the SAME region. Compensation = that / this presentation's actual display cell (renderer
## integer cell x this node's uniform scale), so the displayed Scrubbot is identical to the
## 32x32 look on every board resolution / aspect. Non-finite or non-positive input is ignored.
func set_scrubbot_reference_display_cell(reference_display_cell: float) -> void:
	if not is_finite(reference_display_cell) or reference_display_cell <= 0.0:
		return
	var display_cell: float = get_cell_size() * absf(scale.x)
	if not is_finite(display_cell) or display_cell <= 0.0:
		return
	_reference_cell_size = reference_display_cell
	_scrubbot_size_compensation = reference_display_cell / display_cell
	_presentation_generation += 1

## Board-cell multiplier that keeps a Scrubbot's DISPLAYED size equal to its 32x32-reference
## size on this presentation: local_span_cells = reference_span_cells * compensation, so
## displayed span = reference_span_cells * reference_cell_size for every board resolution.
func get_scrubbot_size_compensation() -> float:
	return _scrubbot_size_compensation

func get_reference_cell_size() -> float:
	return _reference_cell_size

func get_available_size() -> Vector2:
	return _available_size

func get_presentation_generation() -> int:
	return _presentation_generation

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
