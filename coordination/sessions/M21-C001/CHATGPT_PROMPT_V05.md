# M21-C001 V05 - Frozen Owner-Playtest Presentation Correction + Final Validation

You are Claude, the implementation/test runner. ChatGPT is the independent auditor.

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Cycle: `M21-C001` V05

This is a focused correction pass for the complete frozen V04 finding set. Do not broaden it into an unrelated UI/gameplay redesign.

## 0. Mandatory safe sync and repository scope

Work only in:

`https://github.com/Sekiph82/Scrubbots`

Before editing anything:

1. inspect `git status`, current branch, remote, ahead/behind state;
2. fetch `origin`;
3. safely synchronize local `main` with `origin/main` while preserving every pre-existing owner/local tracked and untracked change;
4. never `reset --hard`, never force checkout/restore owner work, never force push;
5. if pre-existing owner/local work prevents a safe sync or makes scope ambiguous, stop `BLOCKED` and report exact evidence;
6. after sync, confirm the canonical repository/branch again.

Read before implementation:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V04.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
- `coordination/sessions/M21-C001/OWNER_PLAYTEST_DECISIONS_V04.md`
- `coordination/sessions/M21-C001/CHATGPT_PROMPT_V04.md` for historical scope only
- current M15/M18/M19/M20 audit conclusions relevant to any touched seam.

Treat V04 audit findings `F-M21-V04-001..004` as **FROZEN**. Solve all four in this one pass.

## 1. Tracker-only V05 start commit first

Before any implementation/test/source edit, update only the root `TASKS.md` lifecycle fields to:

- Current Milestone: M21
- Current Sprint: M21-C001 V05 - owner-playtest presentation correction + final validation
- Current Task: M21-C001-V05
- Current Task Status: IN_PROGRESS
- Required Actor: CLAUDE
- Next Task/Action: execute V05 frozen correction and hand back for independent audit
- Progress: unchanged 304 / 719 = 42.28% (main+ui), overall 304 / 943 = 32.24%
- `lastCompletedTaskId`: unchanged `M20-C001-V11`

Do not close any `SB-M21-*`, `SB-M22-*`, or `SB-UI-*` checkbox.

Commit/push this tracker-only transition before implementation edits. Record its full SHA in `CLAUDE_LOG_V05.md`.

## 2. Accepted basis that V05 must preserve

These are accepted unless a concrete contradiction is discovered:

### Owner source

- path: `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`
- Git blob: `b565743ba52699899007882b750b7c8e7cdd00f9`
- SHA-256: `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899`

### Locked M20 production

- `scripts/gameplay/clearing/complete_clearing_loop.gd`
  blob `06391839523cbc27e88a4b3ef12b730012cd45fa`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
  blob `eee10149e4f116af6706beec832042352bf3a6dd`

Do not edit those files to make V05 pass. If V05 exposes a genuine defect that can only be fixed there, stop `BLOCKED` with exact reproduction/evidence and wait for ChatGPT-scoped remediation.

### Accepted V04 target policy

Current `TargetSelector` policy is owner-locked:

- canonical eligibility remains valid + ACTIVE + requested color + unreserved + currently targetable/reachable;
- among candidates inspected under that contract: largest board-local `y` first, then smallest `x`, deterministic tie break;
- TargetSelector decides WHAT;
- RoutingSystem decides HOW.

Preserve all M15 strict-v2 safety/coherence/reentry/reservation/rollback protections. The V04 policy implementation is not the target of this correction unless you prove a new defect.

### Accepted presentation direction

Keep the shared `BoardPresentation` / `AgentLayer` architecture:

```text
BoardPresentation
├── BoardRenderer
└── AgentLayer
    └── real ScrubbotAgent(s)
```

Movement truth stays in board-local cell units. Screen/UI transform work stays in presentation code.

### Accepted SlotView boundary

Keep `SlotView` native Godot UI, scalar/query-bound, with no mutable SlotState/SlotSystem reference leakage. It may gain a narrow presentation-only spawn-anchor query if needed.

### Accepted builder evidence

Keep V04's direct preview-destination-directory rejection tests for both `overwrite=false` and `overwrite=true` and all accepted V01-V03 builder/path corrections.

## 3. Frozen finding F-M21-V04-001: remove the second movement driver

The production ScrubbotAgent already moves itself:

```gdscript
func _process(delta):
    if MOVING:
        advance(delta)
```

`advance(delta)` then applies `speed * delta`.

