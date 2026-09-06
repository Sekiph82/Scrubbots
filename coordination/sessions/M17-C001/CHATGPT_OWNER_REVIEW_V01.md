# M17-C001 — Owner Routing Review V01

Status: **OWNER_DESIGN_GATE**

Technical audit passed. No implementation correction is required before owner review.

## Claude role for this step

Claude is NOT implementing M18 and is NOT selecting a winner.

Claude should only help the owner review the existing debug lab:

`scenes/debug/routing_prototype_lab.tscn`

Open/run the scene in Godot 4.7.1 and guide the owner through the existing controls.

Do not modify code, tasks, trackers, audit files or production routing.

## Owner review

Compare:
- Direct
- Grid-aware
- Organized/curved

Inspect at minimum:
- S2 blocker/detour
- S3 enclosed/no-route
- S4 before/after clear
- S5 with 10 and 25 bots
- S7 59×59
- S8 53×59

Also toggle Organized **Curved rounding**.

Use the metric panel only as supporting evidence. The final choice is visual/game-feel owner judgment.

## Decision needed

Owner should report one of:

- `OWNER_SELECTS_DIRECT`
- `OWNER_SELECTS_GRID`
- `OWNER_SELECTS_ORGANIZED`
- `OWNER_REQUESTS_HYBRID: <short description>`
- `OWNER_REQUESTS_REVISION: <short description>`

SB-M17-010 remains open because no authoritative original SCRUBBOTS movement reference was found.

M18 must remain unopened until the owner decision is recorded.
