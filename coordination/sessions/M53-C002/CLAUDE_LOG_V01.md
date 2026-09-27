# M53-C002 — CLAUDE LOG V01 — Difficulty V1 Calibration / Policy Robustness

Date: 2026-09-27
Actor: Claude (implementer). No audit verdict is claimed.
Prompt: `coordination/sessions/M53-C002/task_prompts/SB-M53-C002_DIFFICULTY_CALIBRATION.md`
Criteria: `coordination/sessions/M53-C002/audit_criteria/SB-M53-C002_DIFFICULTY_CALIBRATION.md`
Base: `origin/main` `88ed96a`
Commits:
- **`4bea41e`** — calibration freeze. This commit comes before any First 10 V2 measurement.
- the holdout / evidence / log commit that follows it.

Root `TASKS.md` is read only and was not edited.

## Summary

A V2-candidate analyzer was built, calibrated on an independent QA-only corpus, frozen, and then run once on the First 10 as a holdout.

On the corpus:
- all 14 declared ordinal relationships and all 3 family checks pass;
- the anchor rules re-derive exactly from the corpus;
- the policy-robustness gate (tie-break / leave-one-out, τ = 1.75 D) holds on all 27 fixtures.

On the First 10 holdout (V2 D, not changed after viewing):
- **2/10 levels fall inside the ±3.5 window**: L2 (22.08 vs 22) and L3 (38.94 vs 40).
- **L10 is now the cycle maximum** (46.72).
- **8/10 still miss their targets.** EASY L1/L7/L9 score too high (42.4 / 33.2 / 37.2). HARD L5 (29.4) and VERY_HARD L10 (46.7) score far too low. MEDIUM L8 (28.7) is also low.
- **All three recovery guards still fail** (L8→L9 is inverted).
- **L7 exceeds the robustness tolerance** (1.89 > 1.75); the other 9 are within it.

Findings the owner should see:
- **Level 1 can be lost by a neutral player.** Both round-robin reference policies deadlock at about 25% progress on Level 1's historical generator supply. The kernel never reports a false LOST, so this is a real runtime loss path.
- The stress policy deadlocks L1, L3, L5, L9 and L10.

What these results mean: under a calibrated, policy-robust measurement, the First 10 content does not match the locked EASY / HARD / VERY_HARD lane targets or the recovery cadence. This is stronger evidence than C001 that an owner decision on content and/or targets is needed. Nothing was tuned or relabeled.

## Git / owner-work preservation

- Fast-forwarded `9485472…` to `88ed96a` with no conflicts.
- The owner's local `project.godot` modification and the untracked `.import`/`.uid`/art files were left untouched and are not committed.
- Protected content was **not mutated**: First 10 source PNGs, LevelData, metadata, previews, owner supply plans, catalog, class tokens, `difficulty_score_model_v1.json`, `level_progression_v1.json`, and the V1 analyzer/config/evidence. The test hashes all of these before and after its run, and binds them to the M52 bytes.

## A. Independent calibration corpus

**Where it lives:** `tests/fixtures/difficulty_calibration/`, generated deterministically by `tools/calibrate_difficulty_v2.gd -- --build-corpus`.

**What it contains:**
- 27 QA-only LevelData + supply-plan fixtures, `difficulty: "TEST"`, `qaOnly: true`.
- None of them is in the production catalog (asserted by test).
- Every fixture is fully ACTIVE with canonical C-IDs and is proven **SOLVED** by `SolvabilitySolver`.

**Coverage:**

| Family | Fixtures | Isolated axis |
|---|---|---|
| FLOW_SIZE | 3-colour 8-wide stripes at 20, 24, 32, 40, 48 | W / Session Load, board size only |
| COLOR (geometry-matched) | the same 12 two-wide stripes coloured with 3 / 6 / 12 / skewed-6 colours | C |
| ACCESSIBILITY | solid band vs eight 1-wide shafts; same colours and counts, all border-touching (unlock wave 0) | A |
| UNLOCK | outer band vs six alternating rings | U |
| ROUTE | open block vs single-entrance serpentine corridor | R |
| BOTTLENECK | same 3-ring board; interleaved vs column-split (outer only in column 1) supply | B |
| SLOT | same ring board; ring-aligned vs colour-first 30-robot batches | S |
| COMPACT_HARD | 20×20 rings + column-split supply | compact-hard vs large-flow |
| *_EXPLORATORY | first-draft colour stripes 6/12/skew, halves, comb, 4-stripes, mosaic | kept; they feed the anchor distributions |

