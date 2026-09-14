# M22-C001 V02 — Scrubbot Railroad V1 + Slot Connector Integration — Strict Audit Criteria

Date: 2026-09-14
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Milestone: M22 — Production Slot UI
Actor: Claude (implementer/test runner)
Auditor/tracker owner: ChatGPT
Owner contract: `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`

V01 is accepted `AUDITED_PASS / PRODUCTION_SLOT_FOUNDATION_ACCEPTED`. V02 implements the new owner-locked Railroad V1 movement/presentation contract without reopening TargetSelector WHAT-policy, ReservationState ownership or M20 authenticated clearing authority.

## A. Governance / scope

- **M22-V02-001** Work only in `Sekiph82/Scrubbots` on `main`.
- **M22-V02-002** Safely sync with current `origin/main` while preserving all owner/local tracked and untracked work.
- **M22-V02-003** Read `CLAUDE.md`, root `TASKS.md`, `coordination/AUDIT_POLICY.md`, `CHATGPT_AUDIT_V01.md`, `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`, `docs/MASTER_UI_SYSTEM.md`, `docs/01_GAMEPLAY_SPEC.md`, `docs/02_TECH_ARCHITECTURE.md`, routing/access/dispatcher/agent source and M22 V01 component source before editing.
- **M22-V02-004** Do not modify root `TASKS.md`; ChatGPT is sole tracker writer.
- **M22-V02-005** Preserve owner/local work; no force push, `reset --hard`, destructive clean/restore or unrelated deletion.
- **M22-V02-006** Preserve owner Hazard Bot source and M21 LevelData/preview/metadata/reference-composite bytes.
- **M22-V02-007** Do not modify TargetSelector ordering logic merely to satisfy railroad behavior.
- **M22-V02-008** Do not modify ReservationState ownership semantics.
- **M22-V02-009** Do not bypass CompleteClearingLoop authenticated arrival/clear authority.
- **M22-V02-010** Do not invent slot quantity, cooldown, refill, collision-lane, congestion, win/lose, economy or booster rules.
- **M22-V02-011** No AI image generation or Magnific credits in V02; the railroad structural visual is native/procedural Godot UI/2D presentation.
- **M22-V02-012** Do not implement the full M23 gameplay screen.

## B. Owner decision / documentation

- **M22-V02-013** Treat `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` as owner-locked production direction.
- **M22-V02-014** Update `docs/01_GAMEPLAY_SPEC.md` to record railroad travel and orthogonal aligned exit law.
- **M22-V02-015** Update `docs/02_TECH_ARCHITECTURE.md` to record single-source railroad geometry and ownership boundaries.
- **M22-V02-016** Update `docs/05_TECH_DECISIONS.md` with a versioned ADR/supersession note for M21's adjacent one-cell ring geometry.
- **M22-V02-017** Update `docs/MASTER_UI_SYSTEM.md` with the reusable railroad presentation/spacing contract.
- **M22-V02-018** Documentation must state that M21 V07–V10 historical audit evidence remains valid for those commits while future production geometry is superseded.
- **M22-V02-019** Documentation must not claim the railroad is LevelData/BoardState or a C01..C16 artwork layer.
- **M22-V02-020** Documentation must state V1 uses one consistent railroad visual language across levels.
- **M22-V02-021** No per-level themed railroad system is introduced in V02.
- **M22-V02-022** No external reference game's exact visual assets/composition are copied.

## C. Preserve accepted V01 slot foundation

- **M22-V02-023** Preserve reusable `SlotCell` / `ColorSelectionPanel` component architecture.
- **M22-V02-024** Preserve exactly five production slot cells.
- **M22-V02-025** Preserve native Godot slot/color presentation and zero generated slot art.
- **M22-V02-026** Preserve scalar/query binding; panel must not retain mutable SlotSystem/SlotState/BoardState/ReservationState references.
- **M22-V02-027** Preserve real Button activation and desktop mouse support.
- **M22-V02-028** Preserve per-slot active/in-flight presentation behavior.
- **M22-V02-029** Preserve responsive/container-driven slot layout.
- **M22-V02-030** Preserve minimum 88 reference-pixel interactive target.
- **M22-V02-031** Preserve absence of hidden SPACE/keyboard gameplay dispatch.
- **M22-V02-032** Harden incomplete/malformed `bind_colors` input to fail closed or return an explicit failure; do not silently fabricate magenta as production color truth.

## D. Single-source railroad geometry

