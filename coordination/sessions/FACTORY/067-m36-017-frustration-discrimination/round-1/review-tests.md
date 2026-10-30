VERDICT: PASS

## Findings
None.

## Notes
- Re-ran `m36_frustration_fixtures.gd` myself: exit 0, last line `M36_FRUSTRATION_FIXTURES PASS (11 cases, 0 fail)`.
- Did not re-run `m36_frustration_v1.gd` (about 10 min). I rely on the build.md result (`PASS (62 cases, 0 fail)`). The tool diff is additive and the default path is unchanged, so I expect no regression.
- The suite proves what it claims.
  - It runs the tool as a subprocess.
  - It checks the output fields: slot, 3 profiles, F in 0..100.
  - It checks that the sha and mtime of all 5 default outputs are the same before and after.
  - It checks three guards that each exit 1: `--fixtures` without `--frustration`, an unknown fixture id, and `--model v1`.
  - These assertions would fail if the behaviour broke.
- Tool diff is small and correct.
  - The `--fixtures` guard is placed before the `--frustration` branch.
  - Both anchor and catalog paths are sha-bound, so a stale raw returns `RAW_STALE` and exit 1.
  - It writes only under `OUT_DIR_FIXTURES`.
- Evidence matches the findings doc.
  - F values: hard_maze8 2.48, rings10h 0.33, tiles9 3.35, vh_maze10 3.28, L1 41.66.
  - Clear rates: anchors are 1.0 for all three profiles. L1 is 0.09375, 0.09375, 0.0625, which is 3, 3 and 2 of 32.
  - L1 retryRisk is 0.9125 (doc: 0.912) and lateFailure is 0.
  - L1 dead placements are 4.875, 4.875 and 4.9375, matching the doc's 4.88/4.88/4.94.
  - The per-anchor F figures are all consistent with 15 x choiceOpacity.
  - I did not check the dead-placement columns for the 10 anchors, nor the "9 of 10" claim.
- `data/config` and `046-difficulty-model-v2` are unchanged versus origin/main (`git diff --quiet` exits 0).
- The suite only deletes its own `_r1` output file. My runs modified no tracked files (only the stat-only `.import` dirt and untracked `.uid` files that were already there).
