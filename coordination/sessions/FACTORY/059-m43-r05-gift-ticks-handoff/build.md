STATUS: READY

# Build: Close R05 / 013 into CI, build robot + feature unlock feel (MAJOR_UNLOCK)

## Summary
Branch `factory/059-m43-r05-gift-ticks-handoff` (commits a292c390, 4077ce5b, 7d31930a on top of 7eb22271):
- `scripts/ui/feel/meta_reward_feel.gd`: `_on_ceremony_shown` maps `robot_unlock` and `feature_unlock` to `_play("F007", "MAJOR_UNLOCK", hero, "c005f007:" + key)` on the ceremony `HeroArt` (both builders already name the hero `HeroArt`, nothing renamed). Header table has two F007 rows plus a note that World Transition is gated and has no intent. `SETTLE` gains `"MAJOR_UNLOCK": [1.12, 0.5]` (FULL only, peak equals the adapter's ~1.12).
- `tests/m43_c005f_phase6_unlock_feel.gd`: new suite, 8 cases u01..u08, real `main.tscn` with test save paths and spy GFF/Spark backends.
- `.github/workflows/android-family-first10.yml`: 3 suites appended to the `validate` list (49 -> 52), 3 exact-summary guards, header comment line.
- `TASKS.md`: R05-001, R05-002, SB-M43-013, C005F-007 ticked `[x]` with LOCAL_PASS evidence (C005F-007 robot + feature, world gated, not implemented); the three queue rows are now DONE.
- AGENTS.md / docs/TESTING_CONVENTIONS.md: not changed, because neither lists a CI suite count or the suite names (they point at the workflow).
- R05 and 013 production code: unchanged (verify-close).

## Acceptance criteria
1. [x] `m43_master_c005r_gift_micro_progress`: exit 0, no diagnostics, `M43 master C005R gift micro-progress evidence: PASS (8/8 cases, 0 fail)`.
2. [x] `m43_master_c005_meta_ceremonies`: exit 0, no diagnostics, `M43 master C005 meta ceremonies evidence: PASS (32/32 cases, 0 fail)` (includes e27/e28).
3. [x] `m43_c005f_phase6_unlock_feel`: exit 0, no SCRIPT ERROR/Parse Error, `M43 C005F phase6 unlock feel evidence: PASS (8/8 cases, 0 fail)`. The suite checks:
   - u01: robot gives exactly `["F007","MAJOR_UNLOCK","c005f007:robot:moppy","HeroArt"]` and one burst of 24.
   - u02: feature gives `c005f007:unlock:daily`.
   - u03: under REDUCED the key is consumed, plugin work is zero, the hero scale stays 1 and the actions are unchanged.
   - u04: plan amount 24 <= 24, lifetime 0.45 s <= 1.3 s, at most 1 owned group, released after 1300 ms, settle peak 1.120 and back to rest.
   - u05: clear + re-show (2 presentations), refresh, resize, EQUIP and re-drain still give one request.
   - u06: the economy snapshot (minus wall-clock anchors), progression and every feature_unlocked value are identical before and after the feel, for both robot and feature.
   - u07: `world_unlock` / `world_transition` request nothing.
   - u08: the static boundary (no grant/spend/save/equip/unlock/world code; the branch is a single `_play(MAJOR_UNLOCK)`).
4. [x] `m43_master_c005f_feel`: `PASS (10/10 cases, 0 fail)`. `m43_c005f_phase3_meta_rewards_acquisition`: `PASS (15/15 cases, 0 fail)`, exit 0. It prints one SCRIPT ERROR, which is the suite's announced `EXPECTED_FAULT_INJECTION` ('explode' on Nil). That suite is not in the CI list.
5. [x] `grep -c MAJOR_UNLOCK meta_reward_feel.gd` = 5. `grep -n world` returns only the line-34 comment saying world is gated, with no intent mapping.
6. [x] The workflow list has the 3 suites and 3 `grep -qxF` guards. `python tools/run_suites.py --list` gives 52. `python tools/run_suites.py` gives `aggregate=PASS (52/52)`, exit 0 (LOCAL_PASS on 4077ce5b).
7. [x] `git diff --check HEAD~3 HEAD` is clean. Changed files: `meta_reward_feel.gd`, the new test, the workflow and `TASKS.md`. The test `.uid` is not committed, per the job prompt.
8. [x] TASKS.md R05-001, R05-002 and SB-M43-013 are `[x]` with LOCAL_PASS evidence. C005F-007 is `[x]` for robot + feature with the note "World part gated, not implemented".

## Validation
- `$GODOT --headless --path <worktree> -s res://tests/m43_c005f_phase6_unlock_feel.gd`: PASS 8/8.
- Same for m43_master_c005r_gift_micro_progress (8/8), m43_master_c005_meta_ceremonies (32/32), m43_master_c005f_feel (10/10) and m43_c005f_phase3_meta_rewards_acquisition (15/15): all PASS.
- `python tools/run_suites.py` (all CI suites): aggregate=PASS (52/52), exit 0.
- `git diff --check`: clean.
- Worktree note: `git status --porcelain` is not empty. It lists pre-existing untracked/modified `.uid` and `.import` files from the imported worktree / Godot import. Per the job prompt these are deliberately not committed. None of them are task files.

## Log
### Round 0
- Added the F007 robot/feature MAJOR_UNLOCK mapping and the FULL-only settle (1.12 / 0.5 s) to meta_reward_feel.gd. No flash, camera, loop or new intent was added, and nothing that grants, equips, saves or navigates.
- Wrote the phase6 suite. Fixes while writing it:
  - u02: a seeded L4 profile auto-showed the ceremony during boot, before the spies were installed. Fixed by booting at L3 and advancing the live frontier to L4.
  - u06: the hearts anchor and speed clock_high_water are wall-clock fields, so they are excluded from the comparison, the same way the existing meta-ceremonies `_auth` helper does it.
  - u08: switched to line-based matching.
- Wired the 3 suites and their guards into CI (52). Verify-close for R05 and 013 needed no code change; both suites pass as they are.
- Ticked TASKS.md. The review label is still pending: no independent audit or owner visual sign-off is claimed.
