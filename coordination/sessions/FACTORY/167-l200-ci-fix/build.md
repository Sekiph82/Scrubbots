STATUS: READY

# Build: L200 CI fix (difficulty goldens, world-2 transition)

## Summary
One commit, **bf9b39ef**, on `factory/167-l200-ci-fix`, based on origin/main 41b74e74. Not pushed. It fixes the two suites that failed in GitHub CI run 44049002157 after job 164 grew the catalog to 200 levels.

**`tests/difficulty_v1_identical_output.gd`**
- The campaign set is now catalog orders 1..30 (`CAMPAIGN_MAX_ORDER`), the levels the goldens were written for. L31+ get no goldens.
- The set check is now stricter: the set's ids must equal the golden record ids, not just their count.
- The byte-identical comparison itself is unchanged.

**`tests/m54_world_regression.gd`**
- r06 now uses the shipped catalog. At frontier 150 nothing triggers. At 151 the shipped catalog (200 levels) has L151, and exactly one World 02 event appears: Bubble District, AREA 2, World 01 fallback art. It opens once and grants nothing.
- The "L151 absent" rule is still covered, with an injected 1..150 catalog.
- New case r08 checks the real game. It boots the app, wins the real L150 (`level_150_mimic`) and lands on Home. After the reward flight, the Home ceremony drain shows the Gift popup and then `ceremony_world_unlock`, titled "Bubble District" with WorldArt. The Home area label reads BUBBLE DISTRICT / AREA 2. After the popup is acknowledged, nothing is pending.
- Nothing about world 2 is broken in the game.

**`.github/workflows/android-family-first10.yml`**
- The m54 guard is now exact 8/8 (was 7/7).

## Acceptance criteria
1. [x] difficulty_v1_identical_output compares exactly the L1..L30 golden records: `Difficulty V1 identical output: PASS (9/9 cases, 0 fail)`, with "campaign set has 30 levels, 30 golden records, same ids".
2. [x] m54 covers the world-2 transition at L151 on the shipped catalog, including the real-app run: `M54 world regression evidence: PASS (8/8 cases, 0 fail)`.
3. [x] Full CI list run locally with `tools/run_suites.py` in 2 shards: shard A `aggregate=PASS (48/48)`, shard B `aggregate=PASS (48/48)`. That is 96/96, with the exact guards applied.

## Validation
LOCAL_PASS. Godot 4.7.2, after a one-off `--import` in the worktree.
- `M54 world regression evidence: PASS (8/8 cases, 0 fail)`
- `Difficulty V1 identical output: PASS (9/9 cases, 0 fail)`
- Full CI list: 96 suites, all `status=PASS`. Logs are `shard_a.log` and `shard_b.log` in this folder.
- `git diff --check` is clean. I reverted project.godot and the .import line-ending churn, and removed the generated files by explicit list (no stash, no clean). The tree is clean.

## Log
### Round 1
- Read both CI failures.
- Narrowed the difficulty campaign set to L1..L30 and made its golden check compare ids, not just counts.
- Rewrote m54 r06 for the shipped 200-level catalog and added the real-app r08 case. Raised the m54 guard to 8/8.
- Ran both suites, then the full CI list in 2 shards: all pass.
- Committed bf9b39ef.
