# M21-C001 V08 — Production-Immutable Adversarial Validation

You are Claude acting as implementation/test runner for `Sekiph82/Scrubbots` on `main`.

V07 production correction has passed ChatGPT's implementation-stage strict audit. **Do not modify the accepted V07 production candidate.** V08 exists solely because M21 is a critical routing/dispatch/clearing sprint and ChatGPT cannot independently execute Godot. This is the required auditor-authored validation-only stage before the owner repeats the visual playtest.

Read and obey every criterion in:

`coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V08.md`

Read first, in order:

1. `CLAUDE.md`
2. root `TASKS.md`
3. `coordination/AUDIT_POLICY.md`
4. `coordination/AUDIT_INDEX.md`
5. `coordination/sessions/M21-C001/OWNER_PLAYTEST_FINDINGS_V07.md`
6. `coordination/sessions/M21-C001/CHATGPT_PROMPT_V07.md`
7. `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V07.md`
8. `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`
9. `coordination/sessions/M21-C001/CHATGPT_AUDIT_V07.md`
10. `coordination/sessions/M21-C001/M21_V07_OWNER_PLAYTEST.md`

## 1. Safe sync and owner-work preservation

Safely synchronize local `main` with `origin/main` while preserving all owner/local tracked and untracked work.

Work only in `Sekiph82/Scrubbots`.

Never use `reset --hard`, destructive restore, `clean -fd`, force push, or any other shortcut that can erase owner work.

If local owner work prevents safe validation, stop `BLOCKED` rather than deleting it.

## 2. Root TASKS.md is ChatGPT-owned

**Read root `TASKS.md`, but do not modify it.**

Do not change lifecycle, status, actor, progress, notes, checkboxes or task text. ChatGPT owns the tracker and will update it after the V08 independent audit.

## 3. Production is immutable in V08

Do not modify any accepted production/presentation source, including but not limited to:

- `scripts/gameplay/routing/production_routing_system.gd`
- `scripts/debug/m21_real_art_vertical_slice.gd`
- `scripts/gameplay/routing/production_access_query.gd`
- `scripts/gameplay/dispatch/production_target_access.gd`
- `scripts/gameplay/targeting/target_selector.gd`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
- `scripts/gameplay/clearing/complete_clearing_loop.gd`
- `scripts/gameplay/agents/scrubbot_agent.gd`
- `scripts/gameplay/board/board_presentation.gd`
- `scripts/ui/slot_view.gd`
- `scenes/**`
- `project.godot`
- committed M21 level/art/generated artifacts.

The accepted V07 production blobs are locked by the V08 criteria.

You may add focused **test-only** validation code and `CLAUDE_LOG_V08.md`.

If a fresh test reveals a real production defect, **do not patch it in V08**. Record the exact failing evidence and stop `BLOCKED`.

## 4. Build one fresh auditor-authored validation surface

Create a focused validation script, preferably:

`tests/m21_v08_corridor_validation.gd`

It should be independently structured rather than a copy/paste rename of V07 tests.

It must test the actual V07 candidate through production collaborators.

### 4.1 Slot-only input

Independently validate that owner controller source contains no SPACE/keyboard gameplay fallback:

- no `KEY_SPACE`;
- no `step_one_clear`;
- no gameplay `_unhandled_input`;
- no replacement keyboard `_input`/`_shortcut_input` dispatch.

Then instantiate the real owner scene.

Prove the real Button signal chain is load-bearing:

1. disconnect one real SlotView's `slot_activated` connection to the scene handler;
2. press/emit the real Button path;
3. prove no dispatch/clear occurs;
4. reconnect the normal signal path;
5. press again;
6. prove real dispatch occurs from that exact visible slot anchor.

Do not treat direct `request_slot()` as sufficient owner-input evidence.

### 4.2 Recording access wrapper

Create a **test-only** recording wrapper around a real `ProductionAccessQuery`.

It must expose/delegate the complete required seam:

- `is_segment_traversable`
- `classify_cell`
- `cell_of_point`
- `is_bound_to`

Record calls without changing real access decisions.

Use it to prove the V07 planner search domain itself is exactly the board plus the one-cell ring. For a 20x20 case:

- outside cell classifications used by the planner must never have x < -1, x > 20, y < -1 or y > 20;
- every classified outside cell must be one of the four ring sides/corners;
- the exact slot-origin connector is allowed to start farther outside the ring, so do not misclassify the connector start as BFS search expansion.

Also create a test-only wrapper/mode that blocks exterior/ring cells while otherwise delegating real access truth. The same far-left bottom target must become `NO_ROUTE`. This makes the ring load-bearing without editing production.

### 4.3 Fresh four-side/corner matrix

Create fresh purpose-built arrangements that independently verify:

- below -> far-left bottom;
- above -> far-right top;
- left -> far-bottom left;
- right -> far-top right;
- a route that truly uses two adjacent exterior sides around a corner;
- a rectangular board;
- 59x59;
- enclosed interior ACTIVE stays unreachable;
- after a legitimate CLEARED opening, an interior target can become reachable;
- diagonal squeeze/corner cutting through ACTIVE blockers stays rejected.

