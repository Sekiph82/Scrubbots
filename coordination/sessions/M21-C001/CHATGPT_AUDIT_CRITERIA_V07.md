# M21-C001 V07 — Strict Audit Criteria

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Scope: owner-playtest correction after V06 engineering PASS
Owner basis: `OWNER_PLAYTEST_FINDINGS_V07.md`

V07 is a production-routing + owner-scene interaction correction. It is not permission to redesign TargetSelector, reservation, clearing authority, board semantics, UI art, boosters, win/lose, or final Scrubbot visuals.

A green test count alone is insufficient. The audit will inspect source, exact diff, route geometry, runtime evidence, test sensitivity, locked blobs, and owner-visible behavior.

## A. Governance / scope

- **V07-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **V07-002** Safely sync before edits; preserve owner/local work.
- **V07-003** Root `TASKS.md` was updated by ChatGPT before V07 handoff and is not modified by Claude/Codex anywhere in the V07 implementation/handoff diff.
- **V07-004** Claude does not create a tracker-only commit, does not alter lifecycle/status/actor/progress/check boxes, and records in `CLAUDE_LOG_V07.md` that `TASKS.md` was read but left unchanged.
- **V07-005** No M21/M22/UI checkbox is pre-closed by Claude.
- **V07-006** Read `CLAUDE.md`, root `TASKS.md`, `AUDIT_POLICY.md`, V06 audit, V06 owner-gate result, and V07 owner findings before implementation.
- **V07-007** No force push, reset/clean/restore of owner work, or unrelated refactor.
- **V07-008** Full changed-file list is logged.
- **V07-009** Historical V01–V06 evidence is not rewritten to pretend V07 behavior existed earlier.
- **V07-010** Owner-approved Hazard Bot source remains byte-identical.

## B. Owner-facing input law: slot clicks only

- **V07-011** `scripts/debug/m21_real_art_vertical_slice.gd` contains no SPACE-triggered gameplay dispatch.
- **V07-012** `_unhandled_input(KEY_SPACE)` or equivalent dispatch hook is removed.
- **V07-013** `step_one_clear()` or equivalent hidden owner-playtest gameplay dispatcher is removed.
- **V07-014** Synthetic origin arrays used only by SPACE fallback are removed.
- **V07-015** No replacement keyboard key secretly dispatches gameplay work.
- **V07-016** Visible `SlotView` activation remains connected through `slot_activated` to the real controller handler.
- **V07-017** Visible slot activation still reaches `CompleteClearingLoop.activate_slot()` rather than mutating BoardState directly.
- **V07-018** A successful visible slot click uses that exact SlotView's laid-out spawn anchor.
- **V07-019** Invalid/no-work slot activation creates no Scrubbot and clears no cell.
- **V07-020** A test is sensitive to reintroducing the SPACE fallback or hidden synthetic-origin dispatch path.

## C. Exterior corridor geometry contract

For board `W × H`, the one-cell routing ring is the set of logical exterior cells:

- top `y=-1`, `x=-1..W`;
- bottom `y=H`, `x=-1..W`;
- left `x=-1`, `y=0..H-1`;
- right `x=W`, `y=0..H-1`;
- all four corner cells included.

- **V07-021** Corridor width is exactly one logical cell in V07.
- **V07-022** Corridor is routing state only; it is not added to LevelData.
- **V07-023** Corridor is not added to BoardState dimensions.
- **V07-024** Corridor does not create palette cells/colors.
- **V07-025** Corridor geometry is derived from live `board.get_width()/get_height()`; no 20×20 constant.
- **V07-026** Rectangular boards are supported.
- **V07-027** 59×59 is supported without a hardcoded smaller envelope.
- **V07-028** Top, bottom, left, right, and all four corner ring cells are representable.
- **V07-029** Ring cell centers use board-local logical units, not screen pixels.
- **V07-030** Screen/design resolutions such as 1080×2160/2400 do not enter routing truth.

## D. Start connector semantics

- **V07-031** A SlotView origin may lie farther than one logical cell outside the board.
- **V07-032** Production routing can connect an exact outside slot origin to the exterior ring.
- **V07-033** That connector must be accepted by the existing authoritative access seam; it is not trusted merely because both endpoints are outside.
- **V07-034** A connector that crosses blocked ACTIVE artwork is rejected.
- **V07-035** The first route point remains exactly the request/slot origin.
- **V07-036** After joining the ring, exterior planning does not invent arbitrary far-outside search cells beyond the one-cell ring.
- **V07-037** No teleport from slot origin to target is introduced.
- **V07-038** Slot origin mapping from V05/V06 remains unchanged and exact.

