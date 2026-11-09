# Review round 1: 137-plugin-regressions (SB-M54-037..038)

Reviewer: single reviewer (code, rules, tests). Commits 968a5391, a7a59e27, 512c2ef3.

## Runs (headless, throw-away saves, after `--import`)
- m54_regression_pack_037_038: PASS 6/6 (exit 0). Exactly 11 diag lines, all the labelled `SCRIPT ERROR: Invalid call. Nonexistent function 'explode' in base 'Nil'.`
- m43_c005f_phase2_results_pack_feel: PASS 22/22
- m43_c005f_phase2_r01_earned_pack_runtime: PASS 22/22
- m43_c005f_phase1_foundation: PASS 23/23
- m43_c005f_phase3_meta_rewards_acquisition: PASS 15/15
- m60_release_gates: PASS 6/6, diag 0. (The "FAIL SB-M60-005/006" lines in the log are gate-state labels, not failures.)
- The phase1/2/3 diag lines are also only the `explode` injection. Those suites are local-only.
- m54_visual_regression_038 under `--headless`: prints `NOT_RUN`, exit 1. Honest.
- `git diff --check`: clean.
- Not run: the windowed 038 pass, so its baselines are not independently confirmed.

Cleanup: project.godot restored, tracked files reset with `git checkout -- .`, generated untracked `.import` / `.uid` / `.translation` files deleted. Worktree `git status --porcelain` is empty.

## Focus findings

1. Product fix, `scripts/ui/results_screen.gd`: correct.
   - The deferred burst is now gated by the row's own rect settling (up to 8 frames).
   - After the await, `_after_layout` bails out if `self` or `w` is freed or out of the tree. `w` is the row, so a freed bound `row` is never passed to `_row_feel`.
   - `_row_feel` re-checks `_feel`, `_victory`, `id == _feel_id()` (so a stale result is dropped), the row's validity and `row.get_parent() == _lines`.
   - It is still a one-shot. The adapter key from `_row_key` is consumed only inside `_row_feel`. A re-show within the 8 frames produces a second deferred call that the one-shot key refuses.
   - Reduced mode consumes the keys statically, and `_feel_event` is a no-op for a Reduced model.
   - It cannot leak. There is no stored state, and the coroutine ends by itself.
   - When the node is outside the tree, it runs synchronously, as before.
   - The watched rect uses the existing `SETTLE_FRAMES` bound. The change is small.
2. Test-only path exclusions (phase1 a01, phase3 b01, e2e s01): narrow.
   - Each strips only the two exact strings `res://addons/game_feel_flow/LICENSE` and `res://addons/saltmire_spark/LICENSE.txt` before the scan.
   - The plugin words and the `addons/...` patterns are still scanned. Any other mention of a plugin in a script is still caught.
   - The Credits screen reads those files by exactly those paths (SB-M59), so this is not a weakening.
3. `tests/m54_regression_pack_037_038.gd`: sound.
   - One-shot: it asserts that no key is requested twice in any arm, that each `ONE_SHOT` key appears exactly once in FULL, and that 0 new requests follow duplicate WON/LOST signals, route re-show, `show_model` x2, resize, focus and refresh.
   - Duplicate provider callbacks are asserted as `[true,false,false,+1]`.
   - Fail-open: ABSENT, DISABLED (autoloads detached, no test seam) and THROWING all complete every seam. THROWING is checked as one throw per planned dispatch.
   - Identical game state: the economy and progression snapshot is compared with FULL for all 5 arms. Wall-clock fields are excluded narrowly, and the Spark and GFF bound checks are also asserted.
   - Request logs: ABSENT, DISABLED and THROWING equal FULL's logs. REDUCED is a non-empty subset with 0 plugin calls.
   - Allow-list: narrow. The workflow's `INJECTED` is the exact full-line `explode` message, and it is applied only to phase4 and this one suite by exact name. `tools/run_suites.py` mirrors it with an exact-line match and a tested selftest. Any other SCRIPT ERROR still fails.
   - CI wiring: append-only on the validate list. The exact whole-line guard `M54 regression pack 037-038: PASS (6/6 cases, 0 fail)` is added with fail-closed "summary missing" handling, and it matches the produced line.
4. `tests/m54_visual_regression_038.gd`: sane.
   - Baselines are coarse and committed as numbers: ink band, a centred bbox with a 40 px tolerance, and an 8-bin histogram with 0.06 tolerance. The builder's measured spread was far below these (<= 0.003 on the histogram). No image blobs are committed.
   - It is local only and not in CI.
   - NOT_RUN under headless is honest. It exits 1, so it can't be counted as a pass.

## Must-fix
None.

## Notes (non-blocking)
- The branch is based on an older main. The `android-family-first10.yml` validate list and the `TASKS.md` lines may conflict on merge. Rebase or cherry-pick, and re-check that the single trailing `m54_regression_pack_037_038` append survives.
- The 038 GFF probe is synthetic, because production never drives GFF on a Node2D. The build.md documents this.

VERDICT: PASS
