# M29-C001 V02 — Exact Visible Slot-Origin Remediation Criteria

Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V02`
Prior audit: `coordination/sessions/M29-C001/CHATGPT_AUDIT_V01.md`

## Verdict policy

V02 passes only if `F-M29-V01-STRICT-001` is closed without regressing accepted M29 V01 behavior.

## 1. Exact production origin

`SlotOriginProvider.origin_for_slot(i)` must derive the routing start from the actual laid-out M28 production slot:

`FiveSlotStrip.get_slot_anchor_global(i)`
-> `BoardPresentation.global_to_board_local(...)`

No synthetic `board_width/5` lane calculation may remain as production authority.

## 2. Dynamic responsive mapping

The provider must query current layout geometry, not cache stale screen coordinates.

Prove exact mapping before and after responsive relayout / viewport change.

## 3. Fail closed

Return an invalid/fail-closed result for:
- out-of-range slot;
- missing/dead strip;
- missing/dead presentation;
- non-finite mapped origin.

No silent synthetic fallback.

## 4. Railroad / route integration

With the exact visible origin:
- route point 0 / request origin corresponds to the visible slot top-center mapping;
- connector still reaches canonical BOTTOM rail;
- M22 Railroad V1/V07 rules remain intact;
- no diagonal/corner-cut/teleport.

## 5. Real Hazard Bot

Re-run the M29 real runtime smoke with the exact visible origins.

The real board must still reach:
- 400 authenticated clears;
- final ACTIVE = 0;
- no ghost robot;
- no duplicate target;
- M23 fully exhausted;
- auto-2x after final successful transfer.

If the previous M27 solved supply order is no longer sufficient under the actual visible origins, do not reintroduce synthetic origins. Fix the integration while preserving production geometry and accepted gameplay authorities.

## 6. Preserve V01

No broad rewrite of:
- input gate;
- mouse/touch dedup;
- rapid/multitouch;
- pause/focus;
- cadence;
- speed authority;
- auto-2x;
- M23–M27 engines.

## 7. Manual playtest documentation

`CLAUDE_LOG_V02.md` must provide exact F6 instructions and explicitly include the known deterministic solved column sequence:

`0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2`

so the owner can reproduce a complete clear.

## 8. Regression floor

Run/report:
- full root suite;
- M29 input evidence;
- M29 speed evidence;
- new exact-origin evidence;
- M29 Hazard Bot runtime smoke;
- M28 viewport smoke;
- M27 Hazard/59/generation;
- M26 Hazard/scale;
- M25 V03;
- M24 V02;
- M23 V03;
- M22 Railroad/connector/real-demo;
- M20 lifecycle;
- `git diff --check`.

## 9. Governance

- root TASKS read-only for Claude;
- implementation first;
- `CLAUDE_LOG_V02.md` separate final commit;
- no M30;
- zero image generation.
