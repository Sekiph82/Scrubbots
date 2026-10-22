APPROVE

## Why
Three of the four unbound booster state arts are now bound to existing events only. The tutorial pointer is deliberately left unbound and documented. All four round-1 reviews are PASS with no real problems, and merge-tree reports no conflicts.

## Acceptance criteria
1. New suite m22_023_booster_state_art: met. The code reviewer re-ran it and got PASS. It asserts node state: textures, child order, badge-frame visibility, glow on a charge increase only, burst on one button only, and 4 children in BoosterRow.
2. m22_025_booster_texture_budget still passes: met. The tests reviewer re-ran it and got PASS; build.md reports 9.43 MiB.
3. Host hook only in the ok path: met. I grepped the host and found a single call, at line 1116, in execute_booster. Build.md says it sits inside the ok-and-valid-screen guard.
4. Existing booster and gameplay suites pass: met. The tests reviewer re-ran m28_c002_c001_gameplay_v02 and m39c_boosters and both passed. Build.md lists further LOCAL_PASS suites.
5. grep for booster_tutorial_pointer in scripts, scenes and tests returns nothing: met. I ran it myself (rc=1). The TASKS.md entry documents why the pointer is not bound.
6. git diff --check clean: met per build.md and the rules reviewer.

## Notes
Direct-tap +1 Slot and Random show no burst, as the spec requires. A rapid double flash can cut the second fade short. Both are cosmetic and non-blocking.
