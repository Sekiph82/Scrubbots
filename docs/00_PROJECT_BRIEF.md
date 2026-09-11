# 00 — Project Brief

## What SCRUBBOTS is

SCRUBBOTS is an original mobile puzzle game. Each level is a piece of pixel-art whose cells start **ACTIVE** at their canonical source color. The player dispatches tiny cleaning robots — **Scrubbots** — from five color slots to clear the visible artwork one logical cell at a time. A cleared cell becomes **CLEARED**: fully transparent, exposing the gameplay background through the hole it leaves.

There is no grime layer and no hidden second artwork. The visible artwork itself is progressively removed. See `docs/05_TECH_DECISIONS.md` ADR-019.

This is a from-scratch SCRUBBOTS implementation: own architecture, visuals, terminology, rules and level content. External games may be conceptual references only and are never sources to copy assets, levels, code or exact presentation from.

## Mobile puzzle-game objective

The player clears the logical artwork by choosing among the five color/robot slots. A Scrubbot may leave only when a valid reachable matching-color ACTIVE target exists. It travels to its reserved target, clears that logical cell and disappears. Clearing changes future accessibility because ACTIVE non-target cells block traversal while CLEARED/background space is open.

The intended tension is puzzle reasoning and resource/choice management rather than twitch reflexes.

## High-level player experience

1. A level opens as crisp pixel art on a variable-size logical grid.
2. Five color/robot slots are visible.
3. The player activates slots to dispatch Scrubbots.
4. Each Scrubbot receives one reachable matching target before it leaves.
5. The bot visibly travels across/around the board to that target.
6. On arrival the target becomes CLEARED and reveals BG01 through transparency.
7. Clearing may unlock previously enclosed cells and change the set of productive slot choices.
8. The level continues until the canonical win condition is reached.
9. Campaign sequencing deliberately alternates flow, tension, recovery and boss moments rather than increasing difficulty every single level.

## Variable-size logical board

Every puzzle uses a logical grid whose width and height come from level data. Cell count is always `width * height`; no gameplay system may assume a fixed board size or square board.

The current production-capable engine envelope remains **20..59 per dimension**, rectangular boards allowed, maximum **59x59 = 3,481 logical cells**. This is a capability/content envelope, **not a difficulty-class table**.

Owner-locked V1 guidance:

- 20..23: compact / intro / engineering / short-session boards;
- 24..40: preferred standard mobile-content sweet spot;
- 41..48: large boards requiring Session Load review;
- 49..59: exceptional/showcase/challenge-sized boards requiring strict Session Load and mobile-readability evidence.

A 24x24 level may be VERY_HARD. A 38x38 level may be EASY. Logical source dimensions do not determine physical on-screen size; `BoardRenderer` scales the logical image crisply to the available gameplay region.

See `docs/03_LEVEL_DATA_SPEC.md` for data representation and `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md` for the player-facing difficulty model.

## Canonical pixel-art palette

Production logical artwork uses only C01..C16 from `data/palettes/scrubbots_palette_v2.json`. Under Difficulty V1, production artwork normally uses **3..12 distinct canonical colors**, but the number of colors no longer defines EASY/MEDIUM/HARD/VERY_HARD by itself.

Color count, entropy and distribution contribute to the mathematical Challenge Score together with accessibility, unlock depth, bottlenecks, routing, slot pressure and workload.

## Difficulty and campaign rhythm

Difficulty is now a measured property, not a synonym for resolution.

Every ten-level block repeats the owner-locked sequence:

```text
1 EASY
2 EASY
3 MEDIUM
4 EASY
5 HARD
6 EASY
7 EASY
8 MEDIUM
9 EASY
10 VERY_HARD
```

The same rhythm repeats at every campaign age, while each lane grows through a saturating global progression curve. Therefore an EASY at level 311 is harder/richer than an EASY at level 11, but it remains a recovery/flow lane relative to the local MEDIUM/HARD/VERY_HARD peaks.

Every production candidate is analyzed on three separate axes:

- **Challenge Score** — structural/cognitive difficulty;
- **Session Load** — time/action/route burden;
- **Frustration Risk** — retry, late-failure and overlong-attempt risk.

Retention is treated as a first-class design constraint. Recovery levels, novelty, anti-repetition and challenge-vector diversity matter as much as escalation.

Canonical design:
- `coordination/OWNER_DIFFICULTY_PROGRESSION_DECISION_V01.md`
- `docs/09_DIFFICULTY_PROGRESSION_RETENTION_SYSTEM.md`
- `docs/10_LEVEL_FACTORY_GENERATION_SCORING_ARCHITECTURE.md`
- `docs/11_LEVEL_DIFFICULTY_CALIBRATION_QA.md`

## Level Factory philosophy

The Level Factory is not expected to generate a perfect puzzle in one random attempt. It is an evaluator-guided search system:

```text
target campaign envelope
→ generate candidate
→ validate
→ solve/simulate
→ measure Challenge / Session Load / Frustration / novelty
→ accept, mutate or reject
→ repeat under bounded deterministic budgets
```

This architecture makes large-scale generation feasible while keeping output reproducible and auditable.

## The five-slot concept

The player works with **5** visible color/robot slots. Slots are the player's means of introducing Scrubbots onto the board. Slot behavior contributes to the puzzle's measured pressure but future queue/cooldown mechanics must never be invented solely to manipulate difficulty.

## Scrubbot behavior

A Scrubbot leaves only when valid work exists. It receives one exact target, follows a valid route, clears that cell and disappears. It does not carry pixel color and does not return to the slot.

## Why movement matters

Watching Scrubbots cross the artwork is core visual identity, not incidental animation. `TargetSelector` decides WHAT cell is assigned and `RoutingSystem` decides HOW the Scrubbot travels there; those responsibilities remain separate and replaceable.

## Long-term player experience goal

SCRUBBOTS should create a repeating emotional waveform:

```text
flow → confidence → tension → recovery → mini-boss
→ strong recovery → novelty → tension → confidence → boss
→ relief → next cycle
```

The campaign becomes more sophisticated as the player advances without turning every later level into a longer grind. A level is successful when it is fair, readable, satisfying and appropriately demanding for its exact campaign position, not simply when it contains more pixels.
