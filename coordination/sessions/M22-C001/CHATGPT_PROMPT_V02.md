# M22-C001 V02 — Implement Scrubbot Railroad V1 + Slot Connector Integration

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude implementer/test runner
Auditor/tracker owner: ChatGPT

## Mission

Implement the owner's newly locked Scrubbot Railroad V1 movement/presentation system on top of the accepted M22 V01 five-slot foundation.

The production gameplay behavior must become:

`clicked SlotCell → visible slot connector → bottom railroad → railroad-only exterior travel → exact target row/column alignment → orthogonal railroad exit → already-assigned target → authenticated arrival → M20 clear`

The Scrubbot must not cut diagonally across exterior free space, leave the rail early, tunnel through ACTIVE artwork or retarget.

V01 is accepted. Preserve it except where the new owner decision explicitly supersedes spawn/rail integration.

## 1. Safe sync and mandatory reading

Safely synchronize local `main` with current `origin/main` while preserving every owner/local tracked and untracked change. Do not use destructive reset/clean/restore and never force-push.

Work only in `Sekiph82/Scrubbots`.

Read before editing:

1. `CLAUDE.md`
2. root `TASKS.md` **read-only; do not modify it**
3. `coordination/AUDIT_POLICY.md`
4. `coordination/sessions/M22-C001/CHATGPT_AUDIT_V01.md`
5. `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
6. `coordination/sessions/M22-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
7. `docs/MASTER_UI_SYSTEM.md`
8. `docs/01_GAMEPLAY_SPEC.md`
9. `docs/02_TECH_ARCHITECTURE.md`
10. `docs/05_TECH_DECISIONS.md`
11. M22 V01 SlotCell/ColorSelectionPanel/demo/test source
12. current `ProductionRoutingSystem`, `ProductionAccessQuery`, `ProductionTargetAccess`, `RouteValidator`, TargetSelector, ReservationState, ScrubbotDispatcher, ScrubbotAgent, CompleteClearingLoop and BoardPresentation source
13. relevant current routing/target/reservation tests and M21 V07–V10 evidence so you understand which exact geometry is historical and which safety invariants remain current.

Do not modify root `TASKS.md`. ChatGPT owns it.

## 2. Owner-locked Railroad V1 geometry

Implement one canonical/single-source geometry contract, preferably a pure/data-oriented helper such as `ScrubRailGeometry` or a clearly documented equivalent.

For board `W × H`:

- artwork-to-rail inner-edge clearance = exactly `2.0` logical cells in V1;
- rail width = `1.0` logical cell;
- rail centreline offset = `2.5` logical cells outside board boundary;
- TOP centreline: `y=-2.5`, `x=-2.5..W+2.5`;
- BOTTOM centreline: `y=H+2.5`, `x=-2.5..W+2.5`;
- LEFT centreline: `x=-2.5`, `y=-2.5..H+2.5`;
- RIGHT centreline: `x=W+2.5`, `y=-2.5..H+2.5`;
- corners exactly at the four centreline intersections.

Do not duplicate these constants independently in routing and presentation. One geometry source must drive both.

Geometry must be generic for rectangular boards and 20..59, including 59×59.

## 3. Railroad presentation component

Create a reusable production railroad view under the gameplay component/presentation structure, for example:

- `scripts/ui/scrub_rail_view.gd`
- `scenes/components/ui/gameplay/scrub_rail_view.tscn`

Equivalent naming is allowed if documented.

V02 spends **zero** Magnific/image-generation credits. Render the structural railroad natively/procedurally in Godot.

Owner visual direction:

- consistent railroad for every level;
- dark/slate metallic robotic-cleaning track;
- restrained cyan/electric accents/guide nodes;
- rounded mechanical corners;
- artwork remains dominant;
- railroad style does not inspect or change based on level subject/theme.

The view is presentation only. It must not own TargetSelector, BoardState, reservations, clearing or slot model truth.

## 4. Slot → railroad connectors

Keep the accepted V01 SlotCell and ColorSelectionPanel foundation.

