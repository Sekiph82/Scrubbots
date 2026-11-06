# Spec: 20 Release Pool levels as campaign L11-L30

Task: SB-CAMPAIGN-L11-L30 (owner chat 2026-10-30: "10 bolum daha yukleyelim ... yada 20 bolum
daha yukleyelim"; owner delegated the choices). The shipping catalog has 10 levels while
Collection/card_packs unlock at L20, so fresh players can never reach them.

## Source
Level Factory Studio release pool (owner's separate project, READ ONLY):
`C:/Users/sekip/Desktop/Scrubbots - Pixel Art Generator/Release/ScrubBots Factory Studio/level_factory/output/studio-extensions/release-pool/*-ready.json`
(schema `scrubbots-release-pool-entry/v1`). Only `candidate-owner-*` entries (owner art,
`EXACT_LOGICAL_OWNER_UPLOAD_TO_CANONICAL_CANDIDATE`), one per distinct source art, every
`files.level` / `files.supply_plan` / `files.artwork` sha256 verified against the entry.

## Build
1. Select 20 entries for L11..L30, roughly following the locked cadence
   (E E M E H E E M E VH, repeating) by the entry's `difficulty_class` and challenge score.
   The pool has no EASY or VERY_HARD entries: EASY slots take the lowest-score MEDIUM entries,
   VERY_HARD slots the highest-score HARD entries. Prefer moderate session load and avoid
   near-identical neighbours and repeats of L1..L10 subjects. All boards square (S6-C).
2. Import as `level_011_<name>` .. `level_030_<name>` in this repo's format: level JSON,
   supply plan, metadata, preview PNG. Format/metadata only: `cells`, `palette`, `width`,
   `height`, `version` copied verbatim; only `id`, `name`, `difficulty` (campaign slot class)
   change, and the supply plan's `levelId`/`batchId` labels. Metadata carries release-pool
   provenance (entry_digest, candidate_id, source/artwork/level/supply sha256, pool class,
   challenge score, session load). Append entries 11..30 to
   `data/levels/catalog/production_catalog_v1.json`.
3. Committed importer script so the import is reproducible from the pool.

## Acceptance criteria
1. Production catalog loads with 30 entries, orders 1..30, no validation errors; every new
   level passes LevelValidator + ProductionLevelValidator (palette V3 C01..C16, 3..12 colours,
   20..59 envelope, square, VOID version-2 rules, >= 200 non-VOID cells and >= 25%).
2. New level cells/palette are byte-for-byte the pool level's; preview pixels equal the pool
   artwork.png.
3. Each new level WINs with its supply plan in this repo's solver/replay (SupplyPlanLoader
   exact engine + solvability solver or replay of a recorded solution).
4. Feature unlocks (feature_unlocks_v1.json) and end-of-catalog handling behave at L30 as they
   did at L10 (frontier 31 -> CONTENT_MISSING / remote content appended after the last builtin).
5. New permanent suite `tests/campaign_l11_l30.gd` (30 levels in order, all load, palette /
   envelope / provenance rules, cells equal recorded digests) is in the CI validate loop with an
   exact-summary guard; workflow header count bumped from 60 to 61; `tools/run_suites.py --list`
   shows it. Suites assuming exactly 10 levels are updated honestly, no real check weakened.
6. All CI validate suites LOCAL_PASS. Added bytes (APK/IPA impact) reported.
7. TASKS.md: DONE row under `## Autonomous Queue` with LOCAL_PASS evidence, CRLF preserved.
