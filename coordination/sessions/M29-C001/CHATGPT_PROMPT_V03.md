# M29-C001 V03 — Fix Graphical Relayout Renderer / AgentLayer Identity

Repository: `Sekiph82/Scrubbots`
Branch: `main`

Read:
- `coordination/sessions/M29-C001/CHATGPT_MANUAL_AUDIT_V03.md`
- `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V03.md`

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