For each real clicked slot:

- begin at the exact actual SlotCell spawn anchor;
- map that anchor into board-local space using accepted BoardPresentation transform semantics;
- create a visible/travelled connector to the BOTTOM rail;
- bottom-rail connector entry uses the mapped slot x and the canonical bottom-rail y, clamping x only if needed to remain on legal rail span;
- slot cells in the M22 demo must sit physically below the railroad, not inside the 2-cell artwork clearance;
- connector travel is part of the real Scrubbot path, not a teleport.

Do not create hidden keyboard gameplay input. Visible SlotCell click remains the only owner-facing activation path.

## 5. Production routing supersession

The old M21 adjacent one-cell ring (`x=-1`, `x=W`, `y=-1`, `y=H`) is now historical exact geometry. Do not rewrite M21 audit/log evidence, but update current production routing to Railroad V1.

Preserve these M21 invariants:

- TargetSelector chooses WHAT and remains bottom-most then left-most among currently targetable matching cells;
- routing chooses HOW and never retargets;
- reservations remain authoritative and atomic;
- non-target ACTIVE cells block travel;
- no tunnelling/diagonal squeeze;
- no route means no spawn/no side effects;
- authenticated arrival remains required for clear;
- slot-click-only behavior remains;
- rapid assignments/reset remain correct.

### Outside-start Railroad V1 route law

For an outside/slot start:

1. connect from exact slot start to its bottom-rail entry;
2. stay on rail centreline geometry during exterior travel;
3. side changes happen only through rail corners;
4. derive legal exit candidates for the already-assigned target:
   - TOP/BOTTOM exits share target centre `x`;
   - LEFT/RIGHT exits share target centre `y`;
5. final exit→target segment is strictly orthogonal;
6. reject an exit if authoritative access truth says the aligned final approach crosses a non-target ACTIVE blocker;
7. if one side is blocked, another legal side may be evaluated for the **same target**;
8. if no side is legal, return `NO_ROUTE` and never choose another target;
9. choose shortest legal total rail route;
10. equal-distance tie-break: `BOTTOM → LEFT → RIGHT → TOP`.

No route segment may cut diagonally through the two-cell clearance merely to shorten distance.

Be especially careful with the existing shortcut/rounding layer. It must not turn a legal rail route into a diagonal free-space shortcut. If generic shortcut/rounding cannot be constrained to the rail envelope, disable/replace it for rail segments rather than weakening the owner rule.

Inside-board debug/test starts may retain a narrowly documented compatible path where necessary, but they may not undermine owner-facing outside-start railroad behavior.

## 6. Shared geometry / access / validation architecture

Use one source of geometry truth.

The clean target is:

- railroad geometry helper computes sides/corners/entry/exit geometry;
- production routing consumes it;
- railroad view consumes it;
- slot connector integration consumes it;
- existing BoardPresentation maps logical route coordinates to screen space.

Do not move railroad calculations into TargetSelector.

Do not weaken RouteValidator/access truth just to make outside points pass. Any required current-contract extension must be narrow, explicit, fail-closed and strictly tested.

## 7. V01 hardening

Fix the non-blocking V01 hardening item while in this scope:

`ColorSelectionPanel.bind_colors()` must not silently fabricate magenta when given an incomplete/malformed production color snapshot. Make invalid binding fail closed or explicitly reject it while preserving valid five-color behavior and V01 API compatibility as far as practical.

Add direct malformed/undersized binding tests.

## 8. Current-test migration and historical evidence

Do not edit historical M21 audit/log documents.

M21 V07/V08 standalone tests may contain exact adjacent-ring assertions that are now historical. Do not falsify history by pretending they were Railroad V1 tests.

For current production regressions:

- migrate root/current assertions that encode obsolete exact ring coordinates to the new Railroad V1 contract;
- preserve the old tests' safety intent: exterior travel is load-bearing, no tunnelling, no retarget, four-side/corner coverage, rectangular and 59×59 behavior;
- add fresh Railroad V1 tests rather than deleting difficult checks.

