# M21-C001 V04 - ChatGPT Strict Audit

Date: 2026-09-13
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited implementation head: `28ecbe3f7bbbe762df8df1f8e8a0656fb56dff47`
Prompt: `coordination/sessions/M21-C001/CHATGPT_PROMPT_V04.md`
Criteria: `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
Claude log: `coordination/sessions/M21-C001/CLAUDE_LOG_V04.md`

## Verdict

**CHANGES_REQUIRED / FINDING_SET_FROZEN / OWNER_PLAYTEST_BLOCKED**

V04 contains substantial correct work and closes the prior V03 evidence residual, but it is not ready for M21 final closure or final owner visual PASS. The implementation's core TargetSelector policy change is accepted on source review, and the shared BoardPresentation/AgentLayer concept is directionally correct. However, a full-surface audit of the owner-playable scene, the new presentation layer, the SlotView integration, the actual production ScrubbotAgent lifecycle, and the V04 test observability found four closure-blocking findings.

Do not ask the owner to perform the final V04 acceptance playtest against this head. Correct the frozen set in V05 first, then rerun the automated matrix and owner playtest.

## Audited Git state

- V04 tracker-only start commit: `2de75dbc7b5b0b650c2aafe34b37829fd3e20f3f`.
- V04 implementation/handoff head: `28ecbe3f7bbbe762df8df1f8e8a0656fb56dff47`.
- V04 changed only the expected tracker/log/debug/presentation/TargetSelector/SlotView/test surface.
- Owner source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
- M20 CompleteClearingLoop blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- M20 ScrubbotDispatcher blob remains `eee10149e4f116af6706beec832042352bf3a6dd`.
- Root tracker correctly remained at 304/719 main+ui and 304/943 overall with `lastCompletedTaskId = M20-C001-V11`; Claude closed no M21/M22/UI checkbox.

## Accepted V04 work

### A. V03 preview-directory residual is materially closed

The V04 root suite adds a real ProductionArtLevelBuilder case where the preview destination is an existing directory with `overwrite=false`, while retaining the `overwrite=true` case. The fixture is arranged to reach destination-object-type preflight rather than an unrelated earlier failure. This satisfies the outstanding V03 evidence cell. Preserve it.

### B. TargetSelector bottom-most / left-most policy is source-accepted

`scripts/gameplay/targeting/target_selector.gd` changed from blob `a0daad67f8ba2238dd54cb903ac25dec7aa3144d` to `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.

The new comparator:

- operates on the detached Array returned by ColorCandidateIndex;
- uses canonical `BoardState.get_cell_position()`;
- orders larger `y` first, then smaller `x`, then smaller index;
- leaves malformed entries after valid ints and still lets the existing loop skip them fail-closed;
- does not add target selection to RoutingSystem, BoardRenderer, or ScrubbotAgent;
- preserves the existing strict-v2 selection/coherence/reservation transaction body after ordering.

The old ColorCandidateIndex contract was independently checked: `get_candidates()` returns a duplicate/detached Array, so V04's sort does not mutate index-owned cache truth.

The new target-order policy itself is not reopened by V05 unless a correction demonstrably affects it. Existing M15 strict-v2 regressions and the new policy tests must remain green.

### C. BoardPresentation architecture is directionally correct

The new `BoardPresentation` keeps production movement truth in board-local cell units and supplies a presentation-only AgentLayer sharing the BoardRenderer origin with scale equal to renderer cell size. The owner scene explicitly binds ScrubbotDispatcher to that AgentLayer. This is the correct architectural direction and must be preserved.

The defects below are in how the owner-playable controller drives/anchors/observes the real agents and slot UI, not a request to move screen-pixel math into routing or agent truth.

### D. SlotView boundary is directionally correct

`SlotView` is a native Godot Button consuming scalar slot ID + Color, does not retain SlotState/SlotSystem, and emits a slot activation signal. Preserve this separation. V05 may add a narrow presentation anchor/query API if needed, but must not leak mutable gameplay state.

## Frozen finding set

### F-M21-V04-001 - HIGH - Owner scene double-drives the real ScrubbotAgent

The production `ScrubbotAgent` already owns its frame movement:

```gdscript
func _process(delta: float) -> void:
    if _state == State.MOVING:
        advance(delta)
```

