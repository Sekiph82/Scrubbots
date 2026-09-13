# M21-C001 V06 — Genuine Tall-Layout Validation-Only Closure

You are Claude acting as the implementation/test runner for `Sekiph82/Scrubbots` on `main`.

This is **not a production correction pass**. ChatGPT's independent V05 audit accepted the V05 production/presentation corrections and left exactly one frozen evidence residual:

`R-V05-TALL-001`: V05 claimed a second 1080×2400 portrait sanity test, but the committed smoke only compared the existing default-layout rects against a local `Vector2(1080, 2400)` bounds constant. It did not actually run/re-layout the owner scene under a genuine second 1080×2400 configuration, and therefore did not re-prove the slot-anchor → real agent-start chain under that second configuration.

Your job is to close **only that evidence residual**.

Read and obey every numbered item in:

`coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V06.md`

Also read:

- `CLAUDE.md`
- root `TASKS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/AUDIT_INDEX.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_V05.md`
- `coordination/sessions/M21-C001/CHATGPT_AUDIT_CRITERIA_V05.md`
- `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md`

## 1. Safe synchronization first

Safely synchronize local `main` with `origin/main` while preserving every pre-existing owner/local tracked and untracked change.

Do not reset, restore, clean, delete, or overwrite owner/local work merely to obtain a clean tree.

Work only in `Sekiph82/Scrubbots`.

No force push.

Do not recreate `.hiveai` as a live tracker.

## 2. Tracker-only V06 start commit before validation-file edits

Before editing any validation/test/log file, make a separate tracker-only commit containing only the root `TASKS.md` lifecycle transition to:

- Current Milestone: `M21`
- Current Sprint: `M21-C001 V06 — genuine tall-layout validation-only closure`
- Current Task: `M21-C001-V06`
- Current Task Status: `IN_PROGRESS`
- Required Actor: `CLAUDE`
- Progress: unchanged `304 / 719 = 42.28%` main+ui and `304 / 943 = 32.24%` overall
- `lastCompletedTaskId`: unchanged `M20-C001-V11`

Do not close any M21/M22/UI task checkbox.

Push this tracker-only commit before continuing.

## 3. Hard validation-only source lock

A successful V06 must leave these exact accepted blobs unchanged:

