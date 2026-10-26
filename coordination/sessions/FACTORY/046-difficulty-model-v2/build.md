STATUS: READY

# Build: Difficulty score model v2 (resume M53-C003 from the frozen C002 candidate)

## Summary
Branch `factory/046-difficulty-model-v2` adds score model v2 as the active model for NEW analysis. v1, the frozen M53-C002 candidate and `level_progression_v1.json` keep their byte content. v2 copies the candidate's definitions (six-policy non-oracle ensemble, colour-aware U, demand-relative A, B over states with >= 2 legal fronts, remaining-work S) and its corpus anchors. The weights are the locked 10/15/20/20/15/10/10. The corpus re-check found no defect that would justify any change beyond the candidate, and nothing was tuned against the owner ratings. As a result, v2 D equals the candidate D on all 10 levels (largest difference 5e-14). Spearman against the owner ratings is +0.6448, the same as the candidate (v1 +0.27). The doc reports the shortfalls under "Honest shortfall": the HARD slot scores below the MEDIUM mean, all three recovery guards fail, and L5/L10 sit outside the hard limit, so SB-M36-013 is filed.

Files changed (vs main):
- `data/config/difficulty_score_model_v2.json` (new: schema v2, version 2, a `changes` array of 9 entries, a `supersedesNothing` note)
- `data/config/level_difficulty_analysis_v2.json` (new: copy of the candidate config with schema `.../v2`, status ACTIVE_FOR_NEW_ANALYSIS, consumes score model v2, a `derivedFrom` candidate sha; anchors and `firstTenRead: false` unchanged)
- `scripts/difficulty/level_difficulty_analyzer_v2.gd` (new: copy of the candidate class; reads the v2 config and `ChallengeScoreModelV1.new(SCORE_MODEL_PATH)`; provenance includes `scoreModelConfig`)
- `scripts/difficulty/challenge_score_model_v1.gd` (accepts the v2 schema only from an explicit non-default path; provenance reports the schema actually loaded; v1 behaviour unchanged)
- `tools/difficulty_playtest.gd` (`--model v1|v2`, default v2; v2 records and JSON carry `modelVersion`, config paths and sha256; the printed `MODEL ...` header line covers both models; the v1 JSON shape is unchanged)
- `tests/m36_difficulty_v2.gd` (new suite, 38 cases)
- `tests/m53_first10_difficulty.gd` (offline-isolation allowlist: the v2 analyzer preloads v1 like the candidate does)
- `docs/DIFFICULTY_MODEL_V2_CALIBRATION.md` (new), plus status notes in docs/09, docs/10 and docs/11 (section 13 promotion status, playtest pointer)
- `coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json` (fresh run)
- `TASKS.md`

## Acceptance criteria
1. [x] `"$GODOT" --headless --path <wt> -s res://tests/m36_difficulty_v2.gd`: exit 0, 0 SCRIPT ERROR/Parse Error, prints `M36 DIFFICULTY V2 PASS`, last line `M36 difficulty V2 evidence: PASS (38/38 cases, 0 fail)`.
2. [x] v1 untouched. Suite s01 compares the LF-normalised sha256 (`Pack.content_sha256`, the same convention as the C002 freeze hash) of `difficulty_score_model_v1.json` b8310c9d..., `level_difficulty_analysis_v1.json` a0b0236e..., `level_difficulty_analysis_v2_candidate.json` 7dc96a0d... and `level_progression_v1.json` fe967a78... against constants taken from main: all ok. The b8310c9d value equals `git show main:... | sha256sum`. `git diff main -- data/config/difficulty_score_model_v1.json data/config/level_progression_v1.json data/levels | wc -l` gives 0.
3. [x] Suite s02: schema `.../v2`, version 2, weights exactly equal to the locked values, sum 1.000000, formula and challengeVectorOrder equal to v1, publishedLevelStoresModelVersion true. `ChallengeScoreModelV1.new(v2 path)` gives model_version 2; the default constructor still loads v1.
4. [x] Suite s03: empty -> 0, ones -> 100, and three extreme/NaN/+-inf vectors give finite values in [0,100] (27.50, 0.00, 0.00) through the v2 model. Suite s06: all 10 recomputed D are finite, in [0,100], and equal the v2 model applied to the stored vector.
5. [x] `tests/m36_difficulty_v1.gd`: exit 0, `M36 difficulty V1 evidence: PASS`, including "level 311 EASY target (31.03) > level 11 EASY target (20.68)" and the 1/10/11/111/311 cases. The v2 suite (s04) repeats the 11 vs 311 assertion.
6. [x] `-- --model v2` (fresh, no committed raw): exit 0 in 1553 s, `DIFFICULTY_PLAYTEST OK levels=10 anomalies=11`, 0 script errors. `playtest_v2.json` has top-level and per-level `modelVersion` 2, `scoreModelConfig {path, sha256 efa5dd36...}` and `analysisConfig {path, sha256 84e7e5f9...}`; all 10 solver statuses are SOLVED, all `source: fresh`, 0 route failures. `-- --model v1`: exit 0 in 305 s, `DIFFICULTY_PLAYTEST OK levels=10 anomalies=15`. Byte identity: the re-run differed from the committed `playtest_v1.json` only in the 20 wall-clock fields (`solver.ms`, `measureMs`; a python compare with those fields removed gave equal True). The committed file already stored timings, so no re-run can be byte-identical. I restored the committed file with `git checkout`, and `git diff main...HEAD` does not list it.
7. [x] Suite s07 prints `Spearman(v2 D, owner ratings) = +0.6448` (average ranks; a tie-handling self-check is included). This is >= +0.64, so it is accepted and `RANK_CORR_BELOW_CANDIDATE` is not printed. The doc still states that the value equals the candidate and is not an improvement.
8. [x] Suite s08 prints mean D EASY 30.55, MEDIUM 33.81, HARD 29.37, VERY_HARD 46.72, cycle max slot 10, then `CADENCE_ORDER_PARTIAL` (M<H false). The doc reports this under "Honest shortfall", which the suite asserts.
9. [x] `recovery` key in `playtest_v2.json`: 3->4 drop 13.98 (min 15) fail, 5->6 drop 5.80 (min 20) fail, 8->9 drop -8.45 (min 15) fail. Suite s09 checks the guard set and internal consistency against the level D values. The doc has the same table.
10. [x] `docs/DIFFICULTY_MODEL_V2_CALIBRATION.md` contains: the per-level table (class, lane target, v1/candidate/v2 D, W..S, delta, window), Spearman beside v1/candidate, lane window status, cadence order, recovery guards, corpus anchor derivation and re-check, "Honest shortfall" and the section 13 promotion status. `changes` has 9 entries, each with component/before/after/reason (suite s02).
11. [x] Suite s05: `calibratedAnchors.firstTenRead == false`; corpus manifest sha256 equals the candidate's and the file on disk (13885bcf...); anchor values are identical to the candidate's.
12. [x] `git diff --check main...HEAD` is clean. `git diff --name-only main...HEAD` lists only the files above: nothing under `data/levels/` or `assets/`, and not `level_progression_v1.json`. `tools/run_suites.py`: the new suite is NOT in the CI workflow loop. The spec puts GitHub Actions changes out of scope, and the precedent `m36_difficulty_v1` is also not in the loop, so `run_suites.py` cannot run it (it only runs workflow suites). I ran it directly instead (item 1). `python tools/run_suites.py m35_level_catalog m37_level_progression run_tests` gave aggregate=PASS (3/3).
13. [x] TASKS.md: the SB-M36-009 question line is removed (the Questions section is now empty); the SB-M36-009 queue and checklist rows carry "owner chose B 2026-10-26"; DONE SB-M36-012 queue row plus checklist row with evidence; READY SB-M36-013 row plus `- [ ]` row stating it needs a later owner decision (L5 -28.6, L10 -29.3 outside +/-5); the M53-C003 DEFERRED block is replaced by a pointer to SB-M36-012. `grep -c SB-M36-012 TASKS.md` gives 6.