and `advance(delta)` internally applies `speed * delta`.

The V04 owner scene controller also calls:

```gdscript
func _process(delta: float) -> void:
    if _active_agent != null and is_instance_valid(_active_agent) and _active_agent.is_moving():
        _active_agent.advance(delta * 6.0)
```

This creates two independent movement drivers for the same real production agent. The controller call is worse than a simple duplicate tick because it passes `delta * 6.0` to an `advance()` method that multiplies by the agent's speed again. At the scene's assigned speed of 6 cells/sec, the controller contributes roughly 36 cells/sec in addition to the agent's own normal 6 cells/sec.

Consequences:

- owner-visible travel timing no longer represents production ScrubbotAgent truth;
- the marker can traverse or arrive much too quickly;
- the exact symptom V04 is meant to let the owner judge can be masked by an accelerated flash;
- tests stay green because they manually call `agent.advance()` and do not exercise a normal real-frame owner-scene movement interval.

**Required correction:** the owner scene/controller must not tick movement for a real self-processing ScrubbotAgent. The production agent's own `_process(delta)` must remain the single frame movement driver. The owner scene may observe lifecycle/presentation state only. Add a real-frame sensitivity test that fails if any parent/controller double-drives the agent and proves travel after a controlled frame interval matches the agent's speed contract.

### F-M21-V04-002 - HIGH - Visible slot geometry is not the real agent spawn origin

V04 requires a coherent conversion between the visible slot spawn presentation and the board-local RouteRequest start. The implementation does not provide that mapping.

The visible SlotBar is below the board:

```gdscript
bar.position = Vector2(BOARD_ORIGIN.x, BOARD_ORIGIN.y + BOARD_DISPLAY.y + 40.0)
```

but route origins are independently synthesized by slot ID just off the board's left edge:

```gdscript
var oy: float = (float(slot_id) + 0.5) * float(h) / float(_slots.get_slot_count())
_slot_origins.append(Vector2(-1.5, oy))
```

No visible SlotView anchor is converted from UI/global presentation coordinates through BoardPresentation/AgentLayer into board-local route space. Therefore a user clicks a button below the board while the Scrubbot is logically spawned at an unrelated left-edge point.

The claimed V04 criterion 125/126 test is not load-bearing. It checks the stored origin against a getter that returns the same stored origin:

```gdscript
inst._slot_origins[2] == Vector2(-1.5, inst.get_slot_origin(2).y)
```

It never observes SlotView geometry. This is a proxy/self-comparison and violates the direct-observability requirement.

**Required correction:** define one explicit spawn mapping from a visible SlotView anchor to board-local route space. For example, expose a presentation-only spawn anchor on SlotView, obtain its actual global position after layout, convert that point through AgentLayer/BoardPresentation inverse transform to board-local units, and use exactly that mapped value as `CompleteClearingLoop.activate_slot(... start_position ...)`. The mapped start may be outside board bounds if routing supports it.

Direct evidence must prove all of these for an actual clicked slot:

1. visible slot spawn anchor global position;
2. mapped board-local start position;
3. DispatchResult agent `spawn_origin` equals that board-local start;
4. real agent global start equals the visible slot anchor global position within explicit tolerance;
5. route endpoint still aligns with BoardRenderer target cell center.

Update the owner playtest guide so it describes the actual visible spawn behavior rather than an unrelated hardcoded left-edge origin.

### F-M21-V04-003 - HIGH - Active/in-flight presentation loses truth under allowed concurrent assignments

The V04 owner controller stores only:

```gdscript
var _active_agent = null
var _active_slot: int = -1
```

and every successful request overwrites those two fields.

The accepted M19 dispatcher does not enforce one global active agent. It keeps a dictionary of active assignments by owner, and V04's own rapid-activation test can create a second successful C08 assignment before the first completes. Therefore multiple real in-flight assignments are a valid current state.

With singular `_active_agent` / `_active_slot` bookkeeping:

- a second activation overwrites observation of the first;
- two different active slots cannot be represented correctly;
- an earlier slot can remain highlighted forever after a later activation replaces the controller's tracked slot;
- the same slot can have multiple in-flight assignments, but the visual can clear as soon as one tracked assignment resolves while another is still moving;
- the same singular controller state is also tied to the double-drive defect in F-001.

