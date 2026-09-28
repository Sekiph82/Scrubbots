# M43-C002-C001 — CLAUDE LOG V01

Date: 2026-09-28
Prompt: `task_prompts/SB-M43-C002-C001_POPUP_MODAL_PAUSE_FOUNDATION.md`
Criteria: `audit_criteria/SB-M43-C002-C001_POPUP_MODAL_PAUSE_FOUNDATION.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`, remote `origin`.
- Local was behind by 2 commits. I fast-forwarded to `331ebda` with `git pull --ff-only`.
- The pre-existing local `project.godot` modification is owner/editor work. I preserved it and excluded it from the commit.
- Untracked owner media and `.import` caches were left untouched.
- Root `TASKS.md` was read and not edited.

## Implemented

See `POPUP_MODAL_MATRIX_V01.md` for the full requirement → code → test map.

**New files:**
- `scripts/ui/popup/base_popup.gd` — the one reusable `BasePopup`.
  - Scrim, safe-area root, and a promoted NinePatch frame at a uniform scale.
  - Header pill with an optional close button, content region, busy row and footer.
  - Exactly-once lifecycle.
  - Top-only, latched action gating.
  - Pending token with a timeout.
- `scripts/ui/popup/modal_stack.gd` — the one `ModalStack` (`CanvasLayer` at layer 64).
  - LIFO order with a single top input owner.
  - Consumes Back/Escape.
  - Emits `modal_changed`; supports `clear`.
- `scripts/ui/popup/popups.gd` — pure builders:
  - Pause and Restart/Home confirms (built from a consequence dict);
  - generic confirm;
  - committed-only reward;
  - insufficient SB (detached pending context);
  - network error for rewarded_ad, store, cloud and live_event;
  - busy;
  - success/failure feedback.

**Modified files:**
- `scripts/gameplay/runtime/production_gameplay_host.gd`:
  - The V02 Pause control now opens the canonical Pause popup instead of toggling pause directly.
  - Modal hold: while any popup is open, supply input is gated and the runtime is user-paused. Closing releases only a pause the hold created, so a system suspension survives.
  - `attempt_consequence()` is a read-only query of `WinStreakService.gameplay_started()`, `HeartService.hearts()` and `WinStreakService.streak()`.
  - Restart goes through the existing M30 `retry()`, whose `_on_retry_restored` applies the M39 restart-after-action law. That code is unchanged.
  - `exit_to_home()` applies the owner exit law, exactly once:
    - pre-action → `streak.on_pre_action_exit()`;
    - post-action → `hearts.consume()` + `streak.on_restart()`;
    - both paths call `capacity.begin_new_attempt()`, and the post-action path also saves.
  - Booster, 2x and Pause presses are refused while a modal is open.
  - The host creates its own private stack only when no app root injected one.
- `scripts/ui/production_input_controller.gd` — `set_modal_blocked()` rejects activations with `"modal"` (defence in depth behind the scrim).
- `scripts/app/main.gd`:
  - owns the one stack and injects it into each gameplay host;
  - bridges to Home through the existing `set_modal_active("modal_stack")` seam;
  - `handle_back()` asks the stack first;
  - Pause → Home confirmed → `nav.go(HOME)` (an existing GAMEPLAY→HOME edge);
  - the stack is cleared when a host is released.
- `scripts/ui/ui_text.gd` — 32 new copy keys. All values are live arguments.

**Not changed:**
- no prices, Heart, streak, booster or 2x values or truth;
- no Results visuals;
- no Gameplay V02 shell, glyph or 2x overlay;
- no routing or gameplay logic;
- no popup art generated or modified (the focused test checks `git diff` on the frames folder);
- `TASKS.md`.

## Test migrations (deliberate)

Two M28 assertions encoded the old behaviour, where pressing Pause twice toggled pause and resume. Under the new canonical rule, the first press opens the Pause popup and Resume resumes. A second Pause press behind the popup is now blocked, and that is asserted.

- `tests/m28_c002_c001_gameplay_v02.gd` `_pause_top_right`
- `tests/m28_c002_c002_static_shell.gd` `_pause_2x_boxes`

## Tests

**Focused:** `tests/m43_c002_c001_popup_modal_pause.gd` — **PASS, 23/23 cases, 0 fail.** It covers all 20 required items plus the responsive matrix, the Home bridge and a promoted-frames-unchanged check.

