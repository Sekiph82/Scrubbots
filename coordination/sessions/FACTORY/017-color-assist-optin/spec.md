# Color-assist symbols become opt-in, smaller, subtle

> Feature: OWNER CHANGE to the M50 color-blind board symbols. Owner (Şekip) in chat 2026-10-22: "renk körleri için yaptığımız düzenleme sürekli gözükünce çok çirkin bir görüntü oluşuyor piksel art üzerinde. settings kısmına bir düğme koymalıyız ki herkese aynı şekilde gözükmesin. renk körleri için o düğme aktif edildiğinde piksel art görselinin pikselleri üzerinde o işaretler çıksın. piksel art üzerinde her pikselin üzerinde yer alan görsel işaretler çok büyük. bir kişinin görebileceği en küçük boyutta olmalı. tüm görseli bozmuş. piksel art görselini bozmamalı." Meaning: symbols are opt-in via a Settings toggle (default OFF, pure pixel art when OFF); when ON the per-cell glyphs are the smallest still-recognizable size and must not ruin the art.

## Context
SB-M50-BOARD-001 (closed) draws per-cell glyphs in one shader pass.
- `scripts/gameplay/board/board_pixel_grid.gdshader`: uniform `symbols_on` (false by default), `cid_map`, `glyph_atlas`, `glyph_span = 0.8` (glyph tile = 80% of the cell), `ink_alpha = 0.92`, `halo_alpha = 0.5`. The glyph block sits inside `if (symbols_on)` after the CLEARED alpha test. The shader already computes `ppc` (screen px per cell).
- `scripts/gameplay/board/board_renderer.gd`: `_apply_grid_style()` sets `symbols_on` from `are_symbols_shown()` (`ColorSymbols.enabled and _cid_texture != null`).
- `scripts/ui/color_symbols.gd`: `static var enabled := true` (line ~40) is the process-wide flag. It also gates Supply/Slot/booster-chip glyphs. `main.gd:163-166` syncs it from `app_state.effects`.
- `scripts/settings/effects_settings_service.gd`: `_color_symbols = true`; `snapshot()` = `{"reduced","color_symbols"}`; `strict_import_snapshot` uses `s.get("color_symbols", true)`.
- `scripts/save/save_service.gd` `_apply_effects` (~line 213): when `settings.effects` is absent it calls `set_color_symbols(true)`. Save `VERSION` is 2, and `validate_candidate` rejects a non-bool `color_symbols`.
- `scripts/ui/settings_panel.gd:365` falls back to `true`; label `SETTINGS_COLOR_SYMBOLS = "COLOR SYMBOLS"` and hint "Press and hold the board to zoom in." are in `scripts/ui/ui_text.gd:477-478`.
- Magnifier: `scripts/ui/board_magnifier.gd` (`MIN_ZOOM_CELL = 28`). It stays as is.
- Tests: `tests/m50_board_symbols.gd` (b04 asserts default ON; b08 GPU readback assumes glyph_span 0.8 and `diff_total > 1000`), `tests/m50_color_symbols.gd`, `tests/m50_accessibility_audit.gd`, `tests/m41_settings.gd:454` (asserts the exact effects dict), `tests/m46_performance.gd`, tool `tests/tools/m50_symbol_capture.gd`.

A stored `color_symbols: true` cannot be told apart from an explicit player choice, because the old default wrote `true` into every save.

