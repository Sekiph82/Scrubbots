# OWNER M37 LEVEL SELECT DECISION V01

Status: OWNER LOCKED
Date: 2026-09-24
Scope: M37 Level Progression / SB-M37-006

## Decision

There will be **NO shipping Level Select** in ScrubBots V1.

The player progresses forward through the canonical progression frontier:
- complete current progression level;
- advance to the next progression level;
- no backwards manual level picker;
- no replay-by-select menu in the shipping flow unless a later owner decision explicitly changes this.

## Debug exception

A non-shipping debug/test seam such as `LevelProgressionService.debug_set_current_level(n)` is allowed for development, automated tests and calibration.

It must not be exposed as player-facing production UI.

## Closure effect

`SB-M37-006 Level select if approved` is resolved by owner decision as:
**NO SHIPPING LEVEL SELECT / DEBUG SEAM ONLY**.

No additional owner approval is required for this V1 decision.