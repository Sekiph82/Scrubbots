# M21-C001 V04 — Claude Implementation Log

Cycle: `M21-C001` V04 — owner playtest integration + final closure.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

Integrates the owner's first live-playtest decisions (bottom-most/left-most target
priority, visible board-aligned Scrubbot, five functional visible slots), pulls
forward the functional M22 slot subset, closes the one V03 evidence residual, and
preserves all accepted V01/V02/V03 corrections. Runtime results are Claude E1/E2
evidence; owner manual visual PASS is still pending after this handoff.

## 0. Safe sync + preserved owner/local work

- Synchronized starting head: local `3a0953a…` fast-forwarded to `origin/main`
  `e960ca8…` via `git rebase --autostash origin/main` (0 ahead / 5 behind; incoming
  = V03 audit, V04 prompt/criteria/owner-decision docs, and the ChatGPT pre-prompt
  tracker task-plan edit). Confirmed the incoming set did not touch the owner's
  locally-modified files before syncing.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import`, `docs/logs/`, `*.uid`. None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker-only V04 start commit

The §2 canonical task-plan reconciliations (owner-locked bottom-most/left-most
target rule, `SB-M15-003` supersession note, updated M21 intro, M22 pull-forward
record) were already present from the ChatGPT pre-prompt tracker edit `e960ca8`. My
tracker-only start commit set the Project Status lifecycle to
`M21 / M21-C001 V04 / IN_PROGRESS / CLAUDE` (progress unchanged 304/719 and
304/943; `lastCompletedTaskId` M20-C001-V11).

**Tracker-only start commit (only `TASKS.md`): `2de75dbc7b5b0b650c2aafe34b37829fd3e20f3f`.** Pushed before any implementation/test edit.

## 2. TargetSelector blob change (authorized)

- Pre-V04 TargetSelector blob: `a0daad67f8ba2238dd54cb903ac25dec7aa3144d`.
- Post-V04 TargetSelector blob: `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945`.

TargetSelector is the only production gameplay file intentionally changed (owner
policy). M20 loop/dispatcher are unchanged (see §8).

## 3. Owner-locked TargetSelector priority (F-M21-OWNER-PLAYTEST-001)

`scripts/gameplay/targeting/target_selector.gd`: after the detached candidate list
is fetched and coherence re-checked, the list is ordered by a new comparator
`_candidate_before` — **bottom-most first (largest board y), then left-most
(smallest board x), then smallest index** — using canonical
`BoardState.get_cell_position()` (crit 49). The existing eligibility loop is
unchanged, so every strict-v2 safety/coherence/reentry gate, malformed-entry
handling, reservation atomicity and exact-ownership proof still run in order; only
the inspection ORDER changed. The sort mutates only the detached copy — never the
candidate index or BoardState (crit 72/73). Non-int entries sort last and are still
skipped fail-closed. Routing/agent/renderer gain no target-selection role.

Superseded M15 row-major expectations were updated (not deleted) to the new policy:
M15-06/11/12/26 (3×3 → idx 6/7/6), M15-30 (rectangular → 7/9/1), M15-32/40
(benchmark now blocks the first N candidates in priority order and asserts N+1
bounded access queries). Surrounding safety assertions preserved. Sensitivity: the
V04 priority tests assert non-ascending outcomes (e.g. idx 6, not idx 0), so
restoring ascending row-major order fails them for the intended reason.

## 4. Shared board/agent presentation transform (F-M21-OWNER-PLAYTEST-002)

New presentation-only `scripts/gameplay/board/board_presentation.gd`
(`BoardPresentation` Node2D):

```
BoardPresentation (shared board origin)
├── BoardRenderer (Control, local 0,0)
└── AgentLayer (Node2D, local 0,0, scale = cell_size)
      └── real ScrubbotAgent(s)  (board-local cell units)