The V04 owner controller also advances the same real agent in its own `_process`, including `advance(delta * 6.0)`. That is incorrect. It can make the marker travel roughly seven times the intended movement contribution under the current speed and hides the real owner-visible motion.

### Required correction

- The owner scene/controller must **never advance a real production ScrubbotAgent in ordinary frame processing**.
- Remove all parent/controller movement-driving calls for real agents.
- Do not disable `ScrubbotAgent._process()`.
- Do not compensate by changing agent speed.
- Do not rewrite routes into screen pixels.
- The controller may observe agent lifecycle and presentation bookkeeping only.

### Mandatory sensitivity evidence

Create a direct test using a real owner-scene/controller agent:

1. dispatch a real agent on a route long enough not to finish under the chosen delta;
2. capture board-local position/progress;
3. execute the owner controller's frame-observation path for a nonzero test delta and prove it does not move/progress the agent;
4. advance exactly one canonical agent movement step (`ScrubbotAgent._process(delta)` or equivalent one-owner movement call) and prove movement equals one `speed * delta`, not a doubled/multiplied value;
5. prove this test would fail against the V04 parent-driven `advance(delta * 6.0)` behavior.

Also perform a real scene-frame smoke that leaves a sufficiently long-route marker observably in flight for a nonzero interval before arrival. Do not make a fabricated FPS claim.

## 4. Frozen finding F-M21-V04-002: make visible slot geometry the real spawn authority

V04 visually places the SlotBar below the board but independently starts Scrubbots at hardcoded board-local left-edge positions. This is not a coherent visible slot -> Scrubbot spawn contract.

### Required architecture

For each actual visible SlotView:

1. define a documented presentation spawn anchor on the visible component, preferably a stable point such as top-center or center;
2. after real Control layout, obtain that anchor in global/canvas presentation coordinates;
3. convert the exact anchor through the real `AgentLayer` / `BoardPresentation` inverse transform into board-local cell units;
4. pass that mapped board-local point as `start_position` to `CompleteClearingLoop.activate_slot` for the visible activation;
5. the resulting real ScrubbotAgent must begin at that exact mapped board-local point and therefore appear globally at the clicked SlotView anchor.

The mapped start may be outside board bounds. The existing production routing exterior-origin semantics decide whether a target is reachable from it.

### Forbidden shortcuts

Do not:

- keep a parallel slot-id row/band formula as the route-start authority;
- pass raw UI/screen pixels directly into board-local routing;
- move screen math into TargetSelector/RoutingSystem/ScrubbotDispatcher/ScrubbotAgent;
- use an unrelated left-edge start while claiming it corresponds to a slot below the board;
- write a test that compares a stored origin only to its own getter.

### Mandatory direct proof

For at least one actual visible C08 click, and preferably all five slot mappings, record/assert:

- SlotView visible anchor global position;
- converted board-local start;
- real `agent.spawn_origin` equals mapped board-local start;
- real agent global start equals visible anchor global position within an explicit tolerance;
- route first point equals mapped board-local start;
- target/final global position still matches `BoardRenderer.get_cell_center_global()` for the selected target.

Add sensitivity:

- moving the SlotView geometry while retaining an old hardcoded start must fail;
- using slot N's anchor for slot M must fail;
- removing the transform conversion must fail.

## 5. Frozen finding F-M21-V04-003: make active presentation concurrency-correct

Do not invent a new global single-flight gameplay rule. The accepted dispatcher can own multiple active assignments. V04's singular `_active_agent` / `_active_slot` presentation bookkeeping cannot represent that state.

### Required correction

Track owner-playtest UI lifecycle **per real successful assignment** and derive each slot's active visual from the number/set of its still-in-flight assignments.

A valid narrow approach is conceptually:

```text
assignment_id/owner_id -> {slot_id, weak/validated agent identity}
slot_id -> active assignment count/set
```

Exact structure is your choice, but it must satisfy:

- success adds exactly one assignment;
- failure/no-work adds none;
- completion removes only that assignment;
- same-slot second assignment keeps the slot active after the first completes;
- different slots remain independently active;
- slot inactive only when its in-flight set/count reaches zero;
- invalid/freed agent observation is safe;
- reset/scene teardown clears presentation bookkeeping and active visuals;
- UI observation does not become BoardState/ReservationState clear authority;
- UI never owns/resurrects gameplay agents.

A benign presentation listener on the real agent's completion signal is acceptable if M19/M20 remain the only authoritative gameplay consumers. Be careful not to disconnect or replace M19's own callback.

