STATUS: READY

# Build: cloud save seam (SB-M43-152..160 provider-independent, SB-M49-030, SB-M54-031 mock)

## Summary
The branch adds a provider-neutral cloud-save layer on top of the existing CloudSave envelope/resolve rules (M43-C013) and the M40 save. It follows the factory 138 store_provider/store_service pattern. The shipping default is the null provider: the player stays signed out and nothing is read or written. There is no SDK and no network.

- `scripts/save/cloud_provider.gd` (new): the seam (`is_available`, `is_signed_in`, `sign_in`, `read`, `write`). The base class is the null provider.
- `scripts/save/cloud_save_service.gd` (new): CloudSaveService.
  - States: signed_out, syncing, synced, conflict, error and offline.
  - Upload: the whole M40 save goes up as a CloudSave envelope (header: schema `scrubbots.cloud.v1`, revision, a random 128-bit install `device` id, saved_at and lineage).
  - Resolve (via `CloudSave.resolve`):
    - equal: synced, nothing is written;
    - local ahead: upload;
    - proven descendant (built on exactly this device's last synced state): the whole copy replaces the local save. Its progress is provably contained in the copy; the M40 `.bak` holds the replaced save only until the next save. The restore keeps max(local, cloud) 2x anti-rollback clock mark;
    - anything else: CONFLICT, which waits for `choose(KEEP_DEVICE | KEEP_CLOUD)`. Copies are never merged.
  - KEEP_DEVICE uploads a copy built on the cloud copy it replaces. KEEP_CLOUD restores the whole cloud copy through the M40 rules, also keeping max(local, cloud) 2x clock mark.
  - Failures never touch the local save: read/write failure, provider refusal, an invalid or future-schema cloud copy, and a restore whose save fails (that restore is rolled back exactly).
  - Bookkeeping lives in `user://cloud_sync_v1.json`: the device id plus the last synced header and fingerprint, no save content. It is written only after a successful sync.
- `scripts/save/cloud_save.gd`:
  - `summary()` now also returns `scrub_bucks` and `robots`.
  - `authority()` now leaves out the wall-clock bookkeeping `economy.hearts.anchor` and `economy.speed.clock_high_water` (new `CLOCK_FIELDS`). Both move with time alone: with them in, an untouched device never matched its last synced state, so every later sync became a false conflict.
- `scripts/app/app_state.gd`: `cloud` (CloudSaveService) is wired with `request_save`. The sync file is `user://cloud_sync_v1.json`; test saves use `<save>_cloud.json`.
- `scripts/ui/cloud_conflict_screen.gd` (new): the `account_conflict` popup.
  - Two cards (THIS DEVICE / CLOUD), each showing level, Scrub Bucks, robots and last played.
  - Two buttons: KEEP THIS DEVICE and KEEP CLOUD. Each opens a warning `Popups.confirm` (REPLACE). Cancel re-arms the choice; only CONFIRM calls `choose()`.
- `scripts/app/main.gd`: `conflict_found` opens the screen (`open_cloud_conflict`). This only fires with a real provider.
- `scripts/ui/settings_panel.gd`: a read-only `CloudStatus` line, "CLOUD SAVE: NOT AVAILABLE" with the null provider and the live state with a provider.
- `scripts/ui/ui_text.gd`, `scripts/ui/ui_text_tr.gd`: 23 new CLOUD_* / SETTINGS_CLOUD keys in EN and TR. No Hearts copy is involved.
- `tests/m54_cloud_save_seam.gd` (new; 7 cases, MockProvider).
- `.github/workflows/android-family-first10.yml`: suite appended to the validate list, with the exact `M54 cloud save seam: PASS (7/7 cases, 0 fail)` guard (append-only).
- `assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json`: account_cloud_sync_conflict now names the scene and evidence suite, with `live_data` false and the gap "no cloud provider yet". `tests/m49_surface_matrix.gd`: that row's text changes from NOT_BUILT to NOT_LIVE.
- `docs/RELEASE_GATES.json/.md`: regenerated with `-- --write`. Closure lists now show "not built: friends_postlaunch" and "built but not live: account_cloud_sync_conflict".
- `docs/PRIVACY_DATA_INVENTORY.md`: new `user://cloud_sync_v1.json` row, and §7.5 describes the header fields (random install id, not a hardware or ad id).
- `TASKS.md`: the task rows (see below).

Commits (rebased onto origin/main c9e7c7e8): 2a0ecfbf (service), 88cdca52 (UI), 55e120ce (tests/CI/docs), a209953b (TASKS.md), 408df9db (round 2: 2x mark fix + m54 assert), 4f25be0c (TASKS hashes).

## Acceptance criteria
1. [x] Cloud provider seam with a null/mock default, no SDK and no network: `cloud_provider.gd`, where the null provider is the default. Evidence is m54 c01: unavailable, `sync()` gives signed_out, `sign_in()` gives unavailable, no sync file is written, the local save is untouched, and there are no network/SDK tokens in the three cloud scripts.
2. [x] CloudSaveService wraps the local save with a schema plus device/timestamp header (m54 c02):
   - header schema `scrubbots.cloud.v1`, revision 1, saved_at equal to the clock, and a 32-hex random device id;
   - payload fingerprint equals `save.collect()`, and the copy validates through an M40 dry run;
   - a new device restores it byte-identical, and a relaunch reads it back;
   - an equal re-sync writes nothing;
   - local ahead uploads revision 2 with lineage proving revision 1;
   - an unchanged device takes the proven descendant without writing.
3. [x] States signed_out / syncing / synced / conflict / error / offline: c01 (signed_out), c02/c03 (synced, conflict), c05 (offline and error per failure), c07 (Settings shows NOT AVAILABLE, SYNCED and OFFLINE).
4. [x] Conflicts are resolved only by explicit choice and never merged (m54 c03):
   - diverged copies give CONFLICT with both summaries (level, scrub_bucks, robots, saved_at match the live values), and nothing changes on either side while waiting;
   - an unknown choice is refused;
   - KEEP_DEVICE leaves the device save untouched. The cloud gets this device's whole save as revision 3, built on the replaced copy. The other device, which holds progress the chosen copy lacks, gets its own CONFLICT instead of a silent overwrite;
   - KEEP_CLOUD leaves the cloud untouched. The device becomes the whole cloud copy (its device-only tx is gone), and the replaced save is the M40 `.bak`;
   - `choose()` without a conflict is refused.
5. [x] Idempotent transaction ids preserved (m54 c04): after a restore, a StoreService re-delivery of `store:tok-1` is a duplicate with no SB. A reward replay is refused, the Daily claim is not repeatable, and restoring the same copy again does not add to the balance.
6. [x] Error or offline never touches the local save (m54 c05). Each of these leaves the local file bytes, the live authority and the cloud copy unchanged:
   - read offline and read error;
   - provider refusal;
   - write offline and write error;
   - a garbage cloud copy and a future-schema cloud copy.

   A proven-descendant restore whose save fails (fault injector) gives ERROR `save:temp_write_failed` and an exact rollback, and the retry succeeds. Round 2: with a rolled-back clock, a restore (auto descendant and KEEP_CLOUD) keeps the local 2x anti-rollback mark and an expired timed 2x stays expired.
7. [x] Conflict screen with native Controls fits 720x1280 and 1170x2532 (m54 c06, EN and TR; logical 1215x2160 and 1080x2337 as in m49_responsive_matrix):
   - the frame is inside the screen and `text_fits()`;
   - both actions are at least 88 px, inside the frame and not overlapping;
   - both sides' labels equal the keyed copy of the summary values;
   - KEEP CLOUD opens the warning-frame confirm, which also fits;
   - cancel re-arms the choice with nothing changed; confirm commits KEEP_CLOUD and closes the stack.
8. [x] UiText keys in EN and TR: m51_localization_readiness 8/8 (l05 TR parity and placeholders, l08 no hard-coded text).
9. [x] Settings account/cloud status row: c07 shows the line inside the frame and the frame fits 1080x1920. m58_privacy_consent p02 (Settings fits, card order unchanged), m41_settings, m50_accessibility_audit and m49_responsive_matrix all still pass.
10. [x] CI: the suite is appended to the validate list with an exact 7/7 PASS guard.
11. [x] Privacy inventory updated: m58_privacy_inventory 7/7, which includes the new `user://cloud_sync_v1.json` path.

## Validation
All results are LOCAL_PASS (Godot 4.7.2 console, headless, worktree, throw-away user:// saves). There were zero SCRIPT ERROR / Parse Error lines in every log, and every final line was PASS.
- tests/m54_cloud_save_seam.gd: PASS (7/7 cases, 0 fail), about 5 s
- m40_save_system PASS, m40_v02_safety PASS, m40_v03_canonical PASS, m40_v04_bootstrap PASS
- m43_master_c011_c014 PASS (29/29), the existing CloudSave conflict matrix, still green after the authority change
- m54_regression_pack_028_036 PASS (12/12), m54_world_regression PASS (7/7)
- m58_privacy_inventory PASS (7/7), m58_privacy_consent PASS (7/7)
- m51_localization_readiness PASS (8/8)
- m41_settings PASS, m59_credits PASS (3/3), m50_accessibility_audit PASS (11/11), m49_responsive_matrix PASS (8/8)
- m60_release_gates: the first run was FAIL (1 fail). That was only SB-M60-006: the closure lists changed because account_cloud_sync_conflict moved from not built to not live. I re-ran with `-- --write`, and the re-run is PASS (6/6). The regenerated RELEASE_GATES.* are committed.
- `git diff --check` is clean.
- Cleanup: I ran `--import` once, then `git checkout -- .` after committing, and deleted only the untracked import artifacts (.import / .uid / .translation). The tree is clean (`git status --porcelain` is empty). I also removed the debug throw-away saves.

## Log
### Round 1
- Built the seam, service, conflict screen, Settings line, keys, test, CI guard and doc updates listed above.
- Finding while testing: `CloudSave.authority` included the full-Hearts regen anchor (re-stamped to now on every read) and the 2x clock high-water mark. So an idle device's authority changed every second, and every second sync became a conflict ("same_history_economy_differs" or "order_contradiction"). Both fields are now in `CLOCK_FIELDS`, excluded from authority only (payloads are unchanged). Known ceiling, marked `ponytail:` in the code: a Heart regenerated while idle still changes authority, which leads to an explicit conflict (safe).
- Design note for review: a cloud copy that is a proven descendant of this device's last synced state is applied without a prompt. It is the same player's newer progress, the lineage proves it was built on exactly this device's state (the M40 `.bak` holds the replaced save only until the next save). Every other case, including a fresh device against existing cloud progress, waits for the explicit choice plus confirm.
- TASKS.md:
  - Queue: DONE SB-M43-152/154/156..159 (provider-independent) and DONE SB-M49-030.
  - Queue: READY SB-M43-153/160 for the Play Games Saved Games / Game Center + iCloud plugins, the sync trigger, and sign-out / delete-cloud-save.
  - Queue: READY SB-M54-031, with the mock part done and a re-run due with the real providers.
  - The SB-M43-170 row's not built / not live wording now matches the regenerated gates.
  - Detail lines: [x] 152, 154, 156, 157, 158, 159 and SB-M49-030; 153 has an OPEN note; 160 and SB-M54-031 are PARTIAL.
- Not pushed (per job instructions).

### Round 2
Review round-1 VERDICT: CHANGES.
- Must-fix 1 (restore could lower the 2x anti-rollback mark): `_apply_remote` now restores a copy whose `economy.speed.clock_high_water` is max(this device's mark from `pre`, the cloud copy's mark). It is the one apply path, so it covers both auto-apply and KEEP_CLOUD. New m54 c05 assertions (`_anti_rollback`): device A buys timed 2x, the clock runs past expiry (mark high), then rolls back before expiry. A proven-descendant copy with a lower mark is auto-applied, and a fresh device chooses KEEP_CLOUD. In both, the mark stays >= the late mark and `timed_seconds_remaining() == 0`. Without the fix these two assertions FAIL (verified by temporarily reverting the restore argument: mark 1790000640 < 1790002440). Case count is unchanged (7/7), so the CI guard is unchanged.
- Note (.bak wording): softened in the service header comment, TASKS SB-M43-157 and this build.md. The `.bak` holds the replaced save only until the next save.
- Rebased onto origin/main c9e7c7e8. CI conflicts resolved keeping both: the m57_ads_cadence comment, suite and guard plus the m54_cloud_save_seam ones, each guard closed with its own `fi`. The privacy inventory kept origin's save row (ad cadence fields) plus the new cloud_sync_v1 row. TASKS rebased without conflict; hashes updated to the rebased SHAs.
- Re-run after the rebase (LOCAL_PASS, 0 SCRIPT ERROR): m54_cloud_save_seam PASS (7/7), m60_release_gates PASS (6/6, no drift hint, so no `--write` needed), m58_privacy_inventory PASS (7/7), m43_master_c011_c014 PASS (29/29).
- Import artifacts restored and untracked import files deleted; the tree is clean. Not pushed.
