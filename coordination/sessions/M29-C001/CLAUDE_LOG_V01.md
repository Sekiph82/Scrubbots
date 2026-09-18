# M29-C001 V01 — Implementation Log (Claude)

Milestone: `M29 — Mobile Touch / Production Input Integration`
Tasks: `SB-M29-001..009` + owner-locked 1x/2x speed rule
Repository: `Sekiph82/Scrubbots` · branch `main`
Status: **AWAITING_AUDIT**

Owner baseline before implementation: `0cbe285` (`origin/main` at start)
Implementation SHA: `d191bf6839d8e01602d99a5fe5196c17d192c32c`
Log SHA: this commit (separate, log-only)

## 0. Git synchronization / owner-work preservation

- Confirmed repo `Sekiph82/Scrubbots`, branch `main`. Local was 9 behind / 0 ahead of
  `origin/main`; fast-forwarded (`merge --ff-only`) — no `reset --hard` / `clean` /
  force. `origin/main` did not touch `project.godot`, so the owner-local `project.godot`
  edit and all untracked owner assets/`.import`/`.uid` files were preserved untouched.
- The implementation commit stages ONLY M29 source/tests/scene. The owner-local
  `project.godot` modification and untracked owner assets are intentionally NOT included.
  Root `TASKS.md` was not modified.

## 1. What shipped

New:
- `scripts/gameplay/runtime/gameplay_speed_authority.gd` — explicit 1x/2x authority (no `Engine.time_scale`).
- `scripts/gameplay/runtime/production_runtime_controller.gd` — automatic M26 cadence driver + agent-travel clock + pause/focus reasons.
- `scripts/gameplay/runtime/slot_origin_provider.gd` — canonical M27-proven five-lane below-board slot origins.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — wires the full real M23–M27/M19/M20 stack around the M28 screen (shared by scene + smoke).
- `scripts/ui/production_input_controller.gd` — supply-front transaction gate.
- `scripts/debug/m29_hazard_bot_playtest.gd` + `scenes/debug/m29_hazard_bot_playtest.tscn` — the manual playtest scene.
- `tests/m29_input_gate_evidence.gd`, `tests/m29_speed_authority_evidence.gd`, `tests/m29_hazard_bot_runtime_smoke.gd`.

Modified (presentation seams only, no gameplay authority moved):
- `scripts/ui/batch_supply_panel.gd` — opt-in front-row input (`enable_front_input()`), `front_batch_activated` signal, gesture/dedup/cancel, exhausted-front disable.
- `scripts/ui/five_slot_strip.gd`, `scripts/ui/batch_slot_view.gd` — read-only laid-out slot anchor accessors.
- `scripts/ui/gameplay_screen.gd` — `get_pause_button()` / `get_speed_button()` M29 wiring seams.

## 2. Authority chain (unchanged M23–M27 boundaries)

`front supply UI (BatchSupplyPanel row 0) -> front_batch_activated -> ProductionInputController
-> FiveSlotBatchEngine.select_front_batch(real M23, column) -> M26 notify_placed
-> ProductionRuntimeController cadence -> AutoDispatchScheduler.step() -> M25 claim/reservation
-> ProductionRoutingSystem -> ScrubbotDispatcher.dispatch_preclaimed -> ScrubbotAgent
-> CompleteClearingLoop authenticated clear -> M25.finalize_clear`.

UI never calls M23 commit directly, never chooses a slot, never calls legacy slot
activation, never selects targets/routes. The five M24 slots stay read-only (not Buttons,
no activation signal). Preview rows 2/3 are never selectable.

## 3. Exact Godot manual run instructions

1. Open the project in Godot **4.7.2** (graphical, not `--headless`):
   - Project path: `C:\Users\sekip\Desktop\ScrubBots` (repo root — the folder containing `project.godot`).
   - Godot → Import/Open this project.
2. In the FileSystem dock open `res://scenes/debug/m29_hazard_bot_playtest.tscn`.
3. Run the scene: press **F6** (Run Current Scene). Do NOT press F5 — the project main
   scene is unchanged and is not this playtest.
