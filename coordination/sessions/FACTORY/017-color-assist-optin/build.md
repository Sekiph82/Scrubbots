STATUS: READY

# Build: Color-assist symbols become opt-in, smaller, subtle

## Summary
COLOR SYMBOLS is now opt-in and starts OFF. One toggle covers the board glyphs, the Supply/Slot tiles and the booster chips. With it OFF the board is the plain pixel art.

Older saves are migrated once. Saves now carry a `color_symbols_optin: true` marker, and every save without it loads with symbols OFF. There is no VERSION bump. A marker that is not a bool rejects the save with `effects_malformed`.

When symbols are ON, each board glyph is a square of `floor(ppc * 0.4)` whole screen pixels, where `ppc` is screen pixels per cell. This is the owner's round-2 rule: half the original 0.8 glyph, rounded down. Ink alpha is 0.85 and halo alpha 0.35. The `min_glyph_px` = 5 gate hides the glyph when that floor is under 5 px, i.e. on cells under 12.5 px; there the press-and-hold magnifier is the inspect path. The settings hint now names color-blind players.

Branch `factory/017-color-assist-optin`, commits:
- 2bfc7e92 opt-in, migration, glyph size gate (round 1)
- 72ed075c TASKS.md item and queue row (round 1)
- cd7727b1 comment wording (round 1)
- 7bf9a47e board glyph floor(ppc * 0.4) whole screen px (round 2)
- a72d25a5 TASKS.md rework note (round 2)

Files changed:
- `scripts/gameplay/board/board_pixel_grid.gdshader`
- `scripts/settings/effects_settings_service.gd`
- `scripts/save/save_service.gd`
- `scripts/ui/color_symbols.gd`
- `scripts/ui/settings_panel.gd`
- `scripts/ui/ui_text.gd`
- `tests/m50_board_symbols.gd`
- `tests/m41_settings.gd`
- `tests/m50_color_symbols.gd`
- `tests/tools/m50_symbol_capture.gd`
- `TASKS.md`

Shader glyph code (round 2):
```glsl
uniform float glyph_span = 0.4;          // glyph side as a fraction of the cell, floored to whole px
uniform float min_glyph_px = 5.0;
...
float gpx = floor(ppc * glyph_span + 0.001);   // glyph side in whole screen pixels
if (symbols_on && gpx >= min_glyph_px) {
	float gs = gpx / ppc;
	vec2 gp = (f - vec2(0.5)) / gs + vec2(0.5);
	vec2 gq = gp + vec2(0.25 / gpx);   // quarter-pixel bias: exactly gpx px when edges hit pixel centres
	if (cid > 0.5 && gq.x >= 0.0 && gq.x < 1.0 && gq.y >= 0.0 && gq.y < 1.0) { ... }
```

## Acceptance criteria
1. [x] Default OFF. b04 prints `ok: process default: ColorSymbols.enabled OFF before any setting is applied` and `ok: new profile: COLOR SYMBOLS default OFF (opt-in)`.
2. [x] Round-trip. After switching ON, the saved effects dict equals `{"reduced": false, "color_symbols": true, "color_symbols_optin": true}` in b04, and `m41_settings.gd` line ~454 asserts the same dict. Relaunch restores ON, and also restores OFF.
3. [x] Migration (in `m41_settings.gd`).
   - A hand-written `{reduced: true, color_symbols: true}` save with no marker loads OFF with Reduced ON. Loading neither deletes nor rewrites the file.
   - A re-save equals the original except for `color_symbols: false` and the new marker.
   - A player toggle to ON then persists after relaunch, so the migration runs only once.
   - A save with no `effects` key loads OFF.
   - The non-bool markers `1, "true", null, [], {}` are each rejected with `effects_malformed` (5/5).
4. [x] Live toggle and Settings switch, both starting from OFF.
   - The board shader `symbols_on` and the Supply tiles switch ON and OFF together.
   - The `COLOR SYMBOLS` switch (88 px or more) drives AppState and `ColorSymbols.enabled`.
   - The hint contains "color-blind" and "hold the board".
5. [x] Shader parameters. The span is 0.4, the owner's round-2 replacement for the spec's 0.5. b03's code check prints `ok: shader: glyph_span 0.4, min_glyph_px 5.0, glyph side floor(ppc * glyph_span) whole px, drawn only when >= min_glyph_px`. b08 reads the real shader defaults: `glyph_span 0.40, min_glyph_px 5.0 -> glyph 19 px`.
6. [x] b08 windowed real-GPU readback on HEAD a72d25a5: `M50 board symbols evidence: PASS (8/8 cases, 0 fail)`, exit 0, no SCRIPT ERROR. At 48 px per cell:
   - `default (OFF) and toggled-OFF renders are pixel-identical to the glyph-free board`
   - `399/399 rendered ACTIVE cells show symbol ink pixels`
   - `no glyph pixel (ink or halo) outside the central 60% of any cell (0 stray)`
   - `glyph bounding box at most floor(48 * 0.4) = 19 px ... (widest 19 px = 0.40 of the side)`
   - `rendered glyph == the cell's own C-ID shape: mean agreement 0.99 (worst cell 0.96); on 10214 points where it differs from the next C-ID's shape, 97% follow the own shape`. The thresholds are unchanged: worst >= 0.85, own-shape share >= 0.9, more than 1000 points.
   - `CLEARED cell: every one of its 2304 px is exactly the BG01 background`
   - On a 59x59 board, the whole-pixel size gate: `8.00 px per cell (glyph floor 3 px < 5): symbols ON draws no glyph pixel`, `12.00 px per cell (glyph floor 4 px < 5): ... no glyph pixel`, `13.00 px per cell: glyph drawn, 5 px wide on screen within its floor(13.00 * 0.4) = 5 px square`, `16.00 px per cell: glyph drawn, 6 px wide ... = 6 px square`.