**Declared relationships** (`corpus_manifest_v1.json` → `ordinalPairs`): harder > easier on the intended axis and, where declared, on D. There are no arbitrary target scores.

**Family checks:**
- flow 20..48 D spread < 18 (the smallest cycle-0 lane gap);
- every flow board has D < 40 (the MEDIUM target);
- colour count alone does not decide D: the 3-colour fixtures span more than 18, and one of them scores above the 12-colour matched fixture.

**Pre-freeze revisions.** These were all recorded in the manifest and config, and none used First 10 data:

1. **Withdrawn hypotheses** (`withdrawnPairs`, with the measured reason):
   - comb > halves (A);
   - mosaic > 4-stripes (A);
   - 3-colour rings > 12-colour stripes (D). The 12 two-wide stripes turned out to be an accessibility-scarcity board, which confounded colour count with stripe width.

   Replacements: the band/shaft A pair and the geometry-matched `color_m*` family.
2. `color_m6 > color_m6skew`: the D expectation was withdrawn and only the C ordering is claimed. Putting one colour on six narrow stripes also raises A.
3. `slot_high` supply was made colour-first so that inner-ring batches actually wait.

## B. Oracle-independent, policy-robust scoring

**Analyzer:** `scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd` (`m53-level-difficulty-analyzer/v2-candidate`).

**Oracle independence:**
- **No solver trace enters any Challenge component.** The analyzer never loads the solver (asserted).
- `SolvabilitySolver` is used only for solvability/provenance.

**Policy family**, replayed through the real `ProofKernel` and production routing/access:

| Policy | Behaviour |
|---|---|
| **RR / RR_REV** | balanced round-robin, ascending / descending cycle |
| **GREEDY / GREEDY_HI** | most reachable targets; ties go to the lowest / highest column |
| **ACCESS / ACCESS_HI** | best fill ratio min(reach, robots)/robots |
| **STRESS** | fewest reachable; bounded adversarial; diagnostics only |

All non-adversarial policies share one rule: never place a batch with no reachable target while a productive one exists.

**Primary components** are the component-wise **mean over the six non-adversarial policies**, so each family carries equal weight.
- Pre-freeze choice: on the corpus, a 3-policy median moved up to 2.0 D and a 6-policy median up to 3.6 D.
- For two trajectory clusters, the family-out shift is (H−L)/2 for the median, (H−L)/4 for a trimmed mean and (H−L)/6 for the mean.
- STRESS is excluded from the aggregate, and every member follows the no-dead-placement rule.

**Robustness gate (τ = 1.75 D, declared before measurement):**
- **Gated:** leave-one-out (6 variants) and tie-break-uniform (6 variants). This is the analogue of solver search order / tie-break.
- **Reported, not gated:**
  - leave-family-out and family-only D — the strategy spread between genuinely different valid families;
  - the tie-break halves;
  - ORACLE_DIAGNOSTIC and OWNER_DIAGNOSTIC single-path D.

**Operational changes from V1.** All are recorded in the config; the locked weights, W and C are untouched.
- **A — demand-relative, per batch.** A_t = 1 − Σmin(reach, need) / Σneed, with need = min(raw, robots) for each offered front and occupied slot.
  - **This deviates from the locked conceptual text** ("reachable/raw"), so it needs audit and owner adoption.
  - Evidence: on the corpus the V1 ratio is *ordinally inverted*. Comb, maze and mosaic all scored lower than halves, open block and stripes, because reachable/raw measures region compactness. The capped form equals V1 whenever demand ≥ raw.
