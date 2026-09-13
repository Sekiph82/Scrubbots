# M21-C001 V07 — ChatGPT Independent Strict Audit

Date: 2026-09-13
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Audited implementation commit: `d704e2c12d67da428a9a5bd28e645ea430eb1d34`
Implementation base: `e6d7fb80d87da09e324eed5b3bc39d45747fbea7`
Prompt: `coordination/sessions/M21-C001/CHATGPT_PROMPT_V07.md`
Criteria: `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V07.md`
Claude log: `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`
Owner finding source: `coordination/sessions/M21-C001/OWNER_PLAYTEST_FINDINGS_V07.md`

## Verdict

**AUDITED_PASS_IMPLEMENTATION_STAGE / V07_CORRECTION_ACCEPTED / V08_VALIDATION_ONLY_REQUIRED / M21_NOT_CLOSED / OWNER_REQUIRED_AFTER_V08**

No material production defect was found in the V07 correction under the available independent GitHub evidence and strict full-surface audit procedure.

However M21 is a critical routing/dispatch/clearing vertical slice, and V07 changed the production routing implementation after the previous validation-only closure. Under `coordination/AUDIT_POLICY.md` Strict Audit Standard v2, a production correction in a critical sprint is not final closure merely because the implementer-authored correction and tests are green. A fresh auditor-authored, production-immutable adversarial validation pass is required before owner manual acceptance can become the final M21 gate.

Therefore:

- V07 production correction is accepted as the current candidate implementation;
- no V07 production file should be modified in V08;
- V08 is validation-only and must exercise fresh adversarial arrangements designed by ChatGPT;
- after V08 independently passes, the owner replays the Godot scene;
- M21 closes only after that owner playtest explicitly passes.

## Auditor execution limitation

ChatGPT did not independently execute Godot in this environment. Claude's Godot results remain E1/E2 implementation evidence. This audit independently inspected the exact GitHub commit/diff/source/tests/governance and cross-checked locked blobs. Because runtime execution is not available to the auditor, the Strict-v2 two-stage rule requires V08 validation-only evidence.

## Exact audited diff

`e6d7fb8... -> d704e2c...` is exactly one implementation commit and changes only six paths:

1. `scripts/gameplay/routing/production_routing_system.gd`
2. `scripts/debug/m21_real_art_vertical_slice.gd`
3. `tests/run_tests.gd`
4. `tests/m21_v07_corridor_smoke.gd`
5. `coordination/sessions/M21-C001/M21_V07_OWNER_PLAYTEST.md`
6. `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`

Root `TASKS.md` is absent from the V07 implementation diff, as required by the owner-locked ChatGPT-only tracker workflow.

## Pass A — implementation/state sweep

### A1. Owner finding F-M21-OWNER-001: SPACE dispatch

**Status: PROVEN CLOSED**

`m21_real_art_vertical_slice.gd` no longer contains:

- `_unhandled_input()` gameplay dispatch;
- `KEY_SPACE` handling;
- `step_one_clear()`;
- the old `SLOT_ORDER` / synthetic-origin fallback path.

The owner-facing path is now:

`SlotView.pressed -> SlotView.slot_activated -> _on_slot_activated -> request_slot -> CompleteClearingLoop.activate_slot -> dispatcher -> target/routing/agent -> authenticated clear`.

`request_slot()` remains as an explicit test/programmatic seam, which V07 permits. Source inspection found no replacement keyboard gameplay dispatcher in the owner controller.

### A2. Owner finding F-M21-OWNER-002: one-cell exterior corridor

**Status: PROVEN IMPLEMENTED**

`ProductionRoutingSystem` now models a planner-only exterior ring through `_is_ring(c,w,h)`:

- x domain `-1..W`;
- y domain `-1..H`;
- all cells outside the real board but inside that bounding box are ring cells;
- board dimensions, LevelData and BoardState are unchanged.

The BFS expansion accepts only:

- real inside-board cells; or
- `_is_ring(...) == true` cells.

Therefore search expansion cannot wander into arbitrary second/third exterior lanes.

The exact slot/request start position is preserved as route point 0. Ring entries require `is_segment_traversable(start, ring_center, target)` and every BFS edge also requires the same authoritative segment-access seam.

### A3. ACTIVE/CLEARED access law

**Status: PROVEN PRESERVED**

`ProductionAccessQuery` is byte-identical and still defines:

