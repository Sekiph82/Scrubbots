# Review round 1: 114-asset-pixel-qa

- git show --stat: e58f4bbc touches only tool, test, doc, CSV and one workflow line; ff9ec2a2 only TASKS.md. No PNG, no .import changed.
- FAIL rows spot-checked against real PNG sizes: shell_5slot_3col 887x1774 vs drawn 1170x2340 = 0.76x; home_scrubby_still 720x1280 vs 1321x2349 = 0.55x; level_start_scrubby_still 624x640 vs 953x978 = 0.65x. CSV numbers match the files. The 9 FAIL rows are exactly the ones build.md lists. 3 WARN rows with drawn rects re-read from the PNGs match the CSV source sizes.
- Test run: after a full --import, `ui_vis_006_asset_qa.gd` prints "UI-VIS-006 ASSET QA: PASS", exit 0, no SCRIPT ERROR, 9 known rows. Runs in about 2 s of script time, reads only the CSV, .import files and PNG headers; no main.tscn boot, no measure run in CI. (Without a prior import it FAILs on missing .import for untracked defaults; the workflow imports before the suite loop, line 105, so CI is fine.)
- Regression power: the test asserts the four import params on every PNG row and recomputes imported size (size_limit applied) against the drawn rect, so a lowered size_limit or a smaller PNG fails; known FAIL rows have a floor at their recorded ratio. Reading the code agrees with the builder's negative check.
- CI entry: appended to the suite list; the shared loop enforces exit 0, zero diag lines and a PASS last line. The test prints a final PASS/FAIL line. Other ordinary suites have no exact-count guard (only the special CP06/M44/etc.), so none is expected here.
- Owner-visual items are listed as pending, not claimed.

Minor (not blocking): the test depends on .import files existing, which holds in CI after import.

VERDICT: PASS
