# M29-C001 V03 — Fix Graphical Relayout Renderer / AgentLayer Identity

Repository: `Sekiph82/Scrubbots`
Branch: `main`

Read:
- `coordination/sessions/M29-C001/CHATGPT_MANUAL_AUDIT_V03.md`
- `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
- `coordination/OWNER_BATCH_SLOT_DISPLAY_DECISION_V01.md`
- `coordination/OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC_DECISION_V01.md`

The owner manually ran the real Godot playtest and found that batches enter M24 and M26 commits work, but robots/pixel clears are not visible.

Root cause is confirmed:
`GameplayScreen._layout_board()` repeatedly calls `BoardPresentation.configure()`, while `BoardPresentation.configure()` creates a NEW BoardRenderer + AgentLayer on every call. Runtime/M20 remain bound to older instances.

## Required fix

Make BoardPresentation identity-stable.

Preferred shape:
- create BoardRenderer once;
- create AgentLayer once;
- later configure/relayout calls REUSE those exact nodes;
- call the existing renderer's configure/geometry refresh as needed;
- update the existing AgentLayer scale to the renderer's current cell size;
- never orphan or cover live agents by creating replacement layers;
- maintain ScrubRailView ordering.

Do not fix this by rebinding M20/dispatcher on every resize. The stable presentation nodes are the invariant.

Prevent different BoardState identity from silently rebinding an already-live production presentation if that would create split-brain truth. Fail closed or expose a narrow same-board relayout seam as appropriate.

## Direct tests

Add a dedicated regression proving:
- exact renderer identity stable across repeated relayout;
- exact AgentLayer identity stable;
- exactly one of each child;
- live moving agent survives relayout on same parent;
- authenticated clear after relayout updates the CURRENT visible renderer to transparent;
- viewport 1080x2160 -> 683x1366 -> 1080x2160;
- exact visible slot-origin V02 still passes after these relayouts.

Add a second production-style runtime smoke at 683x1366 that does NOT disable runtime processing and does NOT call `runtime.tick()` directly. Let real SceneTree frames drive `ProductionRuntimeController._process(delta)`. After one legal front activation, prove a committed Scrubbot's progress increases, it arrives, the M24 committed work resolves, and the CURRENT visible renderer pixel becomes transparent.

Also exercise embedded-focus suspension/resume explicitly: focus loss may intentionally pause gameplay, but focus regain must resume it and must not leave the playtest permanently system-suspended.

Also apply the owner-locked five-slot presentation correction:
- main displayed batch count = M24 capacity = remaining_to_clear - committed;
- a 50 batch becomes 49 immediately when one Scrubbot is successfully committed/dispatched;
- 50 with two in-flight must display 48, not "50 (2)";
- do NOT change M24 authoritative accounting: remaining_to_clear still decreases only on authenticated clear;
- keep ACTIVE/WAITING core semantics unchanged.

Add direct UI evidence for 50 -> 49 -> 48 on dispatch and stable displayed capacity through authenticated clear.

Also fix live slot-state synchronization. The current production UI refreshes M24 snapshots only after a successful player placement, so later authoritative scheduler mutations can remain visually stale. Add an exact presentation-sync seam so the M28 five-slot strip receives a fresh detached M24 snapshot after every player-visible M24 mutation, including commit/dispatch, ACTIVE->WAITING, WAITING->ACTIVE wake, rollback, authenticated-clear finalization, slot EMPTY completion and reset. UI must remain presentation-only and must not run targetability/routing itself.

Hazard Bot reference assertion:
- after Red15 + Yellow1 + Blue50 + Blue50 + Brown3 are placed and the two Blue50 batches have exhausted their immediately reachable work, Brown3 still has no reachable brown target under the accepted M27 trace;
- Brown must therefore PRESENT WAITING, not stale ACTIVE, until later black/open-corridor progress wakes it;
- when a later authoritative wake changes it back to ACTIVE, the UI must update without another player placement.

Re-run the complete M29 Hazard Bot runtime smoke.

Do not modify TASKS.md.
Do not implement M30.
Zero image-generation credits.

Push implementation first, then:
`coordination/sessions/M29-C001/CLAUDE_LOG_V03.md`

Log must contain exact owner manual retest instructions using:
`res://scenes/debug/m29_hazard_bot_playtest.tscn`
and F6.

Return only:
AWAITING_AUDIT
final implementation SHA
direct GitHub CLAUDE_LOG_V03.md URL.
