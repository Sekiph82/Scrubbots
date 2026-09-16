# M22-C001 V03 — ChatGPT Strict Audit Criteria

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Purpose: close the frozen V02 findings from `CHATGPT_AUDIT_V02.md` without reopening accepted authority.

## A. Governance / scope

- **M22-V03-001** Work only in `Sekiph82/Scrubbots`.
- **M22-V03-002** Safely synchronize local `main` with current `origin/main`; preserve owner/local work; never destructive reset/clean/force-push.
- **M22-V03-003** Read root `TASKS.md` but do not modify it.
- **M22-V03-004** Read `CHATGPT_AUDIT_V02.md`, this criteria file, `CHATGPT_PROMPT_V03.md`, `OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md` and the accepted V01/V02 sources before editing.
- **M22-V03-005** No M23 work, no unrelated refactor, no generation-provider/runtime dependency changes.
- **M22-V03-006** Magnific/image-generation credits spent = 0.
- **M22-V03-007** Historical M21 audit/log evidence is not rewritten.

## B. Production exterior-routing supersession

- **M22-V03-010** `ProductionRoutingSystem` no longer routes any current production outside start through the exact M21 adjacent ring `x=-1 / x=W / y=-1 / y=H`.
- **M22-V03-011** Real below-board SlotCell starts still use exact start → canonical BOTTOM entry → rail-only exterior travel → aligned exit → assigned target.
- **M22-V03-012** Non-below outside starts do not silently fall through to the obsolete M21 exterior-ring planner. They use a Railroad-compatible/fail-closed current contract instead.
- **M22-V03-013** If an interior debug/test compatibility path is retained, it is explicitly limited to inside-board starts and cannot be reached by an outside owner-facing start.
- **M22-V03-014** No TargetSelector call/retarget is added to routing.
- **M22-V03-015** No weakening of ProductionAccessQuery/RouteValidator truth is used to make railroad points pass.
- **M22-V03-016** Generic shortcut/rounding cannot transform rail segments into off-rail free-space movement.
- **M22-V03-017** Current production tests that depended on old outside adjacent-ring injections are deliberately migrated/isolated; historical evidence remains historical.
- **M22-V03-018** Source-level search/test proves the old exact ring is not a current production exterior route lane after V03.

## C. Exact real SlotCell connector evidence

Use a real laid-out owner scene in a real SubViewport or equivalent frame-driven layout environment.

- **M22-V03-020** Await enough layout frames before reading SlotCell geometry or pressing a real Button.
- **M22-V03-021** Exactly five actual SlotCell/Button instances exist after layout.
- **M22-V03-022** For each slot ID `0..4`, independently read the cell's actual top-center global spawn anchor.
- **M22-V03-023** Independently map each actual global anchor through `BoardPresentation.global_to_board_local()`.
- **M22-V03-024** A real Button activation's route point 0 equals the independently measured mapped anchor, not merely `agent.spawn_origin` compared with the route that was initialized from it.
- **M22-V03-025** Route point 1 equals canonical `ScrubRailGeometry.bottom_entry(mapped_anchor.x)` within tolerance.
- **M22-V03-026** If the mapped x is inside the legal rail span, connector point 1 preserves that exact x; clamping occurs only when actually necessary.
- **M22-V03-027** The five mapped connector starts are distinguishable and one-to-one with slot IDs.
- **M22-V03-028** Connector travel is a real route segment from route point 0 to route point 1; no teleport.
- **M22-V03-029** At least two different viewport/layout cases directly re-measure anchors and routes after layout and prove no stale cached connector geometry.
- **M22-V03-030** Responsive evidence retains five slots below the bottom rail outer edge and outside the 2-cell artwork-clearance band.

## D. Real C08 owner path

- **M22-V03-035** A real laid-out SlotCell/Button C08 activation naturally selects target index `380`, coordinate `(0,19)` on fresh Hazard Bot.
- **M22-V03-036** The C08 route starts at the independently measured real slot-2 anchor, not `(0,24)` unless the actual layout independently proves that x value.
- **M22-V03-037** It then enters BOTTOM rail at canonical bottom entry before lateral rail travel.
- **M22-V03-038** Exterior rail travel remains on canonical rail sides/corners.
- **M22-V03-039** It leaves only at an exit aligned with target row/column and reaches `(0.5,19.5)` through a strictly orthogonal final segment.
- **M22-V03-040** Authenticated arrival clears exactly the assigned target and releases reservation/assignment normally.

## E. Direct Railroad domain / route matrix

