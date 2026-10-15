# SB-M50-BOARD-001 — CLAUDE LOG V01

Prompt: `coordination/sessions/M50-BOARD-COLOR-ASSIST-C001/CHATGPT_CLAUDE_MASTER_PROMPT_V01.md` (owner override, 2026-10-15).
Base: `origin/main` `39fd3819`. The Desktop checkout was fast-forwarded from `88894316` with no conflict. The owner-modified `project.godot`, `scenes/app/main.tscn`, the two `tests/tools/owner_review/*.tscn` files and all untracked files were left untouched and not staged.

**Result: IMPLEMENTED_LOCAL_TESTED_CLOUD_CI_DEFERRED_COST_FREEZE_OWNER_VISUAL_PENDING**

**GitHub Actions: NONE run.** There was no dispatch, rerun, `validation_only` or re-enable, and both job-level `if: ${{ false }}` guards are unchanged. Every result below is a `LOCAL_PASS` on the owner laptop using Godot 4.7.2.stable and the existing import cache. Cloud CI is `CLOUD_CI_DEFERRED_COST_FREEZE`.

## What was built

### 1. On-board symbols: one shader pass, no new nodes
These are in `scripts/gameplay/board/board_pixel_grid.gdshader` and `board_renderer.gd`.

- **Identity map.** The renderer builds one RG8 identity texture per board and palette, with one texel per cell:
  - R holds the canonical C-ID (1..16). It is resolved from the exact colour by `ColorSymbols.cid_index_for_color`, never from the level-local index.
  - G holds a dark-ink flag.
- **When the map is rebuilt.**
  - It is rebuilt only for a new board instance or a new palette.
  - Relayout, `refresh_all`, `update_cells` and clears never touch it. A cell's colour id is immutable.
- **How the shader draws.** The existing grid/bevel shader samples the map with `texelFetch`. It draws the C-ID tile from a shared glyph atlas with `textureGrad`:
  - Gradients come from the continuous grid coordinate and are taken in uniform control flow.
  - The ink is drawn over a halo of the opposite ink.
- **CLEARED and VOID cells.** These texels are still discarded to transparent (`base.a < 0.5`) before any glyph code runs.
- **Source art is untouched.** The source colour image and its RGB and alpha are unchanged, and the symbol is only composited in the shader.
- **Glyph atlas** (`ColorSymbols.build_atlas_image`):
  - A 16 × 48 px RG8 mipmapped atlas, built from the **same** `ColorSymbols._parts()` shapes that Supply, Slots and chips draw.
  - Halo polygons come from `Geometry2D.offset_polygon`.
  - It is built once per process and pre-warmed at app boot in `main.gd`.
- **Ink choice.** The renderer picks the higher-contrast ink between navy (0.03, 0.04, 0.09) and white. The weakest result is C09 at 4.58:1, and every ink-to-halo rim is at least 10:1.
- **Size.** The shape spans about 62% of the cell, so the pixel colour stays dominant.

### 2. COLOR SYMBOLS setting
- **Storage.** It is saved as `settings.effects.color_symbols` and defaults to **ON**, which is the accessible owner-preview default.
  - The key is optional, so every pre-M50 save still loads and gets ON.
  - A present non-bool value rejects the whole save candidate, the same rule as `reduced`.
  - An older build reading the new save ignores the extra key.
- **Settings panel.** A `COLOR SYMBOLS` switch, at least 88 px tall, sits under REDUCED EFFECTS. The hint "Press and hold the board to zoom in." is shown under it.
- **Effect.**
  - The switch goes through `AppState.set_color_symbols` to `ColorSymbols.set_enabled`, then a group call to `refresh_color_symbols`.
  - The board shader, Supply and Slot tiles and booster target chips switch together, live, with no rebuild.

### 3. Board magnifier (`scripts/ui/board_magnifier.gd`)
- **Scope.** One Control covers exactly the board rect.
- **Interaction.**
  - Press and hold shows a framed loupe above the finger, clamped on screen.
  - Dragging moves the loupe, and releasing hides it.
- **Rendering.**
  - The loupe draws the renderer's **own** texture and material, so it shows the same symbols, grid and transparent holes.
  - Zoom is at least 28 px per cell and at least 2.5× the board cell. Measured on the real L7 at 1080×2160: 64.8 px per cell, against 24.4 px per cell on the board.
- **Node count.** It is constant at 4 nodes (magnifier, Loupe, Zoom, Focus, plus a Ring frame), whatever the board size.
- **No side effects.** It is read-only, with no gameplay state.
- **Input isolation.** No Supply front hit rect, slot strip, booster row, Pause or 2x overlaps it, and this is asserted.

## Local tests (all LOCAL_PASS, Godot 4.7.2, headless unless noted)

### New suite: `tests/m50_board_symbols.gd`
It passes **8/8** headless, where b08 reports NOT_RUN because there is no renderer. It also passes **8/8 windowed** on a real GPU (OpenGL 3.3 Compatibility, Intel Iris Xe):