Test characteristics:
- Uses real routed pointer input (`SubViewport.push_input`). Positive controls prove that routing reaches the top popup.
- The Restart post-action case asserts that the previewed consequence equals what was applied (5 → 4 Hearts, streak 3 → 0). It also checks the 0-Hearts edge, where no Heart loss is claimed.
- Accumulation over 10 full cycles:
  - nodes 314 → 314;
  - stack connections, Pause connections and timers stable;
  - a released host leaves no stack connection.
- Responsive matrix: 1080×2160, 1170×2532, 1290×2796, 1080×1920 and 1536×2048, with synthetic insets of 96 px top and 64 px bottom. The Pause popup and the loss confirm fit inside the safe area without clipping, and every touch target is at least 88 px.

**Full regression** (Godot 4.7.2 headless, 12-way parallel, 111 suites):

- Root `tests/run_tests.gd`: **Total checks 5323, RESULT: ALL PASS.**
- M28: `c002_c002_r01_visual` 10/10, `c002_c002_static_shell` 16/16, `c002_c001_gameplay_v02` 14/14, layout smoke — all PASS.
- M29 input gate and all other M29 suites: PASS.
- M30 completion, transaction-safe retry and manual smoke: PASS.
- M39 A–E, V02–V04 and the tornado in-flight suite: PASS. M40 save, V02, V03 and V04: PASS.
- M42 home, composition, V04–V07, navigation and opening: PASS.
- M43-C001A 11/11 and M43-C001B 11/11: PASS.
- M52 owner supply plans, R01 and R02: PASS.
- M55 long session, core chaos, economy release, Heart 900 and timed-2x: PASS.

**Non-zero exits:**
- `m21_v08_corridor_validation` (C/043, C/047) and `m21_v09_direct_evidence_reconciliation` (B). These are the historical pre-Railroad-V1 baseline, identical to the previous cycles. No routing was touched.
- `m43_c002_c001_popup_modal_pause` (1 fail in the parallel run). That run picked up a mid-edit version of the new test, and a bad lookup in the new feedback assertion found the frame `Body` VBox instead of the body label. I fixed the test lookup and re-ran it: 23/23 PASS.

**`SCRIPT ERROR`:** matches are only the assertion names in the m20 lifecycle smokes (baseline), plus the M43 test issue above, now fixed.

**Exit noise:**
- "resources still in use" is the same class as baseline.
- The focused suite reports 222 leaked ObjectDB instances at exit. The `--verbose` breakdown is RefCounted 192, GDScript 17, RandomNumberGenerator 12, GDScriptNativeClass 1, with **no Node/Control/Timer**. That is 12 per-boot AppState economy graphs from 12 app boots, the same pre-existing pattern as the M28 suites.

**Other:** `git diff --check` is clean.

## Evidence

`evidence/` holds 18 PNGs rendered by `tests/tools/popup_pause_snapshot.gd`. The file list is in matrix §5. Each shot verified `text_fits()` for every stacked popup and a non-terminal host.

## Known limits / follow-ups (not in scope)

1. **Home's legacy `HomePopup`** (M42 Gift/Cards/Daily) keeps its accepted one-at-a-time mechanism. It is bridged, not migrated: ModalStack state feeds Home through `set_modal_active`, and back consults the stack before `close_top_popup()`. Migrating it onto `BasePopup` is a separate visual change that needs owner review.
2. **`SpeedAcquisitionPopup`** (the M52 functional 2x UI) is not yet on the stack. M43-C003 replaces it with the canonical 2x Acquire popup. While a stack modal is open, the 2x button cannot open it.
3. **Back in gameplay with no popup open** keeps the accepted M42 behaviour: before the first action it goes Home; after it, nothing happens. The only post-action exit is Pause → Home with the loss confirmation. The owner may later want Back to open Pause.
4. **Stacked popups** keep their own scrims, so they darken progressively (owner item P3).

## Reproduce

```bash
godot --headless --path . -s res://tests/m43_c002_c001_popup_modal_pause.gd
```

```bash
godot --path . -s res://tests/tools/popup_pause_snapshot.gd -- coordination/sessions/M43-C002-C001/evidence
```

`AWAITING_CHATGPT_AUDIT / M43-C002-C001 POPUP MODAL PAUSE FOUNDATION`
