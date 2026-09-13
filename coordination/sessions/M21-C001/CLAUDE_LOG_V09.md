# M21-C001 V09 — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Cycle: `M21-C001` V09 — final direct-evidence reconciliation (validation-only, production-immutable)
Engine: `Godot 4.7.2.stable.official.ed1daf0bf`

## 1. Starting / sync state

- Confirmed repository `Sekiph82/Scrubbots`, branch `main`.
- Pre-existing owner/local work preserved untouched: `project.godot` (M), `scenes/debug/routing_prototype_lab.tscn` (M), `scenes/debug/scrubbot_agent_debug.tscn` (M), plus owner inbox/import sidecars (untracked). None staged, modified, or reverted.
- Synchronized local `main` with `origin/main` non-destructively (no `reset --hard`, no `clean -fd`, no force push, no destructive restore, no stash loss).
- HEAD == origin/main at handoff parent `4d1ac43 tracker: advance M21 to V09 direct-evidence reconciliation`.

## 2. Scope executed

Validation-only, production-immutable. No `scripts/**`, `scenes/**`, `project.godot`, root `TASKS.md`, owner Hazard Bot PNG, or M21 generated LevelData/preview/metadata/reference composite was modified.

Authorized committed V09 surface:

1. `tests/m21_v09_direct_evidence_reconciliation.gd` (new)
2. `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md` (this file)

All five frozen V08 direct-evidence gaps (G-V08-01..05) are closed in the single new test, using the real production collaborators (real owner scene, real SlotView Buttons, unchanged `ProductionRoutingSystem` / `ProductionAccessQuery` / `RouteValidator` / `ScrubbotDispatcher` / `ScrubbotAgent` / `CompleteClearingLoop`). No new production hooks were added.

## 3. Changed files (git status)

Intended V09 additions only:

- `tests/m21_v09_direct_evidence_reconciliation.gd`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V09.md`

Root `TASKS.md` NOT in diff. No production/source/scene/project/artifact file in diff. Owner/local `project.godot` + two debug scenes remain unstaged owner work. `git diff --check` clean (rc=0).

## 4. Direct evidence per frozen gap

### G-V08-01 — no-work real Button, zero reservation side effect (§6A)

On a fresh owner scene, the real no-work SlotView/Button was pressed. Complete snapshot taken before/after:

- `ok: A: candidate sets unchanged after no-work click`
- `ok: A: dispatcher active count unchanged (zero reservation side effect)`
- `ok: A: no assignment/reservation created`

Board ACTIVE state vector, per-color candidate sets, reservation count/mappings, dispatcher active count and AgentLayer ScrubbotAgent count all byte-equal across the click. Zero reservation side effect asserted directly (not inferred from agent count).

### G-V08-02 — distinct adjacent-side corner proof (§6B)

Legal below-mid origin → top-mid target corner-transition route built and revalidated through unchanged `RouteValidator + ProductionAccessQuery`. Non-corner side cells identified on two distinct adjacent sides, corner cells excluded from double-counting via dense CROSSED-cell sampling:

- `ok: B: below-mid -> top-mid corner route succeeds`
- `ok: B: corner route revalidates NONE`
- `ok: B: route crosses a TOP-side NON-corner ring cell (y=-1, 0<=x<=19)`
- `ok: B: route crosses a distinct adjacent vertical-side NON-corner ring cell (left x=-1 or right x=20)`
- `ok: B: planner classification stays within the one-cell ring domain`

Actual route vertices:
`[(10,21),(20,20)×5,(20,-1)×5,(10,-1)×5,(10,0)]`
Dense-sampled crossed cells include top-side non-corner `y=-1, 0<=x<=19` and vertical-side non-corner `x=20` (distinct, neither a corner). A `_RecAccess` recording wrapper confirms no route/classification exceeds the one-cell exterior ring.

### G-V08-03 — first C08 real Button exact transaction (§6C)

Fresh owner scene, all 400 BoardState states + exact C08 candidate set snapshotted; real C08 SlotView Button pressed once; assignment captured before overwrite; driven through real ScrubbotAgent to authenticated M20 arrival:

- `ok: C: target 380 == (0,19)`
- `ok: C: route[0] == mapped visible slot anchor`
- `ok: C: in-flight dispatcher owner->target == 380`
- `ok: C: whole-board changed-index set is EXACTLY [380]`
- `ok: C: C08 candidate set = pre minus exactly {380}`
- `ok: C: assignment pair gone; dispatcher active 0 after clear`
- `ok: C: AgentLayer 0 orphan agents after cleanup`

Whole-board delta computed over all 400 cells = exactly `{380}` (ACTIVE→CLEARED); candidate drop, bidirectional reservation lifecycle, dispatcher + AgentLayer cleanup all on the same fresh Button-path transaction.

### G-V08-04 — rapid x3 real visible C08 Button + active presentation (§6D)

Fresh owner scene, real C08 Button pressed three times before first arrival; each assignment stored immediately:

- `ok: D: targets 380,381,382 in order (got [380, 381, 382])`
- `ok: D: in-flight dispatcher owner->target exact for all three`
- `ok: D: C08 SlotView active while assignments in flight`
- `ok: D: slot still active after first arrival (2 in flight)`
- `ok: D: slot still active after second arrival (1 in flight)`
- `ok: D: slot returns inactive after final arrival`
- `ok: D: whole-board delta EXACTLY {380,381,382}`
- `ok: D: C08 candidate set loses exactly those three`

Unique owner IDs, exact bidirectional reservation mappings, no duplicate target. Real SlotView active presentation directly asserted across the in-flight window and its return to accepted idle after final cleanup (per V05/V07 presentation contract). Each of the three transitions ACTIVE→CLEARED exactly once, no unrelated board mutation. All three activations succeeded naturally under accepted production behavior (no refusal path taken).

### G-V08-05 — reset in flight through fresh real scene (§6E)

Fresh owner scene, real C08 Button pressed twice without completing either agent; exact pre-reset truth captured; canonical bound `CompleteClearingLoop.reset()` invoked:

- `ok: E: dispatcher active 2 pre-reset`
- `ok: E: exact pre-reset owner->target pairs`
- `ok: E: dispatcher active 0 after reset`
- `ok: E: in-flight targets remain ACTIVE`
- `ok: E: C08 candidate set coherent/unchanged after reset`
- `ok: E: no orphan agents after deferred frames`
- `ok: E: fresh post-reset C08 Button selects 380/(0,19)`

Exact pre/post BoardState vector, C08 candidate set, bidirectional reservation pairs, dispatcher active truth and AgentLayer identities compared. After reset: assignments zero, reservations zero (old pairs absent), board state identical, in-flight targets remain ACTIVE, candidate set coherent, zero orphan ScrubbotAgent children after deferred frames; a fresh real C08 Button press again naturally selects `380/(0,19)`.

Final line: `M21 V09 direct-evidence reconciliation: PASS`

## 5. Ten locked production blob identities (rechecked, all UNCHANGED)

| File | blob SHA-1 |
|---|---|
| `scripts/gameplay/routing/production_routing_system.gd` | `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1` |
| `scripts/debug/m21_real_art_vertical_slice.gd` | `153c042a17dc0ef9e83699a0beb2932217057ff4` |
| `scripts/gameplay/clearing/complete_clearing_loop.gd` | `06391839523cbc27e88a4b3ef12b730012cd45fa` |
| `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` | `eee10149e4f116af6706beec832042352bf3a6dd` |
| `scripts/gameplay/targeting/target_selector.gd` | `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` |
| `scripts/gameplay/routing/production_access_query.gd` | `7ba9d13556abb0e3a0a6d281449438330a25386d` |
| `scripts/gameplay/board/board_presentation.gd` | `2093df48d367903d332a910dfb3369154831a9ed` |
| `scripts/ui/slot_view.gd` | `480dffc0ee135150bd3dd2258f002264273ead10` |
| `scripts/gameplay/agents/scrubbot_agent.gd` | `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370` |
| owner Hazard Bot source PNG `assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png` | `b565743ba52699899007882b750b7c8e7cdd00f9` |

Root `TASKS.md` blob `2cc8715dec9c96a93b4c475d75da9d837cd85dd9` — unchanged, not in diff.

## 6. Required validation commands (exact observed results)

1. `godot --version` → `4.7.2.stable.official.ed1daf0bf`
2. `tests/m21_v09_direct_evidence_reconciliation.gd` → `M21 V09 direct-evidence reconciliation: PASS`
3. `tests/m21_v08_corridor_validation.gd` → `M21 V08 corridor validation: PASS`
4. `tests/m21_v07_corridor_smoke.gd` → `M21 V07 corridor smoke: PASS`
5. `tests/m21_v06_tall_layout_smoke.gd` → `M21 V06 tall-layout smoke: PASS`
6. `tests/m21_v05_playtest_smoke.gd` → `M21 V05 playtest smoke: PASS`
7. `tests/m21_real_art_smoke.gd` → `PASS — full 400-cell real-art run cleared` (clears=400, colors_cleared=5, no orphan)
8. full root `tests/run_tests.gd` → `Total checks: 4617`, `Failures: 0`, `RESULT: ALL PASS`
9. M20 regressions → `m20_queue_free_smoke`, `m20_v04/v05/v07/v08/v09/v10_lifecycle_smoke` all PASS
10. owner scene headless boot → `0` SCRIPT/Parse errors
11. `tools/build_m21_level.gd` → `LEVEL: UNCHANGED` (preview/metadata unchanged)
12. `tools/build_m21_reference_composite.gd` → `COMPOSITE: UNCHANGED`
13. `SCRIPT ERROR` / `Parse Error` scan → none
14. `git diff --check` → clean (rc=0)

Godot was neither installed, upgraded nor downgraded in V09. Installed version reported truthfully.

## 7. Immutability statement

Accepted production source, scenes, `project.godot`, M21 generated artifacts, owner Hazard Bot PNG, and root `TASKS.md` remained byte-identical throughout V09. All ten locked blobs verified unchanged. No production defect was discovered; no production patch was made. This log records no audit verdict — audit closure belongs to ChatGPT.
