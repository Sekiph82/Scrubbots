# 04 — Roadmap

Milestone-based sequence. Do not implement a later milestone while an
earlier one is incomplete or unvalidated. Each milestone should be small
enough to validate on its own.

> **Note (Prompt 03):** `tasks.md` (project root) is now the authoritative,
> finer-grained master task list (milestones `SB-M00`–`SB-M55`) and should
> be read alongside this file. This roadmap's coarser `M0`–`M15` sequence
> still describes the overall shape of the project; `tasks.md` is where
> day-to-day milestone status and task-level detail actually live.

- **M0 — Project foundation** *(this prompt)*: repo connected to GitHub,
  Godot 4.7 project shell, directory structure, docs, bootstrap scene,
  validation tooling.
- **M1 — Variable-Size Logical Board Engine** *(Prompt 02)*: data-oriented
  BoardState representation whose dimensions come from level data (width ×
  height, derived cell count) — not a fixed board size. Supports at least
  40×40 and 50×50 natively (see ADR-008 in `docs/05_TECH_DECISIONS.md`).
  No rendering yet.
- **M2 — Level data loading** *(Prompt 02, extended in Prompt 03)*:
  LevelLoader + LevelValidator read Version 1 level data
  (`docs/03_LEVEL_DATA_SPEC.md`) into LevelData, which BoardState is then
  built from. Prompt 03 added the separate production-legality layer
  (`DifficultyRules` + `ProductionLevelValidator`, ADR-010) — official
  Easy/Medium/Hard/Very-Hard dimension bands, TEST-vs-production
  separation, validated up to the current maximum 59×59 (3,481 cells).
- **M3 — Board rendering** *(Prompt 04 / tasks.md M06)*: efficient
  single-Node (`Image`/`ImageTexture`) rendering of Board State to screen —
  no interactivity yet. Now uses the owner-locked ACTIVE/CLEARED model
  (ACTIVE = source palette color/opaque, CLEARED = transparent) — see
  ADR-011/ADR-019, `docs/01_GAMEPLAY_SPEC.md`, `tasks.md` M10.
- **M4 — Five-slot gameplay foundation**: Slot System data + basic UI
  representation of 5 slots (no dispatch logic yet).
- **M5 — Scrubbot spawning and dispatch**: Scrubbot Dispatcher enforces
  "no Scrubbot leaves without valid work."
- **M6 — Target selection**: `TargetSelector` implementation (first,
  simplest viable strategy).
- **M7 — Routing/path movement prototype**: first `RoutingSystem`
  implementation, kept swappable per `docs/02_TECH_ARCHITECTURE.md`.
- **M8 — Clearing loop**: Scrubbot reaches its reachable target, the cell
  becomes CLEARED (transparent, background shows through), Scrubbot
  disappears — full loop wired end to end.
- **M9 — Win/lose state**: define and implement actual win/lose condition
  (currently `[TO BE DESIGNED]` in `docs/01_GAMEPLAY_SPEC.md`).
- **M10 — Effects and juice**: pooled/toggleable cleaning feedback effects.
- **M11 — Level progression**: multiple levels, level selection/sequencing.
- **M12 — Save/economy**: persistence, win-streak reward mapping
  implementation, currency.
- **M13 — Mobile optimization**: profiling and tuning for real device
  performance targets (60 FPS).
- **M14 — Content pipeline**: tooling to author/import real artwork (any
  supported board size) into Version-N level data.
- **M15 — Polish/release preparation**: final pass before any release
  candidate.

Prompt 01 delivered **M0**. Prompt 02 delivered **M1 and M2** (variable-size
board engine + level data core, validated with 40×40, 50×50, and a small
generic-size fixture). Prompt 03 extended **M2** with official production
difficulty bands and TEST/production separation, validated across the full
20..59 range up to the current maximum 59×59. Prompt 04 delivered **M3**
(BoardRenderer); META-C004 locked its ACTIVE/CLEARED model (ADR-019) —
owner manual QA of the transparent model is still pending. Do not begin M4
(five-slot gameplay foundation) work until a future prompt.


## Parallel roadmap — SCRUBBOTS Level Platform

The mobile-game M00–M55 sequence remains intact. In parallel, two sidecar
roadmaps exist under canonical root \`tasks.md\`:

- LF00–LF10: Level Factory / Generator, solver, difficulty intelligence,
  human editor, batch production, mutation and advanced research.
- CP00–CP09: Content Pipeline, pack/manifest format, staging/production,
  remote runtime, offline cache, rollback/disable/scheduling, provider
  integration and release/security gate.

These tracks may progress only when their dependencies are satisfied. In
particular, solver/legal-move/difficulty semantics must not be invented ahead
of the gameplay milestones that define them.