```

AgentLayer shares the renderer origin and is scaled by the renderer's integer
cell-size, so a board-local agent position maps to the exact BoardRenderer cell in
display space. The owner-playable scene binds `ScrubbotDispatcher` with the
AgentLayer as its explicit `agent_parent`, so spawned agents inherit the visible
transform instead of an unscaled root dot. No screen-pixel math was added to
RouteRequest/RouteResult/RoutingSystem/ScrubbotAgent — movement truth stays
board-local (crit 88/89/12).

## 5. Five visible functional slots (F-M21-OWNER-PLAYTEST-003 / M22 pull-forward)

- New `scripts/ui/slot_view.gd` (`SlotView`, extends Button): represents one real
  SlotSystem slot id, displays that slot's bound LevelData palette color, consumes
  only scalar state (slot id + Color) and retains no mutable SlotState reference,
  exposes a desktop click that emits `slot_activated(slot_id)`, and a
  presentation-only active/in-flight highlight.
- `scripts/debug/m21_real_art_vertical_slice.gd` rewritten to show exactly five
  SlotViews (colors from `SlotSystem.get_slot_palette_id` → LevelData palette) in an
  HBox below the board, each with a coherent board-local spawn origin. Clicking a
  slot calls `request_slot()` → the real `CompleteClearingLoop.activate_slot()`
  path (real TargetSelector/access/routing/dispatcher/agent/arrival) — no direct
  board mutation, no target forcing, no fake agent, no reservation bypass. The
  SPACE-key developer fallback remains. `SlotSystem.SLOT_COUNT == 5` stays the
  gameplay invariant. No booster/no-work final art invented (functional no-dispatch
  response only).

## 6. V03 evidence residual closed (§C)

Added a direct new-builder test: preview destination is an existing directory with
`overwrite=false` (and retained `overwrite=true`) → rejected by destination
object-type preflight before output/metadata mutation; the fixture leaves
output/metadata legitimately writable so the failure is specifically the preview
directory; owner source unchanged.

## 7. Requirement → evidence table (direct root-suite tests)

| Requirement | Test | Result |
| --- | --- | --- |
| V03 preview-dir overwrite false+true | `_run_m21_v04_preview_dir_tests` | PASS |
| bottom-most/left-most order | `_run_m21_v04_target_priority_tests` (76/77) | PASS |
| blocked bottom-left skipped | (78/87) | PASS |
| reserved bottom-left skipped | (79) | PASS |
| bottom row unavailable → climb | (80) | PASS |
| rectangular board | (81) | PASS |
| input order irrelevant / comparator | (82) | PASS |
| malformed entries safe | (83) | PASS |
| deterministic repeat | (84) | PASS |
| sensitivity (ascending would fail) | (75) | PASS |
| M21 first C08 bottom/left among targetable | (85/86) | PASS — first C08 target index 220 coord (0,11) |
| AgentLayer start maps through transform | `_run_m21_v04_presentation_transform_tests` (105) | PASS |
| agent final == renderer cell center | (106/100) | PASS |
| non-unit cell size | (109) | PASS |
| rectangular transform | (110) | PASS |
| real agent is AgentLayer child | (111/107) | PASS |
| exactly five SlotViews | `_run_m21_v04_slot_ui_tests` (114/136) | PASS |
| SlotView bound color == palette | (137/138) | PASS |
| click → real loop, correct color | (120/124/139) | PASS |
| no-work → no side effect | (140/121) | PASS |
| rapid input no duplicate target/owner | (141) | PASS |
| active state lifecycle | (127/128) | PASS |
| no mutable SlotState leak | (143) | PASS |
| portrait containment | (145) | PASS |
| full 400-cell smoke after order change | `tests/m21_real_art_smoke.gd` | PASS |

## 8. Required commands and actual results

| # | Command | Result |
| --- | --- | --- |
| 1 | `godot --version` | `4.7.1.stable.official.a13da4feb` |
| 2 | `godot --headless --path . -s res://tests/run_tests.gd` | **4580 checks, 0 failures, ALL PASS** (V03 baseline 4534 + 46 V04) |
| 3 | `tests/m21_real_art_smoke.gd` (fresh process) | PASS — 400 clears, 5 colors, exact clean final state; headless CPU diagnostic only (AL-003) |
| 4 | M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| 5 | headless boot `scenes/debug/m21_real_art_vertical_slice.tscn --quit-after 5` | boots, 0 SCRIPT/Parse errors |
| 6 | `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA all UNCHANGED |
| 7 | `tools/build_m21_reference_composite.gd` x2 | UNCHANGED / UNCHANGED |
| 8 | owner source blob + SHA-256 recheck | blob `b565743…`, sha256 `ede1e02…` — unchanged |
| 9 | M20 loop/dispatcher blob recheck | loop `06391839…`, dispatcher `eee10149…` — unchanged |
| 10 | scan required outputs for `SCRIPT ERROR` / `Parse Error` | 0 |
| 11 | `git diff --check` | clean (only benign pre-existing owner/local + LF-authored artifact line-ending advisories) |

Root-suite at-exit leak warnings remain pre-existing baseline behavior; V04 adds
none of substance (the presentation/slot nodes are freed by the tests).

## 9. Exact changed files (authorized V04 work)

Modified:
- `scripts/gameplay/targeting/target_selector.gd` (owner bottom-most/left-most priority; strict-v2 gates preserved)
- `scripts/debug/m21_real_art_vertical_slice.gd` (BoardPresentation + AgentLayer + five SlotViews + real click path)
- `tests/run_tests.gd` (M15 superseded-order expectation updates + V04 test suites)
- `TASKS.md` (tracker-only start `2de75db`, then AWAITING_AUDIT handoff)

Added:
- `scripts/gameplay/board/board_presentation.gd` (shared presentation transform / AgentLayer)
- `scripts/ui/slot_view.gd` (production-compatible SlotView)
- `coordination/sessions/M21-C001/M21_V04_OWNER_PLAYTEST.md` (manual owner-review guide)
- `coordination/sessions/M21-C001/CLAUDE_LOG_V04.md` (this file)

No M19/M20 production gameplay script, `difficulty_rules.gd`,
`production_level_validator.gd`, generic `level_importer.gd`,
`production_art_level_builder.gd`, owner source PNG, level JSON/preview/metadata, or
reference composite changed by V04. `.uid` sidecars not committed. Owner local work
never staged.

## 10. Locked-identity rechecks (after all work)

- owner source blob `b565743ba52699899007882b750b7c8e7cdd00f9`, SHA-256 `ede1e02a9096c4c7ba040b91ed7db2d2c2af3b2e20d5c8774068c8d08ad59899` — unchanged.
- M20 `CompleteClearingLoop` blob `06391839523cbc27e88a4b3ef12b730012cd45fa` — unchanged.
- M20 `ScrubbotDispatcher` blob `eee10149e4f116af6706beec832042352bf3a6dd` — unchanged.
- TargetSelector pre `a0daad67f8ba2238dd54cb903ac25dec7aa3144d` → post `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` (authorized owner-policy change).

## 11. Handoff

Owner manual visual PASS is still PENDING (the owner performs
`M21_V04_OWNER_PLAYTEST.md` after this handoff). Claude closed no `SB-M21-*` /
`SB-M22-*` / `SB-UI-*` checkbox and authored no audit verdict/file. Root `TASKS.md`
set to `M21 / M21-C001 V04 / AWAITING_AUDIT / CHATGPT`; progress unchanged 304/719
and 304/943; `lastCompletedTaskId` M20-C001-V11. All authorized work pushed to
`origin/main` without force. Handoff: **AWAITING_AUDIT**.
