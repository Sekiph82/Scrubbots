extends "res://scripts/gameplay/dispatch/production_target_access.gd"
## M25 re-entry double — a REAL ProductionTargetAccess subclass (M25-C001 V02). It passes
## the strict production access category + board-coherence gate exactly like the canonical
## adapter (same _init(routing_system, routing_access, board, origin)), so re-entry is
## injected through a category-correct boundary and NOT by weakening the production trust
## boundary. On its first probe it synchronously re-enters the claim engine to prove the
## M25 re-entrancy guard fails the nested claim closed, then delegates to the real
## production targetability so the OUTER claim proceeds normally. Test-only.

var engine
var color := 0
var access_map: Dictionary = {}
var nested_result: Dictionary = {}
var _fired := false

func is_targetable(index: int) -> bool:
	if not _fired:
		_fired = true
		nested_result = engine.claim_for_color(color, access_map)
	return super(index)
