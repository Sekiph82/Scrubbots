STATUS: READY

# Build: SB-M36-009 Difficulty V1 lane calibration proposal

## Spec (light path)
Task SB-M36-009. Write docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md: diagnose why measured V1 D is compressed (45..54 vs lane targets 18..76) per component W/C/A/U/B/R/S with numbers from playtest_v1.json; options (A) content-side without touching owner-original art, (B) model-v2 normalization proposal under a new versioned file name with a worked recompute table of the 10 levels (no config file created), (C) accept-window adjustment; recommend one and list the owner decision needed. TASKS.md: tick SB-M36-009, queue row DONE, one `## Questions for Şekip` line if an owner product choice is needed. No data/config/script changes; `git diff --check` clean.

## Summary
The branch adds the proposal doc and updates TASKS.md. The proposal finds the cause is the V1 model, not levels 2..10. V1 U is pure board geometry (0.410 on every 32x32). A and B saturate (A 0.61..0.78, B 0.44..0.64, because there are 3 front columns and lowChoiceThreshold is 2). A, B and S rank-invert against class. Only C tracks the cadence (rho +0.72). The lane bases were never placed on a measured D scale.

The worked recompute (B1) re-normalizes V1 with in-sample anchors. It makes the order worse (rho vs target -0.15), which shows that normalization alone cannot fix V1. The table also lists the M53-C002 V2 candidate. It is the best of the three scorings (owner rho +0.64, 2/10 inside the window) but is still compressed at the top. The proposal recommends B: build score model v2 by resuming the M53-C003 path, with weights unchanged. The proposal also uses the M53-C002 owner Stage-B ratings and the V2 candidate evidence it found in the repo.

Files changed:
- docs/DIFFICULTY_LANE_CALIBRATION_PROPOSAL_V1.md (new)
- TASKS.md (queue row DONE, checklist tick + note, one Questions line)

Commits: 3538e9c3 (doc), f1ae56d6 (TASKS.md).

## Acceptance criteria
1. [x] Diagnosis with numbers from the JSON: section 2 has a per-component table (min/max/mean, D points, spread, rho vs target and owner rating) computed from playtest_v1.json. It also uses the raw sub-measurements from M53-C001 first10_difficulty_v1.json (U waves, B fractions, R, S) and compares the normalization anchors against the observed values.
2. [x] Option A (content-side, owner art untouched): section 3 covers re-sequencing by V1 D and the Level Factory targets needed for EASY 18..22 and VH 76, with consequences.
3. [x] Option B (versioned model v2, no config created, worked recompute table): section 3 names difficulty_score_model_v2.json / level_difficulty_analysis_v2.json (not created). The 10-level table gives V1 D, re-normalized components, B1 D and delta, plus the measured V2-candidate D and delta, followed by a summary table.
4. [x] Option C (accept-window): C1 widen (needs +/-32.9), C2 lane rescale, C3 ordinal, each with consequences.
5. [x] Recommendation and owner decision list: sections 4 and 5.
6. [x] TASKS.md: queue row `DONE SB-M36-009`, checklist `- [x]` with a note (proposal delivered; adoption is a separate decision), and one Questions for Şekip line (A/B/C/keep deferring in plain terms). CRLF line endings were preserved.
7. [x] No data/config/script changes: `git diff --stat 41ab6256..HEAD` shows only TASKS.md and the new doc.
8. [x] `git diff --check 41ab6256..HEAD`: clean.

## Validation
- Numbers were computed with a scratch Python script over playtest_v1.json, first10_difficulty_v1.json and difficulty_v2_candidate_first10.json (Spearman with average ranks). The script is not committed.
- `git diff --check 41ab6256..HEAD`: clean (PASS).
- `git status --porcelain`: empty.
- No Godot suites were run: the change is docs only and touches no code, data or config.

## Log
### Round 1
- Read the inputs and found prior M53-C002 work: the frozen V2 candidate measurement, owner Stage-B ratings 6,3,6,3,5,3,3,5,3,5, and the C003 deferral of 2026-09-27. The proposal is built on that work.
- Wrote the proposal doc and updated TASKS.md, then committed both.
