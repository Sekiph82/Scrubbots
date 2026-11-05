VERDICT: PASS

## Checks
- git diff --check origin/main...HEAD: pass
- tests/m43_c005_c006_standard_pack_presentation.gd: pass (28/28; exit 0; the leak warnings at exit are the usual headless noise)
- Harness SHA pin: the pinned a190fa6e... equals the sha256 of the committed blob (LF), same convention as the old pin. The CRLF working copy hashes differently, but it did before too.

## Findings
None.

## Notes
- Decoder lifecycle is correct. `_start_video` builds one player and cleans up if it fails to start. `_stop_video` is idempotent and is called from `closed`, `_end_video` (finished or tap-skip) and the failure path. The deferred `finished` signal is bound to the player and checked against `_player`, so a late signal from a freed player is ignored. The `_phase == OPENING` check also guards it.
- Tap-skip: a tap while `_player != null` goes to `_end_video`, so the flash shows and the reveal runs. In a video run, `_skip_stage` skips to `_ix_out` only, so there is no jump to a missing frame 04.
- Reduced mode never loads the video. A video that fails to start sets `video = null`, which restores the native pack and rays and runs the native plan.
- Pack contents, pity and economy are untouched. The diff is presentation only, and routing is pinned in v19.
- The test changes do not weaken real guarantees. Setting `video = null` in the c006 harness, c008, c009, c005f and master suites keeps those suites on the native path they were written to pin. The video path has its own coverage in v18..v21 and p20, including the missing-asset fallback, a mid-video close and a skip. The harness SHA re-pin matches the new source.
- Minor, not blocking: `_video_run` is never reset. That is fine because the ceremony is single-use.
- Minor, not blocking: `box.queue_free()` after `remove_child` is fine, since the box is no longer in the tree.