- **U — colour-aware.** Unlock waves use same-colour closure under production access. The V1 colour-agnostic peel was pure geometry on full rectangles.
- **B — exhaustion excluded.** Only states with ≥ 2 legal fronts count, because running a column dry is not a bottleneck.
- **S — imbalance redefined.** The imbalance term is now remaining-work imbalance across demanded colours (the doc 09 wording). The V1 shortfall term would have double-counted A.
- **Progress weighting.** A is weighted by progress interval.

## C. Anchors (rule-derived from the corpus only, frozen)

| Anchor | Value | Rule |
|---|---:|---|
| A_lo / A_hi | 0.0291 / 0.5874 | median of FLOW_SIZE / corpus max |
| U_p95_hi / U_mean_hi | 4.0 / 1.5278 | corpus max |
| R_len lo / hi | 0.7318 / 1.6558 | median of FLOW_SIZE / corpus max |
| R_detour lo / hi | 1.2878 / 2.8803 | same rule |
| R_turn lo / hi | 2.0625 / 4.6811 | same rule |

- Raw distributions for each anchor are stored in `calibration_corpus_v1.json`.
- **Anchor sensitivity:** every anchor was scaled ×0.8 and ×1.25, one at a time. **No declared pair and no family check fails** under any of these variants.
- On the holdout, the D shift under the same variants is at most 3.4 D for any level (L1: 39.76–45.72 around 42.37) (matrix column "Anchor ±sens D").
- Fixed parameters carried unchanged from V1 (not calibrated): A early weight 2.0 and the Session Load envelope anchors.

**Freeze:**
- `calibratedAnchors.firstTenRead = false`.
- Config sha256 `4cd879c5aa8e6ee141169f29b5f6a758e20a1d88987bbff5c5de091051da14f8` is recorded in the corpus evidence.
- Holdout commands refuse to run unless the config matches that hash, and every holdout raw file records the hash (asserted).
- Committed as `4bea41e` before the holdout ran.
- After the freeze, only `tools/calibrate_difficulty_v2.gd` reporting code changed: it adds corpus strategy-family spread to the holdout evidence and matrix. No scoring or config change was made; the config hash is unchanged (asserted).

## E. Validity tests (`tests/m53_c002_difficulty_calibration.gd`: 214 ok, PASS)

1. **Deterministic rerun:** a fresh measurement of `flow_stripes3_20`, run twice, matches itself and the committed raw file (timing excluded).
2. **Bounds:** all W..S are finite and in [0,1] for 27 fixtures + 10 levels, and D equals the locked V1 formula.
3. **Controlled pairs:** all 14 re-score PASS from the committed raw; all families PASS.
4. **Oracle independence:**
   - primary D is identical with the oracle/owner diagnostic runs removed, or with the "oracle" swapped for the owner path;
   - the analyzer contains no solver reference;
   - STRESS does not affect the primary components.
5. **Policy spread:** reported for every fixture and level — all 7 policies plus family-only D and diagnostic paths.
6. **Tie-break / leave-one-out robustness:** ≤ 1.75 on all 27 corpus fixtures (max 1.51). On the holdout the deviation is reported honestly: L7 1.89, all other levels ≤ 1.65.
7. **Board size alone:** flow 20..48 D spans 11.8–17.3 (spread 5.5 < 18, all < 40).
8. **Compact vs large:** `compact_hard_20` (31.2) > `flow_stripes3_48` (17.3).
9. **Colour count alone:** 3-colour fixtures span 29.5 D, and `route_maze_24` (3 colours, 36.5) > `color_m12_24` (12 colours, 32.1).
10. **Intended axes move:** shafts > band on A, deep > shallow on U, maze > straight on R, column-split > interleaved on B, colour-first > ring-aligned on S, 48 > 20 on W/SL.

The suite also checks:
- freeze discipline;
- anchor re-derivation;
- that the V1 evidence copy is unchanged;
- mechanical target/delta/window;
- recovery from actual V2 D;
- the blank owner rating sheet;
- no shipping dependency.

## F. First 10 holdout (V1 Stage A vs V2 candidate)

