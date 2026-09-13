# M21-C001 V08 — Final Technical Validation-Only Strict Audit Criteria

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Scope: post-V07 production-immutable adversarial validation
Production state under validation: V07 candidate `d704e2c12d67da428a9a5bd28e645ea430eb1d34` plus later ChatGPT coordination/tracker commits only
Owner gate: **PASS already recorded** in `coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V07_PASS.md`

V08 is **production immutable**. It exists because V07 changed production routing in a critical milestone and ChatGPT cannot independently execute Godot. The owner has already repeated the V07 manual F6 playtest and passed it. If V08 independently audits clean with production unchanged, ChatGPT may directly close M21. If V08 exposes a genuine production defect, Claude stops `BLOCKED` and does not patch production.

## A. Governance / immutability

- **V08-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **V08-002** Safely sync first and preserve owner/local tracked and untracked work.
- **V08-003** Read `CLAUDE.md`, root `TASKS.md`, audit policy/index, V07 prompt/criteria/log/audit, owner findings, owner guide, and `CHATGPT_OWNER_GATE_V07_PASS.md`.
- **V08-004** Do not modify root `TASKS.md`.
- **V08-005** Do not modify any accepted `scripts/**` production source.
- **V08-006** Do not modify any accepted `scenes/**` source.
- **V08-007** Do not modify `project.godot`.
- **V08-008** Do not modify M21 LevelData/generated JSON/preview/metadata/reference composite/owner PNG.
- **V08-009** Do not rewrite V07 owner findings or owner PASS evidence to fit results.
- **V08-010** If validation exposes a production defect, stop `BLOCKED` instead of fixing it.
- **V08-011** No force push, hard reset, destructive clean/restore, or owner-work deletion.
- **V08-012** V08 committed diff contains only authorized test/evidence/log artifacts.

## B. Production blob lock

