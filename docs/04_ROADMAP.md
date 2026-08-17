# 04 — Roadmap

Milestone-based sequence. Do not implement a later milestone while an
earlier one is incomplete or unvalidated. Each milestone should be small
enough to validate on its own.

- **M0 — Project foundation** *(this prompt)*: repo connected to GitHub,
  Godot 4.7 project shell, directory structure, docs, bootstrap scene,
  validation tooling.
- **M1 — Variable-Size Logical Board Engine** *(Prompt 02)*: data-oriented
  BoardState representation whose dimensions come from level data (width ×
  height, derived cell count) — not a fixed board size. Supports at least
  40×40 and 50×50 natively (see ADR-008 in `docs/05_TECH_DECISIONS.md`).
  No rendering yet.
- **M2 — Level data loading** *(Prompt 02)*: LevelLoader + LevelValidator
  read Version 1 level data (`docs/03_LEVEL_DATA_SPEC.md`) into LevelData,
  which BoardState is then built from.
- **M3 — Board rendering**: efficient batched rendering of Board State to
  screen (no interactivity yet).
- **M4 — Five-slot gameplay foundation**: Slot System data + basic UI
  representation of 5 slots (no dispatch logic yet).
- **M5 — Scrubbot spawning and dispatch**: Scrubbot Dispatcher enforces
  "no Scrubbot leaves without valid work."
- **M6 — Target selection**: `TargetSelector` implementation (first,
  simplest viable strategy).
- **M7 — Routing/path movement prototype**: first `RoutingSystem`
  implementation, kept swappable per `docs/02_TECH_ARCHITECTURE.md`.
- **M8 — Cleaning/reveal loop**: Scrubbot reaches target, cell cleans,
  Scrubbot disappears — full loop wired end to end.
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

Prompt 01 delivered **M0**. Prompt 02 delivers **M1 and M2** (variable-size
board engine + level data core, validated with 40×40, 50×50, and a small
generic-size fixture). Do not begin M3 work until a future prompt.