| L | Class | Target | V1 D | **V2 D** | Window | Family-only D (RR / GREEDY / ACCESS) | Gated dev | Oracle / owner diag |
|---:|---|---:|---:|---:|---|---|---:|---|
| 1 | EASY | 20 | 46.03 | **42.37** | OUT | 48.7 / 39.3 / 39.2 | 1.28 | 43.7 / n/a |
| 2 | EASY | 22 | 45.04 | **22.08** | IN | 18.3 / 23.8 / 24.1 | 0.80 | 18.2 / 18.1 |
| 3 | MEDIUM | 40 | 54.27 | **38.94** | IN | 34.2 / 40.6 / 40.6 | 0.72 | 43.6 / 34.0 |
| 4 | EASY | 19 | 49.49 | **24.96** | OUT (+5.96) | 22.9 / 25.6 / 26.4 | 0.62 | 33.0 / 22.5 |
| 5 | HARD | 58 | 53.19 | **29.37** | OUT | 26.0 / 31.0 / 31.3 | 1.43 | 45.0 / 25.9 |
| 6 | EASY | 18 | 50.91 | **23.58** | OUT (+5.58) | 22.9 / 23.9 / 23.9 | 0.18 | 35.0 / 22.7 |
| 7 | EASY | 21 | 50.96 | **33.19** | OUT | 26.3 / 36.0 / 37.4 | **1.89** | 38.3 / 26.9 |
| 8 | MEDIUM | 42 | 47.37 | **28.69** | OUT | 25.2 / 30.3 / 30.7 | 1.14 | 30.3 / 25.1 |
| 9 | EASY | 19 | 50.78 | **37.15** | OUT | 34.3 / 38.0 / 38.4 | 1.38 | 41.4 / 33.5 |
| 10 | VERY_HARD | 76 | 51.50 | **46.72** | OUT | 45.2 / 47.2 / 47.8 | 1.65 | 53.8 / 44.6 |

**Recovery (actual V2 D):**
- L3→L4: drop 13.98 (min 15). **FAIL** (close).
- L5→L6: drop 5.80 (min 20). **FAIL.**
- L8→L9: drop −8.45. **Inverted, FAIL.**
- L10: V2 D 46.72, **rank 1 — the boss relationship holds.**

**Session Load (V2):** L1 7.5; L2 and L4–L10 24.5–26.6; L3 35.6.

**Frustration:** `PROVISIONAL_STAGE_A`, no scalar; retry risk and session overrun remain UNSUPPORTED.
- Stress-policy deadlocks: L1 (at 0%), L3 (15%), L5 (69%), L9 (20%), L10 (62%).
- L1 primary policies completed: **4/6**. RR and RR_REV deadlock at about 25%.

The single-path oracle vs owner difference under V2 is still up to 19 D (L5), which is why neither path is used for the primary score.

**Structural reading (diagnostic only, no remediation):**
- The HARD and VERY_HARD content is structurally close to the EASY content under V2, with most levels in 22–38 D.
- L10 gets its lead from U (0.967) and C.
- L1, L7 and L9 get bottleneck and slot pressure (B ≈ 0.15–0.70) from their supply structure.
- Which fix applies — content/supply tuning, target revision, or adopting and revising the measurement — is an owner decision after audit.

## G. Owner rating sheet

`OWNER_DIFFICULTY_RATING_SHEET_V01.md` is blank and ready for owner input:
- per level: difficulty, fairness and engagement (1..7), optional duration, and intended class feel (easier / about right / harder);
- cadence feel for each transition.

No values were filled in (asserted).

## I. Regression (Godot 4.7.2.stable.official.ed1daf0bf, headless)

