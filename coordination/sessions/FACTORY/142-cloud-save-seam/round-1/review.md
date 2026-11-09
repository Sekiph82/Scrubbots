# Review 142-cloud-save-seam, round 1

## Checks
- git diff --check: pass
- m54_cloud_save_seam: pass (7/7)
- m40_save_system, m40_v02_safety, m40_v04_bootstrap: pass
- m57_store_products: pass (9/9)
- m58_privacy_inventory: pass (7/7)
- m60_release_gates: pass (6/6). The "FAIL SB-M60-006" line is the computed gate status, not a test failure.
- m51_localization_readiness: pass (8/8)
- Worktree restored with `git checkout -- .`. Untracked import files removed. `git status` is clean.

## Answers to the review points
1. Auto-apply of a newer cloud copy is strict.
   - `CloudSave.resolve` requires a superset of the history, a higher revision, and the other side's exact authority fingerprint in the descendant's lineage. No timestamps decide it.
   - `_local_envelope` reuses the last synced header only when the local fingerprint equals `_last.fp`.
   - A local change since the last sync gets a new revision and a new fingerprint. The cloud copy's lineage does not contain that fingerprint, so the result is CONFLICT (`no_ancestry_proof` / `order_contradiction`). Local progress cannot be lost this way.
   - The only local data that can be replaced silently are device settings, `meta_ui` and the clock fields. These are outside the authority and are replaced with the cloud copy's values. The old save is `.bak` only until the next save rotates it (see Notes).
2. The authority fix excludes exactly `hearts.anchor` and `speed.clock_high_water`. It affects `authority()` only. `collect()` and the payload are unchanged. See finding 1 on the anti-rollback bypass.
3. Idempotent tx ids: a restore replaces the whole payload, including the applied set and `store:<token>` ids. m54 c04 covers store re-delivery, reward replay, the Daily claim and a repeated restore. No double grant.
4. Failure paths: read, write, refusal, garbage and future-schema copies never touch the local save, and a failed restore is rolled back (`_apply` restores exactly; `_save._apply(pre)` after a failed save). Verified by the code and by c05.
5. The conflict screen uses native Controls and a BasePopup. Both choices go through a warning `Popups.confirm`, and only the confirm calls `choose()`. Cancel re-arms. main.gd opens it only from `conflict_found` and guards against duplicates. Fit at 720x1280 and 1170x2532 (EN and TR) is covered by c06.
6. The Settings line is read-only.
7. Docs:
   - The privacy inventory covers the device id (random, not hardware) and the sync file.
   - The TASKS DONE/PARTIAL split is honest: 153 stays open, 160 and SB-M54-031 are PARTIAL.
   - The SB-M43-170 row matches the regenerated gates.
8. The CI append is append-only, with the exact 7/7 guard.

## Findings
1. scripts/save/cloud_save_service.gd:203-216 (`_apply_remote`). A restore can reset the 2x anti-rollback mark, so the claim that the clock mark semantics are kept does not hold.
   - `SpeedEntitlementService.import_snapshot` sets `_clock_high_water` to the cloud copy's value, then maxes it with the current wall clock. The local mark is dropped.
   - Because `clock_high_water` is now outside the authority, a cloud copy with an older mark still counts as a proven descendant. It is applied silently.
   - Exploit: a device whose clock was rolled back (mark in the future, timed 2x correctly expired), plus a synced cloud copy with the same `timed_expiry`. The sync resets the mark to the rolled-back "now", and the timed 2x becomes active again.
   - Fix: before `CloudSave.restore`, build the candidate copy with `economy.speed.clock_high_water = max(local mark, remote mark)`. The local mark is in `pre` (`pre["economy"]["speed"]`). Pass the adjusted copy to `restore`, and mark the original envelope or the adjusted one consistently.
   - Add a check to m54 for this: local mark > cloud mark, then restore, then the mark is >= the local mark and the timed 2x stays expired. The current suite never exercises `clock_high_water`.

## Notes
- The `.bak` that holds the previous local save is overwritten by the next normal save, so "old local save stays as .bak" is short-lived. It is acceptable because auto-apply only happens when the progress is provably identical, but the wording in the docs should not promise more than that.
- The sync file write in `_mark` ignores a failed `FileAccess.open`. The failure only leads to a later conflict, which is safe.
- Hearts regenerated while idle produce a conflict. This is a safe ceiling and it is marked `ponytail:`.

VERDICT: CHANGES

Must-fix:
1. Preserve the local `clock_high_water` (take the max) when restoring a cloud copy, and add an m54 assertion for it (finding 1).