| Case | What it checks |
| --- | --- |
| b01 | Every atlas texel equals the point-in-shape result of the same `_parts()`. The halo contains the shape and the tile borders are empty. Build time 33–114 ms on desktop. |
| b02 | Ink contrast at least 3:1 on all 16 colours (worst C09 4.58:1). Rim at least 3:1 (worst 10.06:1). |
| b03 | 19,584 ACTIVE cells across 12 boards carry their canonical C-ID. The boards are: real L7 pigeon; 20×20, 32×32, 40×24, 53×59 and 59×59 in V3 and reversed palette order; and a VOID-ring v2 level. The 324 VOID cells carry none. Base pixels are exact, and there are 0 child nodes. |
| b04 | The setting defaults ON, persists, is optional in old saves and is strictly a bool (6/6 rejects). The live toggle switches the board and tiles together. The real app root's Settings switch drives AppState. |
| b05 | Clear, reset, relayout (same renderer, same map) and palette-order change all leave no stale identity. |
| b06 | Real app root, **production L7 pigeon**: 1,024 artwork cells carry symbols. The magnifier equals the board rect, with no control overlapping it. Real press, drag and release input events work. The loupe uses the renderer texture and material. Board, Supply and slots are unchanged after inspecting, and a real Supply front tap still places its batch. |
| b07 | 59×59 cost: `refresh_all` 12.5 ms (colour only, as before); relayout configure 13 ms with the map reused; identity map build 9.7 ms once per board; `update_cells` 0.014 ms; 0 child nodes. |
| b08 (GPU) | All 399 rendered ACTIVE cells show ink. The rendered mask equals the cell's **own** C-ID shape: mean agreement 1.00, worst cell 0.98. On 4,300 points where it differs from the next C-ID's shape, 99% follow its own shape. A CLEARED cell is exactly BG01 (1,024/1,024 px). With symbols OFF, the cell centre is back to the plain colour. |

### CI-list regression, run locally (same list as the frozen workflow, 43 suites)
Every suite exited 0 with no script diagnostics. The exception is `m43_c005f_phase4_terminal_home_micro`, which has 4× the documented injected `explode` line that the CI rule allows.

| Suite | Result |
| --- | --- |
| m50_color_symbols | 10/10 |
| m28_c002_c003_r01_remediation | 24/24 |
| m41_settings | PASS |
| m28_c002_c004_tile_visual | 17/17 |
| m28_c002_c001_gameplay_v02 | 14/14 |
| m47_touch_r01_mobile_ux | 14/14 |
| m49_responsive_matrix | 8/8 (re-run after the final Settings change) |
| m43_r15_owner_remediation | 18/18 |
| m51_localization_readiness | 4/4 |
| m50_accessibility_audit | 4/4 |
| m45_debug_tooling | 8/8 |
| m43_c003_c001_acquisition | 34/34 |
| run_tests | ALL PASS |
| m40_save_system | PASS |
| m35, m37, m40_v04_bootstrap, all m39 suites (13) | PASS |
| m55_long_session | PASS |
| m43_c005f_phase4 | 19/19 |
| m43_c001a | 11/11 |
| m42_navigation | PASS |
| m42_home | PASS |
| cp04 | 28/28 |
| cp05 | 15/15 |
| m55_economy_release_regression | PASS |
| cp05_r01 | 6/6 |
| remote_content_family_fixture | PASS |
| cp06 | 16/16 (exact) |
| m44_ftue | 23/23 (exact) |
| m43_master_c009_daily | 12/12 |
| m43_r15_001_r01 | 14/14 |

After the review fixes (§ Peer review), the following were re-run: m50_board_symbols (headless and windowed), m50_color_symbols, m40_v04_bootstrap and m28_c002_c003_r01_remediation. All PASS.

### Edits to existing tests, and why
The owner revoked the "no symbols on the board" rule, so three existing tests needed changes:

- **`m28_c002_c003_r01_remediation` G1.** It asserted that the shader had no `sampler2D`. It now asserts exactly the two M50 samplers (`cid_map`, `glyph_atlas`). The grid itself still has no mask texture.
- **`m41_settings`.** The exact `settings.effects` dictionary now includes `color_symbols: true`.
- **`m50_color_symbols` s09.** Wording only: there are still no symbol **nodes** on the board.

One failure came up during development and was fixed. `m41_settings` requires every Settings label to be at least 30 px, and the first hint label was 24 px. It now uses FONT_BODY at 30 px.

## Real-GPU owner-review screenshots
Captured with `tests/tools/m50_board_symbol_capture.gd`, using a throw-away save; the owner's real save was not touched.

- **Files:** `%APPDATA%\Godot\app_userdata\SCRUBBOTS\m50b_*.jpg`. There are 6 JPGs totalling about 1.5 MB.
- **L7 pigeon, full screen and full-resolution board crop:** every coloured cell carries its shape.
- **L7 with the magnifier held.**
- **A 59×59 board using all 16 colours, with every 7th cell CLEARED:** full screen, crop, and magnifier.

At about 13 px per cell, the 59×59 shapes are visible but small. The loupe shows them clearly at about 65 px per cell, which is the dense-board readability route the prompt asks for.

## Peer review
`CLAUDE_PEER_REVIEW_V01.md` records a distinct, fresh-context, read-only Claude reviewer subagent. It is a `CLAUDE_PEER_REVIEW`, **not** a ChatGPT independent audit. It found no BLOCKER and no MAJOR issues. The fixes it led to are listed there.

## Owner visual sign-off
**2026-10-16: APPROVED.** The owner wrote in chat: "Board symbols and the magnifier look good in F5." This covers the board glyph style, size and ink, and the loupe.

## Open / not done
- **Cloud CI** is `CLOUD_CI_DEFERRED_COST_FREEZE`.
- **Phone performance is unmeasured.** That covers both frame time and the one-time atlas build, which took 33–114 ms on desktop and is pre-warmed at boot. There was no device run.
- **Mip bleed at about 4 px glyph size** (review item 5) is cosmetic and left as is.

## Local footprint
- **No disk survey and no stash/reset/clean** were done.
- **One small harness output file** was created when a long foreground batch auto-moved to the background. It held about 1 KB of suite summary lines and was deleted by its exact path.
- **Test saves** were deleted by the suites themselves.
- **The 6 review JPGs (about 1.5 MB)** are kept for owner review. They can be deleted after review.
