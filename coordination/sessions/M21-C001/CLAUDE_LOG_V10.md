# M21-C001 V10 — Claude Implementation Log

Repository: `Sekiph82/Scrubbots`
Branch: `main`
Actor: Claude (implementer/test runner)
Cycle: `M21-C001` V10 — final ReservationState / scene direct-evidence reconciliation (validation-only, production-immutable)
Engine: `Godot 4.7.2.stable.official.ed1daf0bf`

## 1. Starting / sync state

- Confirmed repository `Sekiph82/Scrubbots`, branch `main`.
- Synced local `main` to `origin/main` via `git rebase --autostash origin/main` (no `reset --hard`, no `clean -fd`, no force push, no destructive restore, no stash loss). Autostash preserved and re-applied owner/local work.
- Pre-existing owner/local work preserved untouched: `project.godot` (M), `scenes/debug/routing_prototype_lab.tscn` (M), `scenes/debug/scrubbot_agent_debug.tscn` (M), plus owner inbox/import sidecars and `.uid` sidecars (untracked). None staged, modified, or reverted.
- Base parent at handoff: `f81672c tracker: advance M21 to V10 final reservation evidence`.

## 2. Scope executed

Validation-only, production-immutable. No `scripts/**`, `scenes/**`, `project.godot`, root `TASKS.md`, owner Hazard Bot PNG, M21 generated LevelData/preview/metadata/reference composite, or existing V07/V08/V09 tests were modified.

Authorized committed V10 surface (exactly two files):

1. `tests/m21_v10_final_reservation_evidence.gd` (new)
2. `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md` (this file)

Closes frozen V09 residuals F-M21-V09-EVIDENCE-001 (exact ReservationState truth) and F-M21-V09-EVIDENCE-002 (implicit/absent exact scene assertions) in one pass, using the real production collaborators and the exact live ReservationState.

## 3. Changed files (git status)

Intended V10 additions only:

- `tests/m21_v10_final_reservation_evidence.gd`
- `coordination/sessions/M21-C001/CLAUDE_LOG_V10.md`

Root `TASKS.md` NOT in diff. No production/source/scene/project/artifact file and no existing V07/V08/V09 test in diff. Owner/local `project.godot` + two debug scenes remain unstaged owner work. `git diff --check` clean (rc=0).

## 4. Exact live ReservationState identity / coherence proof

The V09 proxy (dispatcher assignment map) is not carried forward. The V10 test obtains the exact live `ReservationState` already bound into the real owner scene's real `CompleteClearingLoop` via read-only introspection of the existing `_loop._reservations` field. No production getter/hook was added.

Baseline proof asserted on every scenario's fresh scene:

- `ok: live ReservationState object obtained from _loop._reservations`
- `ok: ReservationState bound to the scene's exact board` (`resv.is_bound_to(inst._board)`)
- `ok: dispatcher bound to the SAME board + SAME ReservationState` (`inst._dispatcher.is_bound_to(inst._board, resv)`)

All direct reservation evidence uses the ReservationState's own read-only queries `get_reservation_count()`, `get_owner(target)`, `get_target_for_owner(owner)`. No parallel ReservationState was instantiated.

`reservation_state.gd` blob (unchanged production, observed only): `6818bb63389dfad69b58248b8cabba9073bb63dd`.

## 5. Direct evidence per scenario

### A. No-work real Button (F-M21-V09-EVIDENCE-002 #1 + reservation zero-effect)

Fresh owner scene:

- `ok: A: exactly five SlotViews on fresh scene`
- `ok: A: ReservationState count 0 before no-work click`
- `ok: A: no-work slot Button yields a legitimate no-work result` (slot 0 / C01 enclosed)
- `ok: A: ReservationState count remains exactly 0 after no-work click`
- `ok: A: BoardState state vector byte-identical after no-work click`
- `ok: A: candidate sets unchanged after no-work click`
- `ok: A: dispatcher active 0 unchanged`
- `ok: A: AgentLayer 0 unchanged`

Zero reservation side effect asserted directly on the live ReservationState (count 0 → 0), not inferred.

### B. First C08 real Button — exact reservation pair lifecycle

Fresh owner scene, real C08 Button pressed once, driven to authenticated arrival:

- `ok: B: target 380 == (0,19)`
- `ok: B: ReservationState get_owner(380) == owner in flight`
- `ok: B: ReservationState get_target_for_owner(owner) == 380 in flight`
- `ok: B: ReservationState count == 1 in flight`
- `ok: B: both ReservationState mappings absent after clear`
- `ok: B: ReservationState count == 0 after clear`
- `ok: B: whole-board changed-index set EXACTLY [380]`
- `ok: B: C08 candidate set = pre minus exactly {380}`
- `ok: B: dispatcher + AgentLayer clean`