- owner Hazard Bot source: `b565743ba52699899007882b750b7c8e7cdd00f9`
- `scripts/gameplay/clearing/complete_clearing_loop.gd`: `06391839523cbc27e88a4b3ef12b730012cd45fa`
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`: `eee10149e4f116af6706beec832042352bf3a6dd`
- `scripts/gameplay/targeting/target_selector.gd`: `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`
- `scripts/debug/m21_real_art_vertical_slice.gd`: `66050fe5ec95498a43c6d4abccf62c4d82744d39`
- `scripts/gameplay/board/board_presentation.gd`: `2093df48d367903d332a910dfb3369154831a9ed`
- `scripts/ui/slot_view.gd`: `480dffc0ee135150bd3dd2258f002264273ead10`

Do not edit `project.godot`, `scripts/**`, or `scenes/**` merely to make V06 pass.

If a genuine 1080×2400 run reveals that any accepted production/presentation source must actually change, **STOP**. Do not fix it in this pass. Record exact reproduction/evidence, set the cycle to `BLOCKED`, push evidence only, and return the direct V06 log URL.

## 4. Build a genuine 1080×2400 frame-aware validation

Create a dedicated fresh-process test, preferably:

`tests/m21_v06_tall_layout_smoke.gd`

The test must boot the real owner scene:

`scenes/debug/m21_real_art_vertical_slice.tscn`

The crucial requirement is that it must actually establish and directly observe a **real second 1080×2400 layout configuration**.

The existing V05 pattern below is NOT sufficient:

```gdscript
var vp := Vector2(1080, 2400)
# compare unchanged/default-layout rects against vp
```

You must use a real Godot mechanism that changes the relevant root/window/viewport/content layout configuration to 1080×2400, then directly prove the actual runtime layout is using that configuration.

For example, if appropriate and reliable under Godot 4.7.1 headless, configure the root Window/Viewport size for the fresh process and await enough frames for Control layout to settle. You may use another real mechanism if it is more reliable, but the test must directly observe the actual tall configuration after applying it.

Do not change committed `project.godot` to achieve this.

Record both:

- the canonical/default reference configuration (`1080×2160`), and
- the actual tall validation configuration (`1080×2400`).

The test must be sensitive to the tall-configuration step being removed. If the process remains at 1080×2160, the tall validation must fail rather than silently pass against a larger local bounds rectangle.

## 5. Re-prove real geometry under the genuine tall layout

After applying 1080×2400 and awaiting layout frames:

1. verify exactly five real SlotViews exist;
2. observe their real laid-out global rects;
3. prove all five are within the actual tall content bounds;
4. prove the SlotBar does not cover the displayed board;
5. prove the board remains visible/readable enough for this focused owner-playtest sanity gate;
6. obtain the actual visible spawn anchor from a reachable slot after the tall layout has settled;
7. map that exact global anchor using the real `BoardPresentation.global_to_board_local()`;
8. activate the visible slot through the real V05 Button/signal chain if feasible under the test harness; do not use direct `request_slot()` as the only tall activation stimulus;
9. prove the result is a real successful production assignment;
10. prove the real ScrubbotAgent is an AgentLayer child;
11. prove `agent.spawn_origin == mapped tall-layout anchor` within explicit tolerance;
12. prove initial `agent.global_position == actual tall-layout visible slot anchor` within explicit tolerance;
13. prove the real route first point equals the mapped board-local start;
14. do not force target identity;
15. prove arrival global equals the actual BoardRenderer target-cell center;
16. prove the authenticated M20 path clears exactly that target;
17. pump deferred cleanup frames and prove AgentLayer contains zero ScrubbotAgent children.

Log a concrete tuple containing:

- actual reference/default size;
- actual tall size;
- slot id and real palette id/color;
- visible slot anchor global;
- mapped board-local start;
- `agent.spawn_origin`;
- route first point;
- owner id;
- target index and coordinate;
- initial agent global position;
- renderer target-cell global center;
- final cleanup child count.

## 6. Preserve all accepted V05 evidence

Re-run and retain:

- full root test suite;
- V05 single-mover tests;
- V05 same-slot and cross-slot concurrency tests;
- V05 Button signal-path test;
- `tests/m21_v05_playtest_smoke.gd`;
- `tests/m21_real_art_smoke.gd` with exactly 400 clears and exact clean final state;
- existing M15 strict tests;
- M18 agent tests;
- M19 strict dispatcher tests/smokes;
- M20 complete-clearing/lifecycle/queue-free smokes;
- M21 V01/V02/V03/V04 tests;
- owner-scene headless boot.

Do not delete/disable/rewrite a previously passing strict test merely to obtain green.

The new V06 test can be standalone if genuine frame/layout behavior is not suitable for the synchronous root runner. It still must be executed explicitly from a fresh process and logged.

## 7. Exact immutability verification after validation

After all V06 work, directly recheck every locked blob listed in section 3.

Also show that the successful V06 diff contains no changes under:

- `scripts/**`
- `scenes/**`
- `project.godot`

Allowed V06 changes should be limited to validation/test/log/tracker evidence required by this prompt.

## 8. V06 log and handoff

Create:

`coordination/sessions/M21-C001/CLAUDE_LOG_V06.md`

The log must include:

- synchronized starting HEAD;
- tracker-only V06 start commit SHA;
- exact changed files;
- exact mechanism used to establish the real 1080×2400 layout;
- direct observation that it actually became 1080×2400;
- the concrete tall-layout mapping/assignment tuple;
- every required command and actual result;
- any failed attempt and correction;
- exact protected blob rechecks;
- explicit statement that owner manual PASS is still pending independent ChatGPT audit.

At successful handoff set only the tracker lifecycle to:

- `M21-C001 V06`
- `AWAITING_AUDIT`
- Required Actor `CHATGPT`

Keep progress and `lastCompletedTaskId` unchanged and do not close M21/M22/UI checkboxes.

Push all authorized work safely to `origin/main`.

Your final response must be exactly two lines:

```text
AWAITING_AUDIT
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V06.md
```

If genuine tall execution exposes a production/presentation defect requiring accepted source changes, your final response must instead be exactly:

```text
BLOCKED
https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M21-C001/CLAUDE_LOG_V06.md
```
