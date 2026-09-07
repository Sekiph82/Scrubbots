extends RefCounted
## DispatchResult — preload this script
## (res://scripts/gameplay/dispatch/dispatch_result.gd) rather than relying on
## global class_name lookup (AL-001 / ADR-009).
##
## M19 — the detached, immutable-by-convention answer ScrubbotDispatcher gives
## for exactly ONE dispatch attempt. It carries no candidate list, no alternate
## target, and no way to retarget: a failed dispatch for one request is never
## permission to pick a different target (mirrors RouteResult, ADR-024).
##
## On success it hands back the spawned agent plus the owner/target identity so
## M20 arrival orchestration can act. On failure every field stays inert:
## owner_id/target_index -1, agent null, and a stable failure_reason. "No work"
## and "route failed" are ordinary first-class results, never exceptions.

## Stable failure categories. Stable enough for tests and debug output.
class FailureReason:
	const NONE := &"NONE"
	const INVALID_REQUEST := &"INVALID_REQUEST"
	const NO_REACHABLE_TARGET := &"NO_REACHABLE_TARGET"
	const ROUTE_FAILED := &"ROUTE_FAILED"
	const AGENT_ASSIGN_FAILED := &"AGENT_ASSIGN_FAILED"
	const RESETTING := &"RESETTING"

var success: bool = false
var owner_id: int = -1
var target_index: int = -1
## The spawned ScrubbotAgent on success, else null. Never a partially-assigned
## or orphaned node — the dispatcher frees a failed agent before returning.
var agent = null
var failure_reason: StringName = FailureReason.NONE

static func success_result(a_owner_id: int, a_target_index: int, a_agent) -> RefCounted:
	var r = load("res://scripts/gameplay/dispatch/dispatch_result.gd").new()
	r.success = true
	r.owner_id = a_owner_id
	r.target_index = a_target_index
	r.agent = a_agent
	r.failure_reason = FailureReason.NONE
	return r

static func failure(reason: StringName) -> RefCounted:
	var r = load("res://scripts/gameplay/dispatch/dispatch_result.gd").new()
	r.success = false
	r.owner_id = -1
	r.target_index = -1
	r.agent = null
	r.failure_reason = reason
	return r
