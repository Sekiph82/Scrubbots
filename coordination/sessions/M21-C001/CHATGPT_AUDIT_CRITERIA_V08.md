# M21-C001 V08 — Validation-Only Strict Audit Criteria

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Scope: post-V07 critical-sprint adversarial validation only
Production state under validation: V07 candidate implementation at `d704e2c12d67da428a9a5bd28e645ea430eb1d34` plus ChatGPT audit/docs commits

V08 is **production immutable**. It exists only because V07 changed production routing in a critical milestone and the auditor cannot independently execute Godot. Claude may add focused tests/evidence/log files only. If a genuine source defect is exposed, stop `BLOCKED`; do not patch production.

## A. Governance / immutability

- **V08-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **V08-002** Safely sync first and preserve owner/local tracked and untracked work.
- **V08-003** Read `CLAUDE.md`, `TASKS.md`, `AUDIT_POLICY.md`, `AUDIT_INDEX.md`, `CHATGPT_AUDIT_V07.md`, V07 prompt/criteria/log, owner findings, and current owner guide.
- **V08-004** Do not modify root `TASKS.md`.
- **V08-005** Do not modify any `scripts/**` production source.
- **V08-006** Do not modify any `scenes/**` source.
- **V08-007** Do not modify `project.godot`.
- **V08-008** Do not modify LevelData, generated M21 level JSON, preview, metadata, reference composite, or owner PNG.
- **V08-009** Do not modify V07 owner decisions/findings to make evidence fit.
- **V08-010** If a validation test exposes a production defect, stop `BLOCKED` instead of fixing it.
- **V08-011** No force push, hard reset, destructive clean/restore, or owner-work deletion.
- **V08-012** V08 implementation diff contains only authorized test/evidence/log artifacts.

## B. Production blob lock

The following blobs must remain exact:

