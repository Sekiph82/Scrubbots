# M43-C005-C005 — CLAUDE LOG V01 — Reusable Production Reward-Reveal Sequencing

Date: 2026-10-04
Implementer: Claude (Opus 5.5)
Canonical task: SB-M43-063
Status: **AWAITING_AUDIT** (implementation evidence E1/E2 only; no audit verdict claimed)

## Inputs read

- Prompt: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C005/CHATGPT_PROMPT_V01.md
- Prior audit: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M43-C005-C004/CHATGPT_AUDIT_V01.md (C004 PASS, SB-M43-076 CLOSED, next = SB-M43-063 inside M43-C005)
- `CLAUDE.md`, root `TASKS.md` (read only, **not edited**), `coordination/AUDIT_POLICY.md`
- `scripts/ui/results_screen.gd`, `scripts/ui/popup/base_popup.gd`, `scripts/ui/popup/modal_stack.gd`, `scripts/app/main.gd`
- M43 Results tests (`m43_c001a/b`, `m43_c001r_c001`) and the C005 preview harness/test (`tests/tools/ceremony_preview/`, `m43_c005_c001_ceremony_visual_masters.gd`)

Learnings applied: "file existence is not evidence" (direct runtime assertions on the real Results), direct observability + sensitivity (every new property assertion has a sensitivity check or a source mutation that makes it fail), headless timing is not visual evidence (timing equivalence is proven structurally on the step plan, not by wall-clock), preserve explicit `preload()` style.

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`; local was 3 behind `origin/main` (8be41ef → e18149b). `git merge --ff-only origin/main` — clean.
- Owner/local work preserved and **not committed**: `M project.godot` (owner addons/autoloads), untracked `.mcp.json`, `addons/`, `*.import`, `*.uid`, level source PNGs, etc. All test runs below used the working tree as-is (owner autoloads loaded).

## 1. Implementation

### 1.1 Sequencer — `scripts/ui/components/reveal_sequencer.gd` (new)

`extends RefCounted`; constructed with its host node: `RevealSequencer.new(host)`. Owns no nodes; its tween is `host.create_tween()`, so freeing the host kills the work. No `preload`/`load`, no economy/progression/save/navigation identifier (statically checked, case s08).

| API | Behavior |
|---|---|
| `static fade(target, duration, delay=0)` | builds the common `modulate:a 0 → 1` step |
| step dict | `{target, property, from, to, duration, delay}`; strictly ordered: wait `delay`, tween `from → to` |
| `play(key, steps, reduced=false) -> bool` | one-shot per key (already played/cancelled key or empty key → `false`, nothing changes); new key cancels any current run first; applies every `from`; Reduced Effects / empty sequence / host outside the tree → lands the exact final state immediately; freed targets are dropped |
| `finish()` | fast-forward: kill tween, apply every `to`, complete. No-op when nothing active |
| `cancel()` | kill tween, drop plan, **no** completion (route change / hidden screen / freed popup) |
| `completed(key)` | at most once per key (natural end, `finish`, Reduced, empty) |
| `step_started(key, index)` | each beat of a full run (presentation hook for later C005F decoration; not wired to anything) |
| `is_running()`, `is_active()`, `has_played(key)`, `current_key()`, `current_step()`, `get_steps()` | read-only inspection |

Stale-callback safety: every tween callback is bound to a generation counter that `cancel`/`finish`/new `play` bumps, and the old tween is killed.

Known ceiling (marked `ponytail:` in source): the one-shot ledger keeps one short String per played key (Results adds one per `show_model`); negligible, trim if it ever matters.

### 1.2 Results — `scripts/ui/results_screen.gd` (first shipping consumer)

- `_reveal: Tween` → `_reveal: RevealSequencer` (created in `_init`, host = the Results screen, i.e. same tween binding/process mode as before).
- `_start_reveal(reduced)`: WON builds one `fade(row, REVEAL_STEP_S)` step per committed row (rows already built from `receipt.reveal_queue` + follow-ups, unchanged), then, if momentum is visible, `fade(_momentum, REVEAL_STEP_S, momentum.reveal_delay_s)`; plays key `results_<serial>` (each `show_model` rebuilds row nodes = a genuinely new presentation instance, so the previously approved "re-show restarts the reveal" behavior is unchanged). LOST/ERROR pass an empty plan → nothing animates.
- `finish_reveal()` → `_reveal.finish()` (same public API, presentation only). `is_revealing()` → `_reveal.is_running()`. New `get_reveal_sequencer()` for tests/future callers.
- `_clear_lines()` (hide via `NOTIFICATION_VISIBILITY_CHANGED`, and each `show_model`) → `_reveal.cancel()` and resets the persistent momentum node to alpha 1 so a cancelled run can never leave it hidden.
- Unchanged: receipt/row derivation, row order, Continue latch, Home, Retry, `set_ceremony_barrier()` semantics, `_sync_primary`, LOST/ERROR layouts. Continue was not turned into a skip action.

Visual equivalence: the old chain was `0.16 s fade × rows → interval(reveal_delay_s) → 0.16 s fade momentum`; the new plan produces the identical chain (plus zero-duration step callbacks). Asserted directly on the live plan in r01, and a 2× timing mutation is caught (M7). Not a material visual change → no new owner visual gate requested.

### 1.3 Future-ceremony seam

`tests/m43_c005_c005_reward_reveal_sequencer.gd` s01–s07 drive the same component with dummy `ColorRect` controls (3- and 5-step plans, mixed property types incl. `position:x` and `scale`, delays). No pack/card/robot asset is bound (SB-M43-064/065 untouched).

## 2. Architecture / test matrix

| Requirement (prompt §2/§4/§5) | Where | Proof |
|---|---|---|
| deterministic ordered steps | sequencer | s01 (`step_started` order `[k,0..n-1]`; per-frame: later step never > 0 before earlier is 1.0) |
| short per-step duration/delay | sequencer | s01 (5-step with delays), r01 (0.16 / 0.2 s plan) |
| start once per key | `_played` ledger | s04, s05; mutation M1 |
| fast-forward to exact final | `finish()` | s02 from step 0 / 2 / 4; r02; mutation M2, M5 |
| cancel / cleanup | `cancel()`, host-bound tween | s04, s07 (host freed), r03 (Results hidden + freed); mutation M3, M6 |
| Reduced Effects = same final info | `play(..., true)` | s03 (mixed props), r04 (real Results info dict); mutation M4 |
| completion at most once | `_done` + generation | s01, s02, s04, s05, r02 (`counts` per key == 1) |
| empty sequence safe | `play` | s06 (empty, freed target, host out of tree, idle finish/cancel) |
| restart / new key, no leakage | generation + kill | s04 (superseded c2 never completes), s07 (60 cycles, no tween/node/connection growth) |
| zero authority | sequencer source + runtime | s08 (static scan + injected-call sensitivity, RefCounted, only presentation signals); r02 (economy snapshot, applied-grant count, save bytes, receipt, route, transition id unchanged; real grant detected as sensitivity) |
| Results text/order stable on re-show | Results | r01, r02 (6× `show_model` + finish + cancel + direct play) |
| hide/free kills work | Results | r03 |

## 3. Validation (all Godot 4.7.2.stable, `--headless --path .`)

`godot --headless --path . --import` run first (rc=0).

| # | Command | Expected / failure condition | Actual |
|---|---|---|---|
| V1 | `-s res://tests/m43_c005_c005_reward_reveal_sequencer.gd` | 12/12 cases, 0 fail; any FAIL or missing case = failure | **PASS 12/12, 0 fail**; re-run 3× identical |
| V2 | mutation sensitivity (temporary source edits, restored, `diff -q` confirmed) | each mutation must make V1 fail | M1 no one-shot ledger → 2 FAIL; M2 finish not final → 9; M3 cancel no kill → 6; M4 Reduced ignored → 3; M5 finish not idempotent → 6; M6 Results hide no cancel → 1; M7 Results timing ×2 → 1. **All detected**; sources restored byte-identical |
| V3 | `-s res://tests/m43_c001a_results_foundation.gd` | PASS | **PASS 11/11** |
| V4 | `-s res://tests/m43_c001b_won_results_visual.gd` | PASS (incl. existing reveal/Reduced/hide cases) | **PASS 11/11** |
| V5 | `-s res://tests/m43_c001r_c001_results_momentum.gd` | PASS | **PASS 40/40** |
| V6 | `-s res://tests/m43_c002_c001_popup_modal_pause.gd` | PASS | **PASS 23/23** |
| V7 | `-s res://tests/m43_c003_c001_acquisition.gd` | PASS | **PASS 34/34** |
| V8 | `-s res://tests/m43_c004_c001_fail_need_a_hand.gd` | PASS | **PASS 40/40** |
| V9 | `-s res://tests/m43_c005_c001_ceremony_visual_masters.gd` | PASS | **PASS 17/17** |
| V10 | M39: `m39a_economy_core`, `m39d_daily_collection`, `m39e_full_matrix`, `m39_v02_integration`, `m39_v02_atomicity`, `m39_v03_integration`, `m39_v04_integration` | PASS each | **all PASS**, rc=0 |
| V11 | Root `-s res://tests/run_tests.gd` | ALL PASS | **Total checks 5323, RESULT: ALL PASS** (rc=0) |
| V12 | `git diff --check` | no output | **clean** |

