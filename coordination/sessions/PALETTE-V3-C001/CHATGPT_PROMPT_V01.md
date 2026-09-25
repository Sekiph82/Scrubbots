# PALETTE-V3-C001 V01 — Repair Palette V3 / Level Data V1 Mismatch

Read first:
- `coordination/sessions/PALETTE-V3-C001/CHATGPT_AUDIT_CRITERIA_V01.md`
- commit `d6bb8df`
- `docs/03_LEVEL_DATA_SPEC.md`
- `docs/08_PIXEL_ART_PALETTE_RULES.md`
- `data/palettes/scrubbots_palette_v3.json`
- `scripts/data/level_data.gd`
- `scripts/data/level_loader.gd`
- `scripts/tools/production_art_level_builder.gd`

The owner-approved Alpix palette migration is valid.
The defect is that the Hazard Bot Level Data schema version was accidentally bumped from 1 to 2.

## Required implementation

1. In `data/levels/m21_level_001_hazard_bot.json`:
   change `"version": 2` back to `"version": 1`.

Do NOT revert the new palette colors.
Do NOT change the cells.
Do NOT change the source/preview migration back to v2.

2. Keep runtime Level Data at V1.
Do not change `LevelData.FORMAT_VERSION`.
Do not broaden LevelLoader to accept version 2.

3. Synchronize active docs:
- `docs/03_LEVEL_DATA_SPEC.md`
- `docs/08_PIXEL_ART_PALETTE_RULES.md`
- `CLAUDE.md`

Use `scrubbots_palette_v3.json` and the exact v3 C01..C16 table as current authority.
Explicitly document that palette v3 does NOT imply Level Data V3/V2.

Historical v2 files/references may remain only when clearly historical/migration provenance.

4. Add a focused headless regression, e.g.
`tests/palette_v3_leveldata_contract.gd`, proving:
- palette authority is schema `scrubbots-global-palette/v3`, version 3;
- Hazard Bot JSON version is 1;
- LevelLoader loads it successfully;
- its local palette is a subset of palette v3;
- ProductionArtLevelBuilder/LevelData format remains version 1.

5. Run the exact current-main regressions required by the criteria.
Do NOT use a throwaway revert this time. The repaired `main` itself must pass.

6. Create:
- `coordination/sessions/PALETTE-V3-C001/task_logs/SB-PAL-V3-001.md`
- `coordination/sessions/PALETTE-V3-C001/CLAUDE_LOG_V01.md`

Log before/after evidence:
- pre-fix unsupported version 2;
- post-fix Hazard Bot load success;
- M33 9/9;
- M41 13/13;
- repaired M38 11/11;
- root full result;
- zero SCRIPT ERROR.

Do not edit `TASKS.md`.
Do not self-audit.
Do not start unrelated work.

Handoff:
`AWAITING_AUDIT / PALETTE-V3-C001 V01 / LEVELDATA-V1 CONTRACT REPAIRED`
