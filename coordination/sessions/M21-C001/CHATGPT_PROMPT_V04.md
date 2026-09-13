# M21-C001 V04 — Owner Playtest Integration + Final Closure Implementation Prompt

You are Claude, the implementation/test runner for `Sekiph82/Scrubbots`. ChatGPT is the independent auditor.

This is a **full V04 implementation prompt**, not a suggestion list. Execute the entire authorized scope, satisfy every linked V04 audit criterion, push all authorized work to `main`, and hand back for independent audit.

## 0. Canonical inputs

Repository: `https://github.com/Sekiph82/Scrubbots`
Branch: `main`

Before implementation, read all of these from GitHub/local after safe sync:

- root `TASKS.md`
- root `CLAUDE.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V03.md`
- `coordination/sessions/M21-C001/OWNER_PLAYTEST_DECISIONS_V04.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V04.md`
- this `CHATGPT_PROMPT_V04.md`
- relevant M15/M18/M19/M20 final audit files before touching their adjacent behavior
- relevant UI/reference docs and inventory for the existing canonical five-slot/gameplay reference

The V04 criteria contain **212 numbered requirements**. They are mandatory.

## 1. Safe synchronization and owner/local-work preservation

Start by inspecting:

```text
git status --short --branch
git remote -v
git log --oneline --decorate -n 20
git fetch origin
```

Safely synchronize local `main` with `origin/main`.

Rules:

- preserve every pre-existing tracked modification, deletion and untracked owner file;
- never `git reset --hard`;
- never force push;
- never restore/overwrite owner-local work merely to obtain a clean tree;
- use safe stash/autostash/rebase/fast-forward mechanics only when they preserve owner work;
- if owner-local changes overlap a file you must edit and cannot be reconciled safely, stop `BLOCKED` and record the exact conflict rather than discarding anything.

Work only in `Sekiph82/Scrubbots`.

## 2. FIRST COMMIT: tracker-only V04 start transition

Before editing implementation/test/UI files, make a dedicated tracker-only commit and push it.

That commit must contain **only `TASKS.md`** and must reflect the owner decisions already recorded in `OWNER_PLAYTEST_DECISIONS_V04.md` plus the V04 lifecycle.

The live tracker must say:

```text
Current Milestone: M21
Current Sprint: M21-C001 V04 — owner playtest integration + final closure
Current Task: M21-C001-V04
Current Task Status: IN_PROGRESS
Required Actor: CLAUDE
```

Keep pre-audit progress/lastCompletedTaskId unchanged. Do not close M21/M22/UI task rows in this start commit.

Reconcile the following canonical task-plan changes in root `TASKS.md` if ChatGPT's pre-prompt tracker edit is not already present after sync:

### 2.1 Locked target-selection rule

Add/retain an owner-locked rule directly after the TargetSelector-vs-Routing separation:

> TargetSelector chooses among otherwise valid/ACTIVE/matching/unreserved/currently-targetable candidates by **bottom-most first (largest board y), then left-most within that row (smallest board x)**. A blocked candidate never wins merely because of position. Routing still decides only HOW to travel to the selected target.

Remove `exact target-selection heuristic` from the unresolved DESIGN GATES because this part is now owner-decided.

### 2.2 M15 task reconciliation

Reopen/update `SB-M15-003 Baseline deterministic strategy` for V04 validation. The old ascending row-major strategy is superseded by the owner decision. Do not reopen unrelated M15 tasks unless actual evidence requires it.

### 2.3 M21 task reconciliation

Update the stale M21 intro that still says the real-art slice is blocked awaiting an owner asset. The Hazard Bot source exists and is owner-approved.

Keep M21 open pending V04 independent audit, and explicitly record that final M21 owner acceptance now requires:

- bottom-most/left-most reachable target priority;
- visible moving Scrubbot aligned to the board presentation transform;
- exactly five visible functional color slots;
- slot activation through the real CompleteClearingLoop path;
- owner-playable Godot scene evidence.

