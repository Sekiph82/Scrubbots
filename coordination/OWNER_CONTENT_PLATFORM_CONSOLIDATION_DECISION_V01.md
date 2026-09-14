# OWNER CONTENT PLATFORM CONSOLIDATION DECISION V01

Status: **OWNER-LOCKED**
Date: 2026-09-14
Owner: Şekip

## Decision

The canonical program home for the 224 SCRUBBOTS Level Factory + Content/Update Platform tasks is now:

`https://github.com/Sekiph82/ScrubBots-Level-Factory`

Canonical Content Platform tracker:

`https://github.com/Sekiph82/ScrubBots-Level-Factory/blob/main/TASKS.md`

The migrated ranges are:

- `SB-LF00-*` through `SB-LF10-*` — 112 tasks.
- `SB-CP00-*` through `SB-CP09-*` — 112 tasks.

The matching LF/CP rows currently retained in this main-game `TASKS.md` are henceforth **shadow/historical roadmap rows**. They must not be independently advanced here. Canonical acceptance/checklist state for those IDs lives in the Content Platform repository.

This decision does not alter the active M22 gameplay/UI sprint.

## Main-game responsibility after migration

`Sekiph82/Scrubbots` remains the canonical shipping game/client runtime and owns:

- gameplay;
- Godot presentation/UI;
- LevelData/runtime catalog consumption;
- runtime `RemoteContentManager`;
- HTTPS manifest/pack download;
- hash/integrity validation;
- `user://` remote-content registry/cache;
- atomic activation and last-known-good fallback;
- offline play behavior;
- application permissions/store-facing runtime behavior.

## Cross-repo tasks

Some canonical Content Platform tasks are implemented here even though their tracker lives in `ScrubBots-Level-Factory`.

Primary examples:

- `CP04 — Godot Remote Content Runtime`
- `CP05 — Offline Cache & Last-Known-Good Recovery`
- runtime portions of CP06/CP09.

For those tasks:

1. Content Platform `TASKS.md` declares `GAME_RUNTIME` or `CROSS_REPO` ownership.
2. The implementation prompt explicitly names `Sekiph82/Scrubbots` as an authorized write repository.
3. Builder follows this repository's gameplay/runtime governance while implementing.
4. ChatGPT audits both producer and consumer evidence.
5. Final canonical task checkbox is updated in `ScrubBots-Level-Factory/TASKS.md`.

## Dependency boundary

The game never imports/preloads Factory or Publisher source code.

Legal flow:

`Factory/Publisher -> declarative versioned artifacts -> Game Runtime`

Remote content is declarative only and may not deliver executable scripts/native libraries/plugins/arbitrary evaluated code.

Runtime remote content installs under `user://`, never rewrites `res://`.

## Difficulty and content contract authority

This main repository remains authoritative for owner-locked gameplay, LevelData, palette, Difficulty V1, campaign and runtime semantics.

The Content Platform must migrate away from stale historical assumptions that:

- difficulty class equals board-dimension band;
- difficulty class equals fixed used-color band.

Current relevant truth includes rectangular boards, C01..C16, general 3..12 production used-color envelope, Challenge/Session Load/Frustration separation and owner-locked campaign cadence.

## Progress reporting

From this decision onward, report three figures separately:

1. **Game/client** completion from the main-game task set.
2. **Content Platform** completion out of 224 from `ScrubBots-Level-Factory/TASKS.md`.
3. **Combined SCRUBBOTS program** completion using both numerators/denominators.

Moving the tracker does not create task-completion credit.

The current main-game header already reports game-only and combined progress separately; denominator separation is therefore retained rather than treated as new development progress.

## Parallel-agent rule

Claude may continue game work in `Sekiph82/Scrubbots` while Codex advances the Content Platform in `Sekiph82/ScrubBots-Level-Factory`.

Neither builder may opportunistically write into the other repository unless an explicit cross-repo prompt authorizes it.

## Precedence

This owner decision supersedes older main-game tracker text that says LF/CP sidecar task acceptance is written only in this root tracker. Historical rows remain for traceability until a later safe tracker compaction, but they are no longer canonical current state for those 224 IDs.
