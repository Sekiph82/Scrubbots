# M22-C001 V03 - Claude Reconciliation Prompt

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: close the frozen M22-C001 V02 strict-audit findings in one pass.

Authoritative inputs:

- `TASKS.md` - read-only for Claude
- `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_V02.md`
- `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V03.md`
- `coordination/sessions/M22-C001/CLAUDE_LOG_V02.md`

The V02 finding set is frozen. Do not create a partial fix, do not ask to split the task, and do not advance to M23. Close all four findings together:

1. `F-M22-V02-STRICT-001`
2. `F-M22-V02-STRICT-002`
3. `F-M22-V02-EVIDENCE-001`
4. `F-M22-V02-EVIDENCE-002`

## 1. Start with GitHub/local synchronization

Before editing:

1. Confirm the working repository is exactly `Sekiph82/Scrubbots` on `main`.
2. Fetch/safely synchronize with current `origin/main` without destroying owner/local tracked or untracked work.
3. Record exact starting `origin/main` SHA.
4. Read every authoritative file listed above.
5. Read the current production routing, rail geometry, rail view, BoardPresentation, SlotView/SlotCell, ColorSelectionPanel, GameplaySlotDemo, ProductionAccessQuery, RouteValidator, TargetSelector, dispatcher, agent and clearing-loop source.
6. Read current M22 Railroad tests and the relevant M21/M20 regressions.
7. Do not modify root `TASKS.md`.

No force push, no destructive clean/reset, no owner-art regeneration, no M23 work, no Magnific/image generation.

## 2. Correct production exterior routing

The current V02 implementation only enters Railroad V1 for `start.y >= board.height`; other outside starts can still fall through to the superseded M21 adjacent ring. That is not accepted.

Correct `ProductionRoutingSystem` so that current production **outside** routing no longer uses the old `x=-1 / x=W / y=-1 / y=H` ring as an exterior movement lane.

Required behavior:

- real SlotCell starts remain exact clicked anchor -> BOTTOM connector -> canonical Railroad V1;
- top/left/right/below outside starts must use a Railroad-compatible current policy or fail closed according to the existing routing contract;
- an outside start must never silently enter the obsolete adjacent-ring planner;
- if a legacy/non-rail planner remains for compatibility, restrict it explicitly to genuine inside-board debug/test starts only;
- keep TargetSelector WHAT-order unchanged;
- never retarget in routing;
- do not weaken ProductionAccessQuery or RouteValidator to force success;
- generic shortcut/rounding must never cut Railroad geometry.

Migrate current regression expectations that force production left/right/top outside injections to use the old ring. Preserve historical M21 V07-V10 evidence files rather than rewriting their history.

## 3. Add independent post-layout SlotCell connector evidence

V02's real Button integration test presses before completed layout and then compares route point 0 with `agent.spawn_origin`, which is circular evidence. The logged slot-2 start `(0.0,24.0)` is therefore not accepted as the real laid-out C08 anchor.

Add a dedicated frame-driven test, preferably a V03-specific test script, that:

1. Hosts the real `m22_slot_demo.tscn` inside a real `SubViewport`.
2. Awaits enough process/layout frames before measuring SlotCell geometry.
3. Observes exactly five actual production SlotCell/Button instances.
4. For every slot ID `0..4`, independently captures the real top-center global anchor from the laid-out Button.
5. Independently maps each anchor through `BoardPresentation.global_to_board_local()`.
6. Proves the five mapped starts are distinct and one-to-one with slot IDs.
7. Presses real Buttons and proves route point 0 equals that independently measured mapped anchor.
8. Proves route point 1 equals `ScrubRailGeometry.bottom_entry(mapped_start.x)` and that x is only clamped if actually outside the legal rail span.
9. Proves the connector is a real visible route segment, not a teleport.
10. Repeats the anchor mapping at a second viewport/layout case and proves values are re-read from current geometry, not cached stale state.

On a fresh Hazard Bot scene, the real laid-out C08 Button must still naturally produce target `380 / (0,19)` through:

`actual slot-2 anchor -> bottom connector -> Railroad -> aligned exit -> (0.5,19.5)`.

Record the actual measured slot-2 anchor and exact route points in `CLAUDE_LOG_V03.md`.

## 4. Strengthen direct Railroad-domain tests

V03 must close the direct-evidence gaps, not merely relabel old tests.

Add direct assertions that classify every successful Railroad route into:

- connector segment(s);
- canonical rail segment(s);
- exactly one final aligned orthogonal target approach.