- **M22-V03-045** Add a direct helper/assertion that classifies route segments as connector, canonical rail, or final aligned approach.
- **M22-V03-046** Every middle rail-travel segment lies exactly on one canonical TOP/BOTTOM/LEFT/RIGHT centreline.
- **M22-V03-047** A rail side change occurs only through an exact canonical rail corner.
- **M22-V03-048** No rail segment occupies the two-cell clearance free-space away from a canonical rail centreline.
- **M22-V03-049** No diagonal connector-to-distant-rail shortcut exists.
- **M22-V03-050** No diagonal final approach exists.
- **M22-V03-051** Far-left/bottom target case proves BOTTOM entry and aligned exit.
- **M22-V03-052** A true far-right/top target case inside the supported production envelope proves required corner/side travel and aligned exit.
- **M22-V03-053** At least one case proves travel across two different rail sides with a real corner between distinct non-corner rail points.
- **M22-V03-054** Preferred aligned exit blocked → another legal aligned side for the SAME target.
- **M22-V03-055** All aligned exits blocked → `NO_ROUTE`, no retarget, no BoardState/reservation/agent side effects.
- **M22-V03-056** Shortest legal total rail route selection is directly proven.
- **M22-V03-057** Equal-distance deterministic tie-break `BOTTOM → LEFT → RIGHT → TOP` is directly proven on a board whose dimensions are within 20..59.
- **M22-V03-058** Rectangular routing proof uses dimensions within 20..59 on both axes.
- **M22-V03-059** 59×59 railroad routing remains proven.

## F. Concurrency / lifecycle / UI hardening non-regression

- **M22-V03-065** Rapid three real C08 Button activations yield unique targets and owners with correct active visual lifecycle.
- **M22-V03-066** Reset while at least two real agents are still on connector/rail travel releases assignments and leaves no orphan ScrubbotAgent after deferred cleanup.
- **M22-V03-067** Reset does not falsely clear unarrived targets.
- **M22-V03-068** No-work slot produces no agent/reservation/clear side effect.
- **M22-V03-069** `ColorSelectionPanel.bind_colors()` malformed/undersized/non-Color input still fails closed; valid five-Color binding still works.
- **M22-V03-070** Accepted V01 five-slot/touch/responsive behavior remains green.

## G. Production-envelope / geometry non-regression

- **M22-V03-075** Geometry remains single-source; routing/view/connector do not independently duplicate owner geometry constants.
- **M22-V03-076** Exact 2.0 clearance, 1.0 width and 2.5 centreline offset remain directly tested.
- **M22-V03-077** Square, valid rectangular and 59×59 geometry remain directly tested.
- **M22-V03-078** Invalid/non-finite geometry inputs fail closed.
- **M22-V03-079** Railroad presentation remains theme-independent and presentation-only.

## H. Mandatory runtime validation

Record exact command, result, check count where applicable, and exit code.

- **M22-V03-085** `godot --version` recorded exactly; no engine installation mutation.
- **M22-V03-086** Full `tests/run_tests.gd` PASS, zero failures, exit 0.
- **M22-V03-087** Dedicated V03 Railroad routing/domain tests PASS.
- **M22-V03-088** `tests/m22_railroad_responsive_smoke.gd` or its V03 replacement PASS with real post-layout connector assertions.
- **M22-V03-089** V01 M22 responsive/component regression PASS.
- **M22-V03-090** M21 real-art full 400-cell clear PASS under current production routing.
- **M22-V03-091** Current M21 V10 reservation/direct evidence PASS.
- **M22-V03-092** Required M20 lifecycle/clearing regressions PASS.
- **M22-V03-093** Current TargetSelector/reservation/dispatcher/ScrubbotAgent strict regressions PASS.
- **M22-V03-094** Headless M22 Railroad demo boots with zero SCRIPT/Parse errors.
- **M22-V03-095** `git diff --check` clean.
- **M22-V03-096** Root `TASKS.md` absent from Claude implementation diff.

Historical standalone M21 tests whose only failing assertion encodes the superseded exact adjacent ring may remain historical failures if explicitly classified. They may not be edited to falsify M21 history and may not drive the current production router back to old geometry.

## I. Exact V03 handoff evidence

Create `coordination/sessions/M22-C001/CLAUDE_LOG_V03.md`.

- **M22-V03-100** Log exact pre-work GitHub/main commit identity.
- **M22-V03-101** Log exact implementation commit identity after it actually exists on GitHub.
- **M22-V03-102** Log exact changed files and prove root `TASKS.md` unchanged.
- **M22-V03-103** Log the final outside-start routing policy and prove no current production adjacent-ring fallback.
- **M22-V03-104** Log five real post-layout SlotCell global anchors and their independently mapped board-local starts for at least one viewport.
- **M22-V03-105** Log the exact real C08 slot-2 mapped start and route points after completed layout.
- **M22-V03-106** Log a second viewport/re-layout mapping proving dynamic connector recomputation.
- **M22-V03-107** Log the far-right/top route, domain-classification proof, blocked fallback, all-blocked failure, shortest path and tie-break evidence.
- **M22-V03-108** Log rapid/reset evidence and exact test commands/results.
- **M22-V03-109** State `Magnific/image-generation credits spent = 0`.
- **M22-V03-110** Verify pushed implementation and V03 log are visible on GitHub `main` before handoff.

## J. Closure rule

V03 passes only if all four frozen V02 findings are closed together:

- `F-M22-V02-STRICT-001`
- `F-M22-V02-STRICT-002`
- `F-M22-V02-EVIDENCE-001`
- `F-M22-V02-EVIDENCE-002`

A green aggregate suite alone is insufficient if source or direct evidence still contradicts the locked owner contract.

On V03 PASS, ChatGPT may close eligible `SB-M22-009` / `SB-M22-026..034` rows and open the separate `SB-M22-035` owner F6 visual/game-feel gate. V03 itself does not grant owner visual acceptance.