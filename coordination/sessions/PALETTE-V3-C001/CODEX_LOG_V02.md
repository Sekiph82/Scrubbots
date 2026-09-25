# MAINT-PALETTE-V3-C001 — Canonical Alpix Palette Cross-Repository Migration
Document role: CODEX BUILDER LOG

## Chronology

- Starting timestamp: 2026-09-25 Europe/Istanbul.
- Canonical repository/root: `Sekiph82/Scrubbots`, `C:\Users\sekip\Desktop\ScrubBots`.
- Cross-repository authority: `data/palettes/scrubbots_palette_v3.json`.
- Starting branch: `main`; starting HEAD after safe fast-forward: `eab38e9`.
- The repository was fetched and fast-forwarded only; no reset, rebase, stash, force-push, or owner-file cleanup was used.
- Pre-existing owner untracked files were preserved and remain unstaged.
- Root `TASKS.md` and historical coordination/audit/log evidence are protected and will not be edited.

## Initial scope

Audit every live palette-dependent runtime, data, config, test, fixture, documentation, UI, generator, validator, and hard-coded color table. Preserve C01..C16 and BG01 exactly from the canonical V3 JSON. Historical Palette V2 provenance may remain only where clearly historical.

Implementation, commands, failures/corrections, tests, changed files, commits, pushes, and final SHA verification will be appended chronologically.

## Implementation chronology

- Updated active `ASSET_GENERATION_MANIFEST.json`, debug renderer fixtures, board fixture loader, Hazard Bot metadata provenance, current docs, Level Factory docs/contract, and production builder to V3. The canonical authority remains `data/palettes/scrubbots_palette_v3.json`.
- Production builder validation now fail-closes on schema/version/owner lock, exact C01..C16 IDs and HEX/RGB values, BG01 `#202533` / `[32,37,51]`, global envelope 3..12, and difficulty-independent color legality. Active per-difficulty band enforcement and the old band table were removed.
- Updated `tests/run_tests.gd` and the dedicated V3 Level Data contract test to assert V3 colors, V3 schema, global 3..12 legality, and Level Data format version 1. Updated the six-color live fixture to a valid 20x20 board so it tests color-count semantics independently of dimension rules.
- The first V3 contract run failed because GDScript JSON numeric arrays are float-valued and the BG01 array comparison was type-sensitive. The builder was corrected to compare BG01 channels numerically; the dedicated V3 contract then passed.
- The first aggregate Scrubbots Godot run failed only because the builder could not load the authority due to that BG01 comparison and because the six-color fixture used an invalid 3x2 production board. Both live issues were corrected. Final aggregate result: `5322` checks, `0` failures, `RESULT: ALL PASS`.
- Final active-scope search for `scrubbots_palette_v2`, `global-palette/v2`, old V2 HEX values, and `difficultyColorCountBands` returned no matches outside clearly historical/provenance files, preserved palette archives, protected `TASKS.md`, and historical coordination/audit/legacy evidence.
- `project.godot` audio changes and all pre-existing owner/untracked asset/import/UID files were preserved and left unstaged. Root `TASKS.md` and historical coordination/audit/log evidence were not edited.

## Builder verification

- Dedicated `tests/palette_v3_leveldata_contract.gd`: PASS.
- Aggregate `tests/run_tests.gd`: PASS, `5322` checks, `0` failures.
- Relevant M35-M38/M27-M28 headless scripts: PASS.
- Offline/runtime boundary: no remote runtime dependency, telemetry, API key, or cloud image generation was added.
- Dependency/license/security review: no dependency or license changes; no secrets added.
- Implementation commit SHA, evidence-log commit SHA, push results, and final local/remote equality are recorded below after publication.

## Publication

- Implementation commit: `89eb552` (`MAINT-PALETTE-V3-001 migrate live Scrubbots consumers to Palette V3`).
- Evidence log is being published in a separate builder-log commit after this implementation commit; no product files are added to that evidence commit.

- Evidence-log commit: `4c766bec0ca2823ad32cd09343b6833ecd1c0d3d`.
- Because `origin/main` advanced with four unrelated owner/audit/tracker commits after the initial sync, the local implementation was merged non-destructively with `origin/main` as merge commit `1822e4f4535c1898b26828056e8c0a3f3ab9af1b`; no reset, rebase, force-push, or owner-file cleanup was used.
- Push result: `origin HEAD:main` succeeded from `3a2a10f` to `1822e4f`; the four remote owner/audit/tracker commits were preserved.
- Final Scrubbots publication state before this final log-only update: local `HEAD == origin/main == 1822e4f`; protected `TASKS.md` and pre-existing `project.godot` owner changes were preserved.