## Requirements
1. Default OFF everywhere: `ColorSymbols.enabled`, `EffectsSettingsService._color_symbols`, the `strict_import_snapshot` fallback, the `_apply_effects` no-`effects` branch and the `settings_panel.gd` fallback all become `false`. With it OFF the board shows the pure pixel art with no glyph pixels, and the Supply/Slot/booster-chip glyphs are also off (one toggle governs all surfaces, orchestrator default).
2. Existing-save migration, with no schema version bump and no data deletion. `EffectsSettingsService.snapshot()` also writes a marker `"color_symbols_optin": true`. `strict_import_snapshot` treats the saved `color_symbols` as the player's choice only when the marker is exactly bool `true`. If the marker is absent (every pre-change save), it forces `color_symbols = false` once, and the next save writes the marker. The marker is optional on read; a non-bool marker rejects the candidate like `color_symbols` does. All other save content is untouched. A player who had explicitly switched ON before the change is reset to OFF once, which is accepted because they cannot be distinguished.
3. Glyph size on the board, when ON:
   - Change shader default `glyph_span` from 0.8 to 0.5, so the glyph is 50% of the cell side, centered.
   - Lower `ink_alpha` to 0.85 and `halo_alpha` to 0.35 so the mark is subtle.
   - Add uniform `min_glyph_px = 5.0`. The shader draws the glyph only when `ppc * glyph_span >= min_glyph_px`, i.e. `ppc >= 10`. Below that the cell shows the plain pixel art, and the existing press-and-hold magnifier is the inspect path. This hide rule is evaluated per fragment from `ppc`, so it needs no GDScript and no nodes.
   - Reference sizes: a 20x20 board at about 660 px wide gives 33 px cells and a 16.5 px glyph. A 59x59 board at 1080x2160 gives about 17 px cells and an 8.5 px glyph. A 59x59 board at 720x1520 gives about 11 px cells and a 5.7 px glyph, still drawn because it is above 5. The builder must verify these numbers against the real layout in the capture tool and report them. If 59x59 at 720 wide falls below 5 px, the glyph is hidden there and the magnifier is used. That is acceptable.
   - The 16 canonical shapes stay unchanged. Tune only if the b08 shape-agreement check still passes at the new size.
4. Settings: the label stays `COLOR SYMBOLS`, the control stays a CheckButton at 88 px or more, and the hint becomes "For color-blind players: marks each pixel with a small symbol. Press and hold the board to zoom in." (`SETTINGS_COLOR_SYMBOLS_HINT` in `ui_text.gd`). Its name `ColorSymbolsHint` stays, and the existing b04 assertion on the text "hold the board" still holds.
5. Keep: no per-cell Nodes, a single shader pass, CLEARED/VOID cells transparent with no glyph, 59x59 supported, the magnifier (`MIN_ZOOM_CELL` 28), gameplay and route truth untouched, no `res://` or art change.
6. Docs: update the CLAUDE.md "Board color-assist" paragraph (section 0, line ~28) to the 2026-10-22 owner decision (opt-in Settings toggle, default OFF, small subtle glyphs, hidden below the minimum cell size with the magnifier as the inspect path; still no per-cell Nodes, the same 16 canonical shapes, CLEARED transparent). Update the SB-M50-BOARD-001 entry in TASKS.md (line ~135) with a note "superseded in part by SB-M50-OPTIN-001: default OFF, opt-in". Add a TASKS.md item `- [ ] **SB-M50-OPTIN-001 ...**` that records the owner quote and this spec, and add the queue row `- READY SB-M50-OPTIN-001 — color-assist symbols opt-in (default OFF, save migration, smaller glyphs); DONE on merge` under `## Autonomous Queue`. The factory flips it to DONE on merge. Also fix the header comments in `effects_settings_service.gd`, `color_symbols.gd` ("default ON") and `tests/m50_board_symbols.gd` to match.

