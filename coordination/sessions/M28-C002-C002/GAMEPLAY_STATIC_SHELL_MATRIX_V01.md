# M28-C002-C002 — GAMEPLAY STATIC SHELL MATRIX V01

Date: 2026-09-28
Actor: Claude (implementer). No audit verdict or owner acceptance is claimed.
Prompt: `coordination/sessions/M28-C002-C002/task_prompts/SB-M28-C002-C002_STATIC_MASTER_SHELL.md`
Owner authority: `coordination/OWNER_GAMEPLAY_345_STATIC_MASTER_SHELL_V01.md`
Focused evidence: `tests/m28_c002_c002_static_shell.gd` (16/16 cases, 79 ok)
Owner review pack: `coordination/sessions/M28-C002-C002/OWNER_GAMEPLAY_STATIC_SHELL_REVIEW_V01.md`

## 1. Asset intake (Step 0)

- **Source:** `C:\Users\sekip\Desktop\ScrubBots Gorselleri\Game Screens\`, the authorized owner reference folder.
- **Filenames:** the owner supplied the canonical names directly (`SHA256_MANIFEST.json` + `README.txt`). Per the updated decision, acceptance rests on the locked SHA-256 hash, the dimensions and the mapping, not on the filename.
- **Copy method:** byte-for-byte `cp -p` to `assets/ui/final/gameplay/master/`, then hashes re-verified in the repo.
- **Historical master:** `scrubbots_gameplay_master.png` is untouched.

| Canonical file | Mapping | Size | SHA-256 (verified = locked) |
|---|---|---|---|
| `gameplay_v02_shell_5slot_3col.png` | 3 cols / 5 slots | 887×1774 RGBA | `4ee6712df6aedb3ee48d5cf2e2971356bd9df14363e777965c7e4691ca3121da` |
| `gameplay_v02_shell_5slot_4col.png` | 4 cols / 5 slots | 887×1774 RGBA | `dcf92b4fe163d0c5e6543f90943528ea064c08b31ed11d5c26c158265a9a8fac` |
| `gameplay_v02_shell_5slot_5col.png` | 5 cols / 5 slots | 887×1774 RGBA | `c520c5055caff58f5a9a1ff7eb7ceb98ce5873b9abf86e03b183a8442afc7636` |
| `gameplay_v02_shell_6slot_3col.png` | 3 cols / 6 slots | 887×1774 RGBA | `75c148266a4d0aec20a0eb5c299d00a2840e13d8cc10ae6ec60731f0823f8f06` |
| `gameplay_v02_shell_6slot_4col.png` | 4 cols / 6 slots | 887×1774 RGBA | `d3d01b697d14fbb8896b70594c5768dd1be7606a6519aec2aa71770a5fa38a55` |
| `gameplay_v02_shell_6slot_5col.png` | 5 cols / 6 slots | 887×1774 RGBA | `5ad162d288e8c8d33c5e40d0bb3caedb32939165853a602d868a4caa6428c12b` |

The test `masters_locked` re-checks all six hashes and dimensions on every run.

## 2. Architecture

```text
GameplayShellGeometry (data)   six shell ids -> measured master-px tables
GameplayScreen
  selection   shell_id(supply columns 3/4/5, strip capacity 5/6)  ("" = fail closed)
  transform   scale = min(safe.w/887, safe.h/1774); origin = centred  (uniform, 1:2)
  GameplayShell TextureRect     the selected owner master (only static art on screen)
  live overlays via the SAME transform:
    BoardPresentation   BoardRenderer + AgentLayer + (hidden) ScrubRailView geometry
    FiveSlotStrip       slot views on the baked frames (Container, explicit rects)
    BatchSupplyPanel    equal-cell grid over the baked cells (front-only hitboxes)
    Profile             portrait + live Level + live Bot Parts inside the baked frame
    Pause / 2x          flat hit areas = baked boxes; glyph / state fill / live text only
    SpeechBubbleMask    bubble-fill patch over the obsolete baked sentence
    BoosterRow          four live boosters in the reserved lower band
    AdRegion            reserved bottom band (layout only, M57 owns serving)
