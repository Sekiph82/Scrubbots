# Fix m50_color_symbols s10 race so Android validation_only CI goes green

> Feature: SB-M50-BOARD-001 - run Android `validation_only` CI, record the run, close the item. Run 39782553609 on eebca405 FAILED with `M50S verdict=FAIL (exact 10/10 summary missing)`; find the real cause and fix it minimally.

## Context
- Downloaded artifact `ScrubBots-Family-First10-Android-Debug-validation-logs`, `validate_logs/m50_color_symbols.log`. The suite ran all 10 cases and printed `M50 color symbols evidence: FAIL (10/10 cases, 1 fail)`. The workflow gate (`.github/workflows/android-family-first10.yml` lines 163-167, `grep -qxF 'M50 color symbols evidence: PASS (10/10 cases, 0 fail)'`) is correct and invoked correctly (suite is in the list at line 109). Fault is NOT the gate and NOT product code.
- The one failing case is `s10_booster_target_chips` (`tests/m50_color_symbols.gd` `_s10`, ~lines 313-346). Log: `tornado: 5 chips`, `selector: 0 chips`, then the FAIL line.
- Cause (test race): `_s10` calls `host.request_booster("selector")` then `await _frames(4)` and immediately reads the popup's `Targets` flow. For an owned Selector at a still moment, `ProductionGameplayHost.request_booster` -> `AcquisitionFlow.open_booster` -> `_refresh_booster` -> `host.booster_legality_offframe("selector")` starts an off-frame proof on a `WorkerThreadPool` task and returns reason `checking` with no targets (`scripts/gameplay/runtime/production_gameplay_host.gd` ~998-1070, `scripts/ui/popup/acquisition_flow.gd` ~330, `_build_targets` ~436). Chips appear only after the worker finishes, host `_process` joins it and emits `booster_proof_settled(id)`, whereupon `_on_booster_proof_settled` rebuilds the chips. On the slower CI runner 4 frames is not enough; locally it is fast. Tornado needs no proof, so it passes. The product behaviour (symbols on Selector chips) is correct; the test samples too early.
- Previous green runs (e.g. 38790518157) predate or raced differently; this is a timing flake exposed on the current runner, not a regression in the symbol code.

## Requirements
1. In `tests/m50_color_symbols.gd` `_s10`, after `host.request_booster(id)`, wait (bounded) until the booster proof has settled and the `Targets` flow has children before asserting. Reuse existing signals/state: `host.is_booster_proof_running()` / `host.booster_proof_settled`. Poll per frame with `await _frames(1)` up to a wall-clock cap of about 10 s (use `Time.get_ticks_msec()`), then fall through to the existing assertions so a genuine failure still fails.
2. Keep every existing `_s10` assertion unchanged: chips > 0 for both boosters, `Symbol` child present, `sym.get_shape() == ColorSymbols.shape_for_color(col)` and non-empty, `mouse_filter == MOUSE_FILTER_IGNORE`, Selector: `Count` label above the symbol, `not sym.emblem`, empty button text; Tornado: `sym.emblem`. Do not lower thresholds, skip a booster, or remove the `chips > 0` check.
3. Do not touch the workflow gate, the 10-case count, `EXPECTED_CASES`, or any product script.
4. No doc change needed beyond one line in the job evidence; AGENTS.md does not document this test's internals.

## Acceptance criteria
1. `"$GODOT" --headless --path <worktree> -s res://tests/m50_color_symbols.gd` (after `--import`) prints, as an exact line, `M50 color symbols evidence: PASS (10/10 cases, 0 fail)` and the s10 output shows `tornado: 5 chips` and `selector: N chips` with N > 0. Verify: `... | grep -cxF 'M50 color symbols evidence: PASS (10/10 cases, 0 fail)'` prints 1.
2. `git diff main -- tests/m50_color_symbols.gd` shows only the added wait in `_s10`; the `_ok(ok and chips > 0, ...)` line and per-chip assertions are byte-identical.
3. `git diff main --stat` lists only `tests/m50_color_symbols.gd` (plus job evidence files).
4. Companion suites still pass: `tests/m50_board_symbols.gd` and `tests/m50_accessibility_audit.gd` print their PASS summaries (`M50 accessibility audit evidence: PASS (4/4 cases, 0 fail)`).
5. After merge to main, the orchestrator reruns Android `validation_only` CI; the `M50S verdict=PASS (10/10)` line appears in the summary and the run concludes success.
6. Then `TASKS.md` SB-M50-BOARD-001 (grep the ID; never read the file whole) is closed/archived per the repo's tracker convention, citing the green run id and the fixing commit SHA.

## Out of scope
- Changing the workflow gate grep, adding retries to the workflow, or marking the suite non-blocking.
- Changing booster proof logic, the 5 s proof cap, or chip construction.
- Any other M50 test or board-symbol shader work.

## Assumptions
- A 10 s cap is ample: the proof itself is capped at 5 s (`PROOF_TOTAL_MS`) and L1 is tiny. If the proof ever times out, chips stay empty and the test still fails honestly.
- Local run did not reproduce the failure in this analysis (worktree import was incomplete when inspected); the diagnosis rests on the CI log (selector 0 chips, tornado 5) plus the off-frame proof code path. The builder should confirm s10 passes locally and, if possible, that `request_booster("selector")` returns reason `target_selection` with `checking` visible right after 4 frames.
