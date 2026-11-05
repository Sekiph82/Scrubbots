# Review round 1, job 106 (SB-M44-028/029/030)

## Checks
- git diff --check origin/main...HEAD: clean.
- Diff is 3 files: new suite, workflow, TASKS.md. No game code or economy data changed.
- Ran tests/m44_meta_verify_achievements_gift.gd (Godot 4.7.2 headless): "M44 meta verify achievements + gift evidence: PASS (4/4 cases, 0 fail)". Only the usual exit leak warnings. project.godot restored (no tracked changes).

## Findings
None.

## Notes
- a01 pins the 50 entries by sha256 of id|metric|target|tier|reward, plus tier counts 13/12/15/10 and an all-economic check. Strong enough.
- Stats come from a fresh L1 profile with real gates (AppState.test_unlock_all asserted false). The first win goes through the real gameplay host terminal.
- Claim-once: 3 rapid taps, then a replay, relaunch of main.tscn on the same save, and snapshot import into a fresh AppState. Each is asserted on wallet, already_claimed and stats.
- The replay is a stale WON on the L2 host with progression_level forced to 1. It is a reasonable proxy for the real replay path (first-clear refused, no extra clears, wallet unchanged). It is not a true replay of the L1 board, but the builder explained why (debug_set_current_level makes request_save refuse).
- Gift Bar: visible and enabled at 0/1 on the first Home, then 1/5 after the first win. The cycle is read from economy_rewards_v1 (1/5/10/25/100/250/500/1000), GIFT 1 pays +25 SB once, and the second claim is refused.
- Saves are throw-away: the path uses user://m44_meta_verify_<tag>_<usec>.save, _cleanup removes them, and the boot overrides are reset.
- CI: the suite is in the validate loop and the exact-guard line matches the printed summary character for character. The "4/4" pattern matches the neighbouring entries, and the header comment is added.
- TASKS.md: SB-M44-029 is closed as superseded with no code, which matches its own "verify-or-retire" row text and the 2026-11-03 override.

VERDICT: PASS
