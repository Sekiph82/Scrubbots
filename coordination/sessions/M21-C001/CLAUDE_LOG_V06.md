# M21-C001 V06 — Claude Implementation Log

Cycle: `M21-C001` V06 — genuine tall-layout validation-only closure.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.1.stable.official.a13da4feb`.

Validation-only pass closing the single frozen V05 residual `R-V05-TALL-001`: prove
the visible-slot-anchor → board-local route start → real ScrubbotAgent chain under a
GENUINE second 1080×2400 layout configuration (not a local bounds constant). No
production/presentation source changed. Runtime results are Claude E1/E2 evidence;
owner manual visual PASS is still pending independent audit.

## 0. Safe sync + preserved owner/local work

- Synchronized starting head: local `4dd3fb0…` fast-forwarded to `origin/main`
  `8de5c89…` via `git rebase --autostash origin/main` (0 ahead / 3 behind; incoming
  = V05 audit, V06 prompt/criteria). Confirmed the incoming set did not touch the
  owner's locally-modified files before syncing.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import` sidecars (incl. new M21 preview/source `.import`), `docs/logs/`, `*.uid`.
  None staged.
- No `.hiveai` tracker recreated. GitHub-only logging.

## 1. Tracker-only V06 start commit

Set Project Status lifecycle to `M21 / M21-C001 V06 / IN_PROGRESS / CLAUDE`
(progress unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11).

**Tracker-only start commit (only `TASKS.md`): `f57746d19c1f4852c0057fd883be0adbbb0ac5f2`.** Pushed before any validation/test edit.

## 2. Genuine 1080×2400 layout mechanism + direct observation

New `tests/m21_v06_tall_layout_smoke.gd` (fresh headless process) establishes a REAL
second layout configuration by hosting the actual owner scene
(`scenes/debug/m21_real_art_vertical_slice.tscn`) inside a `SubViewport` whose
`size` is set to `Vector2i(1080, 2400)`, then awaits Control-layout frames. This is
a real Godot layout mechanism, drives genuine Control layout, and does not touch
committed `project.godot`.

Direct observation (crit 35/36/37): the test asserts `SubViewport.size == (1080,
2400)` — the actual size used for Control layout — and that it is distinct from the
canonical `1080×2160` default. Sensitivity (crit 63/64): removing the
`sub.size = TALL_SIZE` step leaves the SubViewport at its default size, so the
`== (1080,2400)` assertion fails rather than silently passing against a larger local
rectangle. Observed runtime: default `get_root().size` = `(100,100)` under headless;
canonical reference documented as `1080×2160`; genuine tall config = `(1080,2400)`.

## 3. Tall-layout direct proof (all PASS)

Under the genuine 1080×2400 SubViewport, after layout frames:

- exactly five real SlotViews; all five laid-out global rects within the actual
  `1080×2400` bounds (no negative / out-of-bounds);
- the SlotBar sits below the displayed board region (no overlap); board fits within
  tall bounds;
- real Button signal chain (`pressed → _on_pressed → slot_activated → scene handler
  → CompleteClearingLoop`) dispatches a real C08 assignment (not direct
  `request_slot()`);
- `agent.spawn_origin == BoardPresentation.global_to_board_local(SlotView anchor)`;
- agent initial global == the tall visible slot anchor; route first point == mapped
  board-local start; target selected by the real production path (not forced);
- arrival global == `BoardRenderer.get_cell_center_global(target)`; authenticated
  M20 path clears exactly that target (CLEARED); after deferred frames AgentLayer
  has zero ScrubbotAgent children.

### Concrete tall-layout tuple

```
reference/default = (1080,2160) ; tall = (1080,2400)
slot id = 2 ; palette id = 2 (C08)
visible slot anchor global = (400.0, 880.0)
mapped board-local start   = (9.444445, 21.11111)
agent.spawn_origin         = (9.444445, 21.11111)
route first point          = (9.444445, 21.11111)
owner id = 0 ; target index = 388 ; target coord = (8, 19)
agent initial global       = (400.0, 880.0)
renderer target-cell global center = (366.0, 822.0)
AgentLayer child count after cleanup = 0
```

(`spawn_origin == mapped == route[0]`, and `agent initial global == anchor global`,
directly demonstrate the anchor→board-local→agent-start chain under the tall config.)

## 4. Preserved accepted evidence (re-run)

| Command | Result |
| --- | --- |
| `godot --version` | `4.7.1.stable.official.a13da4feb` |
| `tests/run_tests.gd` (root) | **4602 checks, 0 failures, ALL PASS** (0 SCRIPT/Parse errors) |
| `tests/m21_v06_tall_layout_smoke.gd` | PASS (16 checks) |
| `tests/m21_v05_playtest_smoke.gd` | PASS |
| `tests/m21_real_art_smoke.gd` | PASS — 400 clears, exact clean final state (headless CPU diagnostic only, AL-003) |
| M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| owner scene headless boot `--quit-after 5` | boots, 0 SCRIPT/Parse errors |
| `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA UNCHANGED |
| `tools/build_m21_reference_composite.gd` | UNCHANGED |
| scan for `SCRIPT ERROR` / `Parse Error` | 0 |
| `git diff --check` | clean (only benign pre-existing owner/local + LF advisories) |

## 5. Exact changed files (validation-only)

Added:
- `tests/m21_v06_tall_layout_smoke.gd` (genuine tall-layout validation smoke)
- `coordination/sessions/M21-C001/CLAUDE_LOG_V06.md` (this file)

Modified:
- `TASKS.md` (tracker-only start `f57746d`, then AWAITING_AUDIT handoff)

No change under `scripts/**`, `scenes/**`, or `project.godot`. No LevelData /
importer / builder / difficulty / validator / routing / agent / dispatcher /
clearing / UI production or presentation source changed. `.uid` sidecars not
committed. Owner local work never staged.

## 6. Locked-blob rechecks after all V06 work

| File | Blob | Status |
| --- | --- | --- |
| owner Hazard Bot source PNG | `b565743ba52699899007882b750b7c8e7cdd00f9` | unchanged |
| `complete_clearing_loop.gd` | `06391839523cbc27e88a4b3ef12b730012cd45fa` | unchanged |
| `scrubbot_dispatcher.gd` | `eee10149e4f116af6706beec832042352bf3a6dd` | unchanged |
| `target_selector.gd` | `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` | unchanged |
| `m21_real_art_vertical_slice.gd` | `66050fe5ec95498a43c6d4abccf62c4d82744d39` | unchanged |
| `board_presentation.gd` | `2093df48d367903d332a910dfb3369154831a9ed` | unchanged |
| `slot_view.gd` | `480dffc0ee135150bd3dd2258f002264273ead10` | unchanged |

## 7. Handoff

Owner manual visual PASS is still PENDING independent audit. Claude closed no
`SB-M21-*` / `SB-M22-*` / `SB-UI-*` checkbox and authored no audit verdict/file.
Root `TASKS.md` set to `M21 / M21-C001 V06 / AWAITING_AUDIT / CHATGPT`; progress
unchanged 304/719 and 304/943; `lastCompletedTaskId` M20-C001-V11. All authorized
validation-only work pushed to `origin/main` without force. Handoff: **AWAITING_AUDIT**.