- **M22-V02-033** Introduce one canonical data-oriented railroad geometry source consumed by both routing and visual presentation, or prove an equivalent single-source contract.
- **M22-V02-034** Railroad geometry derives from board `W/H`; no fixed 20×20 assumptions.
- **M22-V02-035** Baseline artwork-to-rail inner-edge clearance is exactly 2.0 logical cells.
- **M22-V02-036** Clearance is never less than 2.0 logical cells in production V1.
- **M22-V02-037** Rail visual width is 1.0 logical cell.
- **M22-V02-038** Rail centreline offset is therefore 2.5 logical cells outside each board boundary.
- **M22-V02-039** TOP centreline is `y=-2.5` from `x=-2.5..W+2.5`.
- **M22-V02-040** BOTTOM centreline is `y=H+2.5` from `x=-2.5..W+2.5`.
- **M22-V02-041** LEFT centreline is `x=-2.5` from `y=-2.5..H+2.5`.
- **M22-V02-042** RIGHT centreline is `x=W+2.5` from `y=-2.5..H+2.5`.
- **M22-V02-043** All four corner centre points are represented exactly.
- **M22-V02-044** Geometry supports square and rectangular boards.
- **M22-V02-045** Geometry supports 20..59 dimensions and 59×59.
- **M22-V02-046** Geometry itself does not create one Node per board/rail logical cell.
- **M22-V02-047** Railroad values are not duplicated as unrelated magic numbers across routing/view/controller.
- **M22-V02-048** Geometry helpers reject invalid board dimensions/NaN/non-finite configuration fail-closed.

## E. Reusable railroad presentation

- **M22-V02-049** Create a reusable production railroad view/component under the gameplay UI/presentation component structure.
- **M22-V02-050** Railroad view consumes canonical geometry; it does not own gameplay truth.
- **M22-V02-051** View renders all four sides and all four corners.
- **M22-V02-052** Visual gap between artwork and rail is visibly non-zero and represents >=2 logical cells.
- **M22-V02-053** Rail visual width tracks one logical-cell scale.
- **M22-V02-054** Rail does not distort the board aspect ratio.
- **M22-V02-055** Rail style is a consistent dark/slate metallic robotic cleaning track with restrained cyan/electric accents or an equivalent owner-direction-faithful native rendering.
- **M22-V02-056** Rail remains visually subordinate to pixel art.
- **M22-V02-057** Rounded corners may be drawn, but visual/motion curves stay inside the railroad envelope.
- **M22-V02-058** Railroad presentation is reusable across levels and does not inspect semantic level subject/theme.
- **M22-V02-059** Railroad visual can be reskinned later without changing target/routing truth.
- **M22-V02-060** No generated decorative rail asset is required for V02.

## F. Slot connector geometry

- **M22-V02-061** Every clicked production slot starts at its exact real SlotCell spawn anchor.
- **M22-V02-062** Each slot maps to a connector toward the BOTTOM railroad.
- **M22-V02-063** Connector joins the bottom rail at the slot's mapped board-local x, clamped only to legal bottom-rail span when necessary.
- **M22-V02-064** Connector path is visible/observable travel; no teleport from slot to rail.
- **M22-V02-065** The M22 demo layout positions slot cells below the rail rather than inside the 2-cell artwork clearance.
- **M22-V02-066** Five connector starts remain distinguishable and map one-to-one to five slot IDs.
- **M22-V02-067** Responsive re-layout updates connector geometry from actual SlotCell anchors; no stale cached spawn position.
- **M22-V02-068** Connector logic does not choose/alter a target.

## G. Railroad-constrained routing

