# M28-C002-C004 — CLAUDE LOG V01

Date: 2026-09-29
Prompt: `coordination/sessions/M28-C002-C004/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M28-C002-C004/CHATGPT_AUDIT_CRITERIA_V01.md`
Owner authority: `coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`
Matrix: `IMPLEMENTATION_MATRIX_V01.md`
Status: **AWAITING_CHATGPT_AUDIT**

## Sync / governance

- Repo `Sekiph82/Scrubbots`, branch `main`. Local `main` was 10 commits behind `origin/main`; fast-forwarded (`--ff-only`) to `c01eb3a`, no conflict.
- Root `TASKS.md` was read only. **It was not edited.**
- Preserved and NOT committed: the local `project.godot` editor drift, all untracked owner media / `.import` / `.uid` files, `tests/_m55_diag_tmp.gd`.

## What changed (presentation only)

| File | Change |
|---|---|
| `scripts/ui/color_batch_tile.gd` (new) | The one shared tile: `Glow` / `Base` / `Face`(+`Highlight`, `Count`) / `EmptyWell`, 6 native nodes, runtime colour + count. |
| `scripts/ui/batch_slot_view.gd` | VBox/swatch/count/state stack replaced by one `Tile` child. Empty `StateLineReserve` label kept as an invisible sibling that reproduces the old outer min size (incl. the old state-border growth) so the outer rect / spawn anchor are unchanged. WAITING/ACTIVE text still never shown. |
| `scripts/ui/batch_supply_panel.gd` | Each row `PanelContainer` (still the only front input surface, `HitArea` untouched) now holds a `Tile`. Front = primary + cyan rim; preview = dimmed (unchanged `modulate`) + `set_preview`. Per-panel StyleBox / label styling removed. |
| `scripts/ui/five_slot_strip.gd` | +1 line: in shell mode reports the baked slot interior size to each view so the tile is drawn exactly inside the baked housing (view outer rect untouched). |

## Owner correction — count centring (blocking)

The `Count` label is a child of the `Face` panel with full-rect anchors and CENTER/CENTER alignment: its rect equals the face rect, so its centre equals the face centre on both axes by construction, independent of the base, the hidden state line, container spacing, digits or size. No per-value offset.

Proof:
- **Layout, automated (`c07`–`c10`)**: count-rect centre vs FACE-rect centre, ≤ 1 px tolerance; measured delta is exactly `0.00 px` on every tile: 1/2/3 digits × ACTIVE/WAITING × 5 and 6 slots (66 tiles); 5 viewports × 5/6 slots × 3/5 columns (90 tiles); live resize; real host incl. sixth slot; hostile 400×400 spacer with visible "WAITING" text.
- **Not the whole tile**: `c08` asserts label parent == face, label rect == face rect, face shorter than tile, base below face, and label centre ≠ whole-tile centre.
- **Rendered ink**: the GPU tool measures the bounding box of the pure-white glyph fill in the rendered PNG vs the face centre: `evidence/measurements.txt` — within ≈ 0.0–2.0 px on the phone/tablet shots (≤ 1.4 px vertical, up to 2 px horizontal on some 2–3 digit counts, which is glyph side-bearing of the font, not layout).
- **Mutation check**: temporarily giving the label a 9 px top offset made 7 assertions FAIL (`c07`, `c08`, `c09`, `c10`, resize, real-host five-slot, sixth slot). Reverted.

## Issues found and fixed during the cycle (reported for transparency)

1. **Slot anchor drift (would have failed criterion D).** My first slot rewrite changed the outer slot rect. I measured the pre-C004 layout with `tests/tools/m28_c004_anchor_probe.gd` (10 viewport × capacity configs) and found two causes in the old code: the hidden swatch is absent in shell mode, and the old panel border (ACTIVE 3 px / WAITING 2 px per side) inflated the outer size on narrow phones. Both are now reproduced on the invisible reserve sibling only. Old vs new probe output is **byte-identical**, and the old numbers are pinned in `c12_spawn_anchor_pinned`.
2. **Tile overshooting the baked housing.** With the view inflated by the reserve, the tile base hung below the baked slot frame. Fixed by `set_shell_tile_size` (tile = exact baked interior).
3. **`m55_long_session` FAIL (lap-1 object warm-up 110 > 64; baseline 45).** Root cause: measuring the count text with the font at many distinct tile-derived font sizes. Fixed by sizing the font arithmetically (`DIGIT_EM`) and quantising to 4 px steps / 2 px outlines. m55 now PASS (lap-1 warm-up 40, below the old 45). `c16` still measures real glyph widths against the face.
4. Two older suites asserted the old per-panel `StyleBoxFlat` and were re-pointed at the tile (same asserted properties): `m28_c002_c003_r01_remediation` s02, `m28_c002_c002_r01_visual` accepted_styling_preserved.

