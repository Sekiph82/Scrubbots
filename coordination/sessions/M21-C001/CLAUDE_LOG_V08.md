# M21-C001 V08 — Claude Implementation Log

Cycle: `M21-C001` V08 — production-immutable final technical validation.
Actor: Claude (implementer/test runner). Auditor: ChatGPT (independent).
Repository: `Sekiph82/Scrubbots`, branch `main`. Handoff: `AWAITING_AUDIT`.
Engine: Godot `4.7.2.stable.official.ed1daf0bf` (drift from the historical 4.7.1
recorded truthfully; V08 did NOT install/upgrade/downgrade Godot — the machine was
already on 4.7.2 from the prior run; V08-105/106).

Validation-ONLY pass. Production/presentation source, scenes, `project.godot`, M21
artifacts and root `TASKS.md` are byte-identical. The accepted V07 candidate is
exercised with fresh adversarial arrangements, instrumented access wrappers, the
real owner scene, and real production collaborators. No production defect found;
production was not modified.

## 0. Safe sync + preserved owner/local work

- Synchronized starting head: local `d704e2c…` fast-forwarded to `origin/main`
  `a88b507…` via `git rebase --autostash origin/main` (0 ahead / 8 behind; incoming
  = V07 audit + owner PASS gate + V08 prompt/criteria + ChatGPT tracker commits).
  Confirmed the incoming set did not touch the owner's locally-modified files first.
