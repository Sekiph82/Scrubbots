# M22-C001 — Owner F6 Visual/Game-Feel Review V01

Date: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Gate: `SB-M22-035`
Result: **OWNER_REJECTED / CHANGES_REQUIRED**

## Observed owner-facing behavior

The Railroad V1 demo launches correctly when `res://scenes/demo/m22_slot_demo.tscn` is run directly. During manual play, the owner identified a targetability defect relative to intended gameplay:

- targets directly reachable by one straight orthogonal segment from the rail are treated as targetable;
- matching targets that are reachable only by leaving the rail into cleared/open space and then making a 90-degree turn through that cleared/open corridor are treated as untargetable;
- this causes available matching work to disappear from effective slot behavior even though a legal orthogonal cleared corridor exists.

The owner's annotated example shows two central red cells accepted because a straight upward route exists, while side-offset red cells are rejected even though they should be reachable by moving upward from the BOTTOM rail and then turning left/right through cleared space.

## Owner clarification

This review clarifies the intended movement rule. The entire post-rail approach is **not** required to be one straight target-aligned segment.

After legal rail ingress, a Scrubbot may follow a four-neighbour orthogonal route through OPEN/CLEARED cells and may make 90-degree turns before final arrival at the assigned target.

Non-target ACTIVE cells remain blockers. No diagonal path, corner cutting, teleport, or retarget is allowed.

Canonical owner revision:

`coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`

## Engineering consequence

The earlier `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE` remains valid for the functionality it actually proved, but owner F6 has revealed a production-policy mismatch in targetability/routing. Therefore engineering must reopen narrowly for this route-policy correction before `SB-M22-035` can close.

Do not mark `SB-M22-035` complete. Do not advance M23 on the basis of the rejected F6 gate.
