# M28-C001 V01 — Asset Approval Gate Report

## Inventory approval scan

`assets/art/references/inventory.json` status enumeration at implementation time:

- `CANONICAL_SELECTED` × 10  (layout/composition references only)
- `SUPPLIED_NOT_APPROVED` × 45
- `OWNER_REQUIRED` × 1
- `NOT_APPLICABLE` × 1
- **`PRODUCTION_APPROVED` / `APPROVED` × 0**

There is **no explicitly APPROVED gameplay illustration** for any gameplay-screen
role. Per the M28 prompt + criteria I, M28 therefore uses **neutral native
placeholder anchors** for Scrubby / speech / cleaning props, and binds **zero**
illustration assets.

## What was bound

Nothing. Every illustration role is a neutral `PanelContainer` placeholder
(`ScrubbyDecorationAnchor`, `ScrubbySpeechAnchor`, `CleaningPropsAnchor`), which is
production-ready to receive a later explicitly-approved asset without touching
layout. Boosters and the ad slot are neutral placeholders. Colors shown in slots /
supply are canonical LevelData palette colors (data, not art).

## Prohibitions honored

- ❌ No use of the canonical screenshot as a production background.
- ❌ No crop of Scrubby / props / icons from any reference.
- ❌ No promotion of `SUPPLIED_NOT_APPROVED` / `CANONICAL_SELECTED` references to
  production art.
- ❌ No AI image generation (0 image-generation credits spent).
- ❌ No owner reference image overwritten or modified.
- Untracked owner files under `assets/ui/final/**` (e.g. `scrubby_portrait.png`) were
  **preserved and NOT bound** — their inventory role is not marked APPROVED for the
  gameplay Scrubby anchor, so binding them would violate the gate.

## Ads / monetization

Ad area is a presentation placeholder only (`AdPlaceholder`, label "AD",
`MOUSE_FILTER_IGNORE`, no logic). Ads/IAP remain design-gated (M57). No monetization
enabled.
