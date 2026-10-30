STATUS: READY

# Build: M43 verify sweep (R09, 122-130/134, R10, 143-151, R12, 163-170, C005F-015)

## Summary
Branch `factory/065-m43-verify-sweep` (commits ab035410, 65e21668, 7cab6625):
- `.github/workflows/android-family-first10.yml`: `m43_master_c010_meta` and `m43_master_c011_c014` are in the validate loop (58 suites), with exact `grep -qxF` guards for 12/12 and 28/28 and a new header comment line.
- `tests/m43_master_c010_meta.gd` m07: SB-M43-151 assertions. A positive control (an active event ending within 24 h with a claimable reward gives an `event_ending` candidate), and an expired event that is still claimable (claim_after_end) never gives `event_ending`. No new case, so the count stays 12/12.
- `tests/m43_master_c011_c014.gd` n02: SB-M43-151 assertion. With notifications disabled while live candidates exist, nothing is decided and `last_sent` stays 0. The count stays 28/28.
- `TASKS.md`: 28 rows ticked with LOCAL_PASS evidence. The 15 open rows have gap notes. The queue rows are rewritten as 1 DONE row plus 16 READY rows, one per open ID (15 SB-M43 IDs plus C005F-015). The committed blob keeps LF line endings (0 CRLF, 1989 LF).
No production code, config or art changed.

## Spot-check reclassification (suite source read before ticking)
Closed (VERIFY-CLOSE): R09-001..005, 123, 124, 126, 128, 129, R10-001..007, 144, 145, 147, 148, 149, 151, R12-002, R12-004, R12-006, 163, 164.
The spec listed these as VERIFY-CLOSE, but they move to open because the requirement text is not asserted:
- 122: RANKS is a disabled "coming later" tab (m01), but the row says "RANKS real, no dead tab".
- 134: no case asserts a non-zero Event active/reward badge (m10 only reaches 0). The owner note in TASKS also says broad 134 stays OPEN.
- 143: c02 asserts only the Hearts and Daily summary lines. The Gift/Tasks/Events lines are implemented in `profile_screens.gd` but not asserted.
- 165: a04 only checks that copy keys exist. Retry affordances for Shop/ads/cloud/Ranks are not asserted.
- 166: there is no rankings empty state (Ranks is not live). The no-duplicates and no-tasks empty states exist only as copy keys.
- R12-003: uninstall/reinstall farming and catch-up expiry within `catchup_expire_days` are not asserted. c01/c04 cover clock rollback, relaunch and resume.
R12-006: n03 asserts the factual copy (no "miss"/"lose"/"last chance") and that `event_ending` needs a real claimable reward, so no assertion was added.
169: the assertion was NOT added because it fails against the shipped files. Manifest ids are named differently from the registry ids. These 19 registry ids are missing from the manifest: home, gameplay, results, collection, collection_set, robots, events, settings, friends, life, speed_acquire, reward, confirm, pack_open, world_unlock, error, loading, account_conflict, comeback. The manifest also has no Rewarded Ads surface (TASKS C015 list item 39). 169 stays open; the manifest was not edited.
Still open as the spec says: 125, 127, 130, 146, 150, 168, 170, R12-001, C005F-015 (R09-006 was already a separate READY row and is untouched).

## Acceptance criteria
1. [x] c010 prints `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`: run_suites status=PASS exit=0 diag=0, and the new 151 ok-lines are printed.
2. [x] c011 prints `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)`: run_suites status=PASS exit=0 diag=0.
3. [x] The workflow loop lists 58 suites (`python tools/run_suites.py --list | wc -l` = 58, last two are c010 and c011). Both `grep -qxF` guards are present.
4. [x] `git diff --check` is clean. No tracked `.import`/`.uid` changes; Godot left only untracked noise, which is not committed. The tree is clean apart from untracked files.
5. [x] Each ticked TASKS row names the suite path, the exact summary line and its cases. BUILD rows 125, 127, 130, 146, 150, 168, 170, plus R12-001, C005F-015 and the reclassified rows, are unticked and have `[OPEN ... factory 065 audit gap: ...]` notes.

## Validation
- `python tools/run_suites.py` (all 58, Godot 4.7.2 console): 57 PASS. `m46_performance` FAIL, timing only under local load: `retry() on 59x59 worst 63.70 ms (<= 50.1)` and CPU frame p99/max. m46 is not touched by this job, and the CI known-issue note applies. A second bogus entry came from a literal `\n` in my first loop edit; 65e21668 fixed it, and `--list` now gives 58 clean names.
- Rerun `python tools/run_suites.py m43_master_c010_meta m43_master_c011_c014 m46_performance`: c010 PASS, c011 PASS, m46 FAIL (same timing only).
- `python tools/run_suites.py --selftest`: PASS.
- `git diff --check`: clean.

## Log
### Round 2 (review round-1, commit 2029e87f)
- **Finding 1, R10-002 over-claimed: fixed.** c010 m06 now replays cleared level 1 to a committed WON. The host reports progression_level 1, the terminal is latched and FirstClearTransaction returns `not_frontier`, yet weekly progress stays 2. A source-scan assertion also shows that `event_service.gd` has no rewarded/purchase/debit/wallet/shop input. The R10-002 evidence text now names these checks.
- **Finding 2, 163 over-claimed: fixed.** c011 a02 now checks two more settings. With Master OFF and SFX ON, the meta moment is silent at once. With Music OFF, meta SFX still plays and the voice is not on the Music bus, because meta UI has no music path. The a02 title and the 163 evidence text say this.
- **Note R09-004: fixed.** The citation is now t03 (a LOST terminal counts nothing) and t11 (grind bound, max 3 wins).
- **Notes R10-005, R10-007, 124, 151, R12-004, R12-006, R12-002: not changed.** They are non-blocking, and tightening them is not trivial.
- Case counts are unchanged (12/12, 28/28), so the CI guards are unchanged.
- **Reruns:** c010 `M43 master C010 meta evidence: PASS (12/12 cases, 0 fail)`, c011 `M43 master C011-C014 evidence: PASS (28/28 cases, 0 fail)`. Both exit 0 with no SCRIPT ERROR or Parse Error.
- `git diff --check` is clean. The TASKS.md blob still has LF line endings (0 CRLF, 1989 LF).

### Round 0
Ran the spot-checks, added the 151 assertions (c010 m07, c011 n02), added the two suites and their guards to CI, and fixed the loop continuation. Moved 122/134/143/165/166/R12-003 to open after reading the suite source. Left 169 open with the missing ids listed. Edited TASKS.md through a byte-level script that keeps line endings.

## CI (orchestrator)
GitHub Actions run 41047221613 (job branch head 2029e87f, validation_only): success. m46_performance PASS 22/22; m43_master_c010_meta PASS 12/12; m43_master_c011_c014 PASS 28/28; all exact verdict guards PASS. Earlier run 41046082736 on the round-1 head was cancelled (superseded). Remote branch deleted.