4. What you see: the production M28 gameplay screen — the 20×20 Hazard Bot artwork board
   with its rail, the five read-only batch slots, three supply columns (front + two
   preview rows), boosters, and the bottom row `Pause | Ad | 1x`.
5. What to click (desktop mouse; touch works the same on a touchscreen):
   - Click a **front (top) supply tile** of any column. Only the front row is clickable;
     the two preview rows and the five slots are not.
   - The front batch is placed automatically into the rightmost EMPTY slot (you never pick
     a slot). A Scrubbot then travels the rail from below the board to a matching cell,
     clears it to transparent, and disappears. Robots keep dispatching automatically.
   - Bottom-right control toggles **1x ⇄ 2x**; at 2x the button reads `2x` (cyan) and both
     the dispatch cadence and Scrubbot travel run twice as fast.
   - Bottom-left **Pause** freezes cadence and in-flight robots; press again to resume
     (the selected 1x/2x speed is preserved).
6. What to observe for auto-2x: keep transferring fronts. To fully drain the supply and
   trigger automatic 2x you must follow a solvable order (the level is M27-proven solvable
   with seed 1 / 3 columns / preview 3). When the **final** M23 batch is transferred into a
   slot, gameplay switches to `2x` automatically. You may toggle back to 1x afterward.
7. **M30 limitation:** there is intentionally NO win/lose/result screen yet. When the board
   finishes clearing it simply becomes empty (BG01) — the result flow is M30 scope.

Headless equivalent of the same production path (deterministic, replays the M27-solved
order to a fully-cleared board):
```
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
```

## 4. Task mapping (SB-M29-001..009 + owner speed rule)

| Task | Requirement | Code | Evidence |
|---|---|---|---|
| SB-M29-001 | Only supply front (row 0) selectable; preview rows + five slots non-interactive; column identity only | `batch_supply_panel.gd` (`enable_front_input`, `front_batch_activated`, front-only STOP surface); `five_slot_strip.gd`/`batch_slot_view.gd` read-only | `m29_input_gate_evidence.gd` §B (front STOP, preview IGNORE + unwired, slots not Buttons / no signal) |
| SB-M29-002 | Controller validates authoritative M23 3/4/5; real M24 transactional placement vs real M23; snapshots refresh only after result; full-slot rejection consumes nothing | `production_input_controller.gd` | §B (3/4/5 bind), §C (exact transaction, rejection zero-consume/zero-mutate) |
| SB-M29-003 | Mouse + touch without synthesized double-fire; serialize reentrant activation | `batch_supply_panel.gd` (touch/mouse dedup window, single pending gesture); `production_input_controller.gd` (`_activating` guard) + M24 `_busy` | §D (one touch+synth mouse = one placement; desktop mouse alone), §F (reentrant press-storm = one placement) |
| SB-M29-004 | Touch cancel consumes nothing | `batch_supply_panel.gd` `cancel_all_gestures` + press/release gesture | §E (touch down then cancel => zero activation, no stuck pending) |
| SB-M29-005 | Focus loss cancels pending gesture; stale release after return consumes nothing | `production_runtime_controller.gd` `notify_focus_lost` → input `cancel_all_gestures` | §E (focus loss cancels; stale release => zero activation) |
| SB-M29-006 | Rapid taps cannot duplicate/skip fronts | panel serialized gesture | §F (three rapid taps = three placements; press-storm = one) |
| SB-M29-007 | Multi-touch cannot create partial/duplicate placements | panel single pending gesture rejects secondary touch | §G (only first column consumed; no partial mutation) |
| SB-M29-008 | Separate user vs system/background pause; while paused no input/cadence/travel | `production_runtime_controller.gd` (`_user_paused` vs `_system_suspended`, `tick` gate) | §H (distinct reasons; paused activation blocked; paused tick no-op) |
| SB-M29-009 | Resume preserves speed, no stale replay; background/foreground deterministic + regressed | runtime focus regain (system-only clear, user pause survives, speed preserved) | §H (focus regain ≠ user unpause; resume preserves 2x) + `m29_hazard_bot_runtime_smoke.gd` |
| Owner speed rule §2 | Manual bottom-right 1x⇄2x toggle, visible state | `gameplay_speed_authority.gd` toggle; `production_gameplay_host.gd` `_on_speed_pressed` → `screen.set_speed_2x` | `m29_speed_authority_evidence.gd` J (toggle, half interval) |
| Owner speed rule §3 | Auto-2x after successful FINAL transfer via real `is_exhausted()`; not on rejection / visible-empty / five-full; idempotent; reset→1x | `production_input_controller.gd` (post-placement `is_exhausted`), `gameplay_speed_authority.gd` | K (auto-2x on final; NOT on rejection/five-full/hidden-remains; idempotent; toggle back; reset→1x) + runtime smoke (real board) |
| Owner speed rule §4 | 2x accelerates cadence + current/future travel only; no truth change; no global time scale | `production_runtime_controller.gd` (`delta*factor` travel, halved interval; no `Engine.time_scale`) | J (agent travels ~2× per tick, in-flight updates immediately) + L (1x vs 2x identical clears/board) |
| WP02/WP04 | Automatic cadence (one step/event, no `run_until_idle`); real Hazard Bot scene on real stack | `production_runtime_controller.gd`, `production_gameplay_host.gd`, `m29_hazard_bot_playtest.tscn` | `m29_hazard_bot_runtime_smoke.gd` (real M23→M20, 400 clears, auto-2x, 1x/2x equivalence) |

