# OWNER GAMEPLAY MASTER VISUAL V01

Date: 2026-09-19
Status: OWNER-APPROVED MASTER VISUAL
Repository: `Sekiph82/Scrubbots`
Scope: Canonical gameplay-screen visual reference.

## Canonical asset

Production-reference target path:

`assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`

Owner-local staging path:

`C:\Users\sekip\Desktop\ScrubBots\assets\ui\final\gameplay\master\scrubbots_gameplay_master.png`

The exact approved generated image is the visual master selected by the owner in the 2026-09-19 UI-design conversation.

The binary is now committed at the canonical repository path. `ASSET_GENERATION_MANIFEST.json` marks it `OWNER_APPROVED_IN_REPO`. Do not regenerate or substitute it.

## Visual authority

This master image is the highest-authority gameplay visual reference for:
- overall portrait composition;
- board-to-HUD proportions;
- Railroad V1 visual integration;
- full four-sided dark-slate/cyan railroad;
- five visible fixed slot-to-bottom-rail connectors;
- five execution-slot placement;
- color/count Batch Supply hierarchy;
- Scrubby/tutorial placement;
- four-booster row;
- top-left player/profile chip;
- top-right Pause + 2x controls;
- active timed-2x countdown presentation;
- absence of Settings, Heart HUD, Goal/Moves/Time and ad banner in the current gameplay reference.

Gameplay truth continues to come from the owner decisions and Godot runtime, not from pixels in this mockup.

## Supporting owner decisions

- `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`
- `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
- `coordination/OWNER_ECONOMY_REWARDS_V01.md`

## Asset policy

- STATUS: OWNER_APPROVED
- ROLE: canonical gameplay master visual
- REGENERATION: forbidden unless owner explicitly requests it
- PRODUCTION USE: reference for rebuilding the screen from Godot Controls + BoardRenderer + ScrubRailView; do not ship this flattened image as the interactive gameplay screen
