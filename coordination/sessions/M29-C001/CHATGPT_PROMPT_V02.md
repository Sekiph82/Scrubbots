# M29-C001 V02 — Exact Laid-Out Slot Origin Remediation

Repository: `Sekiph82/Scrubbots`
Branch: `main`

Read:
- `coordination/sessions/M29-C001/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M29-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

This is ONE narrow remediation.

## Fix only the blocking defect

The production SlotOriginProvider currently ignores the visible slot anchors and synthesizes five board-width lanes.

Replace that production authority with the actual M28 layout mapping:

`global_anchor = FiveSlotStrip.get_slot_anchor_global(slot)`

`board_local_origin = BoardPresentation.global_to_board_local(global_anchor)`

`origin_for_slot(slot) = board_local_origin`

Requirements:
- use the current laid-out geometry dynamically;
- no stale cached screen origin;
- no synthetic board_width/5 fallback;
- fail closed for invalid/dead/unlaid-out/non-finite state;
- preserve all accepted M29 V01 behavior.

## Direct evidence

Add a focused V02 test proving all five slot origins equal the exact visible top-center mapping at 1080×2160 and after a different responsive layout/viewport.

Then re-run the real Hazard Bot production runtime smoke using those actual origins and prove full clear.

Preserve M22 connector/Railroad rules.

## Manual log

The V02 log must include exact F6 manual instructions and the solved click order:

`0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2`

Column indices are zero-based in engineering evidence. For the owner-facing wording, also write them as:
`1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`.

Do not modify TASKS.md.
Do not implement M30.
Zero image-generation credits.

Push implementation first, then `coordination/sessions/M29-C001/CLAUDE_LOG_V02.md` as a separate final commit.

Return only:
AWAITING_AUDIT
final implementation SHA
direct GitHub log URL.
