VERDICT: PASS

## Findings
None.

## Notes
- Reproduced locally (0 SCRIPT ERROR / Parse Error in each log, apart from the usual "resources still in use at exit" line):
  - campaign_l11_l30: `CAMPAIGN L11-L30 evidence: PASS (5/5 cases, 0 fail)`
  - m52_owner_supply_plans: `M52 OWNER SUPPLY PLANS: PASS`
- CI run 41192324690 log shows:
  - `m55_long_session exit=0 script_diag=0 status=PASS | M55 LONG SESSION: PASS`
  - `campaign_l11_l30 exit=0 script_diag=0 status=PASS | CAMPAIGN L11-L30 evidence: PASS (5/5 cases, 0 fail)`
  - `real_play_levels exit=0 script_diag=0 status=PASS | REAL PLAY LEVELS: PASS (5/5 cases, 0 fail)`
  - `REAL-PLAY-LEVELS verdict=PASS (5/5)`
- tests/real_play_levels.gd would fail if the behaviour broke:
  - `levels` asserts WON, ACTIVE 0, supply exhausted, slots empty, no rejected click and all clicks placed, for every catalog level.
  - `search_negative` is the negative control. The old L22 clicks must be stuck and not won, and the search must reach SOLVED, be robust at all three dts, and differ from the old clicks.
  - `determinism` compares the L22 cleared sequence, its hash and the frame count across two runs.
  - `provenance` checks the plan sha, status, model, verified dts, the clicks and the regenerated flag.
  - The `EXPECTED_CASES` guard fails the suite if a case does not complete.
  - The CI workflow also requires the exact `5/5` summary line.
- Weakening check:
  - tests/campaign_l11_l30.gd no longer replays plans through ProofKernel. It now checks that clicks are legal and consume every batch, and that the Studio SOLVED and replay WIN evidence is present. Real-play WON is asserted in the new suite instead. The change is documented in the test header and is justified, because a regenerated plan need not be kernel-legal. This is a relocation of the check, not a skip.
  - tests/m52_owner_supply_plans.gd and tests/m55_long_session.gd now drive the plans through RealPlayDriver, which is stricter because it plays at runtime pacing. They keep the won, ACTIVE 0, supply exhausted and no-rejects assertions.
- Non-blocking: fps_sensitivity at 1/30 and 1/120 covers only a subset of levels in CI (the regenerated ones plus L18 and L20). The other levels' three-dt WON is recorded in provenance but is not re-checked in CI. The suite header says so.