| Suite | Result |
|---|---|
| `tests/m53_c002_difficulty_calibration.gd` (new) | exit 0, 214 ok, **PASS** |
| `tests/m53_first10_difficulty.gd` (C001) | exit 0, 315 ok, **PASS** (see harness note) |
| `tests/m52_owner_supply_plans.gd` | exit 0, 255 ok, PASS — 9/9 WON through production input; frontier 11 CONTENT_MISSING |
| `tests/m52_r01_parallel_runtime.gd` / `m52_r02_early_slot_release.gd` | exit 0, 79 / 65 ok, PASS |
| `m27_generation_retry`, `m27_hazard_bot_solve`, `m27_scale_59` | exit 0, PASS |
| `m29_hazard_bot_runtime_smoke`, `m29_realtime_movement_smoke` | exit 0, PASS |
| `m30_completion_authority`, `m30_transaction_safe_retry`, `m30_manual_playtest_smoke` | exit 0, PASS |
| `m36_difficulty_v1`, `m36_v02_migration`, `m37_level_progression` | exit 0, PASS |
| root `tests/run_tests.gd` | exit 0, **5323 checks, ALL PASS**, 0 SCRIPT ERROR, 9 engine `ERROR:` lines (same count as baseline) |
| `git diff --check` / `--cached --check` | clean |

Notes:
- Every suite has 0 SCRIPT ERROR. The per-suite engine `ERROR:` lines are the pre-existing "resources still in use at exit" and M52's intentional malformed-JSON loader fixture, the same as the C001 runs.
- **Harness note:** C001's no-shipping-dependency scan listed the new offline V2 analyzer, because it preloads V1. The scan now also whitelists `scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd`. No other C001 assertion changed.
- **No production gameplay behaviour changed.** No shipping script or scene references the V2 analyzer, the calibration tool or the fixtures (asserted). `ProofKernel` is untouched since C001.

## Limitations

- The corpus is synthetic (stripes, rings, maze and shafts built on a 20..48 grid). Anchors are corpus-relative, so U is clamped at p95 wave 4 (L10's U is 0.967, near the clamp).
- A and S are operational deviations from V1 and need audit and owner adoption. The A early weight and the Session Load anchors are still Stage A.
- Strategy-family spread is real and reported rather than gated: corpus max 3.74 on `route_maze_24`; holdout max 3.47 on L7.
- Frustration has no human-policy model, and no retry-rate claim is made.

## Changed files

Commit `4bea41e` (freeze):
- `scripts/difficulty/level_difficulty_analyzer_v2_candidate.gd` (new)
- `data/config/level_difficulty_analysis_v2_candidate.json` (new, frozen)
- `tools/calibrate_difficulty_v2.gd` (new)
- `tests/fixtures/difficulty_calibration/*` (27 fixtures × level + supply, plus the manifest)
- `coordination/sessions/M53-C002/evidence/corpus_raw/*_raw.json` (27)
- `coordination/sessions/M53-C002/evidence/calibration_corpus_v1.json`
- `coordination/sessions/M53-C002/OWNER_DIFFICULTY_RATING_SHEET_V01.md`

Holdout commit:
- `coordination/sessions/M53-C002/evidence/holdout_raw/*_raw.json` (10)
- `coordination/sessions/M53-C002/evidence/difficulty_v2_candidate_first10.json`
- `coordination/sessions/M53-C002/DIFFICULTY_CALIBRATION_MATRIX_V01.md` (generated)
- `coordination/sessions/M53-C002/CLAUDE_LOG_V01.md` (this file)
- `tests/m53_c002_difficulty_calibration.gd` (new)
- `tools/calibrate_difficulty_v2.gd` (reporting only)
- `tests/m53_first10_difficulty.gd` (whitelist line)

## Reproduce

```bash
godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- --build-corpus
godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- --measure=<fixture_id>
godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- --calibrate
godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- --holdout=<level_id>
godot --headless --path . -s res://tools/calibrate_difficulty_v2.gd -- --holdout-merge
godot --headless --path . -s res://tests/m53_c002_difficulty_calibration.gd
```

In order:
1. build the corpus;
2. measure each fixture (once per fixture);
3. calibrate and freeze — this refuses if the config is already frozen;
4. measure each First 10 level (once per level) — this refuses unless the freeze hash matches;
5. merge the holdout;
6. run the C002 suite.

`AWAITING_CHATGPT_AUDIT / M53-C002 DIFFICULTY CALIBRATION`
