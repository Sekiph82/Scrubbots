# M28-C002-C004 — IMPLEMENTATION MATRIX V01

Prompt: `CHATGPT_PROMPT_V01.md` · Criteria: `CHATGPT_AUDIT_CRITERIA_V01.md` · Authority: `coordination/OWNER_M28_COLOR_BATCH_TILE_VISUAL_V01.md`
Status: **AWAITING_CHATGPT_AUDIT**. Technical evidence only; owner visual acceptance (SB-M28-C002-021) is not self-awarded.

## A. Shared tile architecture

| Requirement | Implementation | Proof |
|---|---|---|
| One shared component | `scripts/ui/color_batch_tile.gd` (`ColorBatchTile`, plain `Control`) | `c01_shared_component`: every slot tile and every supply tile has `get_script().resource_path == color_batch_tile.gd` |
| Slot integration | `BatchSlotView` holds one `Tile` child, no VBox / swatch / count label of its own | code + `c01`, `c02`, `c03` |
| Supply integration | `BatchSupplyPanel._make_row` adds one `Tile` under each row `PanelContainer`; the row panel remains the only input surface | `c01`, `c04`, `c05`, `c13` |
| Data-driven | `set_batch(Color, "N")`, `set_empty()`, `set_active()`, `set_preview()`; runtime Palette v3 colour + live count | `c11`, `c02` |
| No baked art | 6 native nodes per tile: 4 `Panel` + 1 `Label` (`Glow`, `Base`, `Face`+`Highlight`, `EmptyWell`) — no `TextureRect`, no per-colour / per-count texture | `c15_lightweight_no_baked_art` |

## B. Visual structure

| Owner element | How it is drawn |
|---|---|
| Rounded coloured top face, exact Palette v3 colour | `Face` `StyleBoxFlat.bg_color == palette colour`; only a thin darker rim of the same hue |
| Restrained highlight | `Highlight` band in the upper 8–21 % of the face at alpha 0.16 (0.24 ACTIVE); never over the face centre (`c11`) |
| Visible white / light-grey base under the face | `Base` panel (`#EDF2FA`, edge `#A8B5CC`), projects `BASE_FRACTION = 17 %` below the face |
| Compact shadow | `StyleBoxFlat.shadow_size = 4`, offset `(0,3)` on the base (2 for preview) |
| White count, strong dark outline | `Label` white, `font_outline_color #080A17`, `outline_size ≈ 0.24 × font` (font sized arithmetically, 4 px steps), embolden `FontVariation` |
| ACTIVE (no words) | cyan rim + soft cyan glow (`Glow` panel) and slightly stronger highlight; no scale change so layout is untouched |
| WAITING (no words) | plain occupied tile (owner text: "normal occupied appearance") |
| EMPTY | no face / base / count. Shell mode: the baked slot frame / cell is the neutral housing. Non-shell: neutral recessed `EmptyWell`. |
| Supply preview | row panel `modulate = (0.62,0.62,0.70,0.85)` (unchanged accepted value) + `tile.set_preview(true)` (smaller shadow); never receives input |

## C. Exact numeric centring (BLOCKING)

Structure: `Face` → `Count` (child of the face). `Count` uses anchors `0..1`, offsets `0`, `HORIZONTAL_ALIGNMENT_CENTER`, `VERTICAL_ALIGNMENT_CENTER`. Its rect **is** the face rect, so centre X and centre Y are identical by construction. The lower base, the state-line spacer, container spacing, digit count and size cannot enter the calculation. No per-value offset exists.

| Criterion | Proof |
|---|---|
| Count centre == face centre, both axes, ≤ 1 px | `c07`: 66 tiles = 1/2/3 digits × ACTIVE/WAITING × 5 and 6 slots. Measured delta is exactly 0.00 px. |
| Reference is the FACE rect, not the tile/base | `c08`: label parent is the face; label rect == face rect; face height < tile height; base bottom ≥ face bottom + 2 px; label centre is provably NOT the whole-tile centre |
| Hidden spacer / state line cannot move it | `c09`: a hostile `StateLineReserve` (400×400 min size, text "WAITING") leaves the count centred and the face rect unmoved; the reserve is a sibling, not an ancestor/descendant of the tile |
| Responsive | `c10`: 1080×2160, 720×1600, 1080×1920, 1290×2796, 1536×2048 × 5/6 slots × 3/5 supply columns (90 tiles) + live resize |
| Sixth slot | `c03` (real host, +1 Slot, occupied sixth slot) and `c07`/`c10` |
| Rendered ink centre | GPU tool `m28_c004_tile_evidence.gd` measures the pure-white glyph fill bbox in the rendered image against the face rect: within ≈ 0.1–2 px (glyph side bearing) |
| Mutation check | Offsetting the label 9 px down makes 7 assertions FAIL (`c07`, `c08`, `c09`, `c10`, resize, two real-host); reverted |

## D. Slot invariants

| Invariant | Proof |
|---|---|
| Displayed count = `remaining_to_clear - committed` | `c02` (real host, committed > 0 observed) + detached-snapshot case; `m29_slot_display_sync_evidence` |
| ACTIVE/WAITING/EMPTY internal truth unchanged | `get_state()` untouched; `m28_c002_c003_r01` s01/s02 |
| Five/six capacity unchanged | `FiveSlotStrip.set_capacity` untouched; `c03`, `m39_*` |
| No slot input added | `BatchSlotView` still `MOUSE_FILTER_IGNORE`, no signal; tile ignores input |
| Outer slot rect + spawn anchor do not drift | `c12_spawn_anchor_pinned`: anchors AND view rects pinned to values measured on the pre-C004 code for 10 viewport × capacity configs, tolerance 0.01 px. `get_spawn_anchor_global` / `get_slot_anchor_global` are unmodified. |
| Housing/rail separate | shell mode: baked frame is the housing; `BatchSlotView` panel is `StyleBoxEmpty` and the tile is drawn inside the baked interior (2 px inset) |

Legacy-geometry note: the old VBox made the outer slot size depend on the state border (ACTIVE +3 px, WAITING +2 px per side) and on the hidden state line. That is reproduced **only** on the invisible `StateLineReserve` sibling (`_apply_reserve`), so the outer rect and anchor are byte-identical, while the tile is drawn in the exact baked interior (`set_shell_tile_size`).

## E. Batch Supply invariants

| Invariant | Proof |
|---|---|
| 3/4/5 columns, exactly 3 rows | `c04` |
| Row 0 interactive only; rows 1/2 preview, no handler | `c05`, `m29_input_gate_evidence` |
| Hidden queue stays hidden | panel API unchanged (`get_visible_row_count`, 3 panels per column) |
| Hit rects non-overlapping, enclose the tile, ≥ 60 px, unchanged by rebind | `c13` |
| One gesture = one activation; preview tap = none | `c13` (routed `SubViewport.push_input`) |

## G. Scope

Changed presentation files only: `color_batch_tile.gd` (new), `batch_slot_view.gd`, `batch_supply_panel.gd`, `five_slot_strip.gd` (one line: reports the baked interior size to each view). Not touched: root `TASKS.md`, routing, target/claim/reservation, board/grid/bevel, speed, economy, M23/M24 truth, Home, solver, level data.

Existing tests that froze the old per-panel `StyleBoxFlat` were re-pointed at the tile (same asserted properties):
`m28_c002_c003_r01_remediation` (s02), `m28_c002_c002_r01_visual` (accepted_styling_preserved).
