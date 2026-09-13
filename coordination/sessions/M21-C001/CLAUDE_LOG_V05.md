# M21-C001 V05 — Claude Implementation Log

Cycle: `M21-C001` V05 — owner-playtest presentation correction + final validation.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

Focused correction of the frozen V04 findings F-M21-V04-001..004 in the
owner-playtest presentation/controller/UI/test/doc surface only. Accepted V04
TargetSelector priority and all accepted M15/M18/M19/M20 production behavior are
preserved. Runtime results are Claude E1/E2 evidence; owner manual visual PASS is
still pending independent audit.

## 0. Safe sync + preserved owner/local work

- Synchronized starting head: local `28ecbe3…` fast-forwarded to `origin/main`
  `fd0f5e9…` via `git rebase --autostash origin/main` (0 ahead / 3 behind; incoming
  = V04 audit, V05 prompt/criteria). Confirmed the incoming set did not touch the
  owner's locally-modified files before syncing.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import`, `docs/logs/`, `*.uid`. None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker-only V05 start commit

Set Project Status lifecycle to `M21 / M21-C001 V05 / IN_PROGRESS / CLAUDE`
(progress unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11).

**Tracker-only start commit (only `TASKS.md`): `4e7871b40093a3bcbef3a4c3cfeb56a69225f063`.** Pushed before
any implementation/test edit.

## 2. Frozen finding → correction → direct evidence

| Finding | Correction | Direct evidence |
| --- | --- | --- |
| F-M21-V04-001 controller double-drives the real agent | `m21_real_art_vertical_slice.gd` controller no longer calls `advance()` on any real agent; `_process` only `_reconcile()`s slot visuals (observation). Each ScrubbotAgent self-moves via its own `_process`→`advance`. No speed change, no route→pixel math. | `_run_m21_v05_single_mover_tests`: controller `_process(0.5)` leaves agent board-local position/progress unchanged, agent still MOVING; one `advance(delta)` moves exactly `speed*delta`; sensitivity vs V04 `advance(delta*6.0)`. Frame smoke: agent still in flight after a real frame (self-drive only). |
| F-M21-V04-002 slot geometry not the real spawn origin | Removed the slot-id left-edge constant. `SlotView.get_spawn_anchor_global()` exposes a laid-out top-center anchor; `BoardPresentation.global_to_board_local()` maps it through the AgentLayer inverse; the mapped board-local point is the `activate_slot` start. | `tests/m21_v05_playtest_smoke.gd`: for all five slots the anchor↔board-local mapping round-trips; for a real C08 click `agent.spawn_origin` == mapped start, agent global start == visible anchor global, route first point == mapped start, arrival == `BoardRenderer.get_cell_center_global`; sensitivity: moving SlotView geometry changes the mapped start. |
| F-M21-V04-003 singular active bookkeeping | Per-assignment tracking `owner_id → {slot, agent}`; a slot is active iff it has ≥1 in-flight assignment (`_reconcile` recomputes from valid+moving agents; safe against freed agents). Success adds one; failure adds none; completion removes only itself; reset clears all. | `_run_m21_v05_concurrency_tests`: two concurrent same-slot C08 assignments (distinct owner/target) keep the slot active after one completes and inactive only after the last; cross-slot two-active-then-isolated-completion; reset clears visuals. Frame smoke: AgentLayer no-orphan after arrival+frames and after reset. |
| F-M21-V04-004 proxy/missing evidence | Replaced the criterion-126 self-comparison with the real anchor→board-local→agent-start proof; added real Button-signal activation path, tall portrait, and AgentLayer cleanup evidence. | `_run_m21_v05_signal_path_tests` (BaseButton `pressed`→`_on_pressed`→`slot_activated`→scene handler→real loop; correct color; disconnect sensitivity); frame smoke tall 1080×2400 containment + slot bar below board; AgentLayer child-count after frames/reset. |

## 3. Accepted V04 basis preserved

- TargetSelector blob unchanged at `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`
  (owner bottom-most/left-most policy intact; no source edit in V05). All V04
  target-priority + M15 strict-v2 tests remain enabled and green (fresh M21 first
  C08 target still index 220 coord (0,11)).
- BoardPresentation/AgentLayer architecture kept (added only a narrow
  `global_to_board_local` inverse helper). SlotView kept scalar/query-bound (added
  only a presentation-only `get_spawn_anchor_global`); no mutable SlotState leak.
- V01–V03 builder/path corrections and V04 preview-directory tests unchanged.

## 4. One concrete slot mapping evidence tuple (frame smoke, slot 2 / C08)

