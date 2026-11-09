# Review 142-cloud-save-seam, round 2

## Checks
- git diff --check: pass
- m54_cloud_save_seam: pass (7/7)
- m57_ads_cadence: pass (6/6)
- m60_release_gates: pass (6/6). The "FAIL SB-M60-006" line is the computed gate status, not a test failure.
- The workflow YAML parses.
- The worktree is restored and clean.

## Round-1 finding
Fixed.
- `_apply_remote` is the single path for both the auto-applied proven descendant and KEEP_CLOUD. It restores a copy of the cloud envelope with `clock_high_water = max(pre mark, cloud mark)`.
- Non-numeric values are passed through unchanged, so M40 validation still rejects them.
- The new c05 `_anti_rollback` check uses a rolled-back clock and a cloud copy with a lower mark (t+10 against the late mark). It covers both paths and asserts that the mark is not lowered and that the expired timed 2x stays expired.
- The `.bak` wording is softened in the service header.

## Rebase merge
- CI: the m57_ads_cadence guard (6/6) and the m54_cloud_save_seam guard (7/7) are each closed with their own `fi`. Both suites are in the validate list, and the aggregate line follows.
- PRIVACY_DATA_INVENTORY: the new sync-file row and the §7.5 header text are present, and the device-id wording is correct.

## Findings
None.

VERDICT: PASS
