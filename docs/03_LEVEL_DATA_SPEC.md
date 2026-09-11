# 03 — Level Data Specification

Status: **Level Data V1 implemented; production-difficulty semantics updated by owner 2026-09-12**

Canonical owner decision:
`coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`

Difficulty/progression model:
`docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`

## 1. Scope

Level Data V1 is deliberately small and stable. It stores the logical artwork/puzzle source needed to construct runtime board state. It does **not** store runtime ACTIVE/CLEARED state, analytics, campaign sequencing or mutable solver output.

The board engine remains variable-size and dimension-generic.

## 2. Version 1 format

```jsonc
{
  "version": 1,
  "id": "level_001",
  "name": "Display Name",
  "difficulty": "EASY",
  "width": 20,
  "height": 20,
  "palette": ["#E94B4BFF", "#F2C94CFF", "#3451A3FF", "#956447FF", "#000000FF"],
  "cells": [0, 0, 2, 2 /* ... exactly width*height entries ... */]
}
```

### Fields

- `version`: required integer, currently exactly `1`.
- `id`: required non-empty stable level identifier.
- `name`: required non-empty display name.
- `difficulty`: required non-empty string. Production campaign uses `EASY`, `MEDIUM`, `HARD`, `VERY_HARD`; `TEST` is development-only and never production content.
- `width`, `height`: required positive integers.
- `palette`: required non-empty local palette. Palette ID is local array index.
- `cells`: required row-major integer palette IDs; length exactly `width * height`.

Canonical cell index:

`index = y * width + x`

## 3. Structural validation

`LevelValidator` answers only:

> Is this Level Data V1 internally valid?

Structural rules include:

- supported version;
- required fields/types;
- positive dimensions;
- non-empty palette;
- exact cell count;
- every cell palette ID in range.

Structural validation remains dimension/difficulty agnostic. A 3x2 TEST fixture can be structurally valid.

## 4. Production legality under Difficulty V1

Production legality is separate from structural validity.

### 4.1 Production board envelope

Current engine/content envelope:

- width: 20..59;
- height: 20..59;
- rectangular boards allowed;
- maximum 59x59 = 3481 logical cells.

This envelope is **not** an EASY/MEDIUM/HARD/VERY_HARD mapping.

Historical runtime code still contains the legacy class-specific dimension validator (`DifficultyRules` / `ProductionLevelValidator`). That behavior is migration debt after the 2026-09-12 owner decision. Until the audited migration lands, M21 may use it as a compatibility gate for the approved 20x20 vertical-slice asset only.

No new scaled production campaign should be authored by assuming:

```text
EASY = 20..29
MEDIUM = 30..39
HARD = 40..49
VERY_HARD = 50..59
```

### 4.2 Production palette contract

Canonical global palette:
`data/palettes/scrubbots_palette_v2.json`

Production rules:

- ACTIVE logical cells use only C01..C16;
- ACTIVE alpha is 255;
- local palette contains only actually used canonical colors;
- local palette ordered by ascending global C-ID;
- no unused/off-palette entry;
- CLEARED transparency is runtime state, not palette data;
- BG01 is presentation background, not a logical color;
- production artwork normally uses 3..12 distinct canonical colors under Difficulty V1.

The historical color-class bands `EASY 3–5 / MEDIUM 6–7 / HARD 8–9 / VERY_HARD 10–12` are superseded as class-legality rules. Color count/distribution instead contributes to Challenge Score.

## 5. Difficulty field semantics

The `difficulty` field remains in V1 for compatibility and production labeling, but Difficulty V1 changes what the label means.

For final campaign content the class comes from the campaign cadence/target-fit system:

```text
EASY, EASY, MEDIUM, EASY, HARD,
EASY, EASY, MEDIUM, EASY, VERY_HARD
```

repeating every ten levels.

A level qualifies for a campaign slot because its measured Challenge Score fits the slot's target envelope and its Session Load / Frustration / retention gates pass. It does not qualify merely because width/height or color count match an old table.

The same legal level artifact may be suitable for a different campaign slot when measured metrics support it; campaign ordering is separate from cell data.

## 6. Difficulty metrics do not belong inside core Level Data V1

Challenge analysis is derived/versioned data. Do not mutate Level Data V1 every time a scoring model changes.

Store analysis/catalog metadata separately, including:

```text
campaignLevelNumber
cadenceSlot
class
TargetChallenge
challengeScore
W,C,A,U,B,R,S
sessionLoad
frustrationRisk
noveltySignature
scoreModelVersion
progressionModelVersion
solverVersion
generatorVersion
sourceHash
levelDataHash
```

This belongs in Factory QA/catalog/campaign metadata rather than the immutable logical cell contract.

## 7. LevelData vs BoardState

LevelData describes initial logical artwork.

Runtime `BoardState` is built fresh from LevelData:

- all logical cells begin ACTIVE;
- ACTIVE stores source color identity;
- gameplay changes cells to CLEARED;
- runtime reservations, access truth and clearing progress do not rewrite source LevelData.

This separation is locked.

## 8. TEST fixtures

`TEST` is development-only.

Current generic fixtures under `data/levels/` prove engine behavior at small/large/rectangular dimensions. TEST content must never be exposed through the production catalog/campaign.

Examples include:

- 3x2 generic engine proof;
- 40x40 fixture;
- 50x50 fixture;
- 59x59 maximum-capability fixture.

These are test workloads, not examples of how production difficulty classes should be sized.

## 9. M09 exact-pixel importer

`scripts/tools/level_importer.gd` converts PNG to Level Data V1.

Historical audited guarantees remain valid:

- one source RGBA pixel = one logical cell;
- no resize/resample/interpolation/crop/pad;
- row-major cell mapping;
- PNG-only input gate;
- source immutability;
- destination path alias protection;
- multi-artifact preflight;
- overwrite/unchanged safety;
- deterministic reconstruction from LevelData;
- malformed reconstruction fails safely;
- optional preview/metadata generation.

### 9.1 Legacy importer palette order

The M09 importer historically uses first-seen row-major source-color order.

Difficulty V1 production requires local palette order by ascending canonical C-ID. Therefore exact production ingestion needs a normalization/remapping stage that:

1. proves every opaque source cell is exactly one canonical C01..C16 color;
2. collects the used canonical IDs;
3. sorts used IDs ascending globally;
4. rebuilds local palette in that order;
5. remaps cell local IDs without changing any logical cell's actual canonical color;
6. reconstructs and proves exact RGBA equivalence to source;
7. records normalization provenance.

Do not "fix" this by changing colors.

M21 explicitly tests this requirement with the approved Hazard Bot.

## 10. Import request behavior

Single-item importer request contains:

```text
source path
level id
name
difficulty
output path
optional preview
optional metadata
overwrite flag
```

Current legacy production import checks may still consult old `DifficultyRules` until migration. New production pipeline work must cite the owner Difficulty V1 decision rather than extending those old bands.

## 11. Source immutability and path safety

The source PNG can never be a write destination.

Path safety includes:

- `res://` / `user://` resolution;
- bare relative path resolution against project root;
- separator normalization;
- lexical dot-segment simplification;
- Windows case-folding for identity comparison only;
- output/preview/metadata pairwise non-aliasing.

All requested destinations are preflighted before any write.

## 12. Batch importer

`LevelBatchImporter` is a manifest-driven layer over the single importer.

Manifest item shape:

```json
{
  "source": "path/source.png",
  "id": "level_id",
  "name": "Display Name",
  "difficulty": "EASY",
  "output": "path/output.json",
  "preview": "path/preview.png",
  "metadata": "path/meta.json",
  "overwrite": false
}
```

Batch guarantees include:

- schema/type validation;
- duplicate manifest ID rejection;
- cross-item source/destination alias checks;
- catalog ownership checks in both directions;
- malformed catalog fail-closed behavior;
- destination parent/type preflight;
- validation-only dry run;
- prepare-all-before-commit behavior for predictable failures;
- deterministic report order.

Documented limitation: filesystem writes are not a transactional database. A rare OS failure after clean preflight can leave earlier committed items written. Batch result must report this truthfully.

## 13. Level Factory integration

Level Factory does not replace Level Data.

Flow:

```text
Factory candidate
→ canonical source/LevelData legality
→ solver + metrics
→ acceptance QA
→ campaign sequencing
→ production Level Data + separate analysis/catalog metadata
```

Factory outputs declarative content. Mobile runtime never imports Factory scripts.

## 14. Campaign sequencing separation

CampaignBuilder may reorder accepted levels without modifying their Level Data.

This makes it possible to:

- replace a campaign slot;
- rebalance progression;
- rebuild chapters/events;
- change score-model versions;

without repainting logical artwork.

## 15. Versioning rule

Do not introduce V2 fields into V1 ad hoc.

If future gameplay requires source-level special cells, blockers, initial runtime-state overrides or other new logical data, define Level Data V2 explicitly with migration tests.

Difficulty analysis metadata changing does **not** by itself require Level Data V2 because it remains derived sidecar/catalog data.

## 16. M21 compatibility

The approved real-art M21 source:

`assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png`

is a 20x20 engineering vertical slice. It remains valid under the global 20..59 envelope and C01..C16 rules.

Its legacy EASY compatibility label must not be generalized into future board-size or color-count policy.

## 17. Production content warning

Do not scale production content under the obsolete class-by-dimension/color rules.

Scaled production should wait for the Difficulty V1 Factory analyzer/QA path so accepted content has reproducible Challenge, Session Load, Frustration, novelty and model provenance.
