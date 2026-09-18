# OWNER GAMEPLAY SCREEN COMPOSITION V02

Date: 2026-09-19
Status: OWNER-LOCKED
Repository: `Sekiph82/Scrubbots`
Scope: Canonical production gameplay-screen composition and the owner playtest/reference mockup.

This decision supersedes gameplay-screen placement rules that conflict with it, including the older bottom-row Pause / ad / speed layout in `coordination/OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01.md`.

## 1. Canonical visual baseline

The owner-supplied gameplay image shown in the 2026-09-19 UI-design conversation is the visual/compositional baseline.

Preserve its core hierarchy:
- compact player/profile chip at top-left;
- very large pixel-art board as the dominant element;
- five execution slots immediately below the board;
- color/count Batch Supply panel below the slots;
- Scrubby/tutorial area low-left;
- four boosters in one horizontal row below the batch panel;
- glossy SCRUBBOTS industrial-cleaning world/background language.

Do not replace this composition with the separate railroad concept screenshot. The railroad screenshot is reference for Railroad V1 only.

## 2. Required Railroad V1 integration

The baseline gameplay screen must gain the already owner-locked Railroad V1 system without changing its core hierarchy.

Railroad geometry remains exactly as defined by:
- `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
- `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`

Presentation requirements:
- full four-sided reusable railroad around the pixel-art board;
- dark-slate metallic robotic rail;
- rounded mechanical corners;
- restrained cyan/electric guide nodes;
- exactly 2.0 logical-cell artwork-to-rail clearance;
- 1.0 logical-cell rail width;
- rail centreline 2.5 logical cells outside the board boundary;
- railroad remains visually subordinate to pixel art;
- no level-specific railroad skin in V1.

## 3. Five permanent slot-to-rail connectors

Normal gameplay shows five execution slots below the board.

Each slot has a permanent visible connector rail to the BOTTOM Railroad V1 rail:
- connector begins at the exact SlotCell/Scrubbot spawn anchor;
- connector terminates on the bottom-rail centreline at that slot's mapped board-local x;
- connector is real Scrubbot travel, not decoration and not teleport;
- all five connectors are visible even while their slots are empty, so the movement infrastructure is understandable before dispatch;
- connectors use the same dark-slate/cyan railroad language but may be visually lighter/thinner than the main loop;
- connectors must not overlap batch values or make the supply panel unreadable.

Economy V1 +1 Slot may later add a sixth connector only while the sixth slot exists. The baseline/test image shows five.

## 4. Batch Supply / execution-slot structure

The owner baseline Batch Supply area is retained.

Production flow must read visually as:

`Batch Supply -> execution slot -> slot connector -> bottom railroad -> main railroad -> legal ingress -> pixel target`

Rules:
- normal slot capacity is five;
- player chooses a legal front/top color-count batch from a supply column;
- player does not choose a destination slot;
- accepted batch is automatically placed in the authoritative rightmost EMPTY execution slot;
- batch color and count remain live Godot UI;
- Railroad integration must not remove or hide the Batch Supply panel.

## 5. Top-right controls

Gameplay top-right contains exactly two primary controls side by side:

`PAUSE | 2x`

- Settings is removed from the gameplay screen.
- Hearts are not shown on the gameplay screen.
- Goal/Moves/Time HUD is not shown.
- Pause remains a normal pause control.
- 2x is the only gameplay speed control.

The 2x button has these presentation states:
1. inactive/available: displays `2x`;
2. active current-level entitlement: selected/pressed 2x state;
3. active timed entitlement: selected/pressed state whose live label becomes remaining wall-clock time (for example `14:38`);
4. unavailable/not entitled: tapping opens the Economy V1 purchase/entitlement flow rather than enabling free manual 2x.

Timed 2x continues counting in gameplay, menus, pause, background and while the app is closed, per Economy V1.

Automatic M23-exhausted 2x remains free.

## 6. Hearts / failure presentation

No Heart HUD is present during normal gameplay.

Heart state appears in the failure/retry flow after a failed attempt, where the player can see remaining Hearts and any refill/retry choices.

Heart economy remains defined by `coordination/OWNER_ECONOMY_REWARDS_V01.md`.

## 7. Advertising in the current gameplay reference

For the owner playtest/reference image being generated now:
- **NO ad banner/placeholder is shown**;
- the freed lower-screen height is returned to gameplay readability, primarily board/rail/batch spacing;
- this is a visual/playability test reference, not a monetization-layout test.

This does NOT authorize or forbid shipping gameplay advertising. Real ad behavior remains under M57 Real-Money Monetization owner decisions.

If ads are later approved for shipping gameplay, their layout must be revisited explicitly; do not infer a permanent always-playing banner from historical concept art.

## 8. Scrubby and four boosters

Scrubby remains low-left beside the selection/batch region, with optional speech-bubble space for tutorial messaging.

Exactly four Economy V1 boosters appear in one compact row:
- +1 Slot
- Random
- Selector
- Tornado

Booster quantities/prices/states are live Godot UI, not baked into generated art.

## 9. Settings removal

Settings is fully removed from the gameplay screen composition.

Settings remains reachable from appropriate navigation/pause flows defined later, but it must not occupy a gameplay-screen button slot.

## 10. Visual-reference generation target

The immediate owner reference/mockup should:
- start from the supplied canonical gameplay screen composition;
- preserve the existing board, Batch Supply, five slots, Scrubby and four-booster hierarchy;
- add full Railroad V1 around the board;
- add five visible fixed connector rails from the five slots to the bottom rail;
- place Pause and 2x side by side at top-right;
- show a timed 2x active example with countdown if useful for clarity;
- remove bottom Settings;
- remove Heart HUD;
- remove bottom ad banner/placeholder for this test image;
- avoid Goal/Moves/Time panels;
- keep board/pixel art dominant and readable.

This generated image is a visual reference, not a flattened shipping screen. Production remains native Godot Controls + BoardRenderer + ScrubRailView.

## 11. Precedence

This decision supersedes conflicting placement/composition wording in:
- `coordination/OWNER_GAMEPLAY_BOTTOM_ROW_SPEED_DECISION_V01.md`
- older `docs/MASTER_UI_SYSTEM.md` bottom-row layout text
- historical M28 wording that places Pause/ad/speed on the bottom row
- gameplay concept art that includes Settings or a mandatory bottom ad banner

It does not supersede Railroad V1 geometry/routing, Economy V1 pricing/entitlements, batch-supply truth, five-slot baseline mechanics, or M23-exhausted free automatic 2x.