- Preserved owner/local work (autostash reapplied, never dropped/reset/restored):
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`,
  `scenes/debug/scrubbot_agent_debug.tscn` (unstaged), plus untracked owner inbox
  `.import`, `docs/logs/`, `*.uid`. None staged.
- Read root `TASKS.md`; did NOT modify it (ChatGPT owns the tracker; V08-004/109).
  No `.hiveai` tracker recreated.

## 1. Production immutability

No `scripts/**`, `scenes/**`, `project.godot`, M21 LevelData/preview/metadata/
reference-composite, or owner PNG changed. V08 adds only
`tests/m21_v08_corridor_validation.gd` and this log. All ten locked blobs rechecked
unchanged (§6).

## 2. Fresh validation design (`tests/m21_v08_corridor_validation.gd`)

Independently structured (not a rename/copy of the V07 test). Two test-only access
delegates wrap the UNCHANGED `ProductionAccessQuery`: `RecordingAccess` (records
every `classify_cell` coordinate, delegates all real truth) and `BlockingRingAccess`
(returns BLOCKED for any outside-board cell + rejects segments touching outside,
delegating inside). Real production collaborators are used throughout; the real owner
scene is instantiated for the Button-path and slot-only sections.

## 3. Evidence by section (all PASS)

**A slot-only owner input** — owner controller source contains no `KEY_SPACE`, no
`step_one_clear`, no `_unhandled_input`, no `_shortcut_input`, no `func _input(`
gameplay hook. Real scene has exactly five SlotViews. Disconnecting a SlotView
`slot_activated` connection then emitting its real Button `pressed` produces NO
dispatch; reconnecting + pressing dispatches from the exact visible slot anchor. A
no-work slot (C01) press yields zero spawn/reservation/clear.

**B instrumented one-cell ring domain** — on a fresh 20×20 far-bottom route via
`RecordingAccess`, every outside classified cell is within `-1..20` AND is a legal
ring side/corner (never a second exterior lane); the successful route uses the
exterior ring. `BlockingRingAccess` makes the same far-left-bottom target
**unreachable** with production unchanged and keeps the same target (no retarget) —
the corridor is load-bearing.

**C four-side / corner / rectangular / 59×59 / enclosed** — below→far-left-bottom,
above→far-right-top, left→far-bottom-left, right→far-top-right all succeed; a
below-left→top-right route provably uses BOTH left and top exterior sides;
rectangular 30×12 succeeds; 59×59 succeeds (isolated route CPU diagnostic
`7.488` ms, no FPS/GPU claim); enclosed interior ACTIVE stays unreachable; an
interior target becomes reachable only after a legitimate CLEARED corridor is
opened; a diagonal squeeze through two ACTIVE blockers is rejected by access truth.

**D fresh Hazard Bot real scene (Button path)** — clicking the real visible C08
Button:

```
slot id = 2 ; local palette id = 2 (C08)
target index = 380 ; coord = (0,19) ; ACTIVE + C08 before dispatch
route[0] = exact mapped visible slot anchor (BoardPresentation.global_to_board_local)
route end = (0.5,19.5)
detached route revalidates through unchanged RouteValidator + ProductionAccessQuery = NONE
no route segment crosses a non-target ACTIVE board cell
authenticated M20 arrival cleared exactly index 380
dispatcher active = 0 ; AgentLayer 0 orphan agents after deferred cleanup
```

Real-bundle first-clear additionally proves reservation target↔owner exists before
arrival and is released after clear, and the candidate index drops 380 (D/065/066).

**E rapid same-slot** — three concurrent C08 Button/loop activations before first
arrival are all accepted with targets exactly `380, 381, 382` in order, unique owner
ids, exact bidirectional reservation mapping, no duplicate target; after driving all
arrivals each target clears exactly once and reservations/agents clean up.

**H reset-in-flight** — two exterior-routed C08 agents dispatched (2 active, 2
reserved); canonical `CompleteClearingLoop.reset()` removes all active assignments,
releases all reservations, does NOT clear the in-flight targets, leaves candidate
truth coherent with BoardState, and leaves no orphan agents after deferred frames; a
fresh post-reset C08 activation again selects `(0,19)/380`.

**I route integrity** — every claimed success revalidates through RouteValidator
(NONE), begins at the exact request start and ends at the exact target centre, with
finite points (covered inline + inherited M16 strict tests).

## 4. Required commands and actual results

| Command | Result |
| --- | --- |
| `godot --version` | `4.7.2.stable.official.ed1daf0bf` |
| `tests/run_tests.gd` (root) | **4617 checks, 0 failures, ALL PASS** (0 SCRIPT/Parse errors) |
| `tests/m21_v08_corridor_validation.gd` | PASS |
| `tests/m21_v07_corridor_smoke.gd` | PASS |
| `tests/m21_v06_tall_layout_smoke.gd` | PASS |
| `tests/m21_v05_playtest_smoke.gd` | PASS |
| `tests/m21_real_art_smoke.gd` | PASS — 400 clears, exact clean final state (headless CPU diagnostic only, AL-003) |
| M20 queue-free + V04/V05/V07/V08/V09/V10 lifecycle smokes | all PASS |
| owner scene headless boot `--quit-after 5` | boots, 0 SCRIPT/Parse errors |
| `tools/build_m21_level.gd` rerun | LEVEL/PREVIEW/METADATA UNCHANGED |
| `tools/build_m21_reference_composite.gd` | UNCHANGED |
| scan for `SCRIPT ERROR` / `Parse Error` | 0 |
| `git diff --check` | clean (only benign pre-existing owner/local + LF advisories) |

Inherited M15/M16/M17/M18/M19 strict tests remain present and green in the root
suite (root count above).

## 5. Exact changed files (validation-only)

Added:
- `tests/m21_v08_corridor_validation.gd`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V08.md` (this file)

No other file changed. Root `TASKS.md` byte-identical; no production/scene/project/
artifact change; `.uid` sidecars not committed; owner local work never staged.

## 6. Locked-blob rechecks after all V08 work

| File | Blob | Status |
| --- | --- | --- |
| `production_routing_system.gd` | `8a0eea8e91298c852c692bd87ca1d09cd7d7f4a1` | unchanged |
| `m21_real_art_vertical_slice.gd` | `153c042a17dc0ef9e83699a0beb2932217057ff4` | unchanged |
| owner Hazard Bot PNG | `b565743ba52699899007882b750b7c8e7cdd00f9` | unchanged |
| `complete_clearing_loop.gd` | `06391839523cbc27e88a4b3ef12b730012cd45fa` | unchanged |
| `scrubbot_dispatcher.gd` | `eee10149e4f116af6706beec832042352bf3a6dd` | unchanged |
| `target_selector.gd` | `bb1e48a2a82f6ca4e8962f2a24de60e815c1a945` | unchanged |
| `production_access_query.gd` | `7ba9d13556abb0e3a0a6d281449438330a25386d` | unchanged |
| `board_presentation.gd` | `2093df48d367903d332a910dfb3369154831a9ed` | unchanged |
| `slot_view.gd` | `480dffc0ee135150bd3dd2258f002264273ead10` | unchanged |
| `scrubbot_agent.gd` | `48b43b1c8ee1709741fc6ad9c9b1ef436f4d6370` | unchanged |

## 7. Handoff

No production defect was found; production remains byte-identical (V08-115). The owner
manual V07 gate is already PASS (`CHATGPT_OWNER_GATE_V07_PASS.md`). Claude closed no
`SB-M21-*` / `SB-M22-*` / `SB-UI-*` checkbox, authored no audit verdict/file, and did
not modify root `TASKS.md`. Only the V08 test + this log are committed. All authorized
work pushed to `origin/main` without force. Handoff: **AWAITING_AUDIT**.