Warnings/errors: no `SCRIPT ERROR` in any run. The exit-time "ObjectDB instances leaked / resources still in use" lines are pre-existing: C001A/B/R were re-run with `HEAD`'s `results_screen.gd` swapped in temporarily (229/19, 191/19, 685/19) and the new code gives the same counts on re-run (685/19 for C001R twice); `--verbose` shows the leaked objects are economy-service RefCounted cycles + audio playback, none from `reveal_sequencer.gd`. Small run-to-run variance (±6 instances / ±2 resources) follows audio playback timing. The root suite never instantiates Results.

False-positive risks noticed and handled:
- First-frame headless delta can run a whole short plan in one frame, so per-frame sampling cannot prove step order (first draft failed exactly this way) → order is proven via `step_started`, sampling kept only for the "never ahead" invariant.
- Real `main.tscn` may own unrelated tweens → Results tween counts are relative to a baseline.
- Comparators (economy snapshot, Reduced info dict, forbidden-identifier scan) each have a positive sensitivity check.

## 4. Files

| File | Change |
|---|---|
| `scripts/ui/components/reveal_sequencer.gd` | new reusable presentation sequencer |
| `scripts/ui/results_screen.gd` | WON row/momentum reveal now uses the sequencer; `finish_reveal`/`is_revealing` kept; `get_reveal_sequencer()` added |
| `tests/m43_c005_c005_reward_reveal_sequencer.gd` | new focused suite (12 cases) |
| `coordination/sessions/M43-C005-C005/CLAUDE_LOG_V01.md` | this log |

Not touched: `data/`, economy/progression/collection/save code, BasePopup/ModalStack, `main.gd`, ceremony preview harness, assets, root `TASKS.md`. No SB-M43-064+ ceremony content, no GameFeelFlow / Saltmire Spark integration.

## 5. Blockers / unverified

- None blocking.
- No rendered before/after capture was produced: the refactor is structurally equivalent (same tween chain values asserted on the live plan), so per the prompt no owner visual gate is requested. If the auditor wants frame captures, `tests/tools/results_snapshot.gd` still works unchanged (it calls `finish_reveal()`).

## 6. Commit / push

See handoff response for the final SHA (commit made after this log was written).

`AWAITING_GPT_M43_C005_C005_REWARD_REVEAL_SEQUENCER_AUDIT`