### Mandatory concurrency tests

Use real production assignments, not fake booleans.

1. **Same slot:** arrange two successful simultaneous assignments from one slot when canonical gameplay allows it; prove distinct owner/target identities and slot active=true.
2. Complete one while the second remains in flight; prove slot remains active.
3. Complete the second; prove slot becomes inactive.
4. **Cross slot:** after enough real state change/reachability to make another color dispatchable, create one active assignment from each of two different slots; prove both independently active.
5. Complete one; prove the other stays active.
6. Complete/reset remainder; prove both inactive.
7. After deferred cleanup frames, prove AgentLayer contains no orphan agents.

Do not weaken reservation/dispatcher duplicate-assignment rules to create these tests.

## 6. Frozen finding F-M21-V04-004: replace proxy evidence with direct evidence

The V04 suite missed or proxy-tested the exact boundaries that failed. V05 must directly cover them.

### 6.1 Actual visible Button activation path

A V05 activation test must not use `request_slot()` as the activation stimulus.

Exercise the real path:

```text
visible SlotView Button input/pressed
-> SlotView _on_pressed
-> slot_activated(slot_id)
-> scene handler
-> CompleteClearingLoop.activate_slot
-> dispatcher/selector/routing/agent
```

Preferred automated proof: inject a real `InputEventMouseButton` through the scene Viewport at the laid-out slot center and pump the necessary frame(s).

If Godot 4.7.1 headless GUI routing prevents a trustworthy mouse event, document the exact limitation and at minimum exercise the actual BaseButton `pressed` signal into `SlotView._on_pressed`, then `slot_activated`, then the scene handler. A direct call to `request_slot()` alone is forbidden as criterion-147 evidence.

The test must be sensitive to disconnecting either signal connection.

### 6.2 Second/tall portrait case

Keep the 1080x2160 reference case and add a distinct tall portrait case such as 1080x2400 or another canonical repository target.

For both:

- all five slots remain visible/in content bounds;
- board remains visible/readable and is not covered by slot bar;
- slot-anchor -> board-local -> agent-start mapping remains correct.

Do not claim whole M44 responsive completion.

### 6.3 Direct AgentLayer cleanup

After real authenticated arrival/finalization:

- process enough frame(s) for deferred `queue_free()`;
- assert no completed ScrubbotAgent remains under AgentLayer.

Also exercise reset/teardown cleanup and assert no orphan agent children remain.

### 6.4 Canonical five-slot visual reference evidence

M22-001/criteria 163 was not evidenced clearly in V04.

Read repository inventory/tasks and identify the existing canonical gameplay/five-slot owner reference. Do not guess its repository path. Log the exact inventory/reference ID/path found in repository truth.

Record briefly:

- what broad layout direction you used from it;
- what you intentionally did not copy/flatten;
- why V05 still uses native Godot Controls.

No art generation is required.

## 7. Keep V04 target ordering and strict safety load-bearing

Do not regress the accepted owner target policy while correcting presentation.

Retain and run direct tests for:

- bottom-most row beats upper row;
- left-most on equal lowest row;
- blocked lower candidate is skipped;
- reserved lower candidate is skipped;
- unavailable bottom row climbs upward;
- rectangular board;
- randomized candidate input order;
- malformed/duplicate entries safe;
- deterministic repeat;
- fresh M21 first C08 target is bottom-most/left-most among **authoritative targetable** C08 candidates;
- restoring ascending row-major would fail for the intended reason.

Retain all historical M15 strict-v2 safety tests. Update nothing there unless strictly necessary.

## 8. Owner scene and playtest guide

Create:

`coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md`

Leave the V04 guide historical. V05 guide becomes current after ChatGPT audit.

It must tell the owner:

1. exact scene path: `scenes/debug/m21_real_art_vertical_slice.tscn`;
2. run current scene with F6 in Godot 4.7.1;
3. expect Hazard Bot over BG01;
4. expect exactly five slots C01/C03/C08/C11/C16;
5. click C08 first on a fresh board;
6. target policy is bottom-most then left-most **currently targetable** matching cell;
7. Scrubbot marker must visibly depart from the actual clicked slot's visible spawn anchor, not an unrelated board edge;
8. marker follows the real route and arrives at the exact target cell;
9. arrival clears exactly that target to transparency;
10. rapid same-slot clicks may produce multiple valid distinct assignments if gameplay permits and the slot must remain highlighted while any remain in flight;
11. after another color becomes reachable, rapid cross-slot activation must keep each active highlight independent;
12. a no-work color correctly produces no bot/no clear;
13. current marker/slot styling is functional/debug presentation, not final M27/M22 decorative art.

