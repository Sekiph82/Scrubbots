STATUS: READY

# Build: 106-meta-verify-achievements-gift (SB-M44-028 + SB-M44-029 + SB-M44-030)

## Summary
These were verify tasks. Nothing was broken, so no game code changed. The branch adds one permanent regression suite, wires it into CI and updates TASKS.md.
- `tests/m44_meta_verify_achievements_gift.gd` (new, 4 cases, real main.tscn, no `test_unlock_all`, throw-away saves, injected clock/day)
- `.github/workflows/android-family-first10.yml`: suite added to the validate loop with an exact 4/4 summary guard
- `TASKS.md`: three queue rows DONE, three checklist rows [x]

Commits: 676d00b2 (test + CI), 7731c4ef (TASKS.md).

## Acceptance criteria
1. [x] SB-M44-028, all 50 achievements intact. Case a01 checks exactly 50 entries, tiers 13/12/15/10, and an sha256 fingerprint of every id|metric|target|tier|reward pinned to `eaf4e947...e47e`. Every reward is economic. `git log` on achievements_v2.json shows only 1bcf726c (SB-POLISH-007), so the pin is the shipped table.
2. [x] SB-M44-028, stats from L1. Case a02: a fresh L1 profile starts with every stat at 0 (robots_unlocked 1 = the starter robot) and nothing claimable. Case a03: the first L1 win through the real gameplay host terminal gives levels_completed 1 and best streak 1. Clean Start and No Help Needed become claimable and the badge shows 2.
3. [x] SB-M44-028, Achievements UI at L1. Case a02: Profile -> ACHIEVEMENTS opens at L1 under the real gates and shows the Ach_clean_start card.
4. [x] SB-M44-028, CLAIM exactly once. Case a04: 3 CLAIM taps give exactly +100 SB under tx achievement:clean_start. After a stale replay WON of L1 (L2 host, progression_level 1), the first-clear result is not ok, clears stay at 1, the claim is refused and the wallet is unchanged. After saving and relaunching main.tscn on the same save, the claim is refused with already_claimed. After importing the economy + progression snapshot into a fresh profile, the wallet is the same, the claim is refused and stats are kept.
5. [x] SB-M44-029 closed as superseded, no code. The row itself says "verify-or-retire, never change live achievement rewards without separate owner decision". The SB-POLISH-007 economic rewards stay, as the 2026-11-03 override on SB-M44-028 requires.
6. [x] SB-M44-030, Gift Bar from the first Home with the schema-3 cycle. Case a02: the config milestones are [1,5,10,25,100,250,500,1000] and GIFT 1 = 25 SB. On the first Home, GiftMeterButton is visible and enabled, the caption reads "0/1" and the next milestone is 1. Case a03: after the first L1 win the caption reads "1/5", gift_ms:c0:m1 is queued, the gift_bar badge shows 1, the claim gives +25 SB once and a second claim is refused. No quantities changed.

## Validation
All runs were LOCAL_PASS on Godot 4.7.2 headless. Each exited 0, printed 0 SCRIPT ERROR / Parse Error lines, and its last line said PASS.
- m44_meta_verify_achievements_gift: PASS (4/4 cases, 0 fail)
- sb_polish_002_gift_meter: PASS (11/11)
- m43_master_c010_meta: PASS (12/12)
- m44_meta_l1_unlock_ftue: PASS (6/6)
- m43_master_c005r_gift_micro_progress: PASS (8/8)
- m43_master_c009_daily: PASS (12/12)
- `git diff --check` on the workflow: clean.

Not run: CI, phone build.

Tree state: tracked files are clean, and the `--import` churn on .import files and project.godot was restored from HEAD. About 1166 untracked Godot-generated `.uid` / `.import` / `.translation` files from `--import` are still in the worktree, because `git clean` was denied by permissions. They are not committed and go away when the worktree is deleted.

## Log
### Round 1
I read the three rows, achievements.gd, achievements_v2.json, the gift meter service/config and the existing suites. m43_master_c010 m04 already covered the relaunch case, but it runs with test_unlock_all, accepts any count from 40 to 50, and had no snapshot-import, replay or first-Home Gift Bar check. I wrote the new suite to cover those gaps. Its first run had wrong expectations (the starter robot counts 1, the first win also makes No Help Needed claimable, and a debug_set_current_level replay makes request_save refuse). I fixed the test, not the code: the replay is now a stale-level WON on the frontier host. No product bug was found.