### 2.4 M22 pull-forward reconciliation

Record that V04 intentionally pulls forward the **functional production-slot subset** of M22:

- audit/use existing slot references;
- reusable SlotView;
- five-slot layout;
- bind SlotSystem state;
- color presentation;
- desktop-testable interaction target;
- active/in-flight visual state;
- Scrubbot spawn point;
- focused aspect-ratio/safe-area/rapid-input tests.

`SB-M22-008 No-work state if approved` remains visually design-gated unless explicit owner approval exists. Do not invent a final no-work animation/state language.

Do not start booster/decorative Magnific work from M22-013+ in V04.

Commit/push this tracker-only transition before any implementation changes. Record its full SHA in the V04 log.

## 3. Preserve the accepted V03 production correction

V03 implementation commit `3a0953ad8b327a8e979341c27d44890ab3a7c779` closed the production-art physical-path residual.

Do not regress or redesign that builder work.

Re-run the V03 path tests and preserve:

- one `_resolve_physical` identity for alias/preflight/plan/write;
- bare-relative based at `res://`;
- Windows case-fold comparison only;
- source immutability;
- no known deterministic partial write;
- V01 F-001/F-002/F-004 accepted behavior.

### 3.1 Close the one remaining V03 evidence cell

Add a **direct** builder test for:

```text
preview destination is an existing directory
AND overwrite=false
```

It must reject before output or metadata mutation.

Keep/directly prove the corresponding `overwrite=true` preview-directory rejection as well.

Arrange the fixture so it reaches destination-object-type preflight rather than failing earlier for an unrelated reason.

This is evidence reconciliation, not a builder redesign.

## 4. Implement the owner-locked TargetSelector policy

The current production `TargetSelector` blob before V04 is:

`a0daad67f8ba2238dd54cb903ac25dec7aa3144d`

Its current policy says “first targetable candidate in ascending row-major candidate order.” That policy is now superseded by the owner's live playtest decision.

### Required new policy

For one requested color/owner:

1. retain every existing safety/eligibility gate;
2. establish deterministic candidate inspection priority by board coordinate:
   - larger `y` first;
   - for equal `y`, smaller `x` first;
   - deterministic final tie-break;
3. continue canonical validation/reservation/targetability checks in that order;
4. return/reserve the first candidate in that priority that is actually valid and targetable.

Do **not** interpret this as “always pick the absolute bottom-left pixel.” A bottom-left raw candidate that is blocked, invalid, cleared, wrong-color or reserved must be skipped.

### Implementation constraints

- Keep the M15 strict-v2 transaction/reentry/coherence protections intact.
- Do not call routing from TargetSelector.
- Do not use route length as target priority.
- Do not let BoardRenderer or ScrubbotAgent select a target.
- Do not mutate BoardState or ColorCandidateIndex while ordering candidates.
- Prefer canonical `BoardState.get_cell_position(index)` rather than spreading a new index formula.
- If you need to sort a detached candidate list, do so without exposing/mutating the index's internal array.
- Preserve safe handling of malformed candidate entries and dynamic collaborator returns.

### Mandatory direct tests

Add focused tests for all of these:

1. several reachable candidates on several rows -> lowest visual row wins;
2. several reachable candidates on same lowest row -> left-most wins;
3. bottom-left candidate blocked -> next reachable candidate wins;
4. bottom-left candidate reserved -> next eligible candidate wins;
5. whole lowest row unavailable -> next row up, left-most reachable;
6. rectangular board;
7. candidate array intentionally not supplied in priority order;
8. malformed/duplicate entries remain safe;
9. deterministic repeat;
10. M21 fresh Hazard Bot first C08 target directly proves the new priority **among authoritative targetable C08 candidates**, not only raw perimeter cells;
11. a blocked lower candidate never beats a reachable higher candidate.

