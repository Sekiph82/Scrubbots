APPROVE

## Why
Symbols are now opt-in (default OFF, with a one-time marker migration). The board glyph follows the owner's round-2 rule, floor(ppc*0.4) whole pixels, hidden below 5 px. All three round-2 reviews are PASS with no real problems, the reviewers re-ran the suites, and merge-tree against origin/main shows no conflicts. Only three round-2 reviews exist, not four; the visual review was skipped because the owner pre-approved the result and asked for no new images.

## Acceptance criteria
1. Default OFF (b04): met. Shader, service, save and settings defaults are false, and the b04 suite passes.
2. Round-trip dict with the `color_symbols_optin` marker: met. `snapshot()` writes the marker, and m41 passes.
3. Migration: met. `strict_import_snapshot` uses the saved value only when the marker is true, and a non-bool marker is rejected. I read this in the code, and the m41 tests cover it.
4. Live toggle and Settings: met. The m50 suites pass.
5. Shader params: met, with a deliberate change. `glyph_span` is 0.4 (owner rework) instead of the spec's 0.5, and `min_glyph_px` 5.0 gates the whole-pixel glyph size. I confirmed this in the shader.
6. b08 windowed GPU readback: met. PASS 8/8, re-run independently by the tests reviewer.
7. m50_color_symbols and m50_accessibility_audit: met (PASS 10/10 and 4/4).
8. m46_performance: met (22/22). The retry timing check is near its limit and flaky on this machine, but it is CPU-only and unrelated to this change.
9. 43-suite CI list: met as LOCAL_PASS in round 1. Round 2 re-ran only the affected suites.
10. Docs: partly met. TASKS.md is updated and the `default ON` grep is clean. The CLAUDE.md paragraph is a deliberate follow-up job, so it does not block this merge. It should say about 0.4 of the cell side in whole pixels.
11. Captures: met in round 1. Round 2 made no new captures, by owner request.

## For the human