7. [x] `M50 color symbols evidence: PASS (10/10 cases, 0 fail)` and `M50 accessibility audit evidence: PASS (4/4 cases, 0 fail)`.
8. [x] `M46 performance evidence: PASS (22/22 cases, 0 fail)` on HEAD. b07 at 59x59 with symbols ON prints `3,481 cells, symbols ON: ONE TextureRect, 0 child nodes`.
9. [x] The 43-suite CI list all passed locally in round 1. Round 2 changed only the shader, `m50_board_symbols.gd` and the capture tool, so I re-ran only the affected suites listed under Validation.
10. [ ] Partly met. The `git grep "default ON"` check is clean and TASKS.md has `SB-M50-OPTIN-001` 3 times. CLAUDE.md is excluded from this job per the orchestrator; it is a follow-up job. The proposed paragraph is in the round 1 log below, and it should say "about 0.4 of the cell side, whole pixels" instead of "half".
11. [x] Round 1 only: captures and measured px per cell. Per the owner, no images were made in round 2. The round-1 files in `captures/` still show the 0.5-span glyph. Applying the round-2 rule to the px/cell values measured in round 1 gives:

| Board | Screen | px/cell (measured, round 1) | Glyph round 2 = floor(ppc*0.4) | Original glyph (ppc*0.8) |
|---|---|---|---|---|
| L7 | 1080x2160 | 24.43 | 9 px | 19.55 px |
| test_59x59 | 1080x2160 | 14.12 | 5 px (drawn) | 11.29 px |
| L7 | 720x1520 | 16.29 | 6 px | 13.03 px |
| test_59x59 | 720x1520 | 9.41 | 3 px, hidden (magnifier) | 7.53 px |

## Validation
Round 2, on HEAD a72d25a5 (Godot 4.7.2):
- windowed `m50_board_symbols`: exit 0, PASS (8/8 cases, 0 fail)
- headless `m50_board_symbols`: exit 0, PASS (8/8; b08 NOT_RUN as designed)
- `m41_settings`: exit 0, `M41 V01 settings evidence: PASS`
- `m50_color_symbols`: exit 0, PASS (10/10) on the rerun.
  - The first run failed only s09 `300 rebinds in 3438.3 ms` against its 3000 ms bound; the rerun took 2539.6 ms. That check times Supply tile rebinds and round 2 did not touch it.
- `m50_accessibility_audit`: exit 0, PASS (4/4)
- `m46_performance`: exit 0, PASS (22/22), `retry() on 59x59 worst 46.91 ms (<= 50.1)`.
  - That retry check is near its limit on this laptop. Results this round: 47.17 PASS, then 54.38 FAIL, then 53.62 FAIL in a sequential run, then 46.91 PASS.
  - Pre-job baseline: the one full run with the f8b10884 `scripts/` checked out measured 48.04 ms (PASS but near the limit). Two more baseline runs were cut short (exit 127).
  - The check is headless and CPU-only, and does not use the shader. I count it as a timing flake, not a regression from this job.
- `git diff --check` clean. `git status --short --untracked-files=no` is empty. The only untracked files are `.uid`/`.import` files from the Godot import.

## Log
### Round 1
- Made the five defaults false, added the `color_symbols_optin` marker (non-bool rejected), set the shader to span 0.5, ink 0.85, halo 0.35 and `min_glyph_px` 5, and changed the hint text.
- Updated the tests for default OFF, with explicit opt-in where glyphs are checked, and rewrote b08.
- Extended the capture tool and saved captures to `captures/`.
- Updated TASKS.md.
- CLAUDE.md not edited. Proposed paragraph: "Board color-assist (owner 2026-10-22): color-blind symbols are an opt-in Settings toggle (COLOR SYMBOLS, default OFF); OFF shows the pure pixel art. When ON, every ACTIVE cell carries a small, subtle glyph of the same 16 canonical shapes as Supply/Slots, hidden below the minimum on-screen size where the press-and-hold magnifier is the inspect path. Single shader pass, no per-cell Nodes, CLEARED transparent, art and gameplay truth preserved."
- Both reviews returned VERDICT: PASS with no findings to address.

### Round 2
Rework from rework-1.md, owner in chat 2026-10-22: "13'ten 8'e düşmüş ya, bence şu anki boyutun yarısı olsun ama aşağıya yuvarlanmış haliyle. mesela 13 için 6 olsun". The glyph becomes half of the original 0.8 glyph, rounded down to whole screen pixels.
- Shader: `glyph_span` 0.4, glyph side `gpx = floor(ppc * glyph_span + 0.001)`, gate `gpx >= min_glyph_px` (5, unchanged), sampling scaled by `gpx / ppc`.
  - Without the quarter-pixel bias, the first windowed run drew 20 px at 48 px/cell instead of 19: when the square's edges land on pixel centres, both edge pixels were included. With the half-open test plus the bias, exactly `gpx` px are drawn.
- Tests:
  - b03 checks the new shader rule.
  - b08 asserts the glyph bounding box is at most `floor(cs * 0.4)` px and samples shape agreement over the floored square.
  - The size-gate test now uses 59x59 at 8, 12, 13 and 16 px per cell: no glyph pixel at 8 and 12 (floor 3 and 4), a 5 px wide glyph at 13 and a 6 px wide glyph at 16, measured from the readback.
- Capture tool: prints the whole-pixel glyph size. It was not run, because the owner asked for no images this round and pre-approved the visual result.
- Default OFF, the migration and everything else are unchanged from round 1.
- An m46 baseline check briefly checked out the f8b10884 `scripts/` files in the worktree. Those files were restored to HEAD and none of them was committed; the tree is clean on a72d25a5.
