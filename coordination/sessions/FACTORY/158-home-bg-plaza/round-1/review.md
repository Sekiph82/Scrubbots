VERDICT: PASS

## Checks
- SHA-256 of the new PNG and owner_home_background_plaza.png: both 0aa7463b...9cde3, so it is a byte-copy.
- Manifest HOME-124 approved_sha256 matches that hash. The diff touches no old image or video files. Only notes were edited for HOME-121 and HOME-123.
- git diff --check: clean.
- m42_home_v04.gd headless: `18/18 cases, 0 failures`. The historical-assets check reports all 55 APPROVED entries matching their pinned SHA.

## Findings
None.

## Notes
- HOME-121 and HOME-123 are marked OWNER_RETIRED with no bound nodes. Home calls set_video with an empty set, so no still or video can cover WorldBackground. WorldStill and WorldVideo remain as unbound nodes.
- The area label uses only the UiText keys HOME_AREA_TITLE and HOME_AREA_NUMBER, and both exist in EN and TR. The area number comes from WorldService.world_for_level(level)["number"], and the label is empty if no world matches. No hardcoded strings.
- The diff has no unrelated changes. The test updates all follow the background swap.