- **V08-013** `production_routing_system.gd` = `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`.
- **V08-014** `m21_real_art_vertical_slice.gd` = `153c042a17dc0ef9e83699a0beb2932217057ff4`.
- **V08-015** Hazard Bot PNG = `b565743ba52699899007882b750b7c8e7cdd00f9`.
- **V08-016** CompleteClearingLoop = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- **V08-017** ScrubbotDispatcher = `eee10149e4f116af6706beec832042352bf3a6dd`.
- **V08-018** TargetSelector = `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.
- **V08-019** ProductionAccessQuery = `7ba9d13556abb0e3a0a6d281449438330a25386d`.
- **V08-020** BoardPresentation = `2093df48d367903d332a910dfb3369154831a9ed`.
- **V08-021** SlotView = `480dffc0ee135150bd3dd2258f002264273ead10`.
- **V08-022** ScrubbotAgent = `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370`.

## C. Fresh source-level slot-only validation

- **V08-023** Read owner controller source as text in a validation test or explicit command.
- **V08-024** Assert no `KEY_SPACE` token exists in owner controller source.
- **V08-025** Assert no gameplay `_unhandled_input` hook exists in owner controller source.
- **V08-026** Assert no `step_one_clear` symbol exists in owner controller source.
- **V08-027** Assert no replacement `_input`/`_shortcut_input` keyboard dispatch path exists in owner controller source.
- **V08-028** Instantiate the real owner scene and prove exactly five SlotViews.
- **V08-029** Disconnect one SlotView's `slot_activated` from the scene handler, emit/press the real Button, and prove no dispatch/clear occurs.
- **V08-030** Reconnect the real signal path, press the real Button, and prove a real dispatch occurs.
- **V08-031** Successful dispatch route[0] equals exact clicked SlotView global spawn anchor mapped through BoardPresentation.
- **V08-032** A no-work slot click creates zero agent, zero reservation and zero clear side effect.

## D. Instrumented exact-ring domain

Create a test-only recording access wrapper around the unchanged `ProductionAccessQuery`. It must delegate real verdicts while recording planner calls.

- **V08-033** Wrapper implements the complete production access seam required by ProductionRoutingSystem.
- **V08-034** Wrapper preserves exact `is_bound_to(board)` semantics.
- **V08-035** Wrapper delegates actual classify/segment/cell-of-point truth; it does not invent a permissive fake route.
- **V08-036** On a fresh 20x20 far-bottom routing case, every outside `classify_cell(cx,cy)` planner query is inside the exact ring bounds `x=-1..20`, `y=-1..20`.
- **V08-037** Every outside planner-classification query is either top, bottom, left, right or a corner ring cell, never a second exterior lane.
- **V08-038** The exact start connector may begin farther outside the ring, but no BFS classification/search cell beyond the ring is observed.
- **V08-039** At least one successful route records ring-cell classifications/segment checks that are load-bearing to success.
- **V08-040** A test-only access wrapper that classifies all exterior/ring cells BLOCKED makes the far-left bottom target unreachable while leaving production code unchanged.
- **V08-041** The blocked-ring case returns failure for the same assigned target, never retargets.

## E. Fresh four-side/corner arrangements

Use fresh fixtures not copied mechanically from the V07 helper.

- **V08-042** Below-board origin reaches far-left bottom perimeter target.
- **V08-043** Above-board origin reaches far-right top perimeter target.
- **V08-044** Left-of-board origin reaches far-bottom left perimeter target.
- **V08-045** Right-of-board origin reaches far-top right perimeter target.
- **V08-046** At least one route must require a corner transition between adjacent exterior sides.
- **V08-047** Inspect that corner route and prove its route/access evidence actually touches both involved exterior sides.
- **V08-048** Rectangular board case uses independent width and height and succeeds.
- **V08-049** A 59x59 case succeeds without changing production.
- **V08-050** Record 59x59 route-computation elapsed CPU diagnostic separately; no arbitrary pass/fail threshold.
- **V08-051** A fully enclosed interior ACTIVE target stays unreachable despite the ring.
- **V08-052** A formerly enclosed interior target becomes reachable only after a legitimate CLEARED opening is created.
- **V08-053** A diagonal squeeze between ACTIVE blockers remains rejected.

## F. Fresh Hazard Bot real-scene adversarial validation

- **V08-054** Start from a freshly instantiated owner scene.
- **V08-055** Stimulus is the real visible C08 Button path, not `request_slot()` directly.
- **V08-056** Exact slot id = 2 and slot color = C08/local palette id 2.
- **V08-057** First target index = 380.
- **V08-058** First target coordinate = `(0,19)`.
- **V08-059** First target is ACTIVE before dispatch and C08.
- **V08-060** route[0] equals exact mapped visible slot anchor.
- **V08-061** route final point equals `(0.5,19.5)`.
- **V08-062** Every route segment is independently revalidated through unchanged `RouteValidator`/ProductionAccessQuery.
- **V08-063** Route reaches the assigned target without any segment crossing a non-target ACTIVE board cell.
- **V08-064** Authenticated arrival clears exactly 380 and no unrelated cell.
- **V08-065** Candidate index no longer contains cleared 380 for C08.
- **V08-066** Reservation map contains no stale owner/target after completed clear.
- **V08-067** Dispatcher active count returns to zero after completion.
- **V08-068** AgentLayer returns to zero ScrubbotAgent children after deferred cleanup.

## G. Rapid same-slot / reservation validation

On a fresh owner scene, before allowing the first accepted C08 agent to arrive:

- **V08-069** Press C08 rapidly at least three times through the real Button path.
- **V08-070** If all three activations are accepted under current dispatcher rules, their target IDs are exactly distinct `380,381,382` in that order.
- **V08-071** Every accepted assignment has a unique owner id.
- **V08-072** Every accepted target has an exact bidirectional reservation mapping.
- **V08-073** No duplicate target is assigned.
- **V08-074** Slot active presentation remains active while any C08 assignment remains in flight.
- **V08-075** If any rapid activation is legitimately refused by existing rules, prove zero side effects for that refusal and continue with a serial equivalent rather than weakening the assertion.
- **V08-076** After all accepted agents arrive, targets clear exactly once and all reservations/agents clean up.

## H. Reset/cancel while exterior-routed agents are active

- **V08-077** Fresh scene dispatches at least two accepted exterior-routed C08 agents without completing them.
- **V08-078** Capture exact BoardState/candidate/reservation/agent counts before reset.
- **V08-079** Call the canonical reset path.
- **V08-080** Reset removes all dispatcher active assignments.
- **V08-081** Reset releases all reservations.
- **V08-082** Reset/cancel leaves no orphan ScrubbotAgent nodes after deferred cleanup.
- **V08-083** Reset does not clear in-flight target pixels merely because agents existed.
- **V08-084** Candidate truth after reset remains coherent with BoardState.
- **V08-085** A new post-reset C08 click can again select the correct fresh bottom-left target when board state is fresh/unchanged.

## I. Route/result integrity

- **V08-086** Every successful fresh route is a real RouteResult with success metadata coherent.
- **V08-087** Every successful route retains the originally requested target index.
- **V08-088** Every route begins at exact request start and ends at exact target center.
- **V08-089** Every route point is finite.
- **V08-090** RouteValidator returns NONE for every claimed success.
- **V08-091** A deliberately malformed/nonfinite request still fails closed under inherited production code.
- **V08-092** A same-size different BoardState/access bundle still fails coherence checks under inherited strict tests.

## J. Regression suite

- **V08-093** Full root suite passes and exact check count is logged.
- **V08-094** V07 corridor smoke passes unchanged.
- **V08-095** V06 tall-layout smoke passes unchanged.
- **V08-096** V05 playtest smoke passes unchanged.
- **V08-097** M21 real-art 400-clear smoke passes unchanged.
- **V08-098** All required M20 lifecycle/queue-free smokes pass.
- **V08-099** Existing M15/M16/M17/M18/M19 strict tests touched by routing assumptions remain green.
- **V08-100** Owner scene headless boot has zero SCRIPT/Parse errors.
- **V08-101** M21 level build rerun remains UNCHANGED.
- **V08-102** M21 reference composite rerun remains UNCHANGED.
- **V08-103** `git diff --check` is clean for authorized V08 changes.

## K. Engine/environment evidence

- **V08-104** Record exact `godot --version` actually used.
- **V08-105** Do not install, upgrade, downgrade or otherwise change Godot as part of V08.
- **V08-106** If current installed engine differs from historical 4.7.1, report the drift plainly; do not fabricate 4.7.1 execution.

## L. Handoff / closure law

- **V08-107** Create `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`.
- **V08-108** Log exact commands, exits, fresh tuple evidence, timing diagnostic, locked blob rechecks and changed-file set.
- **V08-109** Root `TASKS.md` remains byte-identical throughout Claude V08 work.
- **V08-110** No M21/M22/UI task is closed by Claude.
- **V08-111** No audit verdict/file is authored by Claude.
- **V08-112** Authorized V08 diff contains no production source change.
- **V08-113** Push safely to `origin/main` and return the required two-line handoff.
- **V08-114** If any fresh validation exposes a production defect, return `BLOCKED` and stop without patching it.
- **V08-115** If V08 independently audits clean, ChatGPT updates `TASKS.md` to `OWNER_REQUIRED` and only then asks the owner to run the manual F6 playtest.
- **V08-116** M21 closes only after the owner explicitly confirms the slot-only input and visible bottom-left-first exterior-corridor behavior.