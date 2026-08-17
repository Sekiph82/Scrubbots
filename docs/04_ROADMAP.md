# 04 — Roadmap

Milestone-based sequence. Do not implement a later milestone while an
earlier one is incomplete or unvalidated. Each milestone should be small
enough to validate on its own.

- **M0 — Project foundation** *(this prompt)*: repo connected to GitHub,
  Godot 4.7 project shell, directory structure, docs, bootstrap scene,
  validation tooling.
- **M1 — Logical 40×40 board**: data-oriented Board State representation
  (no rendering yet).
- **M2 — Level data loading**: Level Loader reads Version 1 level data
  (`docs/03_LEVEL_DATA_SPEC.md`) into Board State.
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
- **M14 — Content pipeline**: tooling to author/import real 40×40 artwork
  into Version-N level data.
- **M15 — Polish/release preparation**: final pass before any release
  candidate.

Prompt 01 delivers **M0 only**. Do not begin M1 work in this task.