**Required correction:** do not invent a new global single-flight gameplay rule in V05. Track presentation state per real assignment/agent/owner, and maintain per-slot active counts or sets. One assignment resolving must remove only itself. A SlotView becomes inactive only when that slot has no remaining in-flight assignments. Failure/no-work must not increment active presentation. Reset/scene teardown must clear all presentation bookkeeping and leave no orphan agents.

Add direct regressions for:

- two simultaneous successful assignments from different slots after reachability permits them;
- two simultaneous successful assignments from the same slot when canonical gameplay allows them;
- one completion while another assignment for that slot remains active;
- cross-slot completion isolation;
- reset/cleanup leaves all slot visuals inactive and AgentLayer empty after queued frees are processed.

### F-M21-V04-004 - MEDIUM - Required V04 direct evidence cells 126/146/147/112 are absent or proxy-only

The V04 criteria required direct evidence for several integration boundaries. The implemented root suite does not contain equivalent load-bearing checks:

- **Criterion 126:** visible slot spawn presentation -> board-local route start correspondence. Current test is the proxy/self-comparison described in F-002.
- **Criterion 146:** second/tall portrait sanity proving slots remain visible and board readable. The V04 slot suite ends after a single 1080x2160 containment test; no second/tall portrait case is present.
- **Criterion 147:** actual visible Button click/input/signal path. The test calls `inst.request_slot(2)` directly and labels it as a visible-slot click. That bypasses `SlotView.pressed -> slot_activated -> _on_slot_activated` entirely.
- **Criterion 112:** direct AgentLayer no-orphan assertion after arrival/reset/frame cleanup. Source cleanup paths appear compatible, but the requested direct V04 presentation-container assertion is absent.

This matters because the missing observable paths are exactly where F-001/F-002/F-003 survived a 4580/4580 green suite.

**Required correction:** add sensitivity tests that directly exercise the real boundary:

1. a real SlotView activation signal/pressed path, not a direct controller method call;
2. slot-anchor-to-agent-start mapping as specified in F-002;
3. a second tall portrait viewport sanity case;
4. AgentLayer child-count/no-orphan proof after authenticated arrival + deferred cleanup and after reset;
5. tests must fail for the current V04 broken behavior for the intended reason.

Also reconcile criteria/prompt M22-001/163 evidence: the V05 log must explicitly name the already-recorded canonical gameplay/five-slot owner reference used for broad slot layout direction, and state what was used as broad guidance without copying/flattening it. No new art generation is needed.

## Why 4580/4580 does not close V04

The suite result is valuable regression evidence, but the new V04 tests are correlated with the implementation and bypass the exact broken owner-facing paths:

- movement tests manually call `advance()` instead of observing normal scene-frame movement;
- slot activation tests call the controller method directly instead of the SlotView input/signal chain;
- spawn-origin tests compare internal stored origin to itself instead of visible UI geometry;
- the single portrait containment test does not satisfy the required second aspect/tall case;
- singular active-state bookkeeping is not challenged with cross-slot presentation concurrency.

This is a concrete example of why critical gameplay/presentation closure requires direct observability beyond a green aggregate count.

## V05 correction boundaries

V05 is a focused correction/validation pass. Preserve the accepted basis:

- approved Hazard Bot source and its exact blob/hash;
- V01-V03 production-art builder corrections;
- V04 preview-directory evidence;
- V04 TargetSelector bottom-most/left-most policy and all M15 strict-v2 safety;
- board-local RouteRequest/RouteResult/ScrubbotAgent movement truth;
- BoardPresentation shared-transform architecture;
- SlotView scalar-only gameplay separation;
- M19/M20 accepted production blobs unchanged;
- 400-cell real-art smoke and all previous regression suites.

V05 should change only the narrow V04 owner-playtest presentation/controller/UI/test/doc surface needed to close F-001..F-004. If a real upstream M19/M20 defect is discovered, stop `BLOCKED` rather than patching accepted production opportunistically.

## Closure state

- V04: **CHANGES_REQUIRED**.
- Finding set: **FROZEN** as F-M21-V04-001..004.
- Owner final playtest: **BLOCKED until V05 passes independent audit**.
- M21/M22/UI task checkboxes remain open.
- Progress remains 304/719 main+ui and 304/943 overall; `lastCompletedTaskId` remains M20-C001-V11.