- **M22-V02-069** After joining the railroad, an outside-start Scrubbot remains on railroad geometry until a legal aligned exit.
- **M22-V02-070** The planner may move horizontally on TOP/BOTTOM rail and vertically on LEFT/RIGHT rail.
- **M22-V02-071** Rail side changes occur only through legal corners.
- **M22-V02-072** No diagonal slot→distant-rail shortcut is returned.
- **M22-V02-073** No diagonal rail-corner shortcut leaves the railroad envelope.
- **M22-V02-074** Existing generic shortcut/rounding post-processing must not cut across the two-cell clearance or violate rail confinement.
- **M22-V02-075** If generic post-processing cannot preserve the railroad invariant, it must be disabled/replaced for railroad segments rather than weakening validation.
- **M22-V02-076** The route's first point equals the mapped real clicked-slot spawn anchor.
- **M22-V02-077** The route contains an explicit bottom-rail connector/entry point before lateral railroad travel when the slot starts below the board.
- **M22-V02-078** For an already-assigned target, compute legal aligned exits without retargeting.
- **M22-V02-079** TOP/BOTTOM exit shares exact target-centre x.
- **M22-V02-080** LEFT/RIGHT exit shares exact target-centre y.
- **M22-V02-081** Final approach is orthogonal; no diagonal final approach.
- **M22-V02-082** Final route endpoint remains exact target centre.
- **M22-V02-083** A non-target ACTIVE cell blocks an aligned approach.
- **M22-V02-084** The target ACTIVE cell may be the final endpoint only.
- **M22-V02-085** CLEARED cells may form a legal approach corridor where accepted access truth allows it.
- **M22-V02-086** If one aligned side is blocked, routing may test another aligned side for the SAME target.
- **M22-V02-087** If all aligned sides are blocked, return `NO_ROUTE`; never silently choose a different target.
- **M22-V02-088** Among legal aligned exits, choose shortest legal total railroad route.
- **M22-V02-089** Equal-distance route tie-break is deterministic `BOTTOM → LEFT → RIGHT → TOP`.
- **M22-V02-090** Route remains finite, deterministic and RouteValidator-clean under the updated current production contract.

## H. Target/access authority preservation

- **M22-V02-091** TargetSelector source ordering remains bottom-most then left-most among currently targetable matching candidates.
- **M22-V02-092** Railroad geometry stays out of TargetSelector WHAT-policy.
- **M22-V02-093** ProductionTargetAccess/current targetability seam uses the updated routing behavior without duplicating target-selection logic.
- **M22-V02-094** Reservations remain atomic and duplicate target assignment remains impossible.
- **M22-V02-095** No-work slot still produces no assignment/no clear.
- **M22-V02-096** First fresh Hazard Bot C08 still naturally selects target index `380`, coordinate `(0,19)`.
- **M22-V02-097** Target 380 is approached from an aligned railroad exit, not by crossing a non-target ACTIVE cell.
- **M22-V02-098** Subsequent rapid C08 assignments remain unique (`380,381,382` style sequence where fixture state permits).
- **M22-V02-099** Enclosed interior ACTIVE target remains unreachable until a legitimate aligned/cleared corridor exists.
- **M22-V02-100** Diagonal squeeze through ACTIVE blockers remains rejected.
- **M22-V02-101** Routing failure does not mutate BoardState, CandidateIndex or ReservationState.
- **M22-V02-102** Authenticated arrival remains required before M20 clear.

## I. Historical M21 supersession / test migration

- **M22-V02-103** Do not rewrite M21 audit/log evidence files to pretend Railroad V1 existed during M21.
- **M22-V02-104** Explicitly mark the exact adjacent `-1/W/H` ring geometry as historical/superseded in current docs/tests where needed.
- **M22-V02-105** Preserve safety intent from M21 V07/V08: no tunnelling, no retarget, exterior route load-bearing, four-side/corner coverage, rectangular/59×59 coverage.
- **M22-V02-106** Historical standalone scripts that assert obsolete exact ring coordinates may remain historical and need not be treated as current production acceptance, but current regression suite must not silently depend on obsolete geometry.
- **M22-V02-107** If a current root test asserts obsolete exact one-cell ring coordinates, migrate that assertion to Railroad V1 while preserving the original safety intent.
- **M22-V02-108** Do not delete historical evidence merely to make tests green.

## J. Concurrency / reset

- **M22-V02-109** Three rapid same-slot clicks preserve three unique target/reservation owners where work is available.
- **M22-V02-110** Multiple Scrubbots may share/cross rail geometry; no collision/lane rule is invented.
- **M22-V02-111** Active visual remains correct through concurrent railroad-routed agents.
- **M22-V02-112** Reset while at least two agents are on connector/rail travel cancels assignments and releases reservations without clearing their unarrived targets.
- **M22-V02-113** Reset leaves zero orphan agents after deferred cleanup.
- **M22-V02-114** Fresh post-reset activation again selects canonical first target on fresh fixture state.

## K. Responsive / variable-size geometry

