# SB-PAL-V3-001 — Palette V3 / Level Data V1 contract repair

Status: IMPLEMENTED (AWAITING_AUDIT)
Commits: `744d8f1` (level version + docs + contract test), `5850043` (root-suite v2->v3 expectation sync, test-only)

## Pre-fix (main `9fe13ab`)
`LevelLoader.load_from_path("res://data/levels/m21_level_001_hazard_bot.json")` ->
`ok=false errors=["Level m21_level_001_hazard_bot: unsupported version 2.0 (expected 1)"]`.

## Fix
- `data/levels/m21_level_001_hazard_bot.json`: `"version": 2` -> `"version": 1` (single-line diff; v3 palette `#FF4500FF #FFD635FF #2450A4FF #9C6926FF #000000FF`, cells, id, size, difficulty unchanged).
- `LevelData.FORMAT_VERSION` (1) and `LevelLoader` untouched. No Level Data V2.
- Active docs synced to palette v3: `docs/03_LEVEL_DATA_SPEC.md` (example palette, §4.2 authority + explicit "palette version change does not change Level Data schema version"), `docs/08_PIXEL_ART_PALETTE_RULES.md` (title V3, v3 source, exact C01..C16 table from the JSON, v2 labeled historical), `CLAUDE.md` §7.
- `data/palettes/scrubbots_palette_v2.json` kept (historical).
- `tests/run_tests.gd` M21 bridge/artifact section: v2 hexes remapped by stable C-ID to v3; source provenance constants -> blob `4af4a2d4...`, sha256 `34dfa354...`, 279 bytes (values recorded by owner commit `d6bb8df` metadata; verified with `git hash-object` / `sha256sum`).

## Post-fix
Hazard Bot loads (LevelData version 1, 400 cells). New `tests/palette_v3_leveldata_contract.gd` 6/6. Sensitivity: with the JSON at version 2 the contract test fails (2 FAIL: version != 1, loader unsupported version 2.0).
