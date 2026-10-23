VERDICT: PASS

## Findings
None.

## Notes
- The diff has no *.png files. It changes 8 non-.import files: TASKS.md, docs/07, the measure tool, the budget test and 4 coordination files. The other 47 changes are .import files.
- 45 .import files are new, each adding only process/size_limit and no other line. Two tracked .import files change 512 to 1024 (master_collection_emblem, gift_meter_reward_crate), which is the intended raise. Nothing is lowered. In the new .import files, compress/mode=0 and mipmaps/generate=false are unchanged.
- The budget test diff removes only the old BUDGET_MIB line, the two 512 entries and the `_limited(...)` call, which are replaced by the 1024 values and the new lists. The TASKS.md diff is two lines, both for SB-M22-026: the queue row and the entry.
- I checked every non-zero size_limit in the tree (240 files) against measure_merged.json. Only two fall under 2x the measured side, and neither is a new or lowered cap.
  - scrubby_portrait: 512 against a measured 880. The 880 is the width of the 880x220 hero rect, and the keep-aspect art draws at about 220 px, which gives 2.3x. build.md and the ADR say the same.
  - daily_login_calendar: 1024 against a measured 880. This cap predates this branch (step 1) and the branch does not touch it. It is probably the same rect-width overstatement. Optional follow-up, not blocking.
- The measure fixtures use throw-away saves and build ceremony, pack and coachmark popups from fixture events, so no economy items are granted. build.md reports the real save sha256 unchanged before and after.
- TASKS.md and the ADR match the evidence in build.md. The status stays READY and VRAM compression and atlasing are still listed as open, so no overclaim. No locked rules are touched: no new mechanics, currencies or ads, and no owner art changed.
- I did not re-run Godot, so the LOCAL_PASS suite results are taken from build.md.