For the corner case, do not merely assert `success`. Inspect route/access evidence and prove both expected exterior sides are used.

### 4.4 Exact fresh Hazard Bot scene

On a freshly instantiated owner scene:

- click the real visible C08 Button, slot 2;
- require exact target `380` / `(0,19)` / local palette id 2;
- require route[0] = exact visible slot anchor mapped through BoardPresentation;
- require final point `(0.5,19.5)`;
- revalidate the whole detached route through unchanged `RouteValidator` and `ProductionAccessQuery`;
- independently ensure no segment crosses a non-target ACTIVE board cell;
- drive the real agent to authenticated arrival using normal test orchestration;
- require only 380 becomes CLEARED;
- require candidate removal, reservation cleanup, dispatcher active count zero and AgentLayer zero orphan agents.

### 4.5 Rapid same-slot adversarial case

On another fresh owner scene, press C08 through the real Button path at least three times **before the first accepted agent arrives**.

If current dispatcher rules accept all three, require exact distinct targets:

`380, 381, 382`

in assignment order, unique owner IDs and exact bidirectional reservation pairs.

If a request is legitimately refused by an existing concurrency rule, prove the refused request causes zero side effects and then use a serial equivalent to finish the ordering proof. Do not change production rules merely to force three concurrent accepts.

After accepted agents finish, prove each target clears once and all reservation/agent/slot-active state cleans up.

### 4.6 Reset with ring-routed agents in flight

On another fresh owner scene:

1. dispatch at least two accepted C08 agents;
2. do not let them arrive;
3. capture BoardState/candidate/reservation/agent truth;
4. call the canonical reset path;
5. require zero active dispatcher assignments;
6. require zero reservations;
7. require no orphan agents after deferred cleanup;
8. require no in-flight target was cleared just because reset occurred;
9. require candidate truth remains coherent;
10. prove a fresh post-reset activation works correctly.

## 5. 59x59 performance diagnostic

For the fresh 59x59 routing case, record isolated route computation elapsed CPU time with `Time.get_ticks_usec()` or an equivalent monotonic timing source.

This is diagnostic only. Do **not** invent a hard pass/fail threshold and do not call it rendered FPS/GPU performance.

## 6. Engine environment discipline

Run `godot --version` and record the exact value.

V07 ran on `4.7.2.stable.official.ed1daf0bf` after the local environment had been upgraded from the historical 4.7.1 baseline.

**Do not install, upgrade, downgrade or otherwise change Godot in V08.** Use the current installed engine and report it truthfully.

## 7. Required regressions

Run and log at minimum:

1. `godot --headless --path . -s res://tests/run_tests.gd`
2. new `tests/m21_v08_corridor_validation.gd`
3. `tests/m21_v07_corridor_smoke.gd`
4. `tests/m21_v06_tall_layout_smoke.gd`
5. `tests/m21_v05_playtest_smoke.gd`
6. `tests/m21_real_art_smoke.gd`
7. every M20 lifecycle/queue-free smoke required by V07
8. owner scene headless boot
9. deterministic M21 level build rerun
10. deterministic M21 reference-composite rerun
11. `git diff --check`

Also confirm the inherited M15/M16/M17/M18/M19 strict tests touched by targetability/routing assumptions remain part of and green in the root suite.

Record exact commands, exit codes and exact root-suite count.

## 8. Blob and changed-file audit before push

Directly recheck every V08 locked blob from `CHATGPT_AUDIT_CRITERIA_V08.md`.

Before commit/push, inspect the full changed-file list.

If any production/source/scene/project/tracker file has changed because of V08 work, do not silently include it. Revert only your own V08-local unauthorized edit safely. Never overwrite a pre-existing owner/local modification.

The committed V08 diff should normally contain only:

- new/focused test validation file(s);
- `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`.

Do not modify V07 production tests merely to make V08 green unless ChatGPT explicitly authorized that file. Prefer a new V08 test surface.

## 9. Log

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`

Record:

- synchronized starting HEAD;
- owner/local work preserved;
- exact Godot version;
- statement that root `TASKS.md` was read and not modified;
- statement that all production/scenes/project files remained immutable;
- exact new test design;
- source-text slot-only results;
- instrumented ring-domain call evidence;
- blocked-ring sensitivity result;
- four-side/corner/rectangular/interior-opening results;
- exact Hazard Bot tuple and complete first route point list;
- rapid same-slot target/owner/reservation tuples;
- reset-in-flight before/after state tuple;
- 59x59 elapsed diagnostic;
- root and all focused smoke results;
- exact changed files;
- locked blob rechecks;
- failures encountered and whether they indicate a production defect.

Do not create an audit verdict/file.

## 10. Handoff

If every V08 criterion passes with production immutable:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V08.md
```

If any fresh validation exposes a genuine production/source defect:

```text
BLOCKED
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V08.md
```

In the BLOCKED case, do not fix the defect. ChatGPT will perform a new full-sprint sweep before authorizing any correction.