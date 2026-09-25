# M42 HOME COMPOSED RUNTIME VISUAL AUDIT V01

Date: 2026-09-25
Auditor: ChatGPT
Runtime evidence: owner-supplied Godot DEBUG screenshot after the opening cinematic, showing the production Home screen at the editor's displayed 683x1366 window scale.
Repository HEAD inspected: `730a92686cac825420da15186538264a1e2de616`

## Verdict

**CHANGES_REQUIRED / SB-M42-011 / SB-M42-017**

The owner-asset approval and deterministic manifest promotion are valid and remain closed. This finding is specifically about the live composed Home integration.

The runtime screenshot proves that approved bytes being available through `HomeArtBinder` is not the same as the approved Home art being correctly composed on screen.

## Runtime findings

1. **Play CTA art missing**
   - Approved `HOME-078 / play_button_frame` is not visible.
   - Runtime shows plain live `PLAY` text directly on the street background.

2. **Bottom navigation art missing**
   - Approved `HOME-101..105` navigation icons are not visible.
   - Runtime shows text-only EVENTS / ROBOTS / HOME / RANKS / SETTINGS.

3. **Canonical central-world banner is missing**
   - Approved `HOME-006 / home_arch_whispering_park` and `HOME-007 / home_arch_decor` are not visible.
   - Manifest LIVE entries for area title/number are not represented in the runtime composition.

4. **Central platform composition is wrong**
   - Scrubby and `home_platform_main` occupy the same centered region.
   - The platform visibly crosses behind Scrubby's torso/waist instead of reading as the platform he stands on.
   - Approved `HOME-011 / home_platform_top` is not integrated.

5. **Environment and helper-bot art is absent**
   - Approved HOME-013..021 environment props and HOME-022..024 helper bots are not visible in the composed world.

6. **Top-HUD decorative art is absent**
   - Approved profile avatar frame and rank badge (HOME-034/035) are not visible.
   - Gift Meter emblem/reward crate (HOME-051/054) are not visible.

7. **Win Streak reward-track art is absent**
   - Approved reward badge, Scrub Bucks reuse icon and reward gift art (HOME-086/087/090..094) are not visually composed.
   - Runtime is essentially text-only chips over the street.

8. **Shortcut labels are clipped**
   - Runtime visibly truncates labels such as `WIN STR...`, `COLLECT...` and `CARDS EXC...`.
   - Full live/localizable labels must remain readable at the canonical viewport.

9. **Disabled-state readability is too weak**
   - Several disabled/future shortcuts are heavily dimmed over a detailed background, producing poor legibility.
   - Disabled state may remain visually distinct, but label/icon readability still has to survive.

## Independent source cross-check

Current `scripts/ui/home/home_screen.gd` maps only:

- 6 slugs through `LAYER_ART`;
- 10 slugs through `ICON_ART`.

That is only **16 direct presentation mappings** for a manifest containing **50 approved ART entries**.

The unmapped set includes many assets that are clearly intended for the current Home composition, including the arch/decor, platform top, environment props, helper bots, profile art, Gift Meter art, Play frame, reward-track art and all five bottom-nav icons.

Specific source causes:

- `WORLD_LAYERS` contains only `central_world_and_environment` and `characters`, each as a full-rect centered TextureRect. This cannot independently position the platform, platform top, props, helper bots, banner and Scrubby.
- `_build_hud()` creates native progress/value controls but no nodes for HOME-034/035.
- `_build_gift_meter()` creates only a native progress meter, with no HOME-051/054 presentation nodes.
- the Play button is a plain native Button and does not consume HOME-078.
- `_build_track()` creates only five `UiValueChip` nodes and does not consume HOME-086/087/090..094.
- `_build_bottom_nav()` creates text Buttons and the binding map does not include HOME-101..105.
- no area-title/area-number live nodes are built for the central world.

Therefore the prior test statement that `HomeArtBinder.summary() == {"APPROVED_BOUND": 50}` proves hash/lifecycle availability, not actual on-screen integration of 50 approved ART entries.

## Gate impact

- SB-M42-014 remains **AUDITED_PASS**.
- SB-M42-016 remains **AUDITED_PASS**.
- SB-M42-018 remains **AUDITED_PASS**.
- SB-M42-011 changes from owner-visual-review-only to **CHANGES_REQUIRED**.
- SB-M42-017 changes from owner-visual-review-only to **CHANGES_REQUIRED**.

No approved PNG may be regenerated or modified as part of remediation.

## Required remediation outcome

Recompose Home using the already owner-approved assets, preserve all live/dynamic text and native interaction controls, remove visible clipping/overlap problems, validate the viewport matrix, and return to owner visual review only after the runtime screen actually presents the intended approved composition.