## E. Ring traversal and board entry

- **V07-039** Production routing can traverse laterally across the bottom ring.
- **V07-040** Production routing can traverse laterally across the top ring.
- **V07-041** Production routing can traverse vertically along the left ring.
- **V07-042** Production routing can traverse vertically along the right ring.
- **V07-043** Routing can turn around every exterior corner.
- **V07-044** Every generated ring edge is still checked by authoritative segment access truth.
- **V07-045** Ring traversal never changes an ACTIVE board cell.
- **V07-046** Ring traversal may enter a CLEARED perimeter cell only when existing access truth permits it.
- **V07-047** An assigned ACTIVE perimeter target may be entered only as final arrival under existing access semantics.
- **V07-048** Non-target ACTIVE perimeter cells remain blockers.
- **V07-049** Non-target ACTIVE interior cells remain blockers.
- **V07-050** A fully enclosed interior ACTIVE target remains untargetable until a legal opening exists.
- **V07-051** No diagonal corner-cut through blocked cells is introduced.
- **V07-052** Routing still returns failure rather than retargeting when the assigned target has no valid route.

## F. ProductionRoutingSystem architecture

- **V07-053** The fix resides in production routing/path construction, not a fake TargetSelector override.
- **V07-054** `TargetSelector` retains WHAT-only responsibility.
- **V07-055** `ProductionRoutingSystem` retains HOW-only responsibility.
- **V07-056** `ProductionTargetAccess` remains the selector's production targetability authority.
- **V07-057** The same routing implementation used for targetability is used for actual dispatch route generation.
- **V07-058** Existing `RouteValidator` remains the shared final route validity gate.
- **V07-059** Organized/curved post-processing may not invalidate corridor legality.
- **V07-060** Every route returned as success remains `RouteValidator`-clean.
- **V07-061** Existing no-retarget contract remains structurally true.
- **V07-062** Existing fail-closed malformed request/access behavior remains green.
- **V07-063** Existing exact-board identity/coherence behavior remains green.
- **V07-064** Routing does not mutate BoardState, reservations, candidates, slots, or TargetSelector state.

## G. TargetSelector owner priority must remain canonical

- **V07-065** TargetSelector still orders targetable candidates by highest `y` first.
- **V07-066** Within equal `y`, smallest `x` wins.
- **V07-067** Position does not make a blocked/unreachable candidate valid.
- **V07-068** Reservations still exclude already-owned targets.
- **V07-069** CLEARED candidates cannot win.
- **V07-070** Wrong-color candidates cannot win.
- **V07-071** Existing M15 strict re-entry/coherence/fail-closed tests remain green.
- **V07-072** Prefer leaving the accepted TargetSelector production blob unchanged; any change requires explicit necessity and full strict re-audit evidence.

## H. Exact Hazard Bot acceptance

Fresh Hazard Bot is 20×20; local palette id `2` is canonical C08 and the entire bottom row is C08.

- **V07-073** Visible C08 slot click is the stimulus, not SPACE/direct board mutation.
- **V07-074** Fresh first successful C08 target is exact index `380`.
- **V07-075** Fresh first successful C08 target coordinate is exact `(0,19)`.
- **V07-076** Fresh first target color is exact C08/local palette id `2`.
- **V07-077** Route starts at the actual visible C08 slot spawn anchor mapped to board-local space.
- **V07-078** Route joins the bottom exterior ring.
- **V07-079** Route reaches the far-left bottom target without crossing any intervening ACTIVE bottom-row cell.
- **V07-080** Agent arrival is the exact BoardRenderer center for cell `(0,19)`.
- **V07-081** Authenticated M20 arrival clears exactly index `380`.
- **V07-082** No unrelated pixel clears during the first activation.
- **V07-083** Reservation/candidate/access truth updates remain coherent after the clear.
- **V07-084** Agent cleans up with no orphan node.

## I. Repeated/rapid bottom-row ordering

- **V07-085** If rapid same-slot concurrency is accepted, first distinct reservations on fresh C08 proceed deterministically from bottom-left toward the right (`380`, `381`, `382`, ... as targetable).
- **V07-086** No two assignments reserve the same target.
- **V07-087** Same-slot active visual remains active while any assignment for that slot is in flight.
- **V07-088** Cross-slot active visuals remain independent.
- **V07-089** If concurrency limits make an activation fail, it fails with zero side effects rather than violating order/reservation truth.
- **V07-090** Subsequent clearing can open new interior routes without changing the positional policy.