Sensitivity: show that restoring ascending row-major ordering would fail the new policy tests for the intended reason.

Run all existing M15 strict tests. Update only test expectations that encode the now-superseded row-major target identity. Do not delete strict safety cases.

## 5. Make the real Scrubbot visibly move on the board

The existing production movement contract is correct: ScrubbotAgent positions are board-local cell units.

The owner could not see the moving Scrubbot in the M21 Godot scene because the current scene does not map agent presentation through the same visible board transform.

Fix this in the **presentation layer**.

### Required architecture

Create/use a shared board presentation coordinate space, conceptually:

```text
BoardPresentationRoot
├── BoardRenderer
└── AgentLayer
    └── real ScrubbotAgent
```

Equivalent architecture is allowed only if direct tests prove the same mapping.

Requirements:

- BoardRenderer and AgentLayer share the visible board origin.
- One board-local movement unit maps to exactly the renderer's cell-size in screen/presentation space.
- Bind ScrubbotDispatcher with the explicit AgentLayer as its `agent_parent` in the owner-playable scene.
- Do not multiply or rewrite route points into screen pixels inside RoutingSystem or ScrubbotAgent.
- Keep the current debug marker if useful; do not invent/generate final M27 Scrubbot art.
- Marker must be plainly visible at the live M21 portrait playtest scale.
- Target arrival must visually line up with the actual selected target cell center.
- Authenticated arrival remains the only clear authority.

### Direct transform evidence

Tests must observe actual display/global coordinates:

- agent start after presentation transform vs expected slot/spawn display position;
- agent target/final presentation vs BoardRenderer target-cell center;
- non-unit cell size;
- rectangular-board or width/height-independent proof;
- zero orphan agent children after completion/reset cleanup.

Do not settle for testing only board-local route points; that would miss the exact problem the owner observed.

## 6. Pull forward the minimum production-compatible five-slot UI now

The owner explicitly wants the five-slot system visible immediately.

Do not make five throwaway debug rectangles. Implement/reuse a small production-compatible native Godot slot component that M22/M23 can continue using.

### 6.1 SlotView / slot presentation

Create a reusable `SlotView`-style component in an appropriate UI/gameplay presentation location.

It must:

- represent one real SlotSystem slot ID;
- consume only scalar/query state from SlotSystem or a narrow controller/binder, never retain a mutable SlotState reference;
- show the actual bound LevelData palette color;
- expose a visible desktop-testable activation target;
- show active/in-flight visual state in a simple functional way;
- keep text/state live in Godot;
- avoid any generated artwork dependency for V04.

### 6.2 Five-slot bar

The M21 owner-playable scene must show **exactly five** visible slots.

Use the repository's already-recorded canonical gameplay/five-slot reference for broad layout direction, but do not flatten/copy the screenshot into the game.

Requirements:

- five slots remain readable in the current portrait reference viewport;
- board remains readable and dominant enough for this functional slice;
- slot components use the actual M21 palette mappings;
- no sixth hidden gameplay slot is invented;
- no slot color is hardcoded independently from LevelData/SlotSystem truth.

### 6.3 Click -> real gameplay request

Clicking a slot must call the existing real gameplay path.

It must **not**:

- clear a pixel directly;
- mutate BoardState directly;
- choose/force a target itself;
- skip reservations;
- instantiate a fake Scrubbot.

It must go through the real CompleteClearingLoop/dispatcher/TargetSelector/routing/agent/arrival chain.

The SPACE-key path may remain for developer fallback, but visible slots must be the authoritative V04 owner-playtest proof.

## 7. Slot spawn-origin and visible agent integration

Each visible slot needs a coherent Scrubbot spawn point.

Do not casually pass a slot's raw screen coordinate into board-local routing.

Define/test a clear conversion contract between:

- visible slot spawn presentation;
- board presentation root;
- board-local RouteRequest start position.

A slot may sit outside the board bounds, as the routing system already supports exterior origins, but the visual marker and route start must correspond to the same conceptual origin.

