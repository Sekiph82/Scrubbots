# M21-C001 V08 — Production-Immutable Final Technical Validation

You are Claude acting as implementation/test runner for `Sekiph82/Scrubbots` on `main`.

V07 production correction has passed ChatGPT's implementation-stage strict audit **and the owner has now manually re-tested the V07 Godot scene and explicitly passed the visual/game-feel gate**. Read:

`coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V07_PASS.md`

V08 is therefore the **final technical validation-only stage** before ChatGPT can close M21. It exists because V07 changed production routing inside a critical gameplay sprint and ChatGPT cannot independently execute Godot.

**Do not modify the accepted V07 production candidate.**

Read and obey every criterion in:

`coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V08.md`

## 1. Read first

1. `CLAUDE.md`
2. root `TASKS.md`
3. `coordination/AUDIT_POLICY.md`
4. `coordination/AUDIT_INDEX.md`
5. `coordination/sessions/M21-C001/OWNER_PLAYTEST_FINDINGS_V07.md`
6. `coordination/sessions/M21-C001/CHATGPT_PROMPT_V07.md`
7. `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V07.md`
8. `coordination/sessions/M21-C001/CLAUDE_LOG_V07.md`
9. `coordination/sessions/M21-C001/CHATGPT_AUDIT_V07.md`
10. `coordination/sessions/M21-C001/CHATGPT_OWNER_GATE_V07_PASS.md`
11. `coordination/sessions/M21-C001/M21_V07_OWNER_PLAYTEST.md`

## 2. Safe sync and tracker ownership

Safely synchronize local `main` with `origin/main` while preserving all owner/local tracked and untracked work.

Work only in `Sekiph82/Scrubbots`.

Never use `reset --hard`, destructive restore, `clean -fd`, force push, or any shortcut that can erase owner work.

**Read root `TASKS.md`, but do not modify it.** ChatGPT owns tracker lifecycle, progress, checkbox and closure changes.

## 3. Production is immutable

Do not modify any accepted production/presentation source, including:

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

The exact blob locks are in the V08 criteria.

You may add focused **test-only** validation code and `CLAUDE_LOG_V08.md`.

If fresh validation reveals a real production defect, **do not patch it in V08**. Record exact evidence and stop `BLOCKED`.

## 4. Required fresh validation surface

Create an independently structured test, preferably:

`tests/m21_v08_corridor_validation.gd`

Do not mechanically rename/copy the V07 test. Exercise the actual accepted production collaborators.

The fresh V08 surface must directly validate all of the following:

### A. Slot-only owner input

- no `KEY_SPACE`;
- no `step_one_clear`;
- no gameplay `_unhandled_input`;
- no replacement keyboard `_input`/`_shortcut_input` dispatch;
- exactly five real SlotViews;
- disconnecting a real SlotView `slot_activated` connection prevents dispatch;
- reconnecting and pressing the real Button causes real dispatch from that exact visible slot anchor;
- a no-work slot causes zero spawn/reservation/clear side effects.

Direct `request_slot()` is not sufficient owner-input evidence.

### B. Exact one-cell exterior routing domain

Wrap the real unchanged `ProductionAccessQuery` in a test-only recording delegate exposing the full required seam:

- `is_segment_traversable`
- `classify_cell`
- `cell_of_point`
- `is_bound_to`

Use it to prove planner expansion is restricted to the board plus exactly one exterior ring. For a 20×20 board, no planner-classified outside cell may fall beyond x/y `-1..20`, and every outside classified cell must belong to a legal ring side/corner.

Create a second test-only wrapper that blocks ring/exterior cells while delegating other production truth. The same far-left bottom target must then become unreachable without retargeting. This makes the corridor load-bearing.

### C. Generic routing matrix

Fresh purpose-built cases must cover:

- below → far-left bottom;
- above → far-right top;
- left → far-bottom left;
- right → far-top right;
- a true two-side corner transition;
- rectangular board;
- 59×59;
- enclosed interior ACTIVE remains unreachable;
- a legitimate CLEARED opening can later make an interior target reachable;
- diagonal squeeze/corner cutting through ACTIVE blockers remains rejected.

For the corner case, inspect route/access evidence and prove both expected exterior sides are actually involved.

### D. Exact real Hazard Bot

On a fresh owner scene, press the real visible C08 Button.

Require naturally, without forcing target IDs:

- slot id `2`;
- local palette id `2` / C08;
- target index `380`;
- coordinate `(0,19)`;
- route start = exact clicked visible slot anchor mapped through BoardPresentation;
- route end = `(0.5,19.5)`;
- detached route independently revalidates through unchanged RouteValidator/ProductionAccessQuery;
- no segment crosses a non-target ACTIVE board cell;
- authenticated arrival clears exactly index 380;
- candidate/reservation/dispatcher/AgentLayer cleanup is exact.

### E. Rapid same-slot and reset-in-flight

On a fresh scene, press C08 at least three times before first arrival. If current production legitimately accepts all three, require targets `380,381,382`, unique owner IDs and exact bidirectional reservations. If an existing concurrency rule refuses any press, prove that refusal has zero side effects and complete the ordering proof serially without changing production.

On another fresh scene, dispatch at least two exterior-routed C08 agents and reset before arrival. Require zero active assignments, zero reservations, no orphan agents after deferred cleanup, no accidental clear of in-flight targets, coherent candidates, and a valid fresh post-reset activation.

## 5. Performance diagnostic and engine discipline

For the 59×59 fresh routing case, record isolated route-computation elapsed CPU time using a monotonic timer. Diagnostic only, no invented hard threshold and no FPS/GPU claim.

Run `godot --version` and record the exact installed version. Do not install, upgrade or downgrade Godot in V08.

## 6. Required regressions

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

Confirm inherited M15/M16/M17/M18/M19 strict tests affected by routing assumptions remain present and green in the root suite.

Record exact commands, exit codes and exact root-suite count.

## 7. Blob and changed-file audit

Recheck every V08 locked blob from the criteria.

Before push, inspect the complete changed-file set. The committed V08 diff should normally contain only:

- new/focused test validation file(s);
- `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`.

No root `TASKS.md`, production source, scene, project file, M21 source art or generated production artifact may change.

## 8. Log

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V08.md`

Record synchronized starting HEAD, owner/local work preservation, exact Godot version, production immutability, exact fresh validation design, slot-only evidence, ring-domain instrumentation, blocked-ring sensitivity, four-side/corner/rectangular/59×59 results, exact Hazard Bot tuple and route, rapid-target/reservation tuples, reset-in-flight before/after tuple, timing diagnostic, every regression result, changed files, locked blob rechecks and all failures.

Do not create an audit verdict/file.

## 9. Handoff and final-closure law

If every V08 criterion passes with production immutable:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V08.md
```

If fresh validation exposes a genuine production/source defect:

```text
BLOCKED
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V08.md
```

In the BLOCKED case, do not fix production. ChatGPT will perform the next full-surface audit/correction scope.

**The owner manual V07 gate is already PASS and recorded. If V08 independently audits clean with production unchanged, ChatGPT may directly perform M21 final closure and tracker/task updates. Do not ask the owner to repeat the same manual playtest again unless a later production correction changes the accepted behavior.**