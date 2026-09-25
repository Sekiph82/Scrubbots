# PALETTE-V3-C001 V01 — Palette V3 / Level Data V1 Contract Repair Criteria

Date: 2026-09-25

Authority:
- owner-approved Alpix-aligned `data/palettes/scrubbots_palette_v3.json`
- `docs/03_LEVEL_DATA_SPEC.md`
- `LevelData.FORMAT_VERSION == 1`
- commit `d6bb8df`

This is a targeted compatibility repair. Do not roll back the palette-v3 colors.

PASS requires:

1. Palette version and Level Data schema remain separate concepts.
   - canonical palette: v3;
   - canonical current Level Data schema: v1.

2. `data/levels/m21_level_001_hazard_bot.json`:
   - keeps the new Alpix-aligned v3 colors;
   - changes ONLY its schema field back to `"version": 1`;
   - preserves width/height/cells/id/difficulty and v3 local palette semantics.

3. Do NOT change `LevelData.FORMAT_VERSION` to 2.
   Do NOT make LevelLoader accept a fake/undefined Level Data V2.
   A genuine Level Data V2 is not authorized.

4. Active authority documentation must be synchronized to palette v3:
   - `docs/03_LEVEL_DATA_SPEC.md`;
   - `docs/08_PIXEL_ART_PALETTE_RULES.md`;
   - `CLAUDE.md`.
   Their active canonical palette references/table/examples must use v3.
   Historical/migration references to v2 may remain only when explicitly labeled historical/from-v2.

5. `docs/03_LEVEL_DATA_SPEC.md` must explicitly state:
   a palette-authority version change does not by itself change Level Data schema version.

6. Keep `data/palettes/scrubbots_palette_v2.json` as historical data; do not delete it.

7. Add a regression that proves:
   - canonical palette schema/version is v3;
   - Hazard Bot Level Data version is 1;
   - Hazard Bot loads through LevelLoader;
   - every Hazard Bot local palette color belongs to canonical palette v3;
   - ProductionArtLevelBuilder still emits `LevelData.FORMAT_VERSION` (1), not palette version 3.

8. Run on actual repaired `main`, with zero SCRIPT ERROR:
   - new palette/LevelData contract test;
   - m29_hazard_bot_runtime_smoke;
   - m33_audio_runtime (9/9);
   - m41_settings (13/13);
   - m40_v04_bootstrap;
   - m38_v02_strict (11/11);
   - m39_v04_integration;
   - root run_tests (expected full green, not the current 5126/16-error state).

9. No unrelated production behavior changes.
10. Root `TASKS.md` must not be edited.

Successful handoff:
`AWAITING_AUDIT / PALETTE-V3-C001 V01 / LEVELDATA-V1 CONTRACT REPAIRED`
