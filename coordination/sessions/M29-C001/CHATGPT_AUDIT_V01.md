# M29-C001 V01 — ChatGPT Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V01`
Auditor: ChatGPT
Owner baseline: `0cbe285c83c601483d0a2504d0cc4d24281d288e`
Implementation SHA: `d191bf6839d8e01602d99a5fe5196c17d192c32c`
Claude log SHA: `02b53caab7da36e93755d75bfac399692cf0f833`
Criteria: `coordination/sessions/M29-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CHANGES_REQUIRED / ONE PRODUCTION PLAYTEST GEOMETRY DEFECT**

M29 V01 successfully implements the production front-input transaction gate, mouse/touch deduplication, pause/focus handling, automatic M26 cadence, explicit 1x/2x gameplay speed authority, authoritative M23-exhausted auto-2x, and a real Hazard Bot runtime host.

However, the production manual path does **not** currently start robots from the actual laid-out five-slot anchors on the M28 screen.

This is a blocking M29 issue because the milestone's purpose is a visually coherent owner-runnable production playtest.

## Governance / diff integrity

Verified:
- one implementation commit from the M29 baseline;
- implementation SHA `d191bf6839d8e01602d99a5fe5196c17d192c32c`;
- root `TASKS.md` absent from Claude implementation;
- M30+ not implemented;
- separate final log commit only;
- zero image generation.

## Accepted V01 behavior

The following V01 implementation is accepted and must not be rewritten:

- only M23 supply front row is production-selectable;
- preview rows remain non-selectable;
- five M24 slot views remain read-only;
- real `M24.select_front_batch(real M23,column)` transaction;
- full-slot rejection preserves supply/slots;
- desktop mouse support;
- touch support;
- synthesized mouse/touch deduplication;
- touch cancel;
- focus-loss gesture cancellation;
- rapid-tap serialization;
- multi-touch serialization;
- separate user/system pause reasons;
- paused cadence + in-flight travel freeze;
- automatic M26 cadence without `run_until_idle()`;
- explicit 1x/2x authority without global `Engine.time_scale`;
- current and future agent travel scaling;
- authoritative `M23.is_exhausted()` auto-2x only after successful placement;
- manual toggle back to 1x;
- reset/new session 1x;
- real Hazard Bot host using M23–M27/M19/M20.

Claude reports:
- full root suite PASS;
- M29 input evidence PASS;
- M29 speed evidence PASS;
- M29 Hazard Bot runtime smoke PASS;
- 400 authenticated clears;
- 1x/2x truth equivalence;
- clean `git diff --check`.

## F-M29-V01-STRICT-001 — Production slot-origin provider ignores the actual laid-out slot anchors

M29 adds the correct presentation seams:

- `BatchSlotView.get_spawn_anchor_global()`
- `FiveSlotStrip.get_slot_anchor_global(i)`

These expose the actual top-center of each visible production slot.

However, `scripts/gameplay/runtime/slot_origin_provider.gd` does not use either seam.

Instead, `origin_for_slot()` computes:

`x = (slot + 0.5) * board_width / 5`
`y = board_height + 4`

from board dimensions alone.

The provider retains `_presentation` and `_strip`, but they are unused.

Therefore the manual production screen can show a slot at one screen position while routing starts from a different synthetic board-local position.

This breaks the owner-visible geometry contract:

`actual visible slot top-center -> BoardPresentation.global_to_board_local -> exact routing origin -> bottom rail connector`

and violates the M29 master requirement that the playtest use the actual laid-out slot origin mapping.

The headless runtime smoke does not detect this because the same synthetic origin remains routable and the board can still clear.

## Required V02 correction

Make `SlotOriginProvider.origin_for_slot(slot)` derive the route origin dynamically from presentation geometry:

1. obtain exact visible slot top-center:
   `_strip.get_slot_anchor_global(slot)`;
2. map it through:
   `_presentation.global_to_board_local(global_anchor)`;
3. validate the result is finite;
4. return that exact board-local point;
5. fail closed for invalid/unlaid-out/foreign state.

Do not cache screen-pixel coordinates across resize.

The result must update automatically after responsive relayout.

Do not fall back silently to the old synthetic five-lane origin in production.

## Required V02 direct evidence

At minimum prove:

- each of all five production slots maps:
  `strip.get_slot_anchor_global(i) -> presentation.global_to_board_local() == origin_provider.origin_for_slot(i)`
  within tight epsilon;
- evidence at 1080×2160;
- evidence after a second responsive viewport size / relayout;
- origins move consistently when layout moves;
- invalid slot fails closed;
- Hazard Bot runtime smoke still fully clears the real board using these real laid-out origins;
- no Railroad/connector/routing regressions;
- M23–M28 regressions remain green.

The manual playtest log must also include the deterministic Hazard Bot solved column order explicitly so the owner can reproduce a complete clear:

`0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2`

This log detail is not a second architecture finding; it is required so the owner can actually complete the documented manual test without reverse-engineering the solver trace.

## Closure

Do not close `SB-M29-001..009` yet.

Open one narrow `M29-C001 V02` remediation only for exact laid-out slot-origin mapping + direct evidence/log correction.

If V02 passes, close M29 in full and advance to M30 Win/Lose Rules.