## J. Four-side / rectangular routing matrix

Fresh or purpose-built boards must directly prove:

- **V07-091** below-board origin can reach a far-left bottom perimeter target via bottom ring;
- **V07-092** above-board origin can reach a far-right top perimeter target via top ring;
- **V07-093** left-of-board origin can reach a far-bottom left perimeter target via left ring;
- **V07-094** right-of-board origin can reach a far-top right perimeter target via right ring;
- **V07-095** at least one route uses a corner to move between adjacent ring sides;
- **V07-096** the same matrix includes at least one non-square board;
- **V07-097** 59×59 routing sanity executes successfully within practical headless limits;
- **V07-098** removing/neutralizing ring expansion makes at least one new test fail.

## K. Strict regression locks

- **V07-099** Owner source blob remains `b565743ba52699899007882b750b7c8e7cdd00f9`.
- **V07-100** M20 clearing loop blob remains `06391839523cbc27e88a4b3ef12b730012cd45fa` unless an independently justified blocker proves unavoidable.
- **V07-101** Dispatcher blob remains `eee10149e4f116af6706beec832042352bf3a6dd` unless independently justified.
- **V07-102** TargetSelector blob remains `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` unless independently justified.
- **V07-103** BoardPresentation and SlotView accepted V05 blobs remain unchanged unless independently justified.
- **V07-104** ProductionAccessQuery should remain unchanged if the corridor can be implemented entirely as planner-domain expansion; any access-semantics edit triggers full direct justification and regression evidence.
- **V07-105** RouteRequest and RouteValidator should remain unchanged absent a demonstrated contract defect.
- **V07-106** Existing M17 production-routing tests all remain green.
- **V07-107** Existing M19 dispatcher strict tests all remain green.
- **V07-108** Existing M20 lifecycle/clearing strict tests all remain green.
- **V07-109** Existing M21 V01–V06 evidence tests remain green or are updated only where V07 explicitly supersedes a route-origin/target expectation.
- **V07-110** No previous strict test is deleted/disabled merely to obtain green.

## L. Root suite / focused smoke / scene evidence

- **V07-111** Full root suite passes with exact count recorded.
- **V07-112** Dedicated V07 corridor-focused tests pass.
- **V07-113** Real-art smoke still completes all 400 clears and exact final clean state.
- **V07-114** V05 playtest smoke remains green after legitimate expectation updates.
- **V07-115** V06 1080×2400 genuine tall-layout smoke remains green.
- **V07-116** Owner scene boots headlessly with 0 SCRIPT/Parse errors.
- **V07-117** Five visible slot count remains exact.
- **V07-118** Slot bar remains below/non-overlapping board in both canonical and tall validation configurations.
- **V07-119** AgentLayer has zero orphan agents after completed focused runs.
- **V07-120** Log includes exact first C08 route points and target tuple.

## M. Documentation / owner guide / handoff

- **V07-121** `M21_V07_OWNER_PLAYTEST.md` is created as the current guide; V05 guide remains historical.
- **V07-122** Current guide contains no instruction to use SPACE.
- **V07-123** Current guide explicitly expects first C08 target `(0,19)` / index `380` on a fresh board.
- **V07-124** Current guide tells owner to observe exterior bottom-ring travel before target entry.
- **V07-125** Root `TASKS.md` already records the V07 owner findings/current action from ChatGPT's pre-handoff tracker update, and Claude leaves that file byte-identical.
- **V07-126** Claude does not claim tracker closure/progress; M21 remains open until ChatGPT audit + owner acceptance.
- **V07-127** `CLAUDE_LOG_V07.md` contains start HEAD, explicit TASKS non-modification confirmation, implementation commit(s), exact changed files, commands/results, failures/corrections, route evidence, and protected blob checks.
- **V07-128** Claude hands back `AWAITING_AUDIT` only through the required final response/log and does not edit `TASKS.md` to assign CHATGPT as actor.
- **V07-129** All authorized work is pushed safely to `origin/main`.
- **V07-130** Final Claude response is exactly the required two-line handoff.

## N. Closure law

- **V07-131** Automated green evidence alone does not close M21.
- **V07-132** ChatGPT must independently audit V07 source/diff/tests/log.
- **V07-133** ChatGPT updates root `TASKS.md` after that audit before any next prompt/owner handoff.
- **V07-134** After ChatGPT engineering pass, owner must manually replay the Godot scene.
- **V07-135** M21 closes only if the owner confirms slot-only interaction and correct visible bottom-left-first corridor behavior.
