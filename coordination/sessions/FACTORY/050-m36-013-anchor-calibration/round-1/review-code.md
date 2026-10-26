VERDICT: PASS

## Checks
git diff --check origin/main...HEAD: pass (no output)
Decision-rule arithmetic recomputed by hand from level_progression_v2.json: pass
  - s = (49.6414 - 13.8099) / 56 = 0.63985, matches calibration.scale.
  - growth: 14, 13, 13, 12 times s round to 9.0, 8.3, 8.3, 7.7. Matches.
  - guards: 15, 20, 15, 35 times s round to 9.6, 12.8, 9.6, 22.4. Matches.
  - tolerance (s < 1, so scaled): 3.5, 2.0, 5.0 times s round to 2.2, 1.3, 3.2. Matches.
  - bases are round(M_L, 1). Cap: 49.6 + 7.7 = 57.3 <= 59.70 (best EXTREME probe), so the cap check passes.
Scope: scripts/, data/config/level_progression_v1.json and data/levels have no diff vs origin/main. The only data/ change is the new level_progression_v2.json (additive).
Godot suites: not run (reviewer-tests owns them).

## Findings
None.

## Notes
- Medians use AnalyzerV2._median (sort, middle value, mean of the two middle values for even counts). EXTREME rows are excluded in both tools/measure_difficulty_anchors.gd decide() and the suite's independent recomputation. The suite does not reuse decide(), so it is a real cross-check.
- Determinism: the test re-generates every fixture in memory and compares it with the file bytes. The merge writes canonical JSON. The rule text was committed in 27a66955, before anchors_v2.json in 05129032.
- Unreadable v2 file (SB-M36-016): acceptable. Spec requirement 1 mandates schema `scrubbots-level-progression/v2`. Requirement 6 forbids modifying DifficultyProgressionV1, which hard-checks the v1 schema. The two cannot both hold. The builder kept the mandated schema and the unmodified reader, documented the gap in doc section 5, and filed SB-M36-016. The suite's _target() reimplements the same formula, so the level-311 > level-11 EASY check does not exercise a real reader. That is a weak but honest proxy given the constraint.
- The builder edited the progression-v2 `calibration` block after the first commit (dropped the manifest path, which would have matched the criterion 8 grep). It did not edit any fixture or score. This is disclosed in build.md and is fine.
- Unfavourable results are reported honestly: the 1-wide ring probes score about 40, med_shafts6_24 (22.2) sits below easy_frame5_24 (24.2), and B is at or below 0.28 everywhere. Lane separation is therefore partly set by the design of this corpus. This is a model-sensitivity observation, not a defect in the job.
- Style: the suite's `T` and `TOL` and the tool's `V1_BASE` and `TOL` duplicate constants on purpose, to keep the independent recomputation independent.