```

The host (`ProductionGameplayHost`) is unchanged in this cycle. Its existing seams already feed it:
- `refresh_slot_snapshot` after the +1 Slot grow, the rollback and Retry drives the 5↔6 shell switch;
- the HUD, speed and booster pushes are the same as in C001.

## 3. Measured master coordinates (`scripts/ui/gameplay_shell_geometry.gd`)

How each value was measured:
- **Slot / supply cells:** hole-fill interior detection inside the light rims (scipy). Two cells that glare merged were inferred from the regular spacing and confirmed on a 3× ruler crop.
- **Rail centrelines:** midpoint of the two chrome rods, median over 90–130 scan lines per side. This agrees with manual ruler readings (left ≈ 77, right ≈ 810, top 210, bottom ≈ 961).
- **Connector x:** cyan chevron clusters between the rail and the slot tray.
- **Top boxes:** navy-interior detection; identical across all six masters to ±1 px.
- **Bubble:** white-blob detection. The baked sentence spans ≈ x 37–187 × y 1200–1317.

| Shell | rail L/R/T/B | slot centres x | baked connector x | supply cols × rows |
|---|---|---|---|---|
| 5slot_3col | 76.5 / 811 / 210 / 960.5 | 234, 340.5, 447, 553, 659.5 | 234, 340.5, 447.5, 558, 663 | 3 × 3 |
| 5slot_4col | 77.5 / 810.5 / 210 / 960.5 | same | 234, 341, 448, 558, 663 | 4 × 3 |
| 5slot_5col | 77.5 / 810.5 / 210 / 961 | same | 234, 341, 448, 557.5, 663 | 5 × 3 |
| 6slot_3col | 77.5 / 810 / 210 / 962 | 174.5 … 713.5 | 172, 281.5, 389.5, 496.5, 606.5, 716 | 3 × 3 |
| 6slot_4col | 77.5 / 810 / 210.5 / 961.5 | 190 … 697 | 188.5, 288.5, 392.5, 493.5, 595.5, 697 | 4 × 3 |
| 6slot_5col | 77.5 / 809.5 / 210.5 / 961.5 | 194.5 … 688.5 | 194.5, 294.5, 394.5, 492.5, 592.5, 692 | 5 × 3 |

Shared across all six:
- Profile (46,30)–(407,157)
- Pause (626,34)–(725,130)
- 2x (747,34)–(850,130)
- Bubble text mask (30,1196)–(195,1324)
- Boosters band (196,1582)–(691,1680)
- Ad band (0,1690)–(887,1774)

## 4. Requirement → evidence

| # | Requirement | Implementation | Test (case) / result |
|---|---|---|---|
| 1 | shell by supply column count | `Shell.shell_id(cols, cap)` | `shell_selection_matrix`: 3/4/5 × 5/6 → exact ids and texture paths; 2 columns → "" (fail closed, no shell drawn) |
| 2 | no duplicate visible rail | `ScrubRailView.visible = false` (kept only as the geometry provider) | `no_duplicate_chrome` |
| 3 | no duplicate slot frames/connectors | slot views in shell mode: EMPTY = `StyleBoxEmpty`; no connector drawing | `no_duplicate_chrome`; `six_slot_switch` (6 connectors come from the 6-slot master) |
| 4 | BoardRenderer on the shell aperture | board fitted so the runtime loop (±2.5 cells) meets the baked rail; renderer at an integer cell, presentation scaled by the fractional remainder | `board_on_baked_rail`: L1 20×20, L2 32×32, L3 38×38, L5 33×33 at 1080×2160 / 1080×1920 / 1536×2048 — max centreline error **4.3–4.9 px** (≈0.2 cell); board ≥ 2 cells inside the rail, aspect exact |
| 5 | agents on the baked rail | runtime routing unchanged; one board transform | `agents_on_baked_rail`: 9 334 bottom-rail samples within 4.9 px of the baked centreline; 6 170 connector samples within 6.1 px of the baked connectors |
| 6 | five slot overlays on the baked slots | explicit rects = baked frames | `slot_overlays_align`: all ≤ 1.5 px; runtime `origin_for_slot(i)` on the baked connectors (≤ 6 master px, i.e. baked-art tolerance) |
| 7 | 6-slot master only at capacity 6; 5-slot restored | selection by live strip capacity | `six_slot_switch`: 3, 4 and 5 columns, 3 cycles each; 6 overlays on 6 baked frames; ACTIVE-cell count, supply snapshot and existing slot snapshots unchanged; node count stable |
| 8 | supply overlay/hitbox alignment | equal-cell grid, baked gaps × scale | `supply_align_345`: max error 2.1 / 1.1 / 1.8 px (3 / 4 / 5 columns) |
| 9 | front-only input law | M29 logic unchanged | `front_only_input` (preview cells IGNORE and unconnected; front press → real placement; slots are not buttons) |
| 10 | profile dynamic data only | children = Portrait, Name, Level, BotPartsBar, BotPartsText | `profile_dynamic_only` |
| 11 | Pause/2x in the baked boxes | flat buttons = baked boxes; pause bars / play triangle drawn natively; 2x text; selected = translucent cyan fill, auto = green | `pause_2x_boxes` |
| 12 | timed countdown / anti-rollback | unchanged host HUD path (`SpeedEntitlementService`) | `timed_2x_wallclock`: 15:00 → 13:58 after +62 s; frozen on rollback; auto state after expiry |
| 13 | four boosters + reserved ad region | `BoosterRow`, `AdRegion` | `boosters_and_ad_region` |
| 14 | obsolete bubble text not visible | opaque `SpeechBubbleMask` in the bubble's own fill | `bubble_text_masked`: mask ⊇ measured text box; no tutorial copy |
| 15 | responsive reference-transform invariants | uniform aspect-fit | `responsive_transform`: 7 sizes; real shell node rect is 1:2 inside the safe rect and equals the overlay transform; pause, slot, supply and booster rows on their references; round-trip ≤ 4e-6; notch 141 / gesture 102 case |
| 16 | no node/signal accumulation | — | `no_accumulation` (5 retries: 124 → 124 nodes, no signal/timer growth) + `six_slot_switch` |

## 5. Sensitivity (mutation → focused suite → restored from a byte copy)

| Mutation | Result |
|---|---|
| second rail skin visible | FAIL 4 |
| capacity ignored (always 5-slot shell) | FAIL 4 |
| columns ignored (always 5-col shell) | FAIL 14 |
| non-uniform stretch of the shell node | FAIL 6. The first attempt passed because the test read the transform, not the node. The test now measures the real `GameplayShell` rect. |
| bubble text left unmasked | FAIL 1 |
| integer-only board fit (no fractional scale) | FAIL 7 (rail error 12.9–19.1 px) |
| supply grid gaps ignored | FAIL 10 (18.9–33.3 px) |

## 6. Defects found and fixed during this cycle

1. **Selection timing:** shell selection ran after an early size-0 return, so a new screen had no shell until the first real layout. Selection now depends only on authoritative facts and runs first.
2. **Rail misfit of 13–27 px:** the baked loop is not exactly square (≈733 × 750 master px) and the renderer floors cell size. Fixed with a square cell at the mean of the two fits, capped at 3 % over the strict fit so non-square boards stay inside the rail, plus a fractional scale on the whole `BoardPresentation`.
   - `BoardRenderer.get_cell_center_global` is now transform-aware. Its only caller is the screen accessor, and the result is identical when unscaled.
3. **Booster row stuck at the previous (larger) minimum after a viewport shrink:** the row was placed before its buttons' minimum sizes were updated. The order is fixed and a regression check was added.
4. **New PNGs not imported:** the new masters needed a Godot import pass (`godot --headless --import`). The `.import` files are untracked, like all others in the repo.

## 7. Scope notes

- **No 4/5-column production content:** all First 10 levels are 3-column (owner supply plans; the Level 1 generator defaults to 3). The 4- and 5-column shells are exercised on the real host with the M23 generator `column_count` = 4 / 5 on Level 1 content. That is a harness setting; no level content or supply plan was changed.
- **Non-square boards:** none are in the current catalog. The shell fit keeps a non-square board inside the baked rail, but the runtime loop can then only meet the baked rail on one axis. This is flagged for the owner in case such content is authored.
- **Assets not used:**
  - `buttons/icon_pause.png` is a broken PNG stream;
  - `buttons/icon_speed_2x.png` carries its own outer button frame, which would duplicate the baked box.
  Native glyphs and text are used instead.
- **Removed:** the C001 native chrome (rail skin rendering, slot tray, supply tray, profile panel, control art, gradient backdrop, decorative Scrubby/props nodes). The Scrubby, speech and props anchors remain as invisible rects on the baked art, for tests and the M44 tutorial text anchor.
