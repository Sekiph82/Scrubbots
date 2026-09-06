# M10-C001 — Variable Canvas + C16 Pure Black + Coordination Ownership (V06)

Status: **ISSUED — supersedes unimplemented V05**

This V06 combines the already-pending M10 manual-QA correction with a new owner-locked palette expansion.

## Owner-locked palette change

The canonical production logical palette is now **16 colors**:

- C01..C15 unchanged
- **C16 Pure Black = #000000 = RGB(0,0,0)**

Canonical machine-readable source:
`data/palettes/scrubbots_palette_v2.json`

Historical:
`data/palettes/scrubbots_palette_v1.json` remains the old 15-color palette and must not be treated as current authority.

Rules:
- Production logical artwork colors = C01..C16 only.
- C16 is a normal logical artwork color and counts toward a level's distinct-used-color total when actually used.
- BG01 Midnight Slate `#202533` remains outside C01..C16, is not a logical color, and never counts.
- Difficulty distinct-used-color bands remain unchanged:
  - EASY 3–5
  - MEDIUM 6–7
  - HARD 8–9
  - VERY_HARD 10–12
- Do not reinterpret BG01 as black.
- Do not change C01..C15 values.

## First action

Work in `C:\Users\sekip\Desktop\ScrubBots`.

Safely sync local `main` with `origin/main` preserving owner work. No reset-hard, clean-fd, destructive restore, or force push.

Read current:
- CLAUDE.md
- tasks.md
- coordination/README.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/sessions/M10-C001/CHATGPT_AUDIT_V02.md
- coordination/sessions/M10-C001/CHATGPT_AUDIT_CRITERIA_V06.md
- docs/08_PIXEL_ART_PALETTE_RULES.md
- data/palettes/scrubbots_palette_v1.json
- data/palettes/scrubbots_palette_v2.json
- level_factory/data/canonical_visual_contract_v1.json
- scripts/debug/board_renderer_debug.gd
- scripts/debug/board_debug_fixtures.gd
- scripts/debug/board_grid_overlay.gd
- tests/run_tests.gd
- the three data/debug/board_renderer_fixtures/*.json files
- level_factory/CLAUDE.md
- content_pipeline/CLAUDE.md

# PART A — Variable Real Artwork debug canvas

The Real Artwork JSON dimensions are immutable source bounding matrices, not the final debug canvas.

For a selected canvas `canvas_w × canvas_h`, allow rendering only when:
`canvas_w >= source_w` and `canvas_h >= source_h`.

Center source using:
- `offset_x = floor((canvas_w - source_w)/2)`
- `offset_y = floor((canvas_h - source_h)/2)`

Use debug-only VOID padding. Never crop, scale, stretch, resample, repaint or regenerate.

Source invariants:
- 007 source 27×24; artwork 542; source VOID 106.
  - 30×30 -> offset (1,3), debug VOID 358.
  - 59×59 -> offset (16,17), debug VOID 2939.
- 010 source 49×50; artwork 2450; source VOID 0.
  - 50×50 -> offset (0,0).
  - 59×59 -> offset (5,4), debug VOID 1031.
- 013 source 28×31; artwork 375; source VOID 493.
  - 39×39 -> offset (5,4), debug VOID 1146.
  - 59×59 -> offset (15,14), debug VOID 3106.

Keep the Size dropdown usable for Real Artwork. Invalid too-small size options must be disabled or safely rejected without cropping.

Source VOID + padding VOID never become ACTIVE. ACTIVE/CLEARED patterns affect artwork cells only.

Keep BG01 #202533, flat square-cell fills, visible separation, no gloss/highlight/bevel/shadow/3D bead/interpolation, and no per-cell Nodes.

Debug info must show source size, selected canvas size, offset, artwork count, debug VOID count, palette subset, BG01, cell size and pattern.

# PART B — Implement C16 throughout active code/rules/tests

Update active/current references so the project consistently treats palette v2 as canonical.

At minimum:

1. `scripts/debug/board_debug_fixtures.gd`
   - canonical palette path -> `scrubbots_palette_v2.json`
   - suffix range/documentation -> 1..16
   - future real fixtures may legally use C16.

2. `tests/run_tests.gd`
   - expect 16 global C-IDs
   - legal suffix range 1..16
   - add an explicit assertion that C16 = Pure Black #000000.
   - retain existing fixture checks and all V06 variable-canvas checks.

3. Real-artwork fixture metadata
   - if JSON metadata points to palette v1, update only that metadata reference to palette v2.
   - do NOT change their source dimensions, row-major arrays, VOID masks or existing color counts.

4. Scan active repository code/docs/data for stale current-law references such as:
   - `C01..C15`
   - `15-color`
   - `No C16`
   - `C16+`
   - numeric palette limits `<= 15`
   - current-authority references to `scrubbots_palette_v1.json`

   Update only active/current law. Preserve historical evidence/audit files and the historical palette v1 itself.

5. Any production validator/generator/importer/runtime code that hard-limits legal canonical IDs to 15 must be updated to 16 where appropriate. Do not broaden difficulty color-count bands.

6. Black semantics:
   - C16 = logical Pure Black #000000.
   - It is opaque when ACTIVE.
   - It is transparent when CLEARED because state alpha becomes 0.
   - BG01 remains #202533 and separate.

# PART C — Normalize coordination ownership

Owner-locked workflow:

Claude:
- implement
- test
- write matching CLAUDE_LOG
- commit/push safely
- hand back AWAITING_AUDIT
- stop

Claude must NOT update:
- .hiveai/ACTIVE_CYCLES.md
- .hiveai/ARTIFACT_MAP.md
- .hiveai/PROGRESS_SNAPSHOT.md
- .hiveai/PROJECT_DASHBOARD.md
- coordination/SESSION_INDEX.md

ChatGPT owns those after independent audit.

Normalize only the relevant ownership wording in:
- CLAUDE.md
- coordination/README.md
- coordination/VERSIONED_LOG_POLICY.md
- level_factory/CLAUDE.md
- content_pipeline/CLAUDE.md

Do not alter unrelated governance.

# Validation

Required evidence includes:

- palette v2 parses and has exactly 16 colors;
- C01..C15 values unchanged from historical v1;
- C16 exact ID/name/HEX/RGB;
- BG01 unchanged and outside logical palette;
- difficulty used-color bands unchanged;
- all active hardcoded 15-color limits found/updated or explicitly justified as historical;
- 007 fully visible at 30×30 and 59×59 with exact offsets/counts;
- 010 fully visible at 50×50 and 59×59;
- 013 fully visible at 39×39 and 59×59;
- no source JSON grid changes;
- VOID stability under ALL_ACTIVE/ALL_CLEARED/CHECKER;
- Synthetic Stripes unchanged;
- no per-cell Nodes;
- full Godot 4.7.1 headless suite passes;
- debug scene headless boot succeeds;
- governance scan proves Claude no longer owns tracker/dashboard/SESSION_INDEX updates;
- tasks.md checkbox count unchanged;
- M14+ untouched;
- git diff and diff --check reviewed.

## Coordination output

Write only:
`coordination/sessions/M10-C001/CLAUDE_LOG_V06.md`

Do NOT update H!veAI files, PROJECT_DASHBOARD, or SESSION_INDEX.
Do NOT self-audit.

Commit and push safely, hand back `AWAITING_AUDIT`, then stop.