`SlotView.get_spawn_anchor_global()` → `BoardPresentation.global_to_board_local()`
== `agent.spawn_origin` == `route.points[0]`, and `agent.global_position` at
dispatch == the SlotView anchor global (within <1px); arrival global ==
`BoardRenderer.get_cell_center_global(target)` (within <1px). All five slots’
anchor↔board-local mapping round-trips; distinct slots have distinct anchors.

## 5. Canonical five-slot reference (crit 146/147)

Owner canonical gameplay reference: `ASSET_GENERATION_MANIFEST.json` →
`canonical_references.gameplay` = `assets/art/references/_owner_inbox/Game Screens/deneme 3 OK.png`
(status `CANONICAL_SELECTED`). Used only for broad direction: a five-slot color bar
along the bottom beneath a dominant board. NOT flattened/copied — the runtime uses
native Godot `HBoxContainer` + `Button`-based `SlotView` controls with live colors
from `SlotSystem`/LevelData. No art generated.

## 6. Required commands and actual results

| # | Command | Result |
| --- | --- | --- |
| 1 | `godot --version` | `4.7.1.stable.official.a13da4feb` |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **4602 checks, 0 failures, ALL PASS**, 0 SCRIPT/Parse errors (V04 baseline 4580 preserved) |
| 3 | `tests/m21_real_art_smoke.gd` (fresh process) | PASS — 400 clears, exact clean final state; headless CPU diagnostic only (AL-003) |
| 4 | M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| 5 | `tests/m21_v05_playtest_smoke.gd` (frame-aware) | PASS — anchor mapping (5 slots), spawn_origin/global-start/route/arrival alignment, single-mover in-flight, no-orphan after arrival+reset, tall 1080×2400 |
| 6 | headless boot `scenes/debug/m21_real_art_vertical_slice.tscn --quit-after 5` | boots, 0 SCRIPT/Parse errors |
| 7 | `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA all UNCHANGED |
| 8 | `tools/build_m21_reference_composite.gd` x2 | UNCHANGED / UNCHANGED |
| 9 | owner source blob + SHA-256 recheck | blob `b565743…`, sha256 `ede1e02…` — unchanged |
| 10 | M20 loop/dispatcher blob recheck | loop `06391839…`, dispatcher `eee10149…` — unchanged |
| 11 | scan required outputs for `SCRIPT ERROR` / `Parse Error` | 0 |
| 12 | `git diff --check` | clean (only benign pre-existing owner/local + LF-authored artifact advisories) |

## 7. Exact changed files (authorized V05 work)

Modified:
- `scripts/debug/m21_real_art_vertical_slice.gd` (remove double-drive; anchor-based spawn; per-assignment concurrency tracking; observation-only `_process`)
- `scripts/ui/slot_view.gd` (add presentation-only `get_spawn_anchor_global`)
- `scripts/gameplay/board/board_presentation.gd` (add `global_to_board_local` inverse helper)
- `tests/run_tests.gd` (V05 single-mover/concurrency/signal-path tests; replace the V04 proxy spawn-origin self-comparison; fix the V01 debug-scene smoke to drive tracked assignments)
- `TASKS.md` (tracker-only start, then AWAITING_AUDIT handoff)

Added:
- `tests/m21_v05_playtest_smoke.gd` (frame-aware anchor/cleanup/tall-portrait smoke)
- `coordination/sessions/M21-C001/M21_V05_OWNER_PLAYTEST.md` (current owner guide)
- `coordination/sessions/M21-C001/CLAUDE_LOG_V05.md` (this file)

No M19/M20 production gameplay script, TargetSelector, `difficulty_rules.gd`,
`production_level_validator.gd`, generic `level_importer.gd`,
`production_art_level_builder.gd`, owner source PNG, level JSON/preview/metadata, or
reference composite changed by V05. `.uid` sidecars not committed. Owner local work
never staged.

## 8. Locked-identity rechecks (after all work)

- owner source blob `b565743ba52699899007882b750b7c8e7cdd00f9`, SHA-256 `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` — unchanged.
- M20 `CompleteClearingLoop` blob `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged.
- M20 `ScrubbotDispatcher` blob `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.
- TargetSelector blob `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` — unchanged from V04 (owner policy preserved).

## 9. Handoff

Owner manual visual PASS is still PENDING (owner performs
`M21_V05_OWNER_PLAYTEST.md` after independent audit). Claude closed no
`SB-M21-*` / `SB-M22-*` / `SB-UI-*` checkbox and authored no audit verdict/file.
Root `TASKS.md` set to `M21 / M21-C001 V05 / AWAITING_AUDIT / CHATGPT`; progress
unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11. All authorized
work pushed to `origin/main` without force. Handoff: **AWAITING_AUDIT**.