For rail travel, prove:

- each segment lies exactly on TOP/BOTTOM/LEFT/RIGHT canonical centreline;
- a side change occurs only at an exact canonical corner;
- no intermediate rail segment wanders through the two-cell clearance free-space;
- axis-alignment by itself is not used as confinement proof;
- no diagonal slot shortcut, corner cut, early exit or diagonal final approach exists.

Also add or correct these cases:

- far-left/bottom target through BOTTOM rail;
- a **true far-right/top target** that requires real corner/side travel and an aligned exit;
- at least one two-side route using a real corner between distinct non-corner rail points;
- blocked preferred exit -> another legal side for the SAME target;
- all aligned exits blocked -> `NO_ROUTE`, same target index, no side effects;
- shortest legal total Railroad route selection;
- exact equal-distance tie-break `BOTTOM -> LEFT -> RIGHT -> TOP`;
- rectangular routing with **both dimensions inside 20..59**;
- 59x59 routing.

Do not use `19x19` or `30x12` as the production acceptance proof. Generic helper tests outside the production envelope may remain only if useful, but the required acceptance evidence must be inside 20..59 per axis.

## 5. Preserve accepted authority and lifecycle

V03 must keep all of this green:

- V01 reusable five-slot architecture;
- exactly five visible production slots;
- minimum touch size and responsive ordering;
- no hidden SPACE/keyboard gameplay dispatch;
- `ColorSelectionPanel.bind_colors()` fail-closed behavior;
- TargetSelector bottom-most/left-most targetable ordering;
- ReservationState atomic uniqueness;
- CompleteClearingLoop authenticated clear authority;
- rapid three C08 assignments with unique targets/owners;
- correct active visual while multiple agents are in flight;
- reset with at least two agents travelling, with reservations/assignments released, no false clears and zero orphan agents;
- single-source ScrubRail geometry and procedural theme-independent rail view;
- zero generated-art dependency/credits.

Do not invent congestion, lanes, collision, refill, quantity, economy, booster, win/lose or M23 screen rules.

## 6. Required validation

Run and record exact command, result, check count where applicable, and exit code for at least:

1. `godot --version`
2. full `tests/run_tests.gd`
3. the dedicated V03 Railroad/domain test(s)
4. real post-layout SlotCell connector evidence on at least two viewport/layout cases
5. current `tests/m22_railroad_responsive_smoke.gd` or its deliberate V03 replacement
6. current M22 V01 responsive/component regression
7. M21 full 400-cell real-art clear under current production routing
8. M21 V10 reservation/direct-evidence regression
9. required M20 lifecycle/clearing smokes
10. current TargetSelector/reservation/dispatcher/ScrubbotAgent strict regressions
11. headless M22 demo boot with zero SCRIPT/Parse errors
12. `git diff --check`

Historical M21 V08/V09 scripts may retain failures whose only failing assertions encode the deliberately superseded exact adjacent ring. Do not edit them just to turn history green, and do not restore obsolete production geometry to satisfy them.

## 7. Git / evidence handoff

Use a non-circular evidence procedure.

1. Review the complete implementation diff and prove root `TASKS.md` is absent.
2. Commit the implementation/tests/docs with a focused V03 commit.
3. Push that implementation commit to `origin/main`.
4. Capture its exact GitHub SHA.
5. Create `coordination/sessions/M22-C001/CLAUDE_LOG_V03.md` **after the implementation SHA exists**, recording:
   - exact starting SHA;
   - exact V03 implementation SHA;
   - exact changed files;
   - final outside-start routing policy;
   - five real post-layout anchors and mapped starts for at least one viewport;
   - exact real C08 slot-2 post-layout start and route points;
   - second viewport/re-layout proof;
   - far-right/top route and rail-domain proof;
   - blocked fallback/all-blocked/shortest/tie-break evidence;
   - rapid/reset evidence;
   - every required validation command/result/count/exit;
   - historical-only failures, if any, classified precisely;
   - `Magnific/image-generation credits spent = 0`;
   - root `TASKS.md` unchanged.
6. Commit and push the log as a separate evidence commit if necessary. This evidence commit's SHA may be recorded separately; do not falsely call it the implementation SHA.
7. Verify both implementation and log are visible on GitHub `main`.
8. Handoff state: `AWAITING_AUDIT`.

Do not claim PASS. ChatGPT performs the independent V03 audit and owns any `TASKS.md` checkbox/status changes and the later owner F6 gate.
