# M22-C001 — Owner F6 Railroad V1 Visual / Game-Feel Acceptance Gate

Date opened: 2026-09-17
Repository: `Sekiph82/Scrubbots`
Engineering basis: `coordination/sessions/M22-C001/CHATGPT_AUDIT_V06.md`
Engineering verdict: `AUDITED_PASS / RAILROAD_V1_ENGINEERING_CLOSURE`
Owner task: `SB-M22-035`
Status: **AWAITING_OWNER_VISUAL_ACCEPTANCE**

## Purpose

Engineering correctness is closed. This gate is not another code audit. It is the owner's visual/game-feel decision for the actual Railroad V1 demo.

The owner should run the current M22 production demo in Godot and decide whether the Railroad V1 presentation and movement feel are acceptable as a production direction.

## Required owner observations

Approve only if all of the following look acceptable in the real rendered demo:

1. The real Hazard Bot pixel artwork is clearly visible and remains the dominant visual focus.
2. There is visibly comfortable breathing room between the artwork and railroad, consistent with the locked two-logical-cell clearance.
3. The same robotic cleaning railroad is present on all four sides of the artwork.
4. Rounded railroad corners look intentional and visually coherent.
5. The railroad's dark-slate / restrained cyan-electric visual language feels appropriate for ScrubBots and does not overpower the artwork.
6. Exactly five color slots are visible below the bottom railroad.
7. Clicking a real slot visibly starts the Scrubbot from that clicked slot rather than teleporting from a generic origin.
8. The slot-to-bottom-rail connector is visibly understandable as part of the Scrubbot's movement.
9. Once on the railroad, the Scrubbot visibly remains on railroad sides and turns through railroad corners rather than cutting through exterior free space.
10. The Scrubbot leaves the railroad only from a point aligned with its already-assigned target row or column.
11. The final movement from railroad to target is visually orthogonal, with no diagonal shortcut or early rail departure.
12. On a fresh Hazard Bot run, clicking C08 naturally sends the first Scrubbot to the bottom-left target corresponding to index `380`, coordinate `(0,19)`.
13. Multiple rapid dispatches and normal movement do not make the railroad presentation visually confusing.
14. Overall railroad scale, spacing, contrast, corner treatment, connector appearance and Scrubbot motion feel acceptable for continued production work.

## Owner response

Record one of these outcomes:

- `OWNER_F6_PASS` — Railroad V1 visual/game-feel direction accepted. `SB-M22-035` may close and ChatGPT may determine the next M22/M23 transition from canonical `TASKS.md`.
- `OWNER_F6_CHANGES_REQUESTED` — record concrete visual/game-feel changes. Engineering correctness remains closed unless the requested visual change alters routing/gameplay truth.

Do not mark `SB-M22-035` complete without explicit owner approval.