Do not ask for owner PASS in the Claude handoff. ChatGPT audits first.

## 9. Full validation matrix

Run and log actual output for at least:

1. `godot --version`;
2. full root suite:
   `godot --headless --path . -s res://tests/run_tests.gd`
3. fresh-process `tests/m21_real_art_smoke.gd` with exact 400-clear final truth;
4. all required M20 queue-free/lifecycle smokes previously required by V04;
5. owner scene headless boot/parse smoke;
6. V05 direct real-frame/single-movement-owner test;
7. V05 visible slot anchor -> real agent start tests;
8. V05 actual Button/signal/input chain test;
9. V05 same-slot and cross-slot concurrency presentation tests;
10. V05 tall portrait sanity;
11. V05 AgentLayer post-arrival and reset no-orphan tests;
12. `tools/build_m21_level.gd` deterministic rerun, expected UNCHANGED;
13. `tools/build_m21_reference_composite.gd` deterministic rerun(s), expected UNCHANGED;
14. owner source Git blob/SHA-256 recheck;
15. M20 loop/dispatcher blob recheck;
16. scan required outputs for literal `SCRIPT ERROR` / `Parse Error`;
17. `git diff --check`;
18. final changed-file review.

The V04 baseline was **4580/4580**. The V05 root suite must preserve all prior tests and add focused tests. Record the new exact total. Do not delete/disable a strict regression to preserve the count.

Headless timing is diagnostic only. Do not claim mobile FPS/GPU evidence.

## 10. Expected implementation surface

Prefer a narrow diff around:

- `scripts/debug/m21_real_art_vertical_slice.gd`
- `scripts/ui/slot_view.gd` only if a presentation anchor/query is needed
- `scripts/gameplay/board/board_presentation.gd` only if a narrow inverse/map helper is useful
- `tests/run_tests.gd`
- `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V05.md`
- root `TASKS.md` lifecycle only

TargetSelector should normally remain unchanged in V05. M18/M19/M20 production should remain unchanged.

If you need to touch anything beyond this surface, explain necessity before the change in the log and keep it within the frozen finding set.

## 11. V05 evidence log

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V05.md`

Include:

- safe sync result and preserved owner/local work;
- synchronized starting head;
- tracker-only V05 start commit full SHA;
- exact changed files;
- frozen finding -> correction -> direct test/evidence table;
- exact TargetSelector final blob and confirmation owner priority preserved;
- exact owner source blob/SHA-256;
- exact M20 loop/dispatcher blobs;
- one concrete slot mapping evidence tuple:
  `slot visible global anchor -> mapped board-local start -> agent.spawn_origin -> agent global start`;
- same-slot concurrent active-state lifecycle evidence;
- cross-slot concurrent active-state lifecycle evidence;
- real Button/input/signal-path evidence;
- tall portrait evidence;
- AgentLayer child count after deferred arrival cleanup and reset;
- exact full root test count/result;
- 400-cell smoke result;
- all required smoke/boot/build deterministic results;
- all failures encountered and fixes;
- clear statement that owner manual visual PASS is still pending independent audit.

## 12. Handoff tracker state

At the end, after implementation/tests are committed and pushed, update root `TASKS.md` to:

- Current Milestone: M21
- Current Sprint: M21-C001 V05 - owner-playtest presentation correction + final validation
- Current Task: M21-C001-V05
- Current Task Status: AWAITING_AUDIT
- Required Actor: CHATGPT
- Next Task/Action: independent V05 audit, then owner manual playtest only if audit passes
- Progress unchanged 304/719 and 304/943
- `lastCompletedTaskId` unchanged `M20-C001-V11`

Do not close M21/M22/UI checkboxes.

Push safely to `origin/main`, never force.

## 13. Stop conditions

Stop `BLOCKED` rather than improvising if:

- a correction truly requires modifying locked M19/M20 production;
- owner/local work cannot be preserved safely;
- canonical owner source identity changed unexpectedly;
- repository/branch scope is not `Sekiph82/Scrubbots` / `main`;
- a real engine limitation prevents the required owner-playable behavior and no narrow presentation-layer solution exists.

## 14. Final response

When finished successfully, return **exactly two lines**:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V05.md
```

If blocked, first line is `BLOCKED` and second line is the same direct V05 log URL.
