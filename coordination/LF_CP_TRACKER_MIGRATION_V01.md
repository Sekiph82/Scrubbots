# LF / CP Tracker Migration V01

Date: 2026-09-14

## Decision

The Level Factory + Content Platform program is tracked canonically in:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

The main `Sekiph82/Scrubbots` repository remains the canonical mobile game/runtime tracker.

## Migration scope

The following former game-side sidecar checklist families were migrated out of the game tracker live denominator:

- `SB-LF00-001..SB-LF10-008` — 112 Level Factory source requirements.
- `SB-CP00-001..SB-CP09-010` — 112 Content Pipeline source requirements.

Total migrated source requirements: 224.

The IDs and requirement meanings were not deleted. They are preserved in the Factory root tracker and mapping ledger:

- `docs/migration/LF_CP_REQUIREMENT_MAPPING_V01.md` in `Sekiph82/ScrubBots-Level-Factory`
- `docs/migration/LEVEL_FACTORY_CONTENT_PLATFORM_UNIFICATION_V01.md` in `Sekiph82/ScrubBots-Level-Factory`

## Runtime ownership exception

These canonical program requirements are implemented in this game repository when their runtime milestones activate:

- `SB-CP04-001..014`
- `SB-CP05-001..012`
- `SB-CP06-004`
- `SB-CP06-010`

They remain canonical requirements in the Factory tracker. Main-game implementation/audit evidence is linked back there after independent acceptance.

## Tracker arithmetic

Immediately before migration, the game tracker reported:

`337 / 729 = 46.23% (main+ui); overall 337 / 953 = 35.36%`

The exact denominator delta was 224, matching the migrated LF/CP source requirements.

After migration, the game tracker live scope is:

`337 / 729 = 46.23%`

This is ownership normalization only. No gameplay task was marked complete as part of this migration.

## Gameplay-state preservation

The migration does not change the active game milestone/sprint/task:

- M22
- M22-C001 V02
- Scrubbot Railroad V1 + slot connector integration
- Required actor: CLAUDE

No M22 checklist state was changed by the LF/CP tracker migration.

## Cutover evidence

- Main-game pre-migration HEAD: `2fa0e40b1fbb7b0cf5063dda6be0734cb5fa8544`
- Main-game pre-migration `TASKS.md` blob: `41b031386067ab58ae0aebfad53c6b98d5cad4e2`
- Main-game tracker migration commit: `42ee8b299df68ec49d5600fb30785dd2bdbf25de`
- Main-game post-migration `TASKS.md` blob: `2bd8ee0e6a675fea44524e9f9952a4b39babe5b5`

Factory cutover evidence is recorded in the Factory repository migration documents.