- outside-board/background = OPEN;
- CLEARED = OPEN;
- non-target ACTIVE = BLOCKED;
- assigned ACTIVE target = enterable only for final arrival;
- exact deterministic supercover segment validation;
- diagonal squeeze/corner-cut blocking.

The V07 ring therefore adds planner topology without weakening canonical access truth.

### A4. WHAT/HOW separation

**Status: PROVEN PRESERVED**

`TargetSelector` remains byte-identical. Its owner-locked comparator is still:

1. greatest y first;
2. smallest x next;
3. index tie-break.

`ProductionTargetAccess` still uses the same `ProductionRoutingSystem` for `is_targetable()` and the eventual dispatch route. No coordinate is forced into TargetSelector and no routing code retargets.

### A5. Exact Hazard Bot behavior

**Status: STRONG E2 + STATIC CROSS-CHECK, FRESH V08 EVIDENCE REQUIRED FOR FINAL CLOSURE**

The dedicated V07 smoke drives the real visible C08 `Button.pressed` signal path and asserts:

- first target index = `380`;
- coordinate = `(0,19)`;
- local palette id = `2` / C08;
- route[0] = real visible C08 slot anchor mapped through BoardPresentation;
- final route point = `(0.5,19.5)`;
- route contains bottom-exterior geometry;
- authenticated arrival clears index 380;
- AgentLayer returns to zero agents;
- subsequent serial C08 assignments produce `381,382,383`.

The recorded first-route tuple is structurally consistent with the current production code:

`(9.444445,21.11111) -> exterior bottom space -> (0.5,19.5)`.

The owner decision allows one access-valid connector from an exact slot origin that may be farther than one cell outside the board into the one-cell ring. After ring entry, ordinary generated exterior search is restricted to the ring. The implementation satisfies that contract structurally.

Visual preference for the precise connector shape remains an owner/game-feel gate. It is not silently converted into a new engineering rule in this audit.

### A6. Four-side / rectangular / maximum-size behavior

**Status: PROVEN BY GENERIC SOURCE + E2 TEST MATRIX; V08 WILL RE-PROBE INSTRUMENTED DOMAIN**

The V07 tests exercise:

- bottom;
- top;
- left;
- right;
- a corner-turn case;
- 30x12 rectangular board;
- 59x59 board;
- enclosed interior ACTIVE target failure.

The source is side-agnostic: `_is_ring` and four-neighbour BFS contain no Hazard-Bot, 20x20, bottom-side or C08 special case.

### A7. Modified historical M17 test

**Status: ACCEPTED NARROW SUPERSESSION**

The old perimeter-target `sole blocked edge => NO_ROUTE` fixture became invalid under the new owner-authorized exterior ring because a perimeter target can now legitimately have an exterior alternate route.

Claude did not delete the safety assertion. It moved the target to a true interior ACTIVE cell with a single blocked internal connection, preserving the original purpose:

- no alternate legal route;
- result must remain `NO_ROUTE`;
- blocked edge must actually be queried.

This is a legitimate expectation update, not regression-test weakening.

### A8. State mutation / lifecycle

**Status: PROVEN NO NEW OWNER**

ProductionRoutingSystem remains read-only with respect to:

- BoardState;
- ReservationState;
- ColorCandidateIndex;
- SlotSystem;
- TargetSelector.

Clearing authority remains in the accepted M20 loop. Dispatcher and ScrubbotAgent are byte-identical.

## Pass B — evidence/test/policy sweep

### B1. Root suite and focused smokes

Claude reports on Godot `4.7.2.stable.official.ed1daf0bf`:

- root suite `4617/4617 PASS`;
- V07 corridor smoke PASS;
- V06 genuine tall-layout smoke PASS;
- V05 playtest smoke PASS;
- M21 400-clear smoke PASS;
- M20 lifecycle/queue-free smokes PASS;
- owner scene headless boot with 0 SCRIPT/Parse errors;
- deterministic M21 build/reference outputs unchanged.

These are E1/E2, not E3 runtime evidence.

### B2. Load-bearing quality

The new bottom-corridor test contains an important sensitivity pair:

- direct start -> `(0,19)` straight segment is explicitly asserted blocked;
- production route is asserted successful and exterior.

This prevents a false positive where `(0,19)` merely became reachable by weakening ACTIVE blockers.

The owner-scene smoke also asserts the exact 380 target and real slot signal path, so a nearby-target implementation cannot satisfy it.

### B3. Remaining correlated-test risk