### C. Rapid real Button x3 — exact three pairs + AgentLayer 3→2→1→0

Fresh owner scene, three real C08 Button presses before first completion:

- `ok: C: targets 380,381,382 in order`
- `ok: C: unique owner ids`
- `ok: C: ReservationState count == 3 in flight`
- `ok: C: all three exact bidirectional ReservationState pairs in flight`
- `ok: C: AgentLayer contains exactly 3 real ScrubbotAgent children`
- `ok: C: C08 SlotView active while assignments in flight`
- first arrival → `count 2`, `first pair absent`, `other two pairs intact`, `AgentLayer exactly 2`, `slot active`
- second arrival → `count 1`, `second pair absent, third intact`, `AgentLayer exactly 1`, `slot active`
- final arrival → `count 0`, `third pair absent`, `AgentLayer 0 after deferred cleanup`, `slot returns idle`
- `ok: C: whole-board delta EXACTLY {380,381,382}`
- `ok: C: C08 candidate set loses exactly those three`

All three activations succeeded naturally under accepted production behavior (no refusal path). AgentLayer real-child lifecycle `3 -> 2 -> 1 -> 0` asserted directly (F-M21-V09-EVIDENCE-002 #2).

### D. Reset in flight — exact targets/owners/agent identities + reservation pre/post

Fresh owner scene, two real C08 Button presses without completion:

- `ok: D: targets are exactly 380,381` (F-M21-V09-EVIDENCE-002 #3)
- `ok: D: unique owner ids`
- `ok: D: two distinct agent instance identities captured` (F-M21-V09-EVIDENCE-002 #4)
- `ok: D: AgentLayer contains exactly those two agents`
- `ok: D: ReservationState count == 2 pre-reset`
- `ok: D: exact pair 1 pre-reset`, `ok: D: exact pair 2 pre-reset`
- after canonical `CompleteClearingLoop.reset()` (via `reset_presentation()`):
  - `ok: D: ReservationState count == 0 after reset`
  - `ok: D: old pair 1 absent after reset`, `ok: D: old pair 2 absent after reset`
  - `ok: D: dispatcher active 0 after reset`
  - `ok: D: BoardState state vector identical after reset`
  - `ok: D: in-flight targets remain ACTIVE`
  - `ok: D: C08 candidate set unchanged/coherent after reset`
  - `ok: D: neither captured agent identity remains; AgentLayer 0` (deferred frames)
  - `ok: D: fresh post-reset C08 Button selects 380/(0,19)`

Final line: `M21 V10 final reservation evidence: PASS`

## 6. Ten locked production blob identities (rechecked, all UNCHANGED)

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
| owner Hazard Bot source PNG | `b565743ba52699899007882b750b7c8e7cdd00f9` |

Root `TASKS.md` not in diff (`changed=0`); its current blob `2a3c61a6ceb52f940997344aa31fd998d48648e4` is ChatGPT's tracker state, untouched by this run.

## 7. Required validation commands (exact observed results)

1. `godot --version` → `4.7.2.stable.official.ed1daf0bf`
2. `tests/m21_v10_final_reservation_evidence.gd` → `M21 V10 final reservation evidence: PASS`
3. `tests/m21_v09_direct_evidence_reconciliation.gd` → `PASS`
4. `tests/m21_v08_corridor_validation.gd` → `PASS`
5. `tests/m21_v07_corridor_smoke.gd` → `PASS`; `m21_v06_tall_layout_smoke.gd` → `PASS`; `m21_v05_playtest_smoke.gd` → `PASS`
6. `tests/m21_real_art_smoke.gd` → `PASS` (full 400-cell real-art run cleared, no orphan)
7. full root `tests/run_tests.gd` → `Total checks: 4617`, `Failures: 0`, `RESULT: ALL PASS`
8. M20 regressions → `m20_queue_free_smoke`, `m20_v04/v05/v07/v08/v09/v10_lifecycle_smoke` all PASS
9. owner scene headless boot → `0` SCRIPT/Parse errors
10. `tools/build_m21_level.gd` → `LEVEL: UNCHANGED` (preview/metadata unchanged)
11. `tools/build_m21_reference_composite.gd` → `COMPOSITE: UNCHANGED`
12. `SCRIPT ERROR` / `Parse Error` scan → none
13. `git diff --check` → clean (rc=0)

Godot was neither installed, upgraded nor downgraded in V10. Installed version reported truthfully.

## 8. Immutability statement

Accepted production source, scenes, `project.godot`, M21 generated artifacts, owner Hazard Bot PNG, existing V07/V08/V09 tests, and root `TASKS.md` remained byte-identical throughout V10. All ten locked blobs verified unchanged; the observed-only `ReservationState` production script is unchanged. No production defect was discovered; no production patch was made. This log records no audit verdict — audit closure belongs to ChatGPT.