- **V08-013** `production_routing_system.gd` blob = `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`.
- **V08-014** `m21_real_art_vertical_slice.gd` blob = `153c042a17dc0ef9e83699a0beb2932217057ff4`.
- **V08-015** Hazard Bot PNG blob = `b565743ba52699899007882b750b7c8e7cdd00f9`.
- **V08-016** CompleteClearingLoop blob = `06391839523cbc27e88a4b3ef12b730012cd45fa`.
- **V08-017** ScrubbotDispatcher blob = `eee10149e4f116af6706beec832042352bf3a6dd`.
- **V08-018** TargetSelector blob = `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.
- **V08-019** ProductionAccessQuery blob = `7ba9d13556abb0e3a0a6d281449438330a25386d`.
- **V08-020** BoardPresentation blob = `2093df48d367903d332a910dfb3369154831a9ed`.
- **V08-021** SlotView blob = `480dffc0ee135150bd3dd2258f002264273ead10`.
- **V08-022** ScrubbotAgent blob = `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370`.

## C. Fresh source-level slot-only validation

- **V08-023** Read owner controller source as text in validation.
- **V08-024** Assert no `KEY_SPACE` token exists in owner controller source.
- **V08-025** Assert no gameplay `_unhandled_input` hook exists.
- **V08-026** Assert no `step_one_clear` symbol exists.
- **V08-027** Assert no replacement `_input`/`_shortcut_input` keyboard gameplay-dispatch path exists.
- **V08-028** Instantiate real owner scene and prove exactly five SlotViews.
- **V08-029** Disconnect one real SlotView `slot_activated` connection, press/emit its real Button path, and prove no dispatch/clear.
- **V08-030** Reconnect the real signal path, press the real Button, and prove real dispatch.
- **V08-031** Successful route[0] equals exact clicked SlotView spawn anchor mapped through BoardPresentation.
- **V08-032** A no-work slot click creates zero agent, reservation and clear side effects.

## D. Instrumented exact-ring domain

Use a test-only recording wrapper around unchanged `ProductionAccessQuery` that delegates real decisions.

- **V08-033** Wrapper implements the complete production access seam required by ProductionRoutingSystem.
- **V08-034** Wrapper preserves exact `is_bound_to(board)` semantics.
- **V08-035** Wrapper delegates real classify/segment/cell-of-point truth; no permissive fake routing.
- **V08-036** In a fresh 20×20 far-bottom case, every outside planner classification remains within x/y `-1..20`.
- **V08-037** Every outside planner-classified cell belongs to a legal top/bottom/left/right/corner ring cell, never a second exterior lane.
- **V08-038** Start connector may begin farther outside, but BFS/planner classification never expands beyond the one-cell ring.
- **V08-039** Successful routing records ring classifications/segments that are load-bearing.
- **V08-040** A test-only wrapper that blocks ring/exterior cells makes the same far-left bottom target unreachable with production unchanged.
- **V08-041** Blocked-ring result fails for the original assigned target and never retargets.

## E. Fresh four-side/corner arrangements

- **V08-042** Below-board origin reaches far-left bottom perimeter target.
- **V08-043** Above-board origin reaches far-right top perimeter target.
- **V08-044** Left-of-board origin reaches far-bottom left perimeter target.
- **V08-045** Right-of-board origin reaches far-top right perimeter target.
- **V08-046** At least one route requires a corner transition between adjacent exterior sides.
- **V08-047** Corner-route evidence directly proves both expected exterior sides are used.
- **V08-048** Rectangular board case uses independent width and height and succeeds.
- **V08-049** A 59×59 routing case succeeds unchanged.
- **V08-050** Record isolated 59×59 route CPU elapsed diagnostic with no arbitrary threshold.
- **V08-051** Fully enclosed interior ACTIVE target remains unreachable despite exterior ring.
- **V08-052** A formerly enclosed interior target becomes reachable only after a legitimate CLEARED opening.
- **V08-053** Diagonal squeeze/corner cutting through ACTIVE blockers remains rejected.

## F. Fresh Hazard Bot real-scene validation

- **V08-054** Start from a freshly instantiated owner scene.
- **V08-055** Stimulus is the real visible C08 Button path, not direct `request_slot()`.
- **V08-056** Exact slot id = 2 and local palette id = 2 / C08.
- **V08-057** First target index = 380.
- **V08-058** First target coordinate = `(0,19)`.
- **V08-059** Target 380 is ACTIVE and C08 before dispatch.
- **V08-060** route[0] equals exact mapped visible slot anchor.
- **V08-061** route final point equals `(0.5,19.5)`.
- **V08-062** Detached route revalidates through unchanged RouteValidator and ProductionAccessQuery.
- **V08-063** No route segment crosses a non-target ACTIVE board cell.
- **V08-064** Authenticated arrival clears exactly 380 and no unrelated cell.
- **V08-065** Candidate index no longer contains cleared 380 for C08.
- **V08-066** Reservation map contains no stale owner/target after clear.
- **V08-067** Dispatcher active count returns to zero after completion.
- **V08-068** AgentLayer returns to zero ScrubbotAgent children after deferred cleanup.

## G. Rapid same-slot / reservation validation

- **V08-069** On a fresh scene, press C08 at least three times through the real Button path before first accepted arrival.
- **V08-070** If all three are accepted, targets are exactly `380,381,382` in assignment order.
- **V08-071** Every accepted assignment has a unique owner id.
- **V08-072** Every accepted target has exact bidirectional reservation mapping.
- **V08-073** No duplicate target assignment occurs.
- **V08-074** Slot active presentation remains active while any C08 assignment remains in flight.
- **V08-075** If any activation is legitimately refused, prove zero side effects and complete ordering proof serially without weakening production rules.
- **V08-076** After all accepted arrivals, targets clear exactly once and reservations/agents clean up.

## H. Reset/cancel with exterior-routed agents active

- **V08-077** Fresh scene dispatches at least two accepted exterior-routed C08 agents without completing them.
- **V08-078** Capture exact BoardState/candidate/reservation/agent truth before reset.
- **V08-079** Invoke canonical reset path.
- **V08-080** Reset removes all dispatcher active assignments.
- **V08-081** Reset releases all reservations.
- **V08-082** Reset leaves no orphan ScrubbotAgent nodes after deferred cleanup.
- **V08-083** Reset does not clear in-flight targets merely because agents existed.
- **V08-084** Candidate truth after reset remains coherent with BoardState.
- **V08-085** A fresh post-reset C08 click can again select the correct bottom-left target when board state is fresh/unchanged.

## I. Route/result integrity

- **V08-086** Every successful fresh route is a real coherent RouteResult.
- **V08-087** Every successful route retains the originally requested target index.
- **V08-088** Every route begins at exact request start and ends at exact target center.
- **V08-089** Every route point is finite.
- **V08-090** RouteValidator returns NONE for every claimed success.
- **V08-091** Deliberately malformed/nonfinite request still fails closed under inherited production code.
- **V08-092** Same-size different BoardState/access bundle still fails coherence under inherited strict tests.

## J. Regression suite

- **V08-093** Full root suite passes and exact check count is logged.
- **V08-094** V07 corridor smoke passes unchanged.
- **V08-095** V06 tall-layout smoke passes unchanged.
- **V08-096** V05 playtest smoke passes unchanged.
- **V08-097** M21 real-art 400-clear smoke passes unchanged.
- **V08-098** All required M20 lifecycle/queue-free smokes pass.
- **V08-099** Existing M15/M16/M17/M18/M19 strict tests touched by routing assumptions remain green.
- **V08-100** Owner scene headless boot has zero SCRIPT/Parse errors.
- **V08-101** M21 level-build rerun remains UNCHANGED.
- **V08-102** M21 reference-composite rerun remains UNCHANGED.
- **V08-103** `git diff --check` is clean for authorized V08 changes.

## K. Engine/environment evidence

- **V08-104** Record exact `godot --version` actually used.
- **V08-105** Do not install, upgrade, downgrade or otherwise change Godot in V08.
- **V08-106** Report any engine drift from historical 4.7.1 truthfully; do not fabricate execution.

## L. Handoff / final closure law

- **V08-107** Create `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`.
- **V08-108** Log exact commands/exits, fresh tuple evidence, timing, locked blobs and changed files.
- **V08-109** Root `TASKS.md` remains byte-identical throughout Claude V08 work.
- **V08-110** No M21/M22/UI task is closed by Claude.
- **V08-111** No audit verdict/file is authored by Claude.
- **V08-112** Authorized V08 diff contains no production/source/scene/project change.
- **V08-113** Push safely to `origin/main` and return the required two-line handoff.
- **V08-114** If fresh validation exposes a production defect, return `BLOCKED` and stop without patching it.
- **V08-115** The owner manual gate is already PASS before V08 and is recorded in `CHATGPT_OWNER_GATE_V07_PASS.md`; V08 must preserve that exact accepted production behavior byte-for-byte.
- **V08-116** If V08 independently audits clean with production unchanged, ChatGPT may directly perform M21 final closure and task/progress updates. Do not require the owner to repeat the same manual playtest unless a later production correction changes the accepted behavior.