The following are not defects, but are deliberately re-probed in V08 because the same implementer wrote both V07 production code and V07 tests:

1. Instrumented proof that planner cell classification never expands beyond the exact one-cell ring.
2. Fresh four-side/corner arrangements independent of the V07 helper layout.
3. Rapid same-slot reservations before arrival, proving distinct `380,381,382...` ownership where the existing dispatcher accepts those requests.
4. Reset/cancel while ring-routed agents are in flight, proving no reservation/agent leak and no unauthorized clear.
5. Explicit `RouteValidator` revalidation of fresh routes and segment-access call recording.
6. 59x59 timing recorded as diagnostic evidence, with no invented hard threshold.
7. Source-level slot-only assertion independent of the V07 method-presence smoke.

### B4. Godot version environment note

V07 was actually executed by Claude on Godot 4.7.2 after the local machine was upgraded from the historical 4.7.1 baseline. The V07 owner guide still says 4.7.1.

This is **not treated as a production failure**:

- no engine-version-sensitive production file was changed;
- CLAUDE.md currently specifies Godot 4.7 generally;
- the exact executed engine is disclosed in the implementation log.

V08 must record the exact installed engine it uses and must not install/change/downgrade/upgrade Godot as part of validation. The next owner guide can be reconciled to the actual installed 4.7.x environment after validation.

### B5. Minor log wording discrepancy

`CLAUDE_LOG_V07.md` says leaving `TASKS.md` untouched “intentionally deviates” from prompt §2/§13. The final audited V07 prompt actually instructs exactly that behavior. This is a wording/history artifact, not a code or lifecycle defect. The implementation diff correctly leaves `TASKS.md` unchanged.

## Protected-blob independent cross-check

Independently re-read from audited commit `d704e2c...`:

- Hazard Bot PNG: `b565743ba52699899007882b750b7c8e7cdd00f9` — unchanged.
- CompleteClearingLoop: `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged.
- ScrubbotDispatcher: `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.
- TargetSelector: `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` — unchanged.
- BoardPresentation: `2093df48d367903d332a910dfb3369154831a9ed` — unchanged.
- SlotView: `480dffc0ee135150bd3dd2258f002264273ead10` — unchanged.
- ScrubbotAgent: `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370` — unchanged.
- ProductionAccessQuery: `7ba9d13556abb0e3a0a6d281449438330a25386d` — unchanged.

Authorized changed production blobs:

- ProductionRoutingSystem: `0900e955... -> 8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1`.
- owner-scene controller: `66050fe5... -> 153c042a17dc0ef9e83699a0beb2932217057ff4`.

## Sprint coverage ledger

| Surface / requirement | Production owner | Canonical state | Main adversarial class | Current evidence | Status |
| --- | --- | --- | --- | --- | --- |
| Slot-only player input | M21 debug controller + SlotView | no board mutation before loop | alternate hidden input, wrong origin | exact diff + real Button smoke | PROVEN |
| Visible spawn anchor | SlotView + BoardPresentation | route start | transform drift | locked V05/V06 blobs + V07 smoke | PROVEN |
| Target priority | TargetSelector | reservation target identity | blocked candidate outranks reachable | locked source + exact 380 result | PROVEN |
| Production targetability | ProductionTargetAccess | no mutation, one-shot route memo | stale/mismatched route | locked source + inherited strict tests | PROVEN |
| Exterior ring domain | ProductionRoutingSystem | planner-only | second-lane/far-outside search | source proof; V08 instrumented re-probe required | PROVEN / REVALIDATE |
| Segment access | ProductionAccessQuery + RouteValidator | ACTIVE/CLEARED truth | corner cut/tunnelling | locked source + inherited tests | PROVEN |
| Perimeter target entry | routing/access | assigned target only | transit through ACTIVE target | locked access + V07 routes | PROVEN |
| Interior target isolation | routing/access | ACTIVE blockers | ring tunnels through art | V07 all-active interior test | PROVEN |
| Four-side genericity | ProductionRoutingSystem | dimensions only | bottom-only special case | generic source + matrix | PROVEN |
| Rectangular board | routing | width/height | square assumption | 30x12 test | PROVEN |
| 59x59 | routing | max workload | fixed smaller envelope | 59x59 functional test; V08 timing diagnostic | PROVEN / REVALIDATE |
| Reservation uniqueness | ReservationState/TargetSelector | exact owner-target maps | duplicate assignment | inherited strict tests; V08 rapid fresh arrangement | PROVEN / REVALIDATE |
| Dispatcher lifecycle | ScrubbotDispatcher | active owner map | reset/re-entry | locked blob + M19/M20 regression | PROVEN |
| Authenticated clear | CompleteClearingLoop | ACTIVE->CLEARED | direct/forged clear | locked blob + exact 380 arrival smoke | PROVEN |
| Agent cleanup | ScrubbotAgent/AgentLayer | node lifecycle | orphan after clear/reset | locked blob + V07 smoke; V08 reset case | PROVEN / REVALIDATE |
| Owner visual/game feel | human owner | subjective acceptance | connector feel/readability | not AI-closeable | OWNER_GATE |