- **M22-V02-115** Baseline `1080×2160` displays board + >=2-cell gap + full rail + five slots without essential overlap.
- **M22-V02-116** `1170×2532` validated.
- **M22-V02-117** `1290×2796` validated.
- **M22-V02-118** `1080×2400` validated.
- **M22-V02-119** `1440×3200` validated.
- **M22-V02-120** Shorter 16:9 portrait validated.
- **M22-V02-121** Tablet portrait validated.
- **M22-V02-122** At least one rectangular board geometry case validated.
- **M22-V02-123** 59×59 railroad geometry/routing case validated.
- **M22-V02-124** Logical 2-cell clearance remains invariant across physical viewport scale changes.
- **M22-V02-125** Slot panel stays outside/below rail in every required owner-demo layout case.
- **M22-V02-126** Touch targets remain >=88 reference px.

## L. Required direct tests

- **M22-V02-127** Unit-test canonical rail centreline coordinates for several W/H values.
- **M22-V02-128** Unit-test exact 2.0 clearance + 1.0 rail width relationship.
- **M22-V02-129** Unit-test all four corner coordinates.
- **M22-V02-130** Test invalid geometry input fails closed.
- **M22-V02-131** Test slot connector enters bottom rail before any lateral rail travel.
- **M22-V02-132** Test far-left bottom target route contains bottom-rail travel and only leaves at matching target x.
- **M22-V02-133** Test far-right/top target requires legal corner/side travel and aligned exit.
- **M22-V02-134** Test a case that traverses at least two rail sides and proves corner use beyond a single corner point ambiguity.
- **M22-V02-135** Test route points/segments never occupy forbidden clearance free-space except the slot connector and final aligned target approach.
- **M22-V02-136** Test no diagonal final approach.
- **M22-V02-137** Test blocked preferred exit falls back to another legal side for same target.
- **M22-V02-138** Test all exits blocked returns no route/no retarget/no side effects.
- **M22-V02-139** Test shortest legal rail route selection.
- **M22-V02-140** Test deterministic equal-distance tie-break.
- **M22-V02-141** Test real M22 Button path C08→380/(0,19) through connector+rail+aligned exit.
- **M22-V02-142** Test real agent positions/path points demonstrate no exterior diagonal shortcut.
- **M22-V02-143** Test rapid x3 real Button path reservations/targets/active visuals.
- **M22-V02-144** Test reset while multiple real agents are still in railroad travel.
- **M22-V02-145** Test `ColorSelectionPanel.bind_colors` malformed/undersized input fails closed and does not fabricate a canonical color.

## M. Runtime / regression

- **M22-V02-146** Record exact `godot --version` without changing engine installation.
- **M22-V02-147** Run full root suite PASS with exact count, zero failures and exit 0.
- **M22-V02-148** Run dedicated Railroad V1 unit/routing tests PASS.
- **M22-V02-149** Run dedicated M22 railroad responsive/visual-layout smoke PASS.
- **M22-V02-150** Run current M22 V01 slot component/responsive non-regression PASS where still applicable.
- **M22-V02-151** Run M21 V10/V09 reservation/direct-evidence regressions PASS if they do not assert superseded geometry.
- **M22-V02-152** Run M21 real-art full clear PASS under current production routing.
- **M22-V02-153** Run required M20 lifecycle/clearing regressions PASS.
- **M22-V02-154** Run current TargetSelector/reservation/dispatcher/agent strict tests PASS.
- **M22-V02-155** Headless M22 railroad demo boots with zero SCRIPT/Parse errors.
- **M22-V02-156** `git diff --check` clean.

## N. Evidence / closure

- **M22-V02-157** Create `coordination/sessions/M22-C001/CLAUDE_LOG_V02.md`.
- **M22-V02-158** Log exact changed files and exact implementation commit/parent.
- **M22-V02-159** Log rail geometry constants/coordinates and prove they are single-source.
- **M22-V02-160** Log target-380 real Button route points showing slot→bottom connector→rail→aligned exit→target.
- **M22-V02-161** Log direct no-shortcut/no-early-exit evidence.
- **M22-V02-162** Log blocked-exit fallback and all-blocked failure evidence.
- **M22-V02-163** Log responsive matrix with board/rail/slot geometry and logical clearance measurements.
- **M22-V02-164** Log rapid/reset ReservationState and AgentLayer cleanup evidence.
- **M22-V02-165** Explicitly state Magnific/image-generation credits spent = 0.
- **M22-V02-166** Do not author audit verdict or modify root `TASKS.md`; push safely and hand back `AWAITING_AUDIT` plus direct GitHub blob URL for `CLAUDE_LOG_V02.md`.
