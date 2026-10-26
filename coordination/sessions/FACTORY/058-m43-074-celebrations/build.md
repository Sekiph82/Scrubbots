STATUS: READY

# Build: M43-C005 meta celebrations (SB-M43-074, 075, 077)

## Summary
Verify-close. Production code already shipped; no production change, no defect found. Added one suite with six cases, CI entry with exact-summary guard (49 suites), TASKS.md ticks. Commit b7a7bc74 on factory/058-m43-074-celebrations (not pushed).

Files: `tests/m43_c005_c074_c077_celebrations.gd` (new), `.github/workflows/android-family-first10.yml` (for-list entry, header comment 48 -> 49, grep -qxF 6/6 guard), `TASKS.md` (074, 075, 077 ticked; queue row DONE; 076 noted as nonexistent and untouched).
docs/06_TEST_STRATEGY.md and AGENTS.md list no per-suite names, so they are not touched.

## Acceptance criteria
1. [x] New suite prints `M43 C005 gift/daily/tasks celebrations evidence: PASS (6/6 cases, 0 fail)`, exit 0, no SCRIPT ERROR/Parse Error (grep of the log).
2. [x] EXPECTED_CASES ledger in the file; `_done()` adds a fail and exits 1 if any case is missing; `_ok` failures exit 1 (observed: an early run with a wrong test-side assertion printed FAIL (6/6, 1 fail), exit 1).
3. [x] Existing suites unchanged and PASS inside run_suites (m43_master_c005_meta_ceremonies, m43_master_c009_daily, m43_c005f_phase3_meta_rewards_acquisition, m43_c005_c072_feature_unlock_ceremony 9/9).
4. [x] Workflow has the suite in the `for s in` loop plus the grep -qxF guard; `python tools/run_suites.py` -> `aggregate=PASS (49/49)`.
5. [x] `git diff --check` clean on the changed files (only an LF->CRLF autocrlf warning); commit stats: suite, workflow, TASKS.md only.
6. [x] TASKS.md: 074, 075, 077 ticked with LOCAL_PASS evidence naming the new suite; 076 untouched (noted that it does not exist).

Cases: c01 Gift 10/50/250/500/1000 FULL==Reduced labels, rows == config bundle (fallback excluded), HeroGlow spin only in FULL; c02 presenter under Reduced: acknowledge grants nothing, occurrence still claimable, reload none pending; c03 Daily D1..D5 via real claim_daily_login on injected days: popup text == config login_rewards == wallet/booster/pending-selected delta, Day 5 DAILY_CYCLE_DONE, days 1-4 streak copy, opening grants nothing; c04 3/3 ScrubBox == config charges and committed result, no popup/grant when not all done, second claim refused; c05 Reduced: Daily + ScrubBox identical labels and grants vs FULL, no animation/particle/spin nodes; c06 drain with one showing opens no second, Daily/ScrubBox mark no MetaUiState key seen.

## Validation
- New suite headless: PASS 6/6 (exit 0).
- `python tools/run_suites.py`: aggregate=PASS (49/49), including all four named existing suites.
- Temp save paths only (`user://m43c005_c074_*`, removed at end); main.tscn never booted.
- Tree: Godot re-import dirtied ~240 tracked `.import` files and created untracked `.import`/`.uid`; restored/removed in the worktree; `git status --porcelain` empty.

## Log
### Round 0
Wrote the suite, found one test-side error (Day 5 `selected_booster_charges` lands in `boosters.pending_selected()`, not the four charge counters; fixed the assertion to check pending_selected, not weakened). No production defect found.