## Criteria reconciliation summary

- V07-001..010 governance/scope: PROVEN from exact one-commit diff, log and locked source.
- V07-011..020 slot-only law: PROVEN by source + direct Button smoke; V08 repeats source sensitivity independently.
- V07-021..030 ring geometry: PROVEN by source; V08 instruments queried planner cells.
- V07-031..038 connector semantics: PROVEN by source and exact slot-origin tuple; V08 fresh access recorder.
- V07-039..052 traversal/entry/access: PROVEN by generic source + matrix + unchanged supercover access; V08 adversarial re-probe.
- V07-053..064 architecture: PROVEN by source separation and locked blobs.
- V07-065..072 selector priority: PROVEN by unchanged TargetSelector and exact 380 result.
- V07-073..084 Hazard Bot: strong E2 direct real-scene evidence; fresh V08 validation required before final closure.
- V07-085..090 repeated/rapid ordering: serial ordering directly proven; inherited concurrency remains green; V08 adds fresh pre-arrival rapid reservation test.
- V07-091..098 generic matrix/sensitivity: source + tests materially satisfy; V08 adds independent instrumented sensitivity.
- V07-099..110 regression locks: independently cross-checked for named production blobs; Claude reports inherited strict suites green.
- V07-111..120 runtime evidence: E1/E2 only because auditor cannot run Godot; exact results logged.
- V07-121..130 docs/handoff: owner guide/log exist; TASKS remained unchanged; exact Claude chat response itself is outside GitHub and is not independently reconstructable, but the user supplied the required log URL and the repo handoff state is coherent.
- V07-131..135 closure law: V07 implementation audit completed here; V08 is now required; owner gate remains pending.

## Sibling-failure sweep

After reviewing the exterior-ring root class, the audit checked sibling surfaces:

- top/bottom/left/right ring generation uses the same function;
- corners are included by the same bounding-box rule;
- rectangular dimensions use live W/H;
- 59x59 uses the same path;
- segment checks remain centralized in ProductionAccessQuery;
- post-processing remains self-validating through RouteValidator;
- TargetSelector and ProductionTargetAccess were not forked or patched specially for C08/Hazard Bot;
- debug interaction removed SPACE rather than redirecting it elsewhere.

No sibling production defect was found.

## Interaction sweep

Reviewed:

- ring routing + target priority;
- ring routing + reservations;
- ring routing + organized/curved post-process;
- ring routing + ACTIVE/CLEARED access;
- slot-origin transform + ring connector;
- arrival + authenticated clear;
- clear + candidate/access refresh;
- concurrent assignments + per-slot presentation;
- reset/cleanup + ring-routed agents;
- maximum size + search surface.

No material production contradiction was found from static inspection. Reset/concurrency/max-size are deliberately re-executed in V08 because runtime evidence is implementer-correlated.

## Frozen finding set

There is **no frozen production-defect finding** from V07.

The only open audit item is procedural/evidentiary:

### R-V07-VALIDATION-001 — critical post-correction adversarial validation required

V07 changed production routing in a critical milestone and its runtime proof is implementer-authored. Under Strict-v2, final closure requires a fresh auditor-authored validation-only pass with production immutable.

This is not permission to change production code.

If V08 exposes a source defect, Claude must stop `BLOCKED`; ChatGPT will then perform a new whole-sprint sweep before authorizing any correction.

## Next action

Create and execute `CHATGPT_PROMPT_V08.md` / `CHATGPT_AUDIT_CRITERIA_V08.md` as **validation-only**.

After V08 independently passes, update `TASKS.md` to owner-playtest state and ask the owner to run `scenes/debug/m21_real_art_vertical_slice.tscn` with F6.

Only the owner can close the final visual/game-feel gate.