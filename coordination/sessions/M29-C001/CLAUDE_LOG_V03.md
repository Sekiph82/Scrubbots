# M29-C001 V03 — Implementation Log (Claude)

Milestone: `M29 — Mobile Touch / Production Input Integration`
Cycle: `M29-C001 V03` — owner graphical-playtest remediation
Repository: `Sekiph82/Scrubbots` · branch `main`
Status: **AWAITING_AUDIT**

Prior audits: `CHATGPT_MANUAL_AUDIT_V03.md`, `CHATGPT_AUDIT_V02.md`
Implementation SHA: `acce76ceaec6b9565196ab3b9cc41a262d0baedc`
Log SHA: this commit (separate, log-only)

## 0. Scope / governance

Fixed all currently confirmed M29 graphical/playtest defects in one pass. Root `TASKS.md`
not modified. No M30. No Economy/Collection work. Zero AI image-generation credits.

Git: fast-forward synced to `origin/main` (owner Economy V1 + Codex visual commits present).
No `reset --hard` / `clean` / force. Codex-owned files under `coordination/codex_visual_assets/`
and `assets/ui/**` were NOT staged, reverted, or modified (three concurrently-modified
`assets/ui/final/gameplay/profile/*.png` were left untouched). Owner-local `project.godot`
left unstaged. Implementation commit staged only the 8 Claude source/test files by explicit path.

## 1. Root cause + fixes

### F-M29-MANUAL-001 — duplicate presentation nodes (the freeze)

`BoardPresentation.configure()` created a NEW `BoardRenderer` and `AgentLayer` on EVERY
call. `GameplayScreen._layout_board()` calls it on each responsive relayout, so after the
host bound M20 to the build-time renderer and the dispatcher/runtime to the build-time
AgentLayer, a later relayout produced newer presentation nodes. Reproduced headlessly at
683×1366: **2 BoardRenderer children**, agents dispatched into a layer that was no longer
the visible one, `cleared=0` while committed climbed — exactly the owner's frozen `50 (2)`.

Fix: `configure()` now creates the renderer and agent layer **exactly once** and, on every
later call, reconfigures the SAME instances (renderer re-render at the new cell size,
AgentLayer rescale). Geometry changes; presentation-node authority identity does not. Live
`ScrubbotAgent` children and the screen-inserted `ScrubRailView` are never replaced or
reordered. Post-fix: exactly one renderer + one AgentLayer; agents advance and clear the
CURRENT visible renderer.

### Live five-slot synchronization (F-M29-MANUAL-002)

`ProductionRuntimeController` now invokes a presentation-only sync callback at the end of
every driven tick; the host pushes a fresh detached `FiveSlotBatchEngine.snapshot()` into
the M28 strip. So scheduler-driven M24 mutations (commit, ACTIVE↔WAITING wake, rollback,
finalize, completion→EMPTY, reset) refresh the UI with no new player click. The UI never
runs TargetSelector/routing and never infers reachability; WAITING/ACTIVE come from the
authoritative M25-driven M24 slot state.

### Slot displayed count

`BatchSlotView` main number is now `capacity = remaining_to_clear − committed` (robots
still waiting in the slot). The raw `50 (2)` form is removed. M24 accounting is unchanged.

## 2. Files changed (Claude)

- `scripts/gameplay/board/board_presentation.gd` — identity-stable configure().
- `scripts/gameplay/runtime/production_runtime_controller.gd` — end-of-tick `_state_sync`.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — wire sync + `reset_session()`.
- `scripts/ui/batch_slot_view.gd` — display capacity; `get_display_count()`/`get_count_label_text()`.
- `scripts/ui/gameplay_screen.gd` — `refresh_slot_snapshot()` strip-only live refresh.
- Tests: `m29_presentation_identity_evidence.gd`, `m29_realtime_movement_smoke.gd`, `m29_slot_display_sync_evidence.gd`.

Preserved unchanged: M23–M27 engines, M29 input gate, mouse/touch dedup, rapid/multitouch,
pause/focus, cadence, speed authority, auto-2x, V02 exact visible slot-origin mapping. No
global `Engine.time_scale`.

## 3. Owner manual retest — exact F6 instructions

Scene: `res://scenes/debug/m29_hazard_bot_playtest.tscn` — open in graphical Godot 4.7.2
(project root `C:\Users\sekip\Desktop\ScrubBots`) and press **F6** (Run Current Scene).

You see the production M28 screen: the 20×20 Hazard Bot board + rail, five read-only slots,
three supply columns (front + two preview rows), boosters, and bottom row `Pause | Ad | 1x`.