## 5. Regression evidence (Godot 4.7.2, headless unless noted)

```
godot --headless --path . -s res://tests/run_tests.gd                          -> exit 0 (full root suite PASS)
godot --headless --path . -s res://tests/m29_input_gate_evidence.gd            -> PASS
godot --headless --path . -s res://tests/m29_speed_authority_evidence.gd       -> PASS
godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd       -> PASS (board fully cleared: 400 clears; auto-2x; 1x=167 vs 2x=112 ticks)
godot --headless --path . -s res://tests/m28_gameplay_layout_smoke.gd          -> PASS
godot --headless --path . -s res://tests/m27_hazard_bot_solve.gd               -> PASS
godot --headless --path . -s res://tests/m27_scale_59.gd                       -> PASS
godot --headless --path . -s res://tests/m27_generation_retry.gd               -> PASS
godot --headless --path . -s res://tests/m26_hazard_bot_integration.gd         -> PASS
godot --headless --path . -s res://tests/m26_scale_59_sanity.gd                -> PASS
godot --headless --path . -s res://tests/m25_v03_exact_work_binding_evidence.gd-> PASS
godot --headless --path . -s res://tests/m24_v02_transaction_hardening_evidence.gd -> PASS
godot --headless --path . -s res://tests/m23_v03_transaction_identity_evidence.gd  -> PASS
godot --headless --path . -s res://tests/m22_railroad_responsive_smoke.gd      -> PASS
godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd         -> PASS
godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd            -> PASS
git diff --check                                                               -> clean
```
M19 dispatcher and M18 agent regressions are covered inside the full root suite (`run_tests.gd`).

## 6. Scope / prohibitions honored

- Root `TASKS.md` unchanged by Claude.
- No M30 win/lose/result implemented; no M31/M32.
- Five slots remain read-only destinations; preview rows remain non-selectable.
- Gameplay speed is an explicit authority + per-agent travel scaling; NO global
  `Engine.time_scale`.
- Zero AI image-generation credits.
- Implementation commit precedes this separate log commit.

## 7. Notes for the auditor

- The greedy "fill any slot" order can deadlock the Hazard Bot (a genuine gameplay
  order-dependence, not an engine fault); the runtime smoke therefore replays the
  M27-solved front order to prove the real production path clears the whole board and
  fires auto-2x. `SlotOriginProvider` uses the exact five-lane geometry the M27
  ProofKernel certified, so live routing reproduces the proven reachability.
- Auto-2x reads authoritative `BatchSupplyEngine.is_exhausted()` after a successful M24
  placement (hidden future batches counted), never UI visuals.
