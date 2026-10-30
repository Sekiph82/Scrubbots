# Spec: SB-M36-017 frustration discrimination findings (light path)

Follow-up to factory 053 (FrustrationAnalyzerV1, HUMAN_BR population).

## Build
- Add an opt-in `--fixtures id[,id...]` path (requires `--frustration`) to `tools/difficulty_playtest.gd` that runs only HUMAN_BR on anchor fixtures (`tests/fixtures/difficulty_anchors`) or catalog levels, taking Session Load / choice opacity from the committed v2 raw, and writes its own output file. Without `--fixtures` the tool is unchanged.
- Run 32 runs/profile on the 5 HARD + 5 VERY_HARD anchors and on L1 (sanity only).
- Write `docs/DIFFICULTY_FRUSTRATION_DISCRIMINATION_FINDINGS_V1.md`: clear-rate ordering NOVICE<=CASUAL<=SKILLED per level, non-tied retryRisk pairs, conclusion, next step. FINDINGS only.

## Must not
- Edit frustration_analysis_v1.json, difficulty score/analysis models, level_progression_v1/v2.json, or any committed playtest_v2.json / frustration_v1 output.
- Use L1..L10 as calibration references.

## Acceptance criteria
1. New test proves the fixtures path works and default outputs are not touched; `tests/m36_frustration_v1.gd` still PASS.
2. 32-run results for 10 anchors + L1 committed as evidence; findings doc written.
3. Configs byte-unchanged vs main.
4. TASKS.md SB-M36-017 ticked and queue row DONE, CRLF preserved, minimal diff.