Required proof:

- click slot N;
- returned assignment color equals slot N's actual palette ID;
- real agent appears at that slot's corresponding spawn point;
- route ends at TargetSelector's selected cell;
- transformed endpoint aligns with BoardRenderer target center.

## 8. Active/in-flight and rapid-input behavior

Provide a simple visible active/in-flight state for the clicked slot.

Do not make the UI state authoritative gameplay truth.

Test:

- activation with reachable work;
- activation with no reachable work -> no bot, no reservation, no pixel clear;
- rapid repeated click cannot duplicate one target/assignment or bypass the dispatcher/selector reservation model;
- active state returns to appropriate non-active presentation after completion/failure;
- reset/scene cleanup leaves no stale active visual or orphan agent.

Do not invent final `No Work` artwork/animation for `SB-M22-008`; that visual is still design-gated. A simple neutral disabled/no-dispatch response is enough for V04 functional correctness.

## 9. Continue the existing M22 functional work, do not replace it

V04 deliberately pulls forward these existing M22 responsibilities because the owner needs them to judge the game now:

- M22-001 audit/use slot references;
- M22-002 reusable SlotView;
- M22-003 five-slot layout;
- M22-004 bind SlotState/SlotSystem truth through safe APIs;
- M22-005 color presentation;
- M22-006 functional interaction target for desktop owner testing now; do not claim M24 mobile-touch completion;
- M22-007 active state;
- M22-009 Scrubbot spawn point;
- M22-010 focused aspect-ratio sanity;
- M22-011 focused safe/content-area sanity;
- M22-012 rapid-tap regression.

Keep M22-008 final no-work visual behavior unresolved unless explicit owner approval is already present.

Do **not** begin M22-013+ Magnific booster/decorative asset generation in V04.

Do not mark these task rows completed yourself at handoff. ChatGPT will decide which rows can close after independent audit.

## 10. Owner-playable end-to-end scenario

Update the real-art M21 scene so the owner can visibly exercise this exact flow:

```text
Hazard Bot visible over BG01
+ five visible color slots
→ click a color slot
→ no reachable work: no bot/no clear
OR reachable work:
→ TargetSelector picks bottom-most then left-most currently targetable matching cell
→ reservation exists
→ visible real ScrubbotAgent departs from that slot's mapped spawn point
→ real ProductionRoutingSystem route is traversed
→ marker visibly moves in the same board presentation coordinate space
→ authenticated arrival
→ exact target ACTIVE -> CLEARED alpha 0
→ reservation / dispatcher / candidate cleanup
→ slot active visual resolves
→ click again and repeat under the changed board state
```

On the fresh Hazard Bot, add a test/log record of the actual first C08 target coordinate under the new policy.

Continue enough production-path clearing to prove an initially blocked non-C08 color becomes reachable and can clear.

The full 400-cell smoke must continue to complete without deadlock.

## 11. Manual-owner-playtest guide

Create:

`coordination/sessions/M21-C001/M21_V04_OWNER_PLAYTEST.md`

It must contain concise exact steps:

1. sync/open the project;
2. open the correct scene;
3. run current scene with F6;
4. what five slots/colors should be visible;
5. what to click;
6. what bottom-most/left-most reachable behavior to watch;
7. how to see the Scrubbot move from slot/spawn to target;
8. how cleared alpha/BG01 should look;
9. what is intentionally still functional/debug art vs final visual art.

Do not claim owner manual PASS before the owner actually performs this later review.

## 12. Tests and required validation

At minimum run and record:

```text
godot --version
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/m21_real_art_smoke.gd
```

Also run every currently required M20 queue-free/lifecycle smoke used in the V03 log.

Run the M21 owner-playable scene headless boot/parse check.

Run any new focused slot-view/presentation smoke you introduce.

Run:

- canonical M21 level builder deterministic rerun;
- M21 reference-composite generator twice;
- source PNG blob + SHA-256 recheck;
- M20 protected loop/dispatcher blob recheck;
- scan required outputs for literal `SCRIPT ERROR` / `Parse Error`;
- `git diff --check`.

### 12.1 Required target-priority test surface

Root tests must directly prove all criteria 76-87.

### 12.2 Required presentation test surface

Directly prove actual display/global coordinate mapping, not proxy state only.

### 12.3 Required slot/UI test surface

Directly prove:

- exactly five visible views;
- real SlotSystem binding;
- exact colors;
- click activates correct real color;
- no-work creates no gameplay side effect;
- rapid input does not duplicate assignment;
- active state lifecycle;
- slot/spawn-to-route transform coherence;
- portrait layout containment;
- second tall/aspect sanity.

Do not claim full mobile/touch/M44 completion from headless desktop evidence.

## 13. Regression expectations

Do not disable or delete previously passing tests to make V04 green.

All of these remain load-bearing:

- M15 strict-v2 safety/coherence/reentry tests;
- M16/M17 route contract/prototype/production tests;
- M18 agent lifecycle tests;
- M19 strict dispatcher tests;
- M20 strict clearing/lifecycle tests;
- M21 V01/V02/V03 builder/gameplay tests.

When an old assertion expects a particular row-major target, update only that **intentional policy expectation** to the new owner rule. Preserve its surrounding safety assertion.

If changing target order reveals a real routing/dispatcher/clearing defect, stop and report it rather than broad-patching accepted architecture.

## 14. Performance truth

The V04 UI adds only five slot components and a lightweight agent presentation layer. Avoid per-cell Nodes and avoid per-frame whole-board allocations.

Record any CPU/headless timing as diagnostic only. Do not claim phone FPS/GPU performance from headless runs.

## 15. Exact protected rechecks

At final handoff verify and record:

- owner source blob `b565743ba52699899007882b750b7c8e7cdd00f9`;
- owner source SHA-256 `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`;
- M20 loop blob `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- M20 dispatcher blob `eee10149e4f116af6706beec832042352bf3a6dd`;
- pre-V04 TargetSelector blob `a0daad67f8ba2238dd54cb903ac25dec7aa3144d` and its new final V04 blob.

TargetSelector is intentionally authorized to change for the owner policy. M20 loop/dispatcher are not.

## 16. V04 log

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V04.md`

The log must include:

- safe-sync evidence;
- preserved owner/local changes;
- tracker-only start commit full SHA;
- exact implementation commit(s);
- exact changed-file list;
- V03 preview-directory evidence closure;
- before/after TargetSelector policy and blob SHA;
- direct bottom/left priority matrix results;
- M15 strict regression results;
- AgentLayer/presentation transform architecture and direct coordinate evidence;
- SlotView/five-slot architecture and direct click/color/state evidence;
- actual first M21 C08 target coordinate under the new owner rule;
- full 400-cell smoke result;
- all required regression/smoke commands and exact results;
- failures encountered and what fixed them;
- deterministic generator results;
- final source/M20 locked identities;
- explicit statement that owner manual visual PASS is still pending after handoff.

Do not create a ChatGPT audit file or claim `AUDITED_PASS`.

## 17. Handoff tracker state

After implementation/tests are complete, update only the tracker lifecycle/handoff wording to:

```text
Current Milestone: M21
Current Sprint: M21-C001 V04 — owner playtest integration + final closure
Current Task: M21-C001-V04
Current Task Status: AWAITING_AUDIT
Required Actor: CHATGPT
```

Keep M21/M22 task checkboxes open and progress/lastCompletedTaskId unchanged for independent audit.

Push all authorized work safely to `origin/main`, never force.

## 18. Final response contract

If implementation and required validation complete successfully, return exactly:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V04.md
```

If a genuine upstream blocker is found, return exactly:

```text
BLOCKED
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V04.md
```

No extra prose in the final Claude response.
