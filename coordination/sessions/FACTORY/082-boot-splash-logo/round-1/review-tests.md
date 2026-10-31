VERDICT: PASS

## Findings
None.

## Notes
- Re-ran tests/m42_opening.gd: exit 0, no SCRIPT ERROR or Parse Error. Last line: `M42 opening evidence: PASS`.
- The new `boot_splash_logo` case asserts the image path, the 1080x2160 canvas size, show_image, stretch_mode==1, bg_color == OpeningScreen.BACKGROUND, and the canvas corner pixels. Any of these would fail if the setting or asset changed. The case is also added to EXPECTED_CASES, and no existing test was weakened.
- Spec deviations (portrait derivative image, stretch_mode instead of the nonexistent fullsize) are documented in build.md and are reasonable.