## Acceptance criteria
`$GODOT` is the Godot 4.7.2 binary. Commands: `"$GODOT" --headless --path <worktree> -s res://tests/<suite>.gd`.
1. `m50_board_symbols.gd` b04: a new profile has `effects.is_color_symbols() == false`. Verify with `-s res://tests/m50_board_symbols.gd`; the b04 PASS lines say default OFF.
2. b04 round-trip: switching ON saves and relaunch restores ON. The saved effects dict equals `{"reduced": false, "color_symbols": true, "color_symbols_optin": true}`. `tests/m41_settings.gd` line ~454 is updated to the same dict and PASSes.
3. Migration test (b04 or `m41_settings.gd`): a hand-written save with `effects: {reduced: true, color_symbols: true}` and no marker loads with `is_color_symbols() == false` and `is_reduced() == true`. A save without an `effects` key loads OFF. After one save/relaunch cycle, a player toggle to ON persists as ON, so the migration runs only once. No save file is deleted, and the remaining save content is byte-equivalent after a re-save except for the new key. A non-bool marker (`1, "true", null, [], {}`) rejects the candidate with `effects_malformed`.
4. b04 live-toggle and Settings tests start from OFF: toggling ON enables the board shader `symbols_on` and the Supply tiles together, and OFF disables them together. The Settings switch (label `COLOR SYMBOLS`, at least 88 px) drives AppState and `ColorSymbols.enabled`. The hint contains "color-blind" and "hold the board".
5. Shader/params test: `glyph_span` default is 0.5 (the b08 readback and b06 use the uniform or the new default), `min_glyph_px` exists with value 5.0, and `grep -n "min_glyph_px" scripts/gameplay/board/board_pixel_grid.gdshader` shows it applied to `ppc * glyph_span`.
6. b08 windowed GPU readback (run without `--headless`; it prints NOT_RUN under headless as today):
   - With symbols ON, the glyph ink is confined to the central `glyph_span` square of each ACTIVE cell. A ring test checks that no ink-colored pixel lies outside the central 60% of the cell. The glyph bounding box is at most 0.55 of the cell side, and the rendered shape still equals the cell's own C-ID shape. Keep the thresholds meaningful at 0.5 span, by enlarging cells (for example 48 px) or sampling more points rather than weakening the checks.
   - With symbols OFF (and at default after boot), every ACTIVE cell is pixel-identical to the same board rendered with `symbols_on=false`, so no glyph pixels exist. CLEARED cells show exactly BG01.
   - A board rendered at under 10 px per cell (for example a 59x59 board in a 500 px square) draws no glyph pixels even with symbols ON.
   Expected final line: `M50S`-style PASS with all cases complete (the suite prints its verdict; it must report PASS and 8/8 cases).
7. `m50_color_symbols.gd` and `m50_accessibility_audit.gd` PASS. They are updated for default OFF and enable symbols explicitly where they check glyph presence. The Supply/Slot shape-equality and contrast checks are unchanged.
8. `m46_performance.gd` PASS (the 59x59 cost bounds are unchanged), and the node count is constant with symbols ON at 59x59.
9. The CI list of headless suites in the Android `validation_only` workflow (the 43-suite list used for run 39785950814) all PASS locally. Report LOCAL_PASS honestly; Actions run only under CLAUDE.md section 0D.2.
10. `git grep -n "default ON"` in the files edited in requirement 6 returns no stale claim about color symbols. CLAUDE.md contains "opt-in" in the board color-assist paragraph. TASKS.md contains `SB-M50-OPTIN-001` in both the item and the queue row.
11. `tests/tools/m50_symbol_capture.gd`, run windowed, produces captures of L7 and 59x59 with symbols OFF and ON, in the scratch directory and not committed. The builder reports the measured px/cell and glyph px. Capture output is not committed.

## Out of scope
- Separate toggles for board vs Supply/Slots, or any new setting beyond the existing one.
- Changing the 16 canonical shapes, palettes, the magnifier behaviour or `MIN_ZOOM_CELL`.
- A save `VERSION` bump or a new schema, and deleting or rewriting any save beyond the one-time `color_symbols` reset.
- Per-cell Nodes, a CPU-drawn overlay, new art, a store or CI-config change.

## Assumptions
- One existing toggle controls all symbol surfaces (the orchestrator default), so the Supply/Slot cues are also off by default. This is simplest and matches "everyone sees the same only if they opt in".
- Migrating every pre-marker save to OFF is acceptable, because the old default makes "explicit ON" indistinguishable from the default; a marker key avoids a version bump that would make older builds refuse the save.
- 0.5 cell fraction and a 5 px floor are the "smallest recognizable" values chosen from the shader math. A 16-shape glyph needs at least about 5 px to stay distinguishable. The builder may adjust within 0.45..0.55 and 4..6 px only if the b08 shape-agreement check fails, and must record the reason.
