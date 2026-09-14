# SCRUBBOTS Content Platform Tracker Handoff V01

Status: ACTIVE
Date: 2026-09-14

## Canonical tracker split

### Game / client

Canonical tracker remains:

`Sekiph82/Scrubbots/TASKS.md`

It owns gameplay, UI, progression/runtime and release work for the shipping game.

### Content Platform

Canonical tracker for the migrated 224 tasks is:

`Sekiph82/ScrubBots-Level-Factory/TASKS.md`

It owns program state for:

- LF00-LF10, 112 tasks;
- CP00-CP09, 112 tasks.

## Shadow rows in this repository

The existing `SB-LF*` / `SB-CP*` rows retained in this repository are frozen shadow/history entries after `OWNER_CONTENT_PLATFORM_CONSOLIDATION_DECISION_V01.md`.

Rules:

- do not mark those shadow rows complete here;
- do not use them to discover the active Content Platform task;
- do not calculate Content Platform completion from them;
- use the external canonical tracker instead.

A future dedicated tracker-compaction task may replace the shadow block with a pointer once doing so can be performed without disturbing active gameplay tracker state.

## Runtime implementation routing

Canonical task tracking and code location are intentionally separate.

For `GAME_RUNTIME` tasks such as CP04/CP05:

- tracker state lives in the Content Platform repository;
- code lands in this main-game repository;
- implementation must obey this repository's `CLAUDE.md`, audit policy and runtime contracts;
- final end-to-end task acceptance is written by ChatGPT to the Content Platform tracker after cross-repo audit.

## Current parallel work

The active game milestone M22 may continue independently while Content Platform migration/evidence work proceeds in the Level Factory repository.

Do not delay M22 merely because Content Platform tasks were migrated.

## Progress presentation

Always distinguish:

- Game/client progress;
- Content Platform progress /224;
- Combined program progress.

Tracker relocation does not change actual completion.