- **What to click:** the FRONT (top) tile of a supply column. Only front tiles are clickable
  (preview rows and the five slots are not). Each placement drops the batch into the
  rightmost EMPTY slot automatically.
- **Blue 50 display after dispatch:** when a slot holds Blue 50 and one Scrubbot is
  committed/dispatched, the slot shows **49**; with two in flight it shows **48** (the main
  number = robots still waiting in the slot). It is no longer `50 (2)`. As robots authenticate
  clears, `remaining` and `committed` fall together so the waiting number stays correct.
- **Where the debug Scrubbot circles move:** a small colored circle leaves from directly
  under the clicked slot's on-screen position, travels the rail loop around the board and
  into the artwork, reaches its target cell, and disappears. Multiple circles move at once
  (one dispatched per scheduler step).
- **When pixels become transparent:** the instant a circle arrives at its cell, that pixel
  clears to transparent (BG01 shows through). Movement + clearing now run on the real
  `_process` clock — they must NOT freeze.
- **When Red/Yellow/Brown show WAITING:** in the deterministic first column
  (Red 15, Yellow 1, Blue 50, Blue 50, Brown 3) only the two Blue 50 batches have immediately
  reachable targets. Red, Yellow and Brown have no currently claimable target, so their slots
  display **WAITING** automatically (no extra click). WAITING = "no reachable target right
  now", not a bug.
- **Confirm WAITING → ACTIVE wake:** keep transferring fronts from the other columns. As
  clears open interior corridors, a slot that was WAITING flips back to **ACTIVE** on its own
  (no click) and its circle dispatches. This is the live authoritative sync updating the UI.
- **Verify pause:** click bottom-left **Pause** — cadence and all in-flight circles freeze;
  click again to resume (the selected 1x/2x speed is preserved). Switching the OS window
  focus away also pauses; returning focus resumes automatically without replaying a click.
- **Verify 1x/2x:** click the bottom-right control to toggle **1x ⇄ 2x** (it reads `2x`,
  cyan, at 2x). At 2x both the dispatch cadence and every circle's travel run twice as fast.
  When the FINAL supply batch is transferred, the game switches to `2x` automatically.

**Known complete-clear owner-facing click sequence** (1-based columns, left→right; place the
next as a slot frees): `1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3`. Following it clears the whole
board to empty and triggers automatic 2x on the final transfer.

**M30 limitation:** there is intentionally no win/lose/result screen — the board simply
becomes empty when fully cleared.

## 4. Regression evidence (Godot 4.7.2, headless unless noted)

```
run_tests.gd                              -> exit 0 (full root suite PASS)
m29_presentation_identity_evidence.gd     -> PASS (1080x2160 -> 683x1366 resize: renderer &
                                             AgentLayer identity unchanged, one child each,
                                             live agent survives, cleared pixel alpha 0)
m29_realtime_movement_smoke.gd            -> PASS (683x1366, real _process, NO manual tick:
                                             progress increases, arrives, clears, pixel
                                             transparent; focus suspend/resume; not spuriously
                                             suspended)
m29_slot_display_sync_evidence.gd         -> PASS (50->49->48 capacity; raw "50 (2)" gone;
                                             live WAITING / WAITING->ACTIVE wake / EMPTY /
                                             reset sync; Hazard non-blue WAITING)
m29_hazard_bot_runtime_smoke.gd           -> PASS (400 clears, ACTIVE=0, no ghost/dup,
                                             M23 exhausted, auto-2x, 1x/2x equivalence,
                                             exact visible origins)
m29_exact_slot_origin_evidence.gd         -> PASS
m29_input_gate_evidence.gd                -> PASS
m29_speed_authority_evidence.gd           -> PASS
m28_gameplay_layout_smoke.gd              -> PASS
m27_hazard_bot_solve / scale_59 / generation_retry -> PASS
m26_hazard_bot_integration / scale_59_sanity       -> PASS
m25_v03 / m24_v02 / m23_v03                          -> PASS
m22_railroad_responsive / v03_connector / v06_real_demo -> PASS
m20_v10_lifecycle_smoke                             -> PASS
git diff --check                                    -> clean
```
M19 dispatcher / M18 agent regressions are covered inside the full root suite.

## 5. Notes for the auditor

- The freeze was the duplicate-presentation lifecycle; the real-clock smoke proves the fix
  under `_process(delta)` without manually calling `runtime.tick()`.
- WAITING for Red/Yellow/Brown in the first column is correct (M27 trace: no immediate
  clears before Blue opens progress); the UI now shows it live and wakes it live.
- Codex visual-asset work was left entirely untouched.