If you retain historical standalone scripts that no longer represent current production geometry, explicitly mark them historical/superseded in comments/evidence and do not cite them as current Railroad V1 acceptance.

## 9. Direct required evidence

Build fresh tests that directly prove all criteria in `CHATGPT_AUDIT_CRITERIA_V02.md`, especially:

- exact geometry for multiple W/H values;
- 2-cell gap + 1-cell rail width;
- all four corners;
- invalid geometry input fail-closed;
- slot connector enters bottom rail before lateral travel;
- far-left bottom target: connector → bottom rail → target-column exit → target;
- far/top-right case using real corners/sides;
- at least one route using two rail sides, with evidence stronger than a single corner point;
- no route point/segment wandering through forbidden exterior free-space;
- no diagonal final approach;
- blocked preferred exit fallback to another aligned side for SAME target;
- all aligned exits blocked → no route/no retarget/no side effects;
- shortest route and deterministic tie-break;
- real M22 visible Button C08 → target `380/(0,19)` → real agent path on rail → authenticated clear;
- rapid real Button x3 reservation uniqueness/active visuals;
- reset while at least two agents are still on connector/rail travel;
- rectangular board;
- 59×59;
- required responsive matrix and physical slot/rail separation;
- no Magnific usage.

The target ID must arise naturally from production TargetSelector. Do not force the test to target 380.

## 10. Documentation updates

As part of authorized implementation, update current canonical docs so they no longer claim the adjacent one-cell ring is the future production movement geometry:

- `docs/01_GAMEPLAY_SPEC.md`
- `docs/02_TECH_ARCHITECTURE.md`
- `docs/05_TECH_DECISIONS.md`
- `docs/MASTER_UI_SYSTEM.md`

Record a clean supersession statement rather than deleting M21 historical context.

Do not modify root `TASKS.md`.

## 11. Required validation

At minimum run and record:

- `godot --version`
- full `tests/run_tests.gd` with exact total/failure count and exit 0
- dedicated Railroad V1 geometry/routing test(s)
- dedicated M22 railroad responsive/demo smoke
- applicable M22 V01 component/responsive regression
- M21 V10/V09 reservation/direct-evidence tests where they do not depend on obsolete exact ring geometry
- M21 real-art full clear under current production routing
- required M20 lifecycle/clearing regressions
- current TargetSelector / reservation / dispatcher / ScrubbotAgent strict regressions
- headless boot of the M22 railroad demo
- `git diff --check`

If a current test fails because it asserts superseded exact ring geometry, do not hide the failure. Classify it, preserve historical evidence, and migrate the current regression safely.

## 12. Owner-facing visual acceptance readiness

The resulting M22 demo must be suitable for a new F6 owner review after ChatGPT audit. It should visibly show:

- artwork;
- at least 2 logical cells of breathing room;
- the robotic railroad on all four sides;
- rounded corners;
- five slots below the bottom rail;
- real slot connector travel;
- Scrubbot staying on the rail;
- exit only at target row/column alignment;
- orthogonal final approach;
- no exterior diagonal shortcut.

Do not claim owner visual PASS yourself.

## 13. Log / handoff

Create:

`coordination/sessions/M22-C001/CLAUDE_LOG_V02.md`

The log must include:

- exact starting/ending commit identities;
- exact changed files;
- safe-sync/owner-work preservation evidence;
- geometry constants and single-source proof;
- representative exact route points for the real C08→380 flow;
- proof of connector-before-rail and aligned exit;
- no-shortcut evidence;
- blocked-exit fallback and all-blocked failure evidence;
- rapid/reset reservation and cleanup evidence;
- responsive board/rail/slot matrix;
- documentation supersession summary;
- exact commands/results/check counts;
- statement `Magnific/image-generation credits spent = 0`;
- statement that root `TASKS.md` was not modified.

Push authorized work safely to `origin/main`. Never force-push.

Final response must be exactly two lines:

`AWAITING_AUDIT`

`https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M22-C001/CLAUDE_LOG_V02.md`