## Validation
All runs are LOCAL_PASS on Godot 4.7.2 headless, worktree HEAD 90d012dd. Each had 0 SCRIPT ERROR/Parse Error.
- tests/m36_difficulty_v2.gd: PASS (38/38), exit 0
- tests/m36_difficulty_v1.gd: PASS, exit 0
- tests/m53_first10_difficulty.gd: PASS, exit 0 (first run FAILed its offline-isolation check on the new analyzer; fixed in 58e5c283, see Log)
- tests/m53_c002_difficulty_calibration.gd: PASS, exit 0 (same first failure; fixed by a comment change in the v2 analyzer)
- tests/m53_c002_canonical_json.gd: PASS (30 checks); tests/m36_v02_migration.gd: PASS
- tools/difficulty_playtest.gd `--model v2` (fresh): OK, 1553 s; `--model v2 --committed-measure`: OK, 80 s, same numbers; `--model v1` (fresh): OK, 305 s, content-identical except wall-clock fields (committed file restored)
- python tools/run_suites.py m35_level_catalog m37_level_progression run_tests: aggregate=PASS (3/3)
- git diff --check main...HEAD: clean
- I restored the tracked `.import` files Godot rewrote and removed the generated untracked `.import`/`.uid` files. `git status --porcelain` is empty.

## Log
### Round 1
- Read the spec, the proposal doc, the candidate analyzer/config, `calibrate_difficulty_v2.gd`, the C002 corpus and holdout evidence, the owner ratings and the reconciliation. The candidate already contains every change the diagnosis motivates. The corpus re-check found: A's declared pair passes and there is no inversion; B low-choice is 0..0.16 on the corpus and 0..0.32 on L2..L10, so there is no saturation, and with 3 columns the `< legal` condition already makes the threshold relative; S is low on the EASY slots; W/C/R pairs and family checks pass. So I made no definition or anchor change beyond the candidate, and recorded the reasons in `changes` and in doc section 4.
- Commits: d4a1b328 (model v2 configs + analyzer + score-model reader), 08448e0b (playtest `--model`), 58e5c283 (m53 isolation allowlist and v2 analyzer comment wording, so neither m53 isolation scan flags the new offline analyzer), 2394713f (suite, doc, fresh playtest_v2.json, docs 09/10/11), 90d012dd (TASKS.md).
- Decisions worth review:
  - (a) The v1 JSON shape is kept, so it does not gain the new model/sha keys. The spec's byte-identity criterion wins over "every output includes"; v1 gets the provenance only in the printed `MODEL` header.
  - (b) Strict byte identity of `playtest_v1.json` is impossible because the file stores wall-clock ms. Evidence is content identity except timing, and the committed file is restored.
  - (c) The suite is not added to the CI workflow (out of scope: Actions).
  - (d) The new READY SB-M36-013 row is placed after SB-M36-011 and its text says it must not start without the owner decision.
- Honest results: rank correlation +0.6448 (= candidate, not better; without L1, v2 +0.56 < v1 +0.60). Cadence is partial (HARD below MEDIUM mean). All 3 recovery guards fail. L7 fails the policy-robustness gate (1.89 > 1.75). L5 and L10 sit about 29 below their lanes.