## Tests

**New:** `tests/m28_c002_c004_tile_visual.gd` — **PASS, 16/16 cases** (c01–c16, mapped to prompt items 1–17 in the matrix).
**Tools:** `tests/tools/m28_c004_tile_evidence.gd` (GPU evidence + ink measurement), `tests/tools/m28_c004_anchor_probe.gd`.

**Full regression** (Godot 4.7.2, headless, 8-way parallel, all 115 `tests/*.gd` except the untracked `_m55_diag_tmp.gd`): **113 exit 0, 2 non-zero.**
- Root `tests/run_tests.gd`: `Total checks: 5323`, all pass.
- PASS: M28 (C001 14/14, C002 static shell 16/16, R01 visual 10/10, C003 final gate 22/22, R01-V02 remediation 24/24, layout smoke), M29 (all), M30, M39 (incl. `m39_v03/v04_integration`), M40–M42, M43 (C001A/B, C002, C003), M52 (plans, R01, R02), M55 (all 5 incl. long session), routing / clearing / solver / M53 difficulty, responsive / touch suites.
- **Non-zero (pre-existing baseline, identical to the last two cycles):** `m21_v08_corridor_validation`, `m21_v09_direct_evidence_reconciliation`.
- `SCRIPT ERROR` appears only in the `m20_v04/v05/v07/v08` lifecycle assertion-name baseline.
- `git diff --check`: clean (only the local CRLF advisory on the owner-drifted `project.godot`, not committed).

## Evidence (`coordination/sessions/M28-C002-C004/evidence/`)

| Required | File(s) |
|---|---|
| 5-slot occupied runtime | `c004_5slot_5col_phone_1080x2160.png` |
| 6-slot runtime | `c004_6slot_4col_phone_1080x2160.png`, `c004_6slot_5col_phone_1080x2160.png` |
| 5×3 Batch Supply | `c004_5slot_5col_phone_1080x2160.png` |
| 3-column / 4-column supply | `c004_5slot_3col_phone_1080x2160.png`, `c004_5slot_4col_phone_1080x2160.png`, `c004_6slot_3col_tablet_1536x2048.png`, `c004_6slot_4col_phone_1080x2160.png` |
| ACTIVE / WAITING / EMPTY / preview | slots in every shot (slot 1 & 4 ACTIVE, others WAITING, last slot EMPTY, supply rows 2–3 preview); isolated in `c004_tile_gallery_palette_states_sizes.png` |
| Light and dark Palette v3 faces | gallery (all 16 colours, C12 pale yellow / C15 white / C13 grey light; C14 / C16 / C08 dark); slots use C03, C12, C13, C14 |
| Narrow phone / tablet | `c004_5slot_5col_narrow_720x1600.png`, `c004_6slot_5col_narrow_720x1600.png`, `c004_5slot_5col_tablet_1536x2048.png`, `c004_6slot_3col_tablet_1536x2048.png` |
| 1-, 2-, 3-digit slot counts centred on the FACE | `*_closeup_slot0_7.png` (1 digit), `*_closeup_slot1_42.png` (2), `*_closeup_slot2_120.png` (3) on phone / narrow / tablet; 6-slot: `_slot0_5`, `_slot1_16`, `_slot2_250`. Overlay (debug only): green cross = face centre, red cross = count-rect centre, magenta box = face rect. |
| Numbers | `measurements.txt` (layout delta + rendered-ink delta per slot) |

## Owner visual review still required (SB-M28-C002-021 stays open)

1. Overall 3D tile look: base height (17 % of tile), shadow, highlight band strength.
2. Count weight: three-digit counts (`120`, `250`) are tight; outlines of adjacent glyphs touch. Readable and inside the face, but the owner may want a slightly smaller 3-digit size.
3. Perceived centring (layout is exact; rendered ink ≤ 2 px).
4. ACTIVE rim vs WAITING (WAITING is the plain occupied tile per the owner text) and front-vs-preview hierarchy.
5. Empty slot / empty supply cell rely on the baked frame art in production shell mode (the tile draws a neutral recessed well only in non-shell mode).

## Reproduce

```bash
godot --headless --path . -s res://tests/m28_c002_c004_tile_visual.gd
godot --path . -s res://tests/tools/m28_c004_tile_evidence.gd -- <out_dir>
godot --headless --path . -s res://tests/tools/m28_c004_anchor_probe.gd
```

`AWAITING_CHATGPT_AUDIT / M28-C002-C004 COLOR-BATCH TILE VISUAL POLISH V01`
