# M29-C001 V03 — Owner Manual Playtest Regression Audit

Date: 2026-09-19
Repository: `Sekiph82/Scrubbots`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Source: owner graphical Godot playtest after M29 V02 PASS

## Verdict

**M29 REOPENED / CHANGES_REQUIRED**

The owner ran:

`res://scenes/debug/m29_hazard_bot_playtest.tscn`

in graphical Godot and transferred five batches from the first supply column.

Visible slot state proved production input + dispatch had started:
- five M24 slots were occupied;
- at least one slot displayed committed in-flight work, e.g. `50 (2) ACTIVE`.

However:
- no visible Scrubbot movement was observed;
- board pixels did not visibly clear.

The owner supplied a graphical screenshot at approximately 683×1366 embedded-game viewport.

A second owner screenshot taken approximately three minutes later showed the same visible slot/accounting state, including the same committed in-flight count (for example `50 (2) ACTIVE`), and the same uncleared board image. This means the manual regression cannot be closed by proving renderer identity alone: the real SceneTree-driven runtime clock must also prove that committed agents actually advance and arrive without tests manually calling `runtime.tick()`.

## F-M29-MANUAL-001 — responsive relayout recreates BoardRenderer and AgentLayer after runtime binding

Root cause is in the production presentation lifecycle.

`GameplayScreen._layout_board()` calls:

`_presentation.configure(_board, _palette, ...)`

on every responsive relayout.

But `BoardPresentation.configure()` currently creates NEW children every call:

- a new `BoardRenderer`;
- a new `AgentLayer`.

It does not reuse or remove the prior instances.

M29 production host binds:
- M20 clearing loop to the renderer instance returned during host build;
- dispatcher/runtime to the AgentLayer instance returned during host build.

A later graphical resize/relayout can therefore create newer presentation instances while the runtime remains bound to the old ones.

Result:

1. M20 clears BoardState and updates the OLD bound BoardRenderer.
2. A NEWER BoardRenderer is drawn later/on top and remains visually unchanged.
3. Dispatcher spawns/moves ScrubbotAgents in the OLD AgentLayer.
4. A NEWER renderer/layer ordering can cover or visually separate those agents.
5. Headless BoardState/runtime tests still pass because authoritative gameplay truth clears correctly, while the owner sees no visible cleaning.

The duplicate presentation-node lifecycle is a confirmed graphical coherence bug and explains how authoritative clears/agents can become invisible. The unchanged second screenshot additionally requires direct verification of the real graphical `_process(delta)` runtime clock, because the owner's committed count did not visibly progress for approximately three minutes.

## Required correction

BoardPresentation presentation-node identity must be stable for the lifetime of a production gameplay host.

After initial construction:
- do NOT create a second BoardRenderer during relayout;
- do NOT create a second AgentLayer during relayout;
- resize/reconfigure the existing BoardRenderer instance;
- update the existing AgentLayer transform/scale;
- preserve live ScrubbotAgent children through relayout;
- keep ScrubRailView ordering coherent;
- keep M20's renderer identity equal to the currently visible renderer;
- keep dispatcher/runtime AgentLayer identity equal to the currently visible AgentLayer.

A responsive relayout must change geometry, not presentation authority identity.

## Direct regression evidence required

Before -> after one or more relayouts:
- `presentation.get_renderer()` exact identity unchanged;
- `presentation.get_agent_layer()` exact identity unchanged;
- exactly one BoardRenderer child;
- exactly one AgentLayer child;
- an in-flight Scrubbot remains parented to the same AgentLayer;
- relayout updates the layer scale/geometry without replacing it;
- M20 authenticated clear makes the CURRENT visible renderer cell transparent;
- real Hazard Bot production runtime still reaches 400 authenticated clears / ACTIVE=0;
- a SceneTree-driven production smoke with `ProductionRuntimeController._process(delta)` enabled, not a test that manually calls `runtime.tick()`, proves committed agents advance, arrive and visibly clear pixels.

Viewport evidence must include:
- 1080×2160;
- 683×1366, matching the owner's embedded graphical test;
- one resize transition between them.

## Manual retest

After the fix the owner must repeat the same F6 playtest:
- click first supply column fronts;
- committed counts may appear;
- visible debug Scrubbot circles must actually move;
- pixels must visibly become transparent after arrivals.

M30 remains blocked until this graphical M29 regression is closed.


## Owner presentation correction discovered during manual review

The owner also clarified that the main number on each occupied five-slot batch represents robots still physically waiting in that slot.

Canonical presentation:
`display_count = remaining_to_clear - committed`.

Therefore the screenshot state `50 (2)` is not the desired shipping presentation. With two committed in-flight Scrubbots it must display `48`.

This is UI/presentation only. M24 authoritative accounting remains unchanged: `remaining_to_clear` decrements only after authenticated clear.

Owner decision:
`coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`.

The same manual review confirmed that Red/Yellow WAITING is not automatically a bug. In the deterministic Hazard Bot first column, Red 15 and Yellow 1 have no immediate clears in the accepted M27 solution trace before Blue opens progress. WAITING therefore correctly means "no currently claimable reachable target"; ACTIVE is eligibility, not proof that a robot is currently moving.


## F-M29-MANUAL-002 — five-slot UI snapshot is stale after scheduler mutations

Owner review identified that Brown 3 was displayed ACTIVE while Red/Yellow were WAITING.

The accepted M27 Hazard Bot solution trace confirms the owner's topology observation:
- Red15: 0 immediate clear;
- Yellow1: 0 immediate clear;
- Blue50: 50 clear;
- Blue50: another 50 clear;
- Brown3: still 0 immediate clear.

Therefore Brown3 is not currently reachable/claimable at that state and, once M25/M26 evaluates it, its authoritative lifecycle must be WAITING until later corridor-opening progress.

The production UI currently calls `GameplayScreen.update_snapshots(...)` only after successful player placement in `ProductionInputController`. Scheduler-driven M24 changes such as commit, ACTIVE->WAITING, wake, rollback, finalize and slot-empty completion have no production presentation refresh seam. This can leave the player seeing an old ACTIVE state and old count indefinitely.

Required V03 correction:
- introduce authoritative live slot-presentation synchronization using fresh detached M24 snapshots;
- do not let UI infer targetability;
- Brown3 must visibly become WAITING in the above Hazard Bot state without another player click;
- later wake must visibly return it to ACTIVE automatically.

Canonical decision:
`coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`.
