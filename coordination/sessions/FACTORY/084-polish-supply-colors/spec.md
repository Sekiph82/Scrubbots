# Supply preview rows show original batch colours

> Feature: Owner (2026-10-31, phone, Level 22 crab): supply batch tiles in the rows below the top row are darker or desaturated compared with the front row (8 orange under 14 white looks unlike the 16 orange on top). All three rows must show the ORIGINAL batch colours. Remove the dimming. If the front row needs to read as "tappable", do it without recolouring (raise/outline/glow on the front tile only), subtle. Task SB-POLISH-001.

## Context
- `scripts/ui/batch_supply_panel.gd` `_bind_row()` (line ~300) sets `panel.modulate = Color(0.62, 0.62, 0.70, 0.85)` on preview rows (rows 1/2). That is the dimming/desaturation (cool tint plus alpha over the dark background). Front stays `Color(1,1,1,1)`.
- `scripts/ui/color_batch_tile.gd` `set_preview()` / `_style()`: `_preview` only lowers the shadow alpha (0.55) and shadow size (2 vs 4); face/base colours are already the exact canonical colour. The front already has the cyan `ACTIVE_GLOW` rim via `set_active(front)`, which is the existing "tappable" affordance (keep it).
- Preview rows are also shorter (0.72 x min height) in `_make_row`; leave unchanged.
- Tests asserting the dim: `tests/m28_c002_c001_gameplay_v02.gd` line ~258 (`rows[r].modulate.r < 0.9`, "visibly dimmed") and `tests/m28_c002_c004_tile_visual.gd` line ~181 (`fp[0].modulate.a > fp[1].modulate.a and ...r >`; c05 label "dimmed"). The same file already has the pattern for canonical-colour asserts (~line 297: `get_face_panel().get_theme_stylebox("panel") as StyleBoxFlat`, `bg_color == want`, `get_face_color()`).
- Colour-symbol overlay is opt-in (CLAUDE.md board color-assist); this change must not touch it.

## Requirements
1. Remove the preview-row modulate dimming in `_bind_row`: all rows use `Color(1,1,1,1)` (or no modulate assignment), so effective on-screen colour for rows 0..2 equals the canonical palette colour.
2. Keep front-row affordance only as it already is (cyan rim/glow on the front tile via `set_active`); no recolouring of any row. Do not add new effects beyond that. Preview rows keep no rim and stay non-interactive (mouse IGNORE, no gui_input connections).
3. Update the two tests above so they no longer require dimming: they must assert front vs preview differ by `is_preview()` / `is_active_style()` and that preview `modulate == Color(1,1,1,1)` (and front too). Rename "dimmed" wording in messages/comments (also stale comments in `batch_supply_panel.gd`).
4. Add one direct assertion (in `tests/m28_c002_c004_tile_visual.gd`, c05 block) that, for a bound supply panel, a preview-row tile (row 1 and 2) has `get_face_panel()` StyleBoxFlat `bg_color` equal to the canonical palette colour of its batch, `tile.get_face_color()` equal, and its panel `modulate` is exactly white/opaque.
5. Capture evidence: render the gameplay supply at the reference phone viewport (1080x2160) showing all three rows, using an existing tests/tools capture script (e.g. `tests/tools/gameplay_v02_final_snapshot.gd` pattern, run without `--headless`, using a temp save / save override, NEVER booting main.tscn on the real save). Save the PNG under the job folder `factory/jobs/084-polish-supply-colors/` (e.g. `supply_capture.png`) and reference it in the evidence. Use a level where a lower row repeats an upper colour if possible (e.g. Level 22).
6. Docs: if any doc (grep `docs/`, AGENTS.md, MASTER_UI_SYSTEM.md) states preview rows are dimmed, correct it. Mark SB-POLISH-001 done in TASKS.md per factory convention with evidence.

## Acceptance criteria
1. `grep -n "0.62, 0.62, 0.70" scripts/ui/batch_supply_panel.gd` returns nothing.
2. `"$GODOT" --headless --path <worktree> -s res://tests/m28_c002_c004_tile_visual.gd` ends with its normal all-pass summary (no FAIL lines), including the new preview-row canonical-colour assertion.
3. `"$GODOT" --headless --path <worktree> -s res://tests/m28_c002_c001_gameplay_v02.gd` ends with its normal all-pass summary, including the updated "preview rows IGNORE, unconnected" check.
4. Reverting the `_bind_row` change makes the new assertion fail (builder confirms once locally).
5. The capture PNG exists in the job folder, is 1080x2160 (or the stated reference viewport), and visibly shows rows 2 and 3 in the same colours as row 1 for the same hue, with only the front tile having the rim.
6. Other supply-related suites that CI runs (`m28_c002_c002_static_shell.gd`, `m23_v01_batch_supply_evidence.gd`, `m24_supply_handoff_evidence.gd` if they pass on main) still pass.
7. `git diff --check` is clean; diff touches only the files named above plus TASKS.md and any corrected doc.

## Out of scope
- Changing preview tile height, shadows, count labels, glow style, or colour-symbol rules.
- New front-row effects/animation.
- Slot/booster tile styling, board rendering, supply plan data.

## Assumptions
- The existing cyan front rim already satisfies "subtle tappable affordance without recolouring", so no new raise/glow is added.
- Preview shadow weakening (`a = 0.55`, size 2) is shadow only, not fill colour, so it stays.
