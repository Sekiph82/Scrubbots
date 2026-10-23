VERDICT: PASS

## Findings
None.

## Notes
Suites re-run by me headless (all exit 0, 0 SCRIPT ERROR/Parse Error; the "resources still in use" lines are normal exit noise):
- m44_unlock_gate: `M44 unlock gate evidence: PASS (6/6 cases, 0 fail)`
- m44_ftue: `M44 FTUE evidence: PASS (23/23 cases, 0 fail)`
- m42_home: `M42 home evidence: PASS`
- m39c_boosters: `M39 Phase C evidence: PASS`
- m46_performance not run, as instructed.

Level walk (tests/m44_unlock_gate.gd:75-96): one fresh bootstrapped profile, advanced only via `progression.record_win(current_level())`, no `debug_set_current_level`. WALK = 1,3,4,5,6,8,11,12,16,20,21,25,30,35,39,40. At each step it asserts the whole 15-feature dictionary `got == want` (want = `frontier >= table level`), so the exact locked set is checked. Boundaries L3/L4, L5/L6, L11/L12 and L39/L40 are covered. It also checks relaunch at L40 stays new-profile and unlocked. The expected table is a separate OWNER_TABLE constant, so the check is not circular.

Edits to m44_ftue and m46_*: the `_unlock_at_l1` hook only sets entries in the in-memory `app.unlocks.cfg`. In m44_ftue each use is preceded by a new assertion of the locked fresh-L1/L2 behaviour (t12, t14, t15). The original assertions are kept after the hook, and no economy or charge assertion was weakened. The retired-policy assertion in t11 replaces the dropped "hard lock policy" mutation. t13 uses the hook only so "no tips at L4+" is not masked by locks. The m46 edits (rm003, r07, rm002) open boosters before the L2 coach boot so those suites still measure the coach. They would hide a gating regression only for those suites, and m44_unlock_gate's booster_gating and ftue_director cases cover real gating on the shipped table.

Minor: those three m46 suites no longer exercise the shipped locked state, which is acceptable here.
