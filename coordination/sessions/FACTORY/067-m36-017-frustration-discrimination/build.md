STATUS: READY

# Build: SB-M36-017 frustration discrimination findings

## Summary
Branch `factory/067-m36-017-frustration-discrimination`, commits `30a0171e` (tool, test, evidence, doc, AGENTS.md) and `bf36b24f` (TASKS.md).

- `tools/difficulty_playtest.gd`: opt-in `-- --frustration --fixtures id[,id...] [--runs N]` runs only the HUMAN_BR population. It accepts anchor fixtures (slot from lane: HARD 5, VERY_HARD 10) and catalog ids (slot from order). Session Load and choice opacity come from `v2.score()` of the committed raw, sha-bound to the level and supply bytes. Output goes to `coordination/sessions/FACTORY/067-m36-017-frustration-discrimination/frustration_<ids>_r<N>.json`. Without `--fixtures` the only change is a guard: `--fixtures` without `--frustration` exits 1.
- `tests/m36_frustration_fixtures.gd` (new suite).
- `coordination/sessions/FACTORY/067-m36-017-frustration-discrimination/frustration_*_r32.json`: 11 evidence files.
- `docs/DIFFICULTY_FRUSTRATION_DISCRIMINATION_FINDINGS_V1.md` (new).
- `AGENTS.md`: one clause added to the difficulty-tools line.
- `TASKS.md`: the SB-M36-017 queue row and checklist line.

## Acceptance criteria
1. [x] **New path works; default untouched; old suite passes.**
   - `$GODOT --headless --path $WT -s res://tests/m36_frustration_fixtures.gd`: exit 0, 0 SCRIPT ERROR or Parse Error, `M36_FRUSTRATION_FIXTURES PASS (11 cases, 0 fail)`.
   - The suite runs the tool as a subprocess at 1 run on `easy_vstripes3_24` and checks the output fields.
   - It checks that the sha and mtime of `playtest_v1.json`, `playtest_v2.json`, `playtest_v2_progression_v2.json` and `frustration_v1.json/.md` are unchanged.
   - It checks the guards: `--fixtures` without `--frustration`, an unknown id, and `--model v1` each exit 1.
   - `tests/m36_frustration_v1.gd`: exit 0, 0 errors, `M36_FRUSTRATION_V1 PASS (62 cases, 0 fail)`. Wall time was 638 s because it ran alongside the sweep. It still prints its L1 2-run FINDING.
2. [x] **32-run evidence and findings doc.**
   - Runs: 5 HARD and 5 VERY_HARD anchors plus L1, 32 runs per profile. All 11 processes exited 0 with no SCRIPT ERROR.
   - Wall time: 41 min total, 11 processes in parallel. Each anchor run took 26-41 min under contention, which is over the ~20 min guide. Runs were not reduced because all of them finished.
   - Findings:
     - Every anchor cleared 32/32 for all three profiles, so the NOVICE<=CASUAL<=SKILLED ordering holds only as ties.
     - All 45 anchor-anchor retryRisk pairs tie at 0. Anchor F equals 15 x choiceOpacity (0.3 to 3.4).
     - The only non-tied pairs are L1 (0.912) against each anchor.
     - L1 cleared 3/32, 3/32 and 2/32: CASUAL > SKILLED, a miss inside the Wilson interval overlap. Dead placements are about 4.9 for every profile, so the losses come from the supply.
     - Dead placements per attempt are SKILLED <= NOVICE on all 10 anchors (a diagnostic only, not an F input).
   - The doc has the tables, the conclusion, and a next step (deadlock-capable supplies; a skill-sensitive input under a new model version).
3. [x] **Configs and committed outputs unchanged.** `git diff --quiet main -- data/config coordination/sessions/FACTORY/046-difficulty-model-v2` exits 0.
4. [x] **TASKS.md.** The queue row is now DONE and the checklist line is `[x]` with evidence. The diff is 2 insertions and 2 deletions, and the file is still CRLF.

## Validation
- m36_frustration_fixtures: PASS, LOCAL_PASS. I re-ran it after restoring the worktree's Godot-rewritten `project.godot`.
- m36_frustration_v1: PASS (62), LOCAL_PASS.
- `git diff --cached --check` on both commits: clean.
- Not run: the full 10-level `--frustration` catalog run. It is optional in the task and would rewrite the committed `playtest_v2.json`.
- Worktree note: `godot --import` (needed for the addon class cache) left Godot artefacts in the worktree. They are untracked `*.uid`/`*.import` files and stat-only dirty `*.import` files with no content diff. None of them is committed. The rewritten `project.godot` was restored.

## Log
### Round 1
Light path (spec+builder). Added the opt-in fixtures path and its suite, ran the 32-run sweep, and wrote the findings doc, AGENTS.md pointer and TASKS.md entries. Nothing was tuned.